@isTest
public class ResetJobSchedulerTest 
{
    @isTest
    static void testAccountORDSAPI()
    {
        
        Job__c job = new Job__c();
        job.Apex_Class__c = 'AccountORDSJob';
        job.Frequency__c = 0;
        job.Run_Order__c = 1;
        job.First_Run__c = System.now();
        job.Status__c = 'Running';
        job.Active__c = true;
        insert job;
        
        Test.StartTest();
        {            
            SchedulableContext ctx = null;
            ResetJobScheduler sch = new ResetJobScheduler();
            sch.execute(ctx);
        }
        Test.stopTest();
        
        List<Job__c> jobs = [SELECT Id, Last_Run__c FROM Job__c];
        System.assertEquals(1, jobs.size(), '1 job should be created');
        
    }
    
}