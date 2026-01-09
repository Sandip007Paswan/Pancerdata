public without sharing class ContactORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c  cus = ORDS_Path__c.getValues('ContactORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'contacts';
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
                ORDSAPI.ResponseContactData result = (ORDSAPI.ResponseContactData) JSON.deserialize(resBody, ORDSAPI.ResponseContactData.class);
                System.debug(result);          
                List<Contact> contacts = new List<Contact>();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();
                
                for (ORDSAPI.ContactData c : result.items)
                {
                    Account accRef = new Account(ERP_Id__c = c.cust_account_id);
                    Contact contact = new Contact();
                    
                    if(c.contact_last_name != null){
                        contact.FirstName = c.contact_first_name;
                        contact.LastName = c.contact_last_name;
                    }
                    else {
                        contact.LastName = c.contact_first_name;
                    }
                    
                    contact.MiddleName = c.contact_middle_name;
                    contact.ERP_Id__c = c.org_contact_id;
                    contact.Title = c.contact_job_title;
                    contact.Email = c.contact_email;
                    contact.phone = c.contact_phone_number;
                    contact.Fax = c.contact_fax_number;
                    contact.MobilePhone = c.contact_mobile_number;
                    contact.Account = accRef;
                    
                    /*if(c.customer_account_number.right(4) == '0000') account.Customer_Account_Type__c = 'Cash';
else account.Customer_Account_Type__c = 'Credit';*/
                    contacts.add(contact);
                }
                
                Schema.SObjectField ftoken = Contact.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(contacts,ftoken,false);
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
                            ContactORDSJob thisJob = new ContactORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('ContactORDSJob');    
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('ContactORDSJob');    
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