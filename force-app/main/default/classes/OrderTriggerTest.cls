@isTest
public class OrderTriggerTest {
    
    public static Account account ;
    public static Account account1 ;
    public static Product2 pro ;
    public static PricebookEntry pb ;
    public static OrderItem mNewOrderItem;
    public static Order order ;
    
    
    @testSetup static void setupData()
    {
        Id pricebookId = Test.getStandardPricebookId();
        insert account = new Account(Name = 'Test Acc');
        
        insert pro = new Product2(Name = 'test Product', ProductCode = '006Z0-J00420');
        insert pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
    
        insert order = new Order(Name = 'Test Order', status = 'Processing', AccountId = account.id,EffectiveDate = System.today(),Pricebook2Id = pricebookId);
        insert mNewOrderItem = new OrderItem(OrderId = order.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
    }
    
    
    @isTest
    static void testDeleteOrder()
    {
        Order order = [Select id,AccountId from Order where name = 'Test Order'];
        Test.startTest();
        delete order;
        Test.stopTest();
    }
    
}