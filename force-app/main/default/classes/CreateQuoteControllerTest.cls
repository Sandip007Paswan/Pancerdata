@isTest
public class CreateQuoteControllerTest {
    
    
    public static Account account ;
    public static Contact contact ;
    public static Address__c shipTo ;
    public static Address__c billTo ;
    public static Warehouse__c warehouse ;
    public static Order_Type__c orderType ;
    public static Opportunity mMIOpportunity ;
    public static Opportunity mSparePartOpportunity ;
    public static Opportunity mSparePartOpportunity1 ;
    public static Product2 pro ;
    public static Product2 coupledProduct ;
    public static PricebookEntry coupledPb ;
    public static PricebookEntry pb ;
    public static OpportunityLineItem mNewOppItem;
    public static Pansar_Product__c UomPrice ;
    public static Inventory__c inv ;
    public static Quote quote ;
    public static List<OpportunityLineItem> mNewOppItems = new List<OpportunityLineItem>();
    
    @testSetup static void setupData()
    {
        Id OppSingleOrderRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId ();
        Id OppSparePartsRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Spare_Parts_Order').getRecordTypeId ();
        Id OppMIRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Customised_Engineering_Solution').getRecordTypeId ();
        Id pricebookId = Test.getStandardPricebookId();
        insert account = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert contact = new Contact(FirstName = 'Test Con',LastName = 'LastName', AccountId = account.id);
        insert shipTo = new Address__c(Name = 'ShipTo', Type__c = 'Ship To', ERP_Id__c = '115057', Account__c = account.id);
        insert billTo = new Address__c(Name = 'BillTo', Type__c = 'Bill To', ERP_Id__c = '115058', Account__c = account.id);
        insert warehouse = new Warehouse__c(Name = 'testWarehouse', code__c = '743');
        insert orderType = new Order_Type__c(Name = 'testWarehouse', Order_Type_ID__c = '1452', Warehouse__c = warehouse.id);
        insert mMIOpportunity = new Opportunity (Name = 'M&I Quotation',StageName = 'Quotation',AccountId = account.id, CloseDate = System.today(), Pricebook2Id = pricebookID,
                                                   RecordTypeId = OppMIRecordTypeId, Division__c = 'MI', Quotation_Approved__c = true);
        insert mSparePartOpportunity = new Opportunity (Name = 'SparePart New Quotation',StageName = 'Quotation',AccountId = account.id, CloseDate = System.today(), Pricebook2Id = pricebookID,
                                                 RecordTypeId = OppSparePartsRecordTypeId, Division__c = 'MI');
        
        insert mSparePartOpportunity1 = new Opportunity (Name = 'SparePart Quotation',StageName = 'Quotation',AccountId = account.id, CloseDate = System.today(), Pricebook2Id = pricebookID,
                                                         RecordTypeId = OppSparePartsRecordTypeId, Division__c = 'MI');
        insert pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert coupledProduct = new Product2(Name = 'Coupled Parent', ProductCode = '123');
        insert coupledPb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = coupledProduct.id, UnitPrice = 300, IsActive = true);
        insert inv = new Inventory__c(Quantity_Remaining__c = 1, Warehouse__c = warehouse.id , Product__c = pro.id, ERP_Id__c = '603373432K274-APS');
        insert UomPrice = new Pansar_Product__c(Product__c = coupledProduct.id, UOM__c = 'EA', Warehouse__c = warehouse.id);
        insert pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        Parent_Product__c parentProduct = new Parent_Product__c(Name = 'Coupled Parent1', Quantity__c = 1, Unit_Price__c= 12,Enquiry__c = mMIOpportunity.id);
        insert parentProduct;

        mNewOppItem = new OpportunityLineItem(OpportunityId = mSparePartOpportunity1.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        mNewOppItems.add(mNewOppItem);
        insert mNewOppItems;
        
        quote = new Quote();
        quote.ContactId = contact.id;
        quote.Name  = 'Test Quote';
        quote.OpportunityId  = mSparePartOpportunity1.id ;
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
        
    }
    
    @isTest
    static void testvalidateQuote()
    {
        Opportunity opp = [SELECT Id from Opportunity where Name = 'SparePart Quotation'];
        CreateQuoteController.QuoteWrapper result = CreateQuoteController.validateQuote(opp.Id);
    }
    
    @isTest
    static void testcreateMIQuote()
    {
        Opportunity opp = [SELECT Id,Name from Opportunity where Name = 'M&I Quotation'];
        system.debug('MI opp'+opp.Name);
        Quote quote = [SELECT Id,ContactId,Customer_Ref_No__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,Price_Validity__c,Contact_Name__c,
                       Price_Validity_Other__c, Delivery2__c, Delivery_Other__c, Payment_Method__c, Payment_Method_Other__c, Warranty_Period__c,Warranty_Period_Other__c,
                       Phone,Fax,Description from Quote];        
        CreateQuoteController.createQuote(opp.Id,quote);
    }

    @isTest
    static void testcreateQuote()
    {
        Opportunity opp = [SELECT Id from Opportunity where Name = 'SparePart Quotation'];
        Quote quote = [SELECT Id,ContactId,Customer_Ref_No__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,Price_Validity__c,Contact_Name__c,
                       Price_Validity_Other__c, Delivery2__c, Delivery_Other__c, Payment_Method__c, Payment_Method_Other__c, Warranty_Period__c,Warranty_Period_Other__c,
                       Phone,Fax,Description from Quote];
        
        CreateQuoteController.createQuote(opp.Id,quote);
    }
    
    @isTest
    static void testsearch()
    {
        String q = 'SELECT Id, Name, ERP_Id__c from Contact LIMIT 1';
        List<LookupSearchResult> searchResult = CreateQuoteController.search(q,'Contact','standard:contact','Name', 'ERP_Id__c', null);
    }
}