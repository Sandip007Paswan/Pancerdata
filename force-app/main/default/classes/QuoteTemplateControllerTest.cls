@isTest
public class QuoteTemplateControllerTest {

    public static Account account ;
    public static Contact contact ;
    public static Address__c shipTo ;
    public static Address__c billTo ;
    public static Warehouse__c warehouse ;
    public static Order_Type__c orderType ;
    public static Opportunity mSingleOpportunity ;
    public static Product2 pro ;
    public static PricebookEntry pb ;
    public static QuoteLineItem mNewQuoteItem;
    public static Quote quote ;
    
    @testSetup static void setupData()
    {
        Id OppSingleOrderRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId ();
        Id pricebookId = Test.getStandardPricebookId();
        insert account = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert contact = new Contact(FirstName = 'Test Con',LastName = 'LastName', AccountId = account.id);
        insert shipTo = new Address__c(Name = 'ShipTo', Type__c = 'Ship To', ERP_Id__c = '115057', Account__c = account.id);
        insert billTo = new Address__c(Name = 'BillTo', Type__c = 'Bill To', ERP_Id__c = '115058', Account__c = account.id);
        insert warehouse = new Warehouse__c(Name = 'testWarehouse', code__c = '743');
        insert orderType = new Order_Type__c(Name = 'testWarehouse', Order_Type_ID__c = '1452', Warehouse__c = warehouse.id);
        insert mSingleOpportunity = new Opportunity (Name = 'M&I Quotation',StageName = 'Quotation',AccountId = account.id, CloseDate = System.today(), Pricebook2Id = pricebookID,
                                                   RecordTypeId = OppSingleOrderRecordTypeId, Division__c = 'MI', Quotation_Approved__c = true);
        insert pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);

        quote = new Quote();
        quote.ContactId = contact.id;
        quote.Name  = 'Test Quote';
        quote.OpportunityId  = mSingleOpportunity.id ;
        quote.Customer_Ref_No__c  = '1' ;
        quote.BillingStreet = 'BillingStreet';
        quote.BillingCity = 'BillingCity';
        quote.BillingState = 'BillingState';
        quote.BillingPostalCode = 'BillingPostalCode';
        quote.BillingCountry = '.BillingCountry';
        quote.Price_Validity__c = 'Other';
        quote.Price_Validity_Other__c = 'Other' ;
        quote.Delivery2__c = 'Other';
        quote.Delivery_Other__c = 'Other;';
        quote.Payment_Method__c  = 'Other' ;
        quote.Payment_Method_Other__c  = 'Other' ;
        quote.Warranty_Period__c = 'Other';
        quote.Warranty_Period_Other__c  = 'Other' ;
        quote.Description = 'Description';
        quote.Quote_Version__c = 0;
        insert quote;
        
        mNewQuoteItem = new QuoteLineItem(QuoteId = quote.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        insert mNewQuoteItem;
        
    }
    
    @isTest
    static void testvalidateQuote()
    {
        Quote quote = [SELECT Id from Quote where Name = 'Test Quote'];
        Test.StartTest(); 

        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        QuoteTemplateController quoteTemCon = new QuoteTemplateController(sc);
        
        PageReference pageRef = Page.StandardQuoteTemplate; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        //testAccPlan.save(); call all your function here
        Test.StopTest();
    }
}