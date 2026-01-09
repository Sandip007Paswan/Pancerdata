public without sharing class OrderController 
{
    @AuraEnabled
    public static List<Order> getOrderDetails(Id recordId, Id accountId) 
    {
        system.debug('accountId '+accountId);
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> orderAccountIdSet = new Set<Id>();
        List<Order> order = new List<Order>();
        List<Order> orderAccount = new List<Order>();
        List<Order> newOrder = new List<Order>();
        
        List<OrderItem> orderItems = [SELECT Product2Id, Product2.ProductCode, Product2.Name,
                                      Product2.Description, UnitPrice, Quantity, ListPrice, CreatedDate, LastModifiedDate
                                      FROM OrderItem where orderId =: recordId];
        
        if(!orderItems.isEmpty()) for (OrderItem item : orderItems) productIdSet.add(item.Product2Id);
        
        system.debug('productIdSet '+productIdSet);
        
        if(!productIdSet.isEmpty())
        {
            orderAccount = [SELECT  Id, OrderNumber, CreatedDate, LastModifiedDate, AccountId, Account.Name,
                            (SELECT Product2Id, Product2.ProductCode, Product2.Name,
                             Product2.Description, UnitPrice, Quantity, ListPrice, CreatedDate, LastModifiedDate
                             FROM OrderItems where Product2Id IN: productIdSet) FROM Order 
                            WHERE AccountId = :accountId and id !=: recordId
                            ORDER BY CreatedDate DESC LIMIT 50];
            system.debug('orderAccount '+orderAccount);
            
            if(!orderAccount.isEmpty() && orderAccount.size() >0) for (Order o : orderAccount) orderAccountIdSet.add(o.Id);
            
            if(!orderAccountIdSet.isEmpty())
            {
                order = [SELECT  Id, OrderNumber, CreatedDate, LastModifiedDate, AccountId, Account.Name,
                         (SELECT Product2Id, Product2.ProductCode, Product2.Name,
                          Product2.Description, UnitPrice, Quantity, ListPrice, CreatedDate, LastModifiedDate
                          FROM OrderItems WHERE Product2Id IN: productIdSet) FROM Order 
                         WHERE id !=: recordId  AND Id NOT IN: orderAccountIdSet
                         ORDER BY CreatedDate DESC LIMIT 50];
                if(!order.isEmpty()) order = reOrder(order);

            }

            if(!orderAccount.isEmpty() && orderAccount.size() >0)
            {
                newOrder = reOrder(orderAccount);
                if(newOrder.size() < 5 && !order.isEmpty())
                {
                    Integer count = newOrder.size();
                    for(Order o : order) 
                    {
                        if(count < 5)
                        {
                            newOrder.add(o);
                            count = count+1;
                        }
                    }   
                }
            }
            else if(!order.isEmpty()) newOrder = reOrder(order);    
            system.debug('newOrder '+newOrder);   
        }
        
        return newOrder;

    }
    
    public static List<Order> reOrder(List<Order> orderList)
    {
        List<Order> reOrder = new List<Order>();
        Integer count =0;
        for(Order o : orderList)
        {
            if(!o.OrderItems.isEmpty() && count<5)
            {
                reOrder.add(o);
                count = count+1;
            }
        }
        return reOrder;
    }
    
    /*  public class ATPTimelineWrapper
{
@AuraEnabled        
public Date atpDate { get; set; }
@AuraEnabled        
public String atpDateDisplay { get; set; }        
@AuraEnabled
public List<OrderItem> products { get; set; }
}


Map<Date, ATPTimelineWrapper> atpTimelines = new Map<Date, ATPTimelineWrapper>();
for (OrderItem item : orderItems)
{
Date atpDate = system.today();
if (!atpTimelines.containsKey(atpDate))
{
ATPTimelineWrapper atpTimeline = new ATPTimelineWrapper();
atpTimeline.atpDate = system.today();
//atpTimeline.atpDateDisplay = item.Availability_to_Promise_ATP_Display__c;
atpTimeline.products = new List<OrderItem>();
atpTimelines.put(atpDate, atpTimeline);
}
atpTimelines.get(atpDate).products.add(item);
}
return atpTimelines.values();*/
}