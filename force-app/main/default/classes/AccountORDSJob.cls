public without sharing class AccountORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c cus = ORDS_Path__c.getValues('AccountORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'customer1';
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
                ORDSAPI.ResponseAccountData result = (ORDSAPI.ResponseAccountData) JSON.deserialize(resBody, ORDSAPI.ResponseAccountData.class);
                System.debug(result);
                List<Account> accounts = new List<Account>();
                List<Account> prospectAccounts = new List<Account>();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();
                for (ORDSAPI.AccountData c : result.items)
                {
                    Account account = new Account();
                    account.Name = c.customer_name;
                    account.Email__c = c.customer_email;
                    account.phone = c.customer_phone;
                    account.Primary_Customer_Category__c = c.customer_category;
                    account.ERP_Id__c = c.customer_account_id;
                    account.AccountNumber = c.customer_account_number;
                    account.Description = c.customer_description;
                    account.Location__c  = c.customer_location;
                    account.Payment_Terms__c = c.customer_payment_term;
                    account.Credit_Standing__c = c.customer_credit_status;
                    account.Current_Month__c  = Decimal.Valueof(c.customer_current_month);
                    account.Past_Due_30_Days__c  = Decimal.Valueof(c.amount_30);
                    account.Past_Due_60_Days__c = Decimal.Valueof(c.amount_60);
                    account.Past_Due_90_Days__c  = Decimal.Valueof(c.amount_90);
                    account.Past_Due_120_Days__c = Decimal.Valueof(c.amount_120);
                    account.Past_Due_180_Days__c = Decimal.Valueof(c.amount_180);
                    account.Past_Due_360_Days__c = Decimal.Valueof(c.amount_360);
                    account.Collector__c = c.collector;
                    
                    if(c.customer_account_number.right(4) == '0000') account.Customer_Account_Type__c = 'Cash';
                    else account.Customer_Account_Type__c = 'Credit';
                    
                    if(c.customer_sf_record_id == null) // True Account from Oracle
                        accounts.add(account);
                    else
                    {
                        account.Id = c.customer_sf_record_id;
                        account.Prospect_Customer__c = false;
                        system.debug('Update customer_sf_record_id : '+c.customer_sf_record_id);
                        prospectAccounts.add(account); // Prospect Account from SF
                    }
                }

                Schema.SObjectField ftoken = Account.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(accounts,ftoken,false);
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
                
                if(!prospectAccounts.isEmpty()) update prospectAccounts;
                
                if (result.hasMore == true)
                {
                    List<ORDSAPI.LinkData> links = result.links;
                    for (ORDSAPI.LinkData link : links)
                    {
                        if (link.rel.equalsIgnoreCase('next'))
                        {
                            AccountORDSJob thisJob = new AccountORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('AccountORDSJob');
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('AccountORDSJob');    
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