@isTest
public class ORDSTest 
{
    //@TestSetup
    static void setupData(String ApexName, String Path, String Offset)
    {
        Job__c job = new Job__c();
        job.Apex_Class__c = ApexName;
        job.Frequency__c = 0;
        job.Run_Order__c = 1;
        job.First_Run__c = System.now();
        insert job;
        
        ORDS_Path__c cus = new ORDS_Path__c();         
        cus.Name = ApexName;        
        cus.Offset__c = Offset;
        cus.Path__c = Path; 
        insert cus;
        system.debug(cus);
    }

    @isTest
    static void testAccountORDSAPI()
    {
        setupData('AccountORDSJob', '/ords/apps/xxkaccreplication/', 'customer1');
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkaccreplication/customer1','ORDSAPIGetAccountMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);

            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();

        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Account> accounts = [SELECT Id FROM Account];
        System.assertEquals(1, accounts.size(), '2 accounts should be created');

    }
    
    @isTest
    static void testShipToORDSAPI()
    {
        setupData('AddressORDSJob', '/ords/apps/xxkaccreplication/address1/', 'SHIP_TO');
        Account accRef = new Account(Name = 'Test Acc', ERP_Id__c = '289807');
        insert accRef;
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkaccreplication/address1/SHIP_TO','ORDSAPIGetShipToMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Address__c> ShipToAddress = [SELECT Id FROM Address__c];
        System.assertEquals(1, ShipToAddress.size(), '1 ShipToAddress should be created');
        
    }
    
    @isTest
    static void testBillToORDSAPI()
    {
        //setupData('BillToORDSJob');
        setupData('BillToORDSJob', '/ords/apps/xxkaccreplication/address1/', 'BILL_TO');
        Account accRef = new Account(Name = 'Test Acc', ERP_Id__c = '296772');
        insert accRef;
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkaccreplication/address1/BILL_TO','ORDSAPIGetBillToMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Address__c> ShipToAddress = [SELECT Id FROM Address__c];
        System.assertEquals(1, ShipToAddress.size(), '1 BillToAddress should be created');
        
    }
    
    @isTest
    static void testProductToORDSAPI()
    {
        setupData('ProductORDSJob', '/ords/apps/xxkmatreplication/', 'materials');
        Warehouse__c war = new Warehouse__c(Name = 'testWarehouse', code__c = '963');
        insert war;
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkmatreplication/materials','ORDSAPIGetProductToMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Product2> products = [SELECT Id FROM Product2];
        System.assertEquals(1, products.size(), '1 products should be created');
        
    }
    
    @isTest
    static void testInventoryToORDSAPI()
    {
        setupData('InventoryORDSJob', '/ords/apps/xxkmatreplication/', 'inventories');
        Inventory__c inv = new Inventory__c(Quantity_Remaining__c = 1, ERP_Id__c = '603373432');
        insert inv;
        
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkmatreplication/inventories','ORDSAPIGetInventoryMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];
        System.assertEquals(1, inventories.size(), '1 inventories should be created');
        
    }
    
    @isTest
    static void testOrderToORDSAPI()
    {
        setupData('OrderORDSJob', '/ords/apps/getorder/', 'orderreplication');
        Id OppSingleOrderRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId ();
        Id pricebookId = Test.getStandardPricebookId();
        Account accRef = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert accRef;
        Address__c shipTo = new Address__c(Name = 'ShipTo', Type__c = 'Ship To', ERP_Id__c = '115057', Account__c = accRef.id);
        insert shipTo;
        Address__c billTo = new Address__c(Name = 'BillTo', Type__c = 'Bill To', ERP_Id__c = '115058', Account__c = accRef.id);
        insert billTo;
        Warehouse__c war = new Warehouse__c(Name = 'testWarehouse', code__c = '743');
        insert war;
        Order_Type__c orderType = new Order_Type__c(Name = 'testWarehouse', Order_Type_ID__c = '1452', Warehouse__c = war.id);
        insert orderType;
        /*Opportunity opp = new Opportunity (Name = 'Test Opportunity',StageName = 'Order Entry',AccountId = accRef.id, CloseDate = System.today(), Pricebook2Id = pricebookID,
                                           RecordTypeId = OppSingleOrderRecordTypeId, Division__c = 'MI');
        insert opp;*/

        Order_Status_Mapping__c cus = new Order_Status_Mapping__c();
        cus.Name = 'BOOKED';
        cus.SF_Stage__c = 'Processing';
        insert cus;
        
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/getorder/orderreplication','ORDSAPIGetOrderMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Order> orders = [SELECT Id FROM Order];
        system.debug(orders.size());
        //System.assertEquals(1, orders.size(), '1 orders should be created');
        
    }
    
    @isTest
    static void testOrderItemToORDSAPI()
    {
        setupData('OrderItemORDSJob', '/ords/apps/getorderline/', 'lineitem');
        Id pricebookId = Test.getStandardPricebookId();
        Product2 pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pro;
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        insert pb;
        Account accRef = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert accRef;
        Order order = new Order(Name = 'Test Order', ERP_Id__c = '3792184', AccountId = accRef.id, EffectiveDate  = system.today(), Status = 'Order Entry',Pricebook2Id = pricebookId);
        insert order;
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/getorderline/lineitem','ORDSAPIGetOrderItemMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem];
        system.debug(orderItems.size());
        System.assertEquals(1, orderItems.size(), '1 orders should be created');
        
    }
    
    @isTest
    static void testContactToORDSAPI()
    {
        setupData('ContactORDSJob', '/ords/apps/xxkaccreplication/', 'contacts');
        Account accRef = new Account(Name = 'Test Acc', ERP_Id__c = '296772');
        insert accRef;

        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkaccreplication/contacts','ORDSAPIGetContactMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Contact> contacts = [SELECT Id FROM Contact];
        system.debug(contacts.size());
        //System.assertEquals(1, orders.size(), '1 orders should be created');
        
    }
    
    @isTest
    static void testAccCategoryToORDSAPI()
    {
        setupData('AccCategoryORDSJob', '/ords/apps/xxkaccreplication/', 'categories');
        Account accRef = new Account(Name = 'Test Acc', ERP_Id__c = '16175');
        insert accRef;

        Test.StartTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock();
            multiMock.setStaticResource('callout:ORDS/ords/apps/xxkaccreplication/categories','ORDSAPIGetAccCategoryMock');
            multiMock.setStatusCode(200);
            multiMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, multiMock);
            
            SchedulableContext ctx = null;
            JobScheduler sch = new JobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        Job__c job = [SELECT Id, Last_Run__c FROM Job__c];
        //System.assertNotEquals(null, job.Last_Run__c, 'Job Last Run should not be null.');
        List<Customer_Category__c> accCat = [SELECT Id FROM Customer_Category__c];
        system.debug(accCat.size());
        //System.assertEquals(1, orders.size(), '1 orders should be created');
        
    } 
}