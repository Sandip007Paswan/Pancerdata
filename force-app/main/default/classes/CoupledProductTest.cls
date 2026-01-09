@isTest
public class CoupledProductTest 
{
    @TestSetup
    static void setupData()
    {
        Account account = new Account();
        account.Name = 'Test';
        insert account;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.Division__c = 'BP';
        opp.StageName = 'Analysis';
        opp.AccountId = account.Id;
        opp.CloseDate = System.today();
        insert opp;
        Product2 product = new Product2();
        product.Name = 'Test';
        insert product;
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbId;
        pbe.Product2Id = product.Id;
        pbe.UnitPrice = 1;
        pbe.IsActive = true;
        insert pbe;
    }

    @isTest
    static void testGetCoupledProducts() 
    {
        Opportunity opp = [SELECT Id FROM Opportunity];    
        Parent_Product__c parentProduct = new Parent_Product__c();
        parentProduct.Name = 'Test';
        parentProduct.Enquiry__c = opp.Id;
        insert parentProduct;
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.Parent_Product__c = parentProduct.Id;
        oppLineItem.UnitPrice = 1;
        oppLineItem.Quantity = 1;
        oppLineItem.PriceBookEntryId = [SELECT Id FROM PricebookEntry].Id;
        oppLineItem.OpportunityId = opp.Id;
        insert oppLineItem;
        List<CoupledProductController.CoupledProduct> coupledProducts = CoupledProductController.getCoupledProducts(opp.Id);
        System.assertEquals(1, coupledProducts.size(), 'Number of parent products returned should be equal');
    }

    @isTest
    static void testSaveCoupledProducts() 
    {
        Opportunity opp = [SELECT Id FROM Opportunity];        
        List<CoupledProductController.CoupledProduct> coupledProducts = new List<CoupledProductController.CoupledProduct>();
        CoupledProductController.CoupledProduct coupledProduct = new CoupledProductController.CoupledProduct();
        coupledProduct.oppProducts = new List<CoupledProductController.OpportunityProduct>();
        coupledProducts.add(coupledProduct);
        coupledProduct.parentProduct = new Parent_Product__c();
        coupledProduct.parentProduct.Name = 'Test';
        coupledProduct.parentProduct.Enquiry__c = opp.Id;
        CoupledProductController.OpportunityProduct oppProduct = new CoupledProductController.OpportunityProduct();
        oppProduct.oppLineItem = new OpportunityLineItem();        
        oppProduct.oppLineItem.UnitPrice = 1;
        oppProduct.oppLineItem.Quantity = 1;
        oppProduct.oppLineItem.PriceBookEntryId = [SELECT Id FROM PricebookEntry].Id;
        oppProduct.oppLineItem.OpportunityId = opp.Id;        
        coupledProduct.oppProducts.add(oppProduct);
        CoupledProductController.saveCoupledProducts(coupledProducts, new List<sObject>(), new List<sObject>());        
        List<Parent_Product__c> parentProductsInDB = [SELECT Id FROM Parent_Product__c];
        System.assertEquals(1, parentProductsInDB.size(), 'Number of parent products returned should be equal');        
    }    
}