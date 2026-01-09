@isTest
public class BaseControllerTest {
    
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
        
        insert pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        mNewOppItem = new OpportunityLineItem(OpportunityId = mNewOpportunity.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        mNewOppItems.add(mNewOppItem);
        insert mNewOppItems;
        insert inv = new Inventory__c(Quantity_Remaining__c = 1, Warehouse__c = warehouse.id , Product__c = pro.id, ERP_Id__c = '603373432K274-APS');
        insert UomPrice = new Pansar_Product__c(Product__c = pro.id, UOM__c = 'EA', Warehouse__c = warehouse.id );
    }
    
    @isTest
    static void testsearchInventory()
    {
        Warehouse__c warehouse = [Select id, Code__c from Warehouse__c where code__c = '743'];
        List<OpportunityLineItem> mNewOppItems = [SELECT Id, OpportunityId, Quantity, TotalPrice, UnitPrice, Product2Id, ProductCode FROM OpportunityLineItem];
        List<sObject> result = BaseController.searchInventory(mNewOppItems,warehouse.code__c);
        
    }
    
    @isTest
    static void testsearchInventoryProductChanged()
    {
        Warehouse__c warehouse = [Select id, Code__c from Warehouse__c where code__c = '743'];
        Product2 pro = [Select id from Product2];
        Decimal qtRemain = BaseController.searchInventoryProductChanged(pro.Id, warehouse.code__c);
        
    }
    
    @isTest
    static void testsearch()
    {
        String q = 'SELECT Id, Name, Warehouse__r.code__c, Product__c, Product_Name__c, Product_Cat_Code__c FROM Pansar_Product__c LIMIT 1';
        List<LookupSearchResult> searchResult = BaseController.search(q,'Pansar_Product__c','standard:product','Product_Name__c', 'Product_Cat_Code__c', null);
        List<sObject> result = BaseController.query(q);
    }
    
    @isTest
    static void testgetPickListValues()
    {
        Opportunity opp = [SELECT Id from Opportunity limit 1];
        Warehouse__c warehouse = [Select id, Code__c from Warehouse__c where code__c = '743'];
        Map<Id,List<BaseController.UomClass>> UOMValue =  BaseController.getPickListValues(opp.id, warehouse.code__c);
        
    }
    
    @isTest
    static void testgetPickListValues1()
    {
        Product2 pro = [Select id from Product2];
        Warehouse__c warehouse = [Select id, Code__c from Warehouse__c where code__c = '743'];
        Map<Id,List<BaseController.UomClass>> UOMValue =  BaseController.testgetPickListValues1(pro.id, warehouse.code__c, system.today());    
    }
    
    
    @isTest
    static void testsaveAndDelete()
    {
        List<sObject> mNewOppItems = [SELECT Id, OpportunityId, Quantity, TotalPrice, UnitPrice, Product2Id, ProductCode FROM OpportunityLineItem];
        system.debug(mNewOppItems);
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opportunity'];
        Product2 newPro = new Product2(Name = 'test newPro', ProductCode = 'NewProCode');
        
        OpportunityLineItem mNewProItem = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 2, UnitPrice = 10);
        List<BaseController.NewProductClass> newProCons = new List<BaseController.NewProductClass>();
        BaseController.NewProductClass newProCon = new BaseController.NewProductClass();
        newProCon.newProduct = newPro;
        newProCon.oppProduct = mNewProItem;
        newProCons.add(newProCon);

        BaseController.saveAndDelete(mNewOppItems, null ,null,newProCons);   
    }

}