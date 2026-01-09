@isTest
public class QuoteTriggerTest {
    
    public static Product2 pro ;
    public static Account accRef ;
    public static Opportunity opp ;
    public static Quote quote ;
    public static Territory2 objTerr;
    public static  PricebookEntry pb;
    static void setupData()
    {
        Id pricebookId = Test.getStandardPricebookId();
        pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pro;
        pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        insert pb;
        accRef = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert accRef;
        
        opp = new Opportunity(Name = 'Test Opp', AccountId = accRef.id, StageName = 'Order Entry',
                              Pricebook2Id = pricebookId, CloseDate = system.today(),Division__c = 'MI');
        insert opp;
        
        quote = new Quote(Name = 'Test Opp', status = 'Draft', OpportunityId = opp.id, Pricebook2Id = pricebookId, Division__c = 'MI');
        insert quote;
        
        QuoteLineItem mOItem = new QuoteLineItem(QuoteId = quote.id, PriceBookEntryId = pb.id, Quantity = 2, UnitPrice = 10);
        insert mOItem;
    }
    
    @isTest
    static void testInsertLineItem()
    {
        setupData();
        
        Test.StartTest();
        {
            QuoteLineItem mOItem1 = new QuoteLineItem(QuoteId = quote.id, PriceBookEntryId = pb.id, Quantity = 1, UnitPrice = 10);
            insert mOItem1;
        }
        Test.stopTest();
    }
  
}