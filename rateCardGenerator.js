import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getLMSolutionTypePicklistValues from '@salesforce/apex/XBRateCardGeneratorController.getLMSolutionTypePicklistValues';
import getE2ERateCards from '@salesforce/apex/XBRateCardGeneratorController.getE2ERateCards';
import QUOTE_OBJECT from '@salesforce/schema/Quote';
import QUOTE_OBJECT from '@salesforce/schema/Quote';


// const variable to store Quote Record Fields
const QUOTE_FIELDS = [
    'Quote.Opportunity.Required_XB_Services__c',
    'Quote.Opportunity.XB_Sales_Channel__c',
    'Quote.Opportunity.XB_Origin_Country__c',
    'Quote.Opportunity.XB_Destination_Country__c',
    'Quote.Opportunity.B2B_or_B2C__c',
    'Quote.Opportunity.Freight_Mode_XB__c',
    'Quote.Opportunity.COD_Non_COD__c',
    'Quote.LM_Rate_Tier__c',
    'Quote.COD_Rate_Tier__c',
    'Quote.E2E_Rate_Tier__c'
];

// const variable to store user input values
const eventHandlerMap = {
    handleE2ERateTier: 'E2ERateTierValue',
    handleCODRateTier: 'CODRateTierValue',
    handleLMRateTier: 'LMRateTierValue',
    handleLMSolutionType: 'LMSolutionValue',
    handleQuoteDate: 'QuoteDateValue'
}

export default class RateCardGenerator extends LightningElement {

    // wire decorator to get object info for Quote Object
    @wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
    objectInfo;

    //Variables to store picklist values
    @track E2ERateTierFilterOptions = [];
    @track LMRateTierOptions = [];
    @track CODFilterOptions = [];
    @track E2ERateData;

    // Variable to store Quote's Opportunity Values
    @track freightmodexbvalue;
    @track xbservicevalue;
    @track origincountryvalue;
    @track destinationcountryvalue;
    @track xbsaleschannelvalue;
    @track b2bb2cvalue;
    @track codvalue;
    @track lmRateTier;
    @track codRateTier;
    @track e2eRateTier;

    // wire decorator to get field values
    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    wiredQuote({ error, data }) {
        if (data) {
            this.record = data;
            this.xbservicevalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.Required_XB_Services__c');
            this.xbsaleschannelvalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.XB_Sales_Channel__c');
            this.origincountryvalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.XB_Origin_Country__c');
            this.destinationcountryvalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.XB_Destination_Country__c');
            this.b2bb2cvalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.B2B_or_B2C__c');
            this.freightmodexbvalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.Freight_Mode_XB__c');
            this.codvalue = getFieldValue(data, '@salesforce/schema/Quote.Opportunity.COD_Non_COD__c');
            this.lmRateTier = getFieldValue(data, '@salesforce/schema/Quote.LM_Rate_Tier__c');
            this.codRateTier = getFieldValue(data, '@salesforce/schema/Quote.COD_Rate_Tier__c');
            this.e2eRateTier = getFieldValue(data, '@salesforce/schema/Quote.E2E_Rate_Tier__c');
            this.LMRateTierValue = this.lmRateTier;
            this.CODRateTierValue = this.codRateTier;
            this.E2ERateTierValue = this.e2eRateTier;
        } else if (error) {
            console.error('Error retrieving Quote record:', JSON.stringify(error));
        }       
    }

    // wire decorator to get picklist values
    @wire(getPicklistValuesByRecordType, {
        objectApiName: QUOTE_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })

    // function to store picklist values in array list varibales
    wiredPicklistValuesData({ error, data }) {
        if (data) {
            console.log(data);
            this.E2ERateTierFilterOptions = data.picklistFieldValues.E2E_Rate_Tier__c.values;
            this.LMRateTierOptions = data.picklistFieldValues.LM_Rate_Tier__c.values;
            this.CODFilterOptions = data.picklistFieldValues.COD_Rate_Tier__c.values;
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }

    // wire decorator to get LM picklist values from salesforce
    @wire(getLMSolutionTypePicklistValues, { xbservice: '$xbservicevalue', destinationcountry: '$destinationcountryvalue' })
    wiredlstdata({ error, data }) {
        try {
            if (data) {

                var LMFilterOptions = [];
                for (var d in data) {
                    LMFilterOptions.push({
                        label: data[d],
                        value: data[d]
                    });
                }
                this.LMFilterOptions = LMFilterOptions;
            }
        } catch (e) {
            console.log('error-2', e.body.message);
        }
    }

    // wire decorator to get object info for Rate Cards
    @wire(getObjectInfo, { objectApiName: XB_Rate_Card })
    XBRateCardInfo;

    // function to get the input value of user
    handleComboboxChange(event) {
        const propertyName = eventHandlerMap[event.target.name];
        if (propertyName) {
            this[propertyName] = event.detail.value;
        }
    }

    // function to execute once user click on submit button
    async handleSubmit() {
        const inputFields = this.template.querySelectorAll('lightning-input,lightning-combobox');
        let allFieldsFilled = true;
        inputFields.forEach(field => {
            const isFieldRequired = field.required;
            if (isFieldRequired) {
                if (!field.value) {
                    // Field is required and empty
                    field.setCustomValidity('Please fill in all required fields');
                    field.reportValidity();
                    allFieldsFilled = false;
                } else {
                    field.setCustomValidity('');
                    field.reportValidity();
                }
            }
        });

        if (allFieldsFilled) {
            const inputwrapper = this.getInputWrapper();
            let xbE2EMatrixDatas = await this.getE2ERateCardsHelper( inputwrapper ); 
            }
    }

    // function to get data for Rate Card table
    async getE2ERateCardsHelper( inputwrapper ){
        return getE2ERateCards({ wrapperObj: inputwrapper }).then(result => { 
            // Handle success
            console.log(result);
            this.E2ERateData = result;
            return result; 
        }).catch(error => {
            // Handle error
            this.error = error;
        });
    }

    // function to create wrapper object and send it to apex controller
    getInputWrapper(){
        const inputwrapper = {
            xbservicevalue: this.xbservicevalue,
            destinationcountryvalue: this.destinationcountryvalue,
            xbsaleschannelvalue: this.xbsaleschannelvalue,
            quoteDateValue: this.QuoteDateValue,
            codvalue: this.codvalue,
            lmsolutionValue: this.LMSolutionValue,
            codRateTierValue: this.CODRateTierValue,
            freightmodexbvalue: this.freightmodexbvalue,
            b2bb2cvalue: this.b2bb2cvalue,
            origincountryvalue : this.origincountryvalue,
            LMRateTierValue : this.LMRateTierValue,
            E2ERateTierValue: this.E2ERateTierValue,
        };
        return inputwrapper;
    }       
}
