public without sharing class AccCategoryORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c  cus = ORDS_Path__c.getValues('AccCategoryORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'categories';
    public void execute(System.QueueableContext ctx)
    {         
        String path = cus.Path__c+ offset;
        ORDS_Log__c log;
        //String path = '/ords/apps/xxkaccreplication/'+ offset;
        try 
        {            
            HttpResponse response = ORDSAPI.sendRequest(path, 'GET', null);
            if(response.getStatusCode() == 200){
                String resBody = response.getbody();
                System.debug(resBody);
                ORDSAPI.ResponseAccCategoryData result = (ORDSAPI.ResponseAccCategoryData) JSON.deserialize(resBody, ORDSAPI.ResponseAccCategoryData.class);
                System.debug(result);          
                List<Customer_Category__c > Categories  = new List<Customer_Category__c >();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();
                for (ORDSAPI.AccCategoryData c : result.items)
                {
                    Account accRef = new Account(ERP_Id__c = c.customer_id);
                    Customer_Category__c cat = new Customer_Category__c();                
                    cat.ERP_Id__c = c.customer_id+c.division_code+c.customer_category;
                    cat.Division__c  = c.division_code;
                    cat.Customer_Category__c  = c.customer_category;
                    cat.Account__r = accRef;
                    Categories.add(cat);
                }
                
                Schema.SObjectField ftoken = Customer_Category__c.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(Categories,ftoken,false);
                for (Database.UpsertResult sr : uResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());                    
                            System.debug('fields that affected this error: ' + err.getFields());
                            log = new ORDS_Log__c(Request__c = path, Response__c = err.getMessage(), Error__c = true);
                            logs.add(log);
                        }
                    }    
                }
                if(!logs.isEmpty()) insert logs;
                
                if (result.hasMore == true)
                {
                    List<ORDSAPI.LinkData> links = result.links;
                    for (ORDSAPI.LinkData link : links)
                    {
                        if (link.rel.equalsIgnoreCase('next'))
                        {
                            AccCategoryORDSJob thisJob = new AccCategoryORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('AccCategoryORDSJob');
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('AccCategoryORDSJob');    
            }
            
        } 
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            //JobScheduler.finishJob('AccountORDSJob'); 
        }
    }
}