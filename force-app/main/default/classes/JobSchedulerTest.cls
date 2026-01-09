@isTest
public class JobSchedulerTest {
    
    @isTest
    static void testsleepJob()
    {
        ORDS_Path__c cus = new ORDS_Path__c();         
        cus.Name = 'ProductORDSJob';        
        cus.Offset__c = 'materials';
        cus.Path__c = '/ords/apps/xxkmatreplication/'; 
        insert cus;
        system.debug(cus);
        
        
        Job__c job = new Job__c(Apex_Class__c = 'OrderORDSJob',Status__c = 'Sleeping', Sleep_Duration__c = 200, Run_Order__c = 1, Frequency__c = 1, 
                                First_Run__c = System.now(), Active__c = TRUE);
        insert job;

        Job__c job2 = new Job__c(Apex_Class__c = 'ProductORDSJob',Status__c = 'Waiting', Sleep_Duration__c = 200, Run_Order__c = 2, Frequency__c = 5, 
                                 First_Run__c = System.now(), Last_Run__c = System.now().addMinutes(-10), Active__c = TRUE);
        insert job2;
        
        Test.startTest();
        JobScheduler.sleepJob('OrderORDSJob', 200);
        JobScheduler.finishJob('OrderORDSJob');
        Test.stopTest();

    }
    
    @isTest
    static void testfinishJob()
    {
        ORDS_Path__c cus = new ORDS_Path__c();         
        cus.Name = 'ProductORDSJob';        
        cus.Offset__c = 'materials';
        cus.Path__c = '/ords/apps/xxkmatreplication/'; 
        insert cus;
        system.debug(cus);

        Job__c job = new Job__c(Apex_Class__c = 'OrderORDSJob',Status__c = 'Sleeping', Sleep_Duration__c = 200, Run_Order__c = 1, Frequency__c = 1, 
                                First_Run__c = System.now(), Active__c = TRUE);
        insert job;

        Job__c job2 = new Job__c(Apex_Class__c = 'ProductORDSJob',Status__c = 'Waiting', Sleep_Duration__c = 200, Run_Order__c = 2, Frequency__c = 5, 
                                 First_Run__c = System.now(), Last_Run__c = System.now().addMinutes(-10), Active__c = TRUE);
        insert job2;
        
        Test.startTest();
        JobScheduler.finishJob('OrderORDSJob');
        Test.stopTest();

    }

}