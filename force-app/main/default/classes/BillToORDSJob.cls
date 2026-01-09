public without sharing class BillToORDSJob implements Queueable, Database.AllowsCallouts
{
    private static List<String> separateCommas(String input){
        List<String> results = input.split(',');
        
        for(String result : results) {
            result = result.trim();
        }
        return results;
    }
    
    ORDS_Path__c  cus = ORDS_Path__c.getValues('BillToORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'BILL_TO';
    public void execute(System.QueueableContext ctx)
    {         
        String path = cus.Path__c+ offset;
        ORDS_Log__c log ;
        //String path = '/ords/apps/xxkaccreplication/address1/'+ offset;
        try 
        {            
            HttpResponse response = ORDSAPI.sendRequest(path, 'GET', null);
            if(response.getStatusCode() == 200){
                String resBody = response.getbody();
                System.debug(resBody);
                ORDSAPI.ResponseAddressData result = (ORDSAPI.ResponseAddressData) JSON.deserialize(resBody, ORDSAPI.ResponseAddressData.class);
                
                System.debug(result);
                String StreetConcat;
                List<Address__c> addrs = new List<Address__c>();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();
                for (ORDSAPI.AddressData address : result.items)
                {
                    Address__c addr = new Address__c();
                    List<String> addrSplit = separateCommas(address.address_line_4);
                    //System.debug(addrSplit);
                    if(address.address_line_1 != null) StreetConcat = address.address_line_1;
                    if(address.address_line_2 != null) StreetConcat = StreetConcat + ' '+ address.address_line_2;
                    if(address.address_line_3 != null) StreetConcat = StreetConcat + ' '+ address.address_line_3;
                    
                    Account accRef = new Account(ERP_Id__c = address.customer_id);
                    addr.Name = address.location;
                    addr.ERP_Id__c = address.site_use_id;
                    addr.Account__r  = accRef;
                    addr.Type__c  = address.site_use_code.replace('_',' ');
                    addr.Street__c = StreetConcat;
                    addr.Primary_Billing_Address__c = Boolean.Valueof(address.bill_to_flag);
                    if(addrSplit.size() == 4)
                    {
                        addr.City__c = addrSplit[0];
                        addr.State__c = addrSplit[1];
                        addr.Postal_Code__c = addrSplit[2];
                        addr.Country__c = addrSplit[3];
                    }
                    if(addrSplit.size() == 3)
                    {
                        //addr.City__c = addrSplit[0];
                        addr.State__c = addrSplit[0];
                        addr.Postal_Code__c = addrSplit[1];
                        addr.Country__c = addrSplit[2];
                    }
                    //System.debug(addr);
                    addrs.add(addr);
                    
                }
                //upsert accounts ERP_Id__c;
                Schema.SObjectField ftoken = Address__c.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(addrs,ftoken,false);
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
                            BillToORDSJob thisJob = new BillToORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('BillToORDSJob');
            }
            else 
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('BillToORDSJob');    
            }
        } 
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            //JobScheduler.finishJob('BillToORDSJob'); 
        }
    }
}