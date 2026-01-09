trigger OpportunityTrigger on Opportunity (After update, Before update, Before delete) {
    List<Id> OppIdSet = new List<Id>();
    Set<Id> accountIds = new Set<Id>();
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    Map<Id, List<OpportunityLineItem >> oppItemsMap = new Map<Id, List<OpportunityLineItem >>();
    List<Opportunity> opps = new List<Opportunity>();
    String profileName = [SELECT Name FROM Profile WHERE Id =:UserInfo.getProfileId()].Name;
    
    if( Trigger.isBefore ) {
        if( Trigger.isDelete ) {
            for( Opportunity opp : Trigger.old ) {
                String recordTypeName = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.RecordTypeId).getDeveloperName();
                if(recordTypeName != 'Recurring_Orders' && opp.Line_Item_Count__c > 0 && (profileName == 'Pansar Sales Person' ||profileName == 'Pansar Branch Management')) {
                    opp.addError('This Enquiry cannot be deleted because there is already a line item. Please contact your System Administrator for further assistance.');
                }
            }
        }
    }
    
    if( Trigger.isUpdate) {
        for(Opportunity opp : Trigger.New){
            if(Trigger.isAfter ==  true)
            {
                if((opp.Line_Item_Count__c != Trigger.oldMap.get(opp.Id).Line_Item_Count__c) && opp.Line_Item_Count__c >0)
                {
                    OppIdSet.add(opp.Id);
                }
            }
            else
            {
                if((opp.accountId != Trigger.oldMap.get(opp.Id).accountId))
                {  
                    accountIds.add(opp.accountId); 
                }
            }
        }
        
        for(Opportunity opp : Trigger.New){
            if(!accountIds.isEmpty()){
                if(Trigger.isBefore && (opp.accountId != Trigger.oldMap.get(opp.Id).accountId) && (!accountIds.isEmpty())){
                    Map<Id, Id> OppIdTerritoryIdResult = new OppTerrAssignDefaultLogicFilter().getTerritoryAccountChange(Trigger.New , accountIds);
                    system.debug('OppIdTerritoryIdResult: '+OppIdTerritoryIdResult);
                    if(!OppIdTerritoryIdResult.isEmpty())
                    {   
                        for (ID oppid : OppIdTerritoryIdResult.keySet()){
                            if(opp.id == oppid)
                                opp.Territory2Id = OppIdTerritoryIdResult.get(oppid);
                            system.debug('Territory2Id : '+opp.Territory2Id);
                        }
                    }  
                }
            }
            
            if(!OppIdSet.isEmpty()){
                if(Trigger.isAfter && opp.Line_Item_Count__c != Trigger.oldMap.get(opp.Id).Line_Item_Count__c){
                    Integer maxItemNo = 1;
                    for (OpportunityLineItem oppItem : [SELECT Id, Name, Item_No__c, OpportunityId FROM OpportunityLineItem 
                                                        where OpportunityId IN: OppIdSet Order by Product2.Name ASC])
                    { 
                        system.debug('oppItem : '+oppItem);
                        if(!oppItemsMap.containsKey(oppItem.OpportunityId)){
                            oppItemsMap.put(oppItem.OpportunityId, new List<OpportunityLineItem >{oppItem});
                        }
                        else{
                            oppItemsMap.get(oppItem.OpportunityId).add(oppItem);
                        } 
                    }
                    
                    if(!oppItemsMap.isEmpty())
                    {
                        for (Id key : oppItemsMap.keySet()) {
                            for (OpportunityLineItem item : oppItemsMap.get(key))
                            {
                                item.Item_No__c = maxItemNo;
                                maxItemNo = maxItemNo + 1;
                                olis.add(item);
                            }
                        }
                    }
                } 
            }
        }
        
        if(!olis.isEmpty()){
            system.debug('Opp Line Items: '+olis);
            try{
                update olis;
            }
            catch (Exception e) {
                System.debug(e.getMessage());
            }
        } 
    } 
}