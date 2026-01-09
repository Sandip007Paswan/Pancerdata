@isTest
public class OpportunityTriggerTest {

    public static Product2 pro ;
    public static Account accRef ;
    public static Opportunity opp ;
    public static Territory2 objTerr;
    public static Territory2 objTerr1;

    @testSetup
    static void setupData()
    {
        Id pricebookId = Test.getStandardPricebookId();
        pro = new Product2(Name = 'test Product', ProductCode = 'L48N6-PTMYI');
        insert pro;
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pro.id, UnitPrice = 300, IsActive = true);
        insert pb;
        accRef = new Account(Name = 'Test Acc', ERP_Id__c = '71601');
        insert accRef;

        System.runAs (new User(Id = UserInfo.getUserId())){
            Territory2Type terriType = [SELECT id, DeveloperName,Priority from Territory2Type where DeveloperName = 'Branch'];
            Territory2Model terrModel = [SELECT id, DeveloperName,State from Territory2Model where DeveloperName = 'Pansar_Territory_Model'];
            insert objTerr = new Territory2(Name='Sibu1',DeveloperName = 'Sibu1', Territory2ModelId = terrModel.Id, Territory2TypeId= terriType.Id);
            insert objTerr1 = new Territory2(Name='Sibu2',DeveloperName = 'Sibu2', Territory2ModelId = terrModel.Id, Territory2TypeId= terriType.Id);
        }

        //ObjectTerritory2Association objTerAsso = new ObjectTerritory2Association(ObjectId = accRef.id, Territory2Id = objTerr.id, AssociationCause = 'Territory2Manual');
        //insert objTerAsso;

        opp = new Opportunity(Name = 'Test Opp', AccountId = accRef.id, StageName = 'Order Entry',
                              Pricebook2Id = pricebookId, CloseDate = system.today(),Division__c = 'MI');
        insert opp;

        OpportunityLineItem mOItem = new OpportunityLineItem(OpportunityId = opp.id, Product2Id = pro.id, Quantity = 2, UnitPrice = 10);
        insert mOItem;
    }

    @isTest
    static void testInsertLineItem()
    {
        Opportunity opp = [Select Id from Opportunity where name = 'Test Opp'];
        Product2 pro = [Select Id from Product2 where name = 'test Product'];

        Test.StartTest();
        {
            OpportunityLineItem mNewOppItem = new OpportunityLineItem();
            mNewOppItem.OpportunityId = opp.id;
            mNewOppItem.Product2Id = pro.id;
            mNewOppItem.Quantity = 1;
            mNewOppItem.UnitPrice = 20;
            insert mNewOppItem;
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccount()
    {
        Test.StartTest();
        {
            Account acc = [Select Id from Account where name = 'Test Acc'];
            Account acc1 = new Account(Name = 'Test Acc1', ERP_Id__c = '71602');
            insert acc1;
            Territory2 objTerr = [Select Id from Territory2 where name = 'Sibu2'];
            ObjectTerritory2Association ota = new ObjectTerritory2Association(Territory2Id = objTerr.id, ObjectId = acc1.id, AssociationCause = 'Territory2Manual');
            insert ota;

            Opportunity opp = [Select id From Opportunity WHERE name = 'Test Opp'];
            Opportunity oppUpdate = new Opportunity(id = opp.id, AccountId = acc1.id);
            update oppUpdate;

        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteEnquiry()
    {
        Test.StartTest();
        {
            Opportunity opp = [Select id From Opportunity WHERE name = 'Test Opp'];
            delete opp;
            
        }
        Test.stopTest();
    }

}