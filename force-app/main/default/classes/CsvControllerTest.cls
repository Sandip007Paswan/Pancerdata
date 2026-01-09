@isTest
public class CsvControllerTest {
    
      public static Account account ;
    public static Address__c shipTo ;
    public static Address__c billTo ;
    public static Warehouse__c warehouse ;
    public static Order_Type__c orderType ;
    public static Opportunity mNewOpportunity ;
    public static Product2 pro ;
    public static PricebookEntry pb ;
    public static OpportunityLineItem mNewOppItem;
    public static Pansar_Product__c UomPrice ;
    public static Inventory__c inv ;
    public static List<OpportunityLineItem> mNewOppItems = new List<OpportunityLineItem>();
    
    @testSetup static void setupData()
    {
        Id OppSingleOrderRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId ();
        Id pricebookId = Test.getStandardPricebookId();
        insert account = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert shipTo = new Address__c(Name = 'ShipTo', Type__c = 'Ship To', ERP_Id__c = '115057', Account__c = account.id);
        insert billTo = new Address__c(Name = 'BillTo', Type__c = 'Bill To', ERP_Id__c = '115058', Account__c = account.id);
        insert warehouse = new Warehouse__c(Name = 'testWarehouse', code__c = '743');
        insert orderType = new Order_Type__c(Name = 'testWarehouse', Order_Type_ID__c = '1452', Warehouse__c = warehouse.id);
        
        insert mNewOpportunity = new Opportunity (Name = 'Test Opportunity',StageName = 'Order Entry',AccountId = account.id, CloseDate = System.today(), Pricebook2Id = pricebookID,
                                           RecordTypeId = OppSingleOrderRecordTypeId, Division__c = 'MI');
        
        insert pro = new Product2(Name = 'test Product', ProductCode = '006Z0-J00420');
        insert pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        mNewOppItem = new OpportunityLineItem(OpportunityId = mNewOpportunity.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        mNewOppItems.add(mNewOppItem);
        insert mNewOppItems;
        insert inv = new Inventory__c(Quantity_Remaining__c = 1, Warehouse__c = warehouse.id , Product__c = pro.id, ERP_Id__c = '603373432K274-APS');
        insert UomPrice = new Pansar_Product__c(Product__c = pro.id, UOM__c = 'EA', Warehouse__c = warehouse.id );
    }
    
    
    @isTest
    static void testreadCSVFile()
    {
        
        Opportunity opp = [Select id from Opportunity];
        Blob CsvProductBody = [SELECT Id, Name, Body FROM StaticResource where name = 'CsvProduct'].body;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'CsvProduct',
            PathOnClient = 'Product_test.csv',
            VersionData = CsvProductBody,
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        Test.startTest();
        list<OpportunityLineItem> oppItems =  CsvController.readCSVFile(documents[0].id, opp.id);
        Test.stopTest();
    }
    
    @isTest
    static void testQuotePDF()
    {
        Opportunity opp = [Select id from Opportunity];
        Blob CsvProductBody = [SELECT Id, Name, Body FROM StaticResource where name = 'CsvProduct'].body;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'CsvProduct',
            PathOnClient = 'Product_test.csv',
            VersionData = CsvProductBody,
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = opp.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        Test.startTest();
        ContentVersion con =  QuotePDFController.getQuotePDFId(opp.id);
        Test.stopTest();
    }

}