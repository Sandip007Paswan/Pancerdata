trigger QuoteTrigger on Quote (After update) {
//Before insert, Before update, After update,
    /*Set<Id> quoteIdSet = new Set<Id>();
    List<QuoteLineItem> olis = new List<QuoteLineItem>();
    Map<Id, List<QuoteLineItem >> quoteItemsMap = new Map<Id, List<QuoteLineItem >>();
    
    for(Quote quote : Trigger.New){
        if((quote.LineItemCount != Trigger.oldMap.get(quote.Id).LineItemCount))
        {
            quoteIdSet.add(quote.Id);
        }
    }
    
    if(!quoteIdSet.isEmpty()){
        Integer maxItemNo = 1;
        for (QuoteLineItem quoteItem : [SELECT Id, Item_No__c, QuoteId FROM QuoteLineItem 
                                        where QuoteId IN: quoteIdSet
                                        Order by Id ASC])
        { 
            
            if(!quoteItemsMap.containsKey(quoteItem.QuoteId)){
                quoteItemsMap.put(quoteItem.QuoteId, new List<QuoteLineItem >{quoteItem});
            }
            else{
                quoteItemsMap.get(quoteItem.QuoteId).add(quoteItem);
            } 
        }
        
        
        if(!quoteItemsMap.isEmpty())
        {
            for (Id key : quoteItemsMap.keySet()) {
                for (QuoteLineItem item : quoteItemsMap.get(key))
                {
                    item.Item_No__c = maxItemNo;
                    maxItemNo = maxItemNo + 1;
                    olis.add(item);
                }
            }
        }
        
    }
    
    if(!olis.isEmpty()){
        system.debug('olis: '+olis);
        update olis;
    }*/

}