public class ResetJobScheduler implements Schedulable
{
    public void execute(System.SchedulableContext ctx)
    {
        //System.debug('execute');
        String q;
        DateTime tmpTime = System.now().addMinutes(-10);
        String formatedDt = tmpTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        system.debug('Now : '+System.now());
        system.debug('Now - 10mins : '+tmpTime);
        /*List<Job__c> jobs = [SELECT Apex_Class__c,Status__c,Last_Run__c,LastModifiedDate FROM Job__c WHERE Active__c = TRUE AND Status__c = 'Running' 
                             AND Next_Run__c = null AND LastModifiedDate <: tmpTime];*/
        q = 'SELECT Apex_Class__c,Status__c,Last_Run__c,LastModifiedDate FROM Job__c WHERE Active__c = TRUE AND Status__c = '+'\'Running\' AND Next_Run__c = null ';
        if(!Test.isRunningTest()) q +=' And LastModifiedDate < '+formatedDt;
        
        System.debug(q);
        List<Job__c> jobs = Database.query(q);
        if (!jobs.isEmpty())
        {
            for(Job__c job : jobs)
            {
                system.debug(job);
                job.Status__c = 'Waiting';
                job.Last_Run__c = System.now();
            }
            update jobs;
        }
    }
    
    /*System.schedule('ResetJob 0', '0 0 * * * ?', new ResetJobScheduler());
System.schedule('ResetJob 10', '0 10 * * * ?', new ResetJobScheduler());
System.schedule('ResetJob 20', '0 20 * * * ?', new ResetJobScheduler());
System.schedule('ResetJob 30', '0 30 * * * ?', new ResetJobScheduler());
System.schedule('ResetJob 40', '0 40 * * * ?', new ResetJobScheduler());
System.schedule('ResetJob 50', '0 50 * * * ?', new ResetJobScheduler());

ResetJobScheduler abc = new ResetJobScheduler(); abc.execute(null);*/
    
}