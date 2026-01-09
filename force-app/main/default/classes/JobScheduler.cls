public class JobScheduler implements Schedulable
{
	public void execute(System.SchedulableContext ctx)
    {
        System.debug('execute');      
        List<Job__c> jobs = [SELECT Apex_Class__c FROM Job__c WHERE Active__c = TRUE AND Status__c != 'Running' AND Next_Run__c <= :System.now() ORDER BY Run_Order__c ASC LIMIT 1];
        if (!jobs.isEmpty())
        {
            Job__c job = jobs.get(0);        
            job.Status__c = 'Running';
            update job;
            Type customType = Type.forName(job.Apex_Class__c);
            Queueable queue = (Queueable)customType.newInstance();        
            System.enqueueJob(queue);
        }

        /*  
        System.schedule('ORDSJobScheduler Job 00', '0 0 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 01', '0 1 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 02', '0 2 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 03', '0 3 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 04', '0 4 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 05', '0 5 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 06', '0 6 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 07', '0 7 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 08', '0 8 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 09', '0 9 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 10', '0 10 * * * ?', new JobScheduler());        
        System.schedule('ORDSJobScheduler Job 11', '0 11 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 12', '0 12 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 13', '0 13 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 14', '0 14 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 15', '0 15 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 16', '0 16 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 17', '0 17 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 18', '0 18 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 19', '0 19 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 20', '0 20 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 21', '0 21 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 22', '0 22 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 23', '0 23 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 24', '0 24 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 25', '0 25 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 26', '0 26 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 27', '0 27 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 28', '0 28 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 29', '0 29 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 30', '0 30 * * * ?', new JobScheduler());    
        System.schedule('ORDSJobScheduler Job 31', '0 31 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 32', '0 32 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 33', '0 33 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 34', '0 34 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 35', '0 35 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 36', '0 36 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 37', '0 37 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 38', '0 38 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 39', '0 39 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 40', '0 40 * * * ?', new JobScheduler());   
        System.schedule('ORDSJobScheduler Job 41', '0 41 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 42', '0 42 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 43', '0 43 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 44', '0 44 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 45', '0 45 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 46', '0 46 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 47', '0 47 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 48', '0 48 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 49', '0 49 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 50', '0 50 * * * ?', new JobScheduler());       
        System.schedule('ORDSJobScheduler Job 51', '0 51 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 52', '0 52 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 53', '0 53 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 54', '0 54 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 55', '0 55 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 56', '0 56 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 57', '0 57 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 58', '0 58 * * * ?', new JobScheduler());
        System.schedule('ORDSJobScheduler Job 59', '0 59 * * * ?', new JobScheduler());
        */   
        
        /*
        JobScheduler.abortAllJobs('ORDSJobScheduler');
        */
    }

    public static void abortAllJobs(String name)
    {
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE :name + '%'];
        for (CronTrigger job : jobs)
        {
            System.abortJob(job.Id);
        }
    }

    //Change current job to "Waiting" and find the next job to run
    public static void finishJob(String name)
    {
        Job__c job = [SELECT Id, Run_Order__c FROM Job__c WHERE Apex_Class__c = :name];
        job.Status__c = 'Waiting';
        job.Last_Run__c = System.now();
        update job;
        List<Job__c> jobs = [SELECT Apex_Class__c FROM Job__c WHERE Active__c = TRUE AND Status__c != 'Running' AND Next_Run__c <= :System.now() AND Run_Order__c > :job.Run_Order__c ORDER BY Run_Order__c ASC LIMIT 1];
        if (!jobs.isEmpty())
        {
            Job__c nextJob = jobs.get(0);        
            nextJob.Status__c = 'Running';
            update nextJob;
            Type customType = Type.forName(nextJob.Apex_Class__c);
            Queueable queue = (Queueable)customType.newInstance();        
            System.enqueueJob(queue);
        }        
    }

    //Change current job to "Sleeping" and find the next job to run
    public static void sleepJob(String name, Integer sleepDuration)
    {
        Job__c job = [SELECT Id, Run_Order__c FROM Job__c WHERE Apex_Class__c = :name];
        job.Status__c = 'Sleeping';
        job.Sleep_Duration__c = sleepDuration;
        job.Last_Run__c = System.now();
        update job;
        List<Job__c> jobs = [SELECT Apex_Class__c FROM Job__c WHERE Active__c = TRUE AND Status__c != 'Running' AND Next_Run__c <= :System.now() AND Run_Order__c > :job.Run_Order__c ORDER BY Run_Order__c ASC LIMIT 1];
        if (!jobs.isEmpty())
        {
            Job__c nextJob = jobs.get(0);        
            nextJob.Status__c = 'Running';
            update nextJob;
            Type customType = Type.forName(nextJob.Apex_Class__c);
            Queueable queue = (Queueable)customType.newInstance();        
            System.enqueueJob(queue);
        }        
    }    
}