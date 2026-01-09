@isTest
public class OrderToOracleControllerTest {
    
    @TestSetup
    static void setupData()
    {
        Id pricebookId = Test.getStandardPricebookId();
        Id OppSingleOrderRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId ();
        Id OppMIRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Customised_Engineering_Solution').getRecordTypeId ();
        
        Product2 pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pro;
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        insert pb;
        Account creditAccount = new Account(Name = 'Credit Acc', ERP_Id__c = '71601', Customer_Account_Type__c = 'Credit');
        insert creditAccount;
        Account cashAccount = new Account(Name = 'Cash Acc', ERP_Id__c = '71602', ParentId = creditAccount.id , Customer_Account_Type__c = 'Cash');
        insert cashAccount;
        
        Warehouse__c warehouse = new Warehouse__c(Name = 'testWarehouse', code__c = '743');
        insert warehouse;
        
        Order order = new Order(Name = 'Cash Order', ERP_Id__c = '3792184', AccountId = cashAccount.id, EffectiveDate  = system.today(), Status = 'Order Entry',Pricebook2Id = pricebookId, Warehouse__c = warehouse.id);
        insert order;
        
        Opportunity opp = new Opportunity(Name = 'Opportunity',  AccountId = creditAccount.Id, RecordTypeId = OppSingleOrderRecordTypeId, CloseDate = System.today().addDays(10), StageName = 'Prospecting', Division__c = 'MI',Warehouse__c = warehouse.id);
        insert opp;
        
        Opportunity MIopp = new Opportunity(Name = 'MI Opportunity',  AccountId = cashAccount.Id, RecordTypeId = OppMIRecordTypeId, CloseDate = System.today().addDays(10), StageName = 'Prospecting', Division__c = 'MI',Warehouse__c = warehouse.id);
        insert MIopp;

        OpportunityLineItem mNewOppItem = new OpportunityLineItem(OpportunityId = opp.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        insert mNewOppItem;
   
        OrderItem mNewOrdertem = new OrderItem(OrderId = order.id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        insert mNewOrdertem;
        
        Parent_Product__c parentProduct = new Parent_Product__c(Name = 'Test', Enquiry__c = MIopp.Id);
        insert parentProduct;
        
        OpportunityLineItem mNewparentItem = new OpportunityLineItem(OpportunityId = MIopp.id, Parent_Product__c = parentProduct.Id, PricebookEntryId = pb.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        insert mNewparentItem;

        Inventory__c  inv = new Inventory__c(Quantity_Remaining__c = 1, Warehouse__c = warehouse.id , Product__c = pro.id, ERP_Id__c = '603373432K274-APS');
        insert inv;
         
    }
    
    
    @isTest
    static void testNotMIEnquiry()
    {
        Opportunity opp = [Select Id from Opportunity where name = 'Opportunity'];
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock orderMock = new MultiStaticResourceCalloutMock();
            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/order1','SubmitOracleMock');
            orderMock.setStatusCode(200);
            orderMock.setHeader('Content-Type', 'application/json');

            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/order2','SubmitOracleMock');
            
            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/submit1','SubmitOracleMock');
            Test.setMock(HttpCalloutMock.class, orderMock);
            
            OrderToOracleController.OracleStatus res =  OrderToOracleController.doProcess(opp.id);
            system.debug('res '+res); 
            
            List<sObject> result = OrderToOracleController.getoppItems(opp.id);
        }
        Test.stopTest();

    }
    
    @isTest
    static void testMIEnquiry()
    {
        Opportunity opp = [Select Id from Opportunity where name = 'MI Opportunity'];
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock orderMock = new MultiStaticResourceCalloutMock();
            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/order1','SubmitOracleMock');
            orderMock.setStatusCode(200);
            orderMock.setHeader('Content-Type', 'application/json');

            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/order2','SubmitOracleMock');
            
            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/submit1','SubmitOracleMock');
            Test.setMock(HttpCalloutMock.class, orderMock);
            
            OrderToOracleController.OracleStatus res =  OrderToOracleController.doProcess(opp.id);
            system.debug('res '+res); 
            
            List<sObject> result = OrderToOracleController.getoppItems(opp.id);
        }
        Test.stopTest();

    }
    
     @isTest
    static void testCreditOrder()
    {
        Order order = [Select Id from Order where name = 'Cash Order'];
        
        Test.StartTest();
        {
             MultiStaticResourceCalloutMock orderMock = new MultiStaticResourceCalloutMock();
            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/order1','SubmitOracleMock');
            orderMock.setStatusCode(200);
            orderMock.setHeader('Content-Type', 'application/json');

            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/order2','SubmitOracleMock');
            
            orderMock.setStaticResource('callout:ORDS/ords/apps/xxkordersubmit/submit1','SubmitOracleMock');
            Test.setMock(HttpCalloutMock.class, orderMock);

            OrderToOracleController.OracleStatus res =  OrderToOracleController.doProcess(Order.id);
            
            system.debug('res '+res); 
            
            List<sObject> result = OrderToOracleController.getoppItems(Order.id);
        }
        Test.stopTest();

    }
    
    
    /*@isTest
    static void testOrder()
    {
        Id pricebookId = Test.getStandardPricebookId();
        Product2 pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pro;
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        insert pb;
        Account account = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert account;
        Order order = new Order(Name = 'Test Order', ERP_Id__c = '3792184', AccountId = account.id, EffectiveDate  = system.today(), Status = 'Order Entry',Pricebook2Id = pricebookId);
        insert order;
        
        Opportunity opp = new Opportunity(
            Name = 'Opportunity',
            CloseDate = System.today().addDays(10),
            StageName = 'Prospecting',
            Division__c = 'MI',
            AccountId = account.Id
        );
        insert opp;
        
        Test.StartTest();
        {
            MultiStaticResourceCalloutMock orderMock = new MultiStaticResourceCalloutMock();
            orderMock.setStaticResource('callout:ORDS/ords/apps/orderreplication/order1','SubmitOracleMock');
            orderMock.setStatusCode(200);
            orderMock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, orderMock);
            
            OrderToOracleController.OracleStatus res =  OrderToOracleController.doProcess(order.id);
            system.debug('res '+res);
            
        }
        Test.stopTest();

    }*/
    
    
}