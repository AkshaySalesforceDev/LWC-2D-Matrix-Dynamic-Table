/**
 * @description       : Apex class for generating the data for table
 * @author            : Akshay S
 **/
public without sharing class RateCardGeneratorController { 

    /**
    * @description       : getLMSolutionTypePicklistValues method will help to get picklist values for LM solution type field 
    **/
    @AuraEnabled(cacheable=true)
    public static List<string> getLMSolutionTypePicklistValues(String xbservice, String destinationcountry) {
        List<String> lmstList = new List<String>();
        for (LM_Solution_Type__mdt lmstItem : [
            SELECT LM_Solution_Type__c
            FROM LM_Solution_Type__mdt
            WHERE Required_XB_Services__c = :xbservice AND XB_Destination_Country__c = :destinationcountry
        ]) {
            lmstList.add(lmstItem.LM_Solution_Type__c);
        }
        
        return lmstList;
    }

    /**
    * @description       : getE2ERatelst method will help to query the rate card record 
    **/
    public static list<XB_Rate_Card__c> getE2ERatelst(WrapperObject wrapperObj){
        return [
            select Id,Weight_Break__c,Rate__c,Service_Code__c,XB_Charging_Currency__c,Estimated_SLA__c,Destination_Country__c,Freight_Type__c, Terms_Conditions__c,E2E_Standard_Liability__c
            from  XB_Rate_Card__c where 
            XB_Service_Rate_Card__c = 'E2E Rate' AND Destination_Country__c =:wrapperObj.destinationcountryvalue
            AND Rates_Start_Date__c <= :wrapperObj.quoteDateValue AND Rates_End_Date__c >= :wrapperObj.quoteDateValue
            AND Freight_Mode_XB__c =:wrapperObj.freightmodexbvalue
            AND XB_Sales_Channel__c =:wrapperObj.xbsaleschannelvalue AND XB_Charging_Currency__c =:wrapperObj.XBCurrencyValue
            AND B2B_B2C__c =:wrapperObj.b2bb2cvalue AND Origin_Country__c =:wrapperObj.origincountryvalue AND E2E_Rate_Tier__c=:wrapperObj.E2ERateTierValue Order by Weight_Break__c, Destination_Region__c]; 
    }
    
    /**
    * @description       : WrapperObject method will wrap the data
    **/
    public class WrapperObject {
        @AuraEnabled
        public String xbservicevalue { get; set; }
        @AuraEnabled
        public String destinationcountryvalue { get; set; }
        @AuraEnabled
        public String xbsaleschannelvalue { get; set; }
        @AuraEnabled
        public Date quoteDateValue { get; set; }
        @AuraEnabled
        public String codvalue { get; set; }
        @AuraEnabled
        public String lmsolutionValue { get; set; }
        @AuraEnabled
        public String codRateTierValue { get; set; }
        @AuraEnabled
        public String freightmodexbvalue { get; set; }
        @AuraEnabled
        public String b2bb2cvalue { get; set; }
        @AuraEnabled
        public String LMRateTierValue { get; set; }
        @AuraEnabled
        public String E2ERateTierValue { get; set; }
    }

    /**
    * @description       : getE2ERateCards method will get the data for E2E rate cards
    **/
    @AuraEnabled(cacheable=true)
    public static MatrixTable getE2ERateCards(WrapperObject wrapperObj){
        if(wrapperObj.xbservicevalue =='E2E'){
            return creatingMatrixForE2ERate(getE2ERatelst(wrapperObj),wrapperObj);
        }
        
        return null;
    }
    
    /**
    * @description       : creatingMatrixForE2ERate method will create the data for table
    **/
    private static MatrixTable creatingMatrixForE2ERate(list<XB_Rate_Card__c> E2ERates, WrapperObject wrapperObj){
        MatrixTable matTbl = new MatrixTable();
        matTbl.mxHeaders = new list<String>();
        matTbl.RatecardIds = new list<String>();
        
        //first matrix header cell
        String firstheaderKey = getFieldLabel('XB_Rate_Card__c', 'Weight_Break__c')+'/'+getFieldLabel('XB_Rate_Card__c', 'Freight_Type__c');
        matTbl.mxHeaders.add(firstheaderKey);
        
        //last matrix header cell
        String lastheaderKey = getFieldLabel('XB_Rate_Card__c', 'XB_Charging_Currency__c');
        
        //last slaFieldLabel
        String slaFieldLabel =  getFieldLabel('XB_Rate_Card__c', 'Estimated_SLA__c');
        
        set<String> restHorizontalHeaders = new set<String>();
        map<String, map<String,String> >  mxdatasMap = new map<String, map<String,String> >();
        
        String estimatedSLA,termAndCondValue,E2EStandardLiabilityValue;
        
        string destinationCountry = wrapperObj.destinationcountryvalue;
        String originCountry = wrapperObj.origincountryvalue;
        string rateChargingUnit = wrapperObj.rateChargingUnitValue;
        string chargingCurrency = wrapperObj.XBCurrencyValue;
        string freightMode = wrapperObj.freightmodexbvalue;
        string salesChannel = wrapperObj.xbsaleschannelvalue;
        
        String query = 'SELECT Freight_Type__c,Sort_Order__c FROM E2E_Rate__mdt '+
            'WHERE Destination_Country_XB__c =:destinationCountry AND Origin_country_XB__c =:originCountry '+
            'AND XB_Charging_Currency__c =:chargingCurrency AND Freight_Mode__c=:freightMode AND Sales_Channel__c=:salesChannel Order By Sort_Order__c ASC';
        
        List<E2E_Rate__mdt> lmlst = Database.query(query);
        for (E2E_Rate__mdt lmstItem : lmlst) {        
            restHorizontalHeaders.add( lmstItem.Freight_Type__c );
        }
        
        map<String,String> estimatedSLAMap = new map<String,String>();
        estimatedSLAMap.put( firstheaderKey , slaFieldLabel ); //first header mapping for sla row
        
        for(XB_Rate_Card__c rateCard : E2ERates){
            if( termAndCondValue == null && rateCard.Terms_Conditions__c != null ){
                termAndCondValue = rateCard.Terms_Conditions__c;
            }
            
            if( E2EStandardLiabilityValue == null && rateCard.E2E_Standard_Liability__c != null ){
                E2EStandardLiabilityValue = rateCard.E2E_Standard_Liability__c;
            }
            if( rateCard.Weight_Break__c != null){
                if(!mxdatasMap.containskey( rateCard.Weight_Break__c ) ){
                    map<String,String> cellMap = new map<String,String>();
                    
                    cellMap.put( firstheaderKey, rateCard.Weight_Break__c );
                    cellMap.put( lastheaderKey , rateCard.XB_Charging_Currency__c );
                    mxdatasMap.put( rateCard.Weight_Break__c, cellMap );
                }
                mxdatasMap.get( rateCard.Weight_Break__c ).put(rateCard.Freight_Type__c, String.valueOf(rateCard.Rate__c) );
                estimatedSLAMap.put( rateCard.Freight_Type__c, rateCard.Estimated_SLA__c );
            }     
        }
        estimatedSLAMap.put(lastheaderKey,'   ');
        mxdatasMap.put( slaFieldLabel , estimatedSLAMap );
        
        //matTbl.mxHeaders.add( lastheaderKey );
        restHorizontalHeaders.add(lastheaderKey);
        matTbl.mxHeaders.addAll(restHorizontalHeaders);
        matTbl.mxdatas = mxdatasMap.values();
        
        matTbl.E2EStandardLiabilityLabel  =  getFieldLabel('XB_Rate_Card__c', 'E2E_Standard_Liability__c');
        matTbl.E2EStandardLiabilityValue =  E2EStandardLiabilityValue;
        
        // t&c Mapping 
        matTbl.termAndCondLabel =  getFieldLabel('XB_Rate_Card__c', 'Terms_Conditions__c');
        matTbl.termAndCondValue =  termAndCondValue;
        
        return matTbl;
        
    }

    /**
    * @description       : MatrixTable method will wrap the data to form matrix table
    **/
    public class MatrixTable{
        @AuraEnabled
        public list<String> mxHeaders{get; set;}
        @AuraEnabled
        public list<map<String,String>> mxdatas{get; set;}

        @AuraEnabled 
        public String slaFieldLabel{get; set;}
        @AuraEnabled 
        public String slavalue{get; set;}

        @AuraEnabled 
        public String E2EStandardLiabilityLabel{get; set;}
        @AuraEnabled 
        public String E2EStandardLiabilityValue{get; set;}
    
        @AuraEnabled 
        public String termAndCondLabel{get; set;}
        @AuraEnabled 
        public String termAndCondValue{get; set;}
        @AuraEnabled 
        public list<String> rateCardIds{get; set;}

    }
    
    /**
    * @description       : getFieldLabel method will get the field lable
    **/
    @AuraEnabled
    public static String getFieldLabel(String objectName, String fieldName) {
        String label;
        try {
            // Get the SObject Describe result for the specified object
            Schema.DescribeSObjectResult sObjectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            
            // Get the field describe result for the specified field
            Schema.DescribeFieldResult fieldDescribe = sObjectDescribe.fields.getMap().get(fieldName).getDescribe();
            
            // Retrieve the field label
            label = fieldDescribe.getLabel();
        } catch (Exception e) {
            // Handle any exceptions or errors that may occur
            System.debug('Error retrieving field label: ' + e.getMessage());
            label = '';
        }
        
        return label;
    }
}