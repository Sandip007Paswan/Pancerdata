@isTest
public class OrderControllerTest {
    
    public static Account account ;
    public static Account account1 ;
    public static Opportunity mNewOpportunity ;
    public static Product2 pro ;
    public static PricebookEntry pb ;
    public static OpportunityLineItem mNewOppItem;
    public static OrderItem mNewOrderItem;
    public static Order order ;
    public static Order orderSameAcc ;
    public static OrderItem orderItemSameAcc;
    public static Order orderDiffAcc ;
    public static OrderItem orderItemDiffAcc;
    public static List<OpportunityLineItem> mNewOppItems = new List<OpportunityLineItem>();
    
    @testSetup static void setupData()
    {
        Id OppSingleOrderRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId ();
        Id pricebookId = Test.getStandardPricebookId();
        insert account = new Account(Name = 'Test Acc');
        insert account1 = new Account(Name = 'Test Acc1');
        
        insert pro = new Product2(Name = 'test Product', ProductCode = '006Z0-J00420');
        insert pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
    
        insert order = new Order(Name = 'Test Order', status = 'Processing', AccountId = account.id,EffectiveDate = System.today(),Pricebook2Id = pricebookId);
        insert mNewOrderItem = new OrderItem(OrderId = order.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        
        insert orderSameAcc = new Order(Name = 'Test Order1', status = 'Processing', AccountId = account.id,EffectiveDate = System.today(),Pricebook2Id = pricebookId);
        insert orderItemSameAcc = new OrderItem(OrderId = orderSameAcc.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        
        insert orderDiffAcc = new Order(Name = 'Test Order2', status = 'Processing', AccountId = account1.id,EffectiveDate = System.today(),Pricebook2Id = pricebookId);
        insert orderItemDiffAcc = new OrderItem(OrderId = orderDiffAcc.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
    }
    
    
    @isTest
    static void testGetOrderDetailsSameAccount()
    {
        Order order = [Select id,AccountId from Order where name = 'Test Order'];
        Test.startTest();
        List<Order> orders =  OrderController.getOrderDetails(order.id, order.AccountId);
        Test.stopTest();
    }
    
}