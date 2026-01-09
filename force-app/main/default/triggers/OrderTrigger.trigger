trigger OrderTrigger on Order (before delete) {
    
    String profileName = [SELECT Name FROM Profile WHERE Id =:UserInfo.getProfileId()].Name;
    if( Trigger.isBefore ) {
        if( Trigger.isDelete ) {
            for( Order order : Trigger.old ) {
                String recordTypeName = Schema.SObjectType.Order.getRecordTypeInfosById().get(order.RecordTypeId).getDeveloperName();
                Opportunity oppDel;

                if(order.OpportunityId != null) oppDel = new Opportunity(Id = order.OpportunityId);
                system.debug('oppDel : '+oppDel);
                if((profileName == 'Pansar Sales Person' || profileName == 'Pansar Branch Management') && ((recordTypeName != 'Recurring_Orders') || (recordTypeName == 'Recurring_Orders' && order.Line_Item_Count__c > 0))){
                        order.addError('This Order cannot be deleted because there is already a line item. Please contact your System Administrator for further assistance.');
                    }
                else if(recordTypeName == 'Recurring_Orders' && oppDel != null) delete oppDel;
            }
        }
    }
}