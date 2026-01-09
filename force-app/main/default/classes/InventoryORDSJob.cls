public without sharing class InventoryORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c  cus = ORDS_Path__c.getValues('InventoryORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'inventories';
    public void execute(System.QueueableContext ctx)
    {         
        String path = cus.Path__c+ offset;
        ORDS_Log__c log;
        //String path = '/ords/apps/xxkmatreplication/'+ offset;
        try 
        {            
            HttpResponse response = ORDSAPI.sendRequest(path, 'GET', null);
            if(response.getStatusCode() == 200){
                String resBody = response.getbody();
                System.debug(resBody);
                ORDSAPI.ResponseInventoryData result = (ORDSAPI.ResponseInventoryData) JSON.deserialize(resBody, ORDSAPI.ResponseInventoryData.class);
                System.debug(result);
                Map<String,Decimal> invenIdQtyRemainMap = new Map<String,Decimal>();
                List<Inventory__c> invens = new List<Inventory__c>();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();
                
                for (ORDSAPI.InventoryData item : result.items)
                {
                    String inven_ERPId = item.inventory_warehouse_id+item.inventory_item_id;
                    //String inven_ERPId = item.inventory_warehouse_id+item.inventory_item_id+item.product_code;
                    if(!invenIdQtyRemainMap.containsKey(inven_ERPId))
                        invenIdQtyRemainMap.put(inven_ERPId, Decimal.valueOf(item.inventory_available_quantity));
                    
                }
                System.debug(invenIdQtyRemainMap.size());
                System.debug(invenIdQtyRemainMap);
                
                if(!invenIdQtyRemainMap.isEmpty())
                {
                    for(Inventory__c inven : [SELECT Id, Quantity_Remaining__c,ERP_Id__c FROM Inventory__c WHERE ERP_Id__c =: invenIdQtyRemainMap.keyset()])
                    {
                        if(invenIdQtyRemainMap.containsKey(inven.ERP_Id__c))
                        {
                            //System.debug('Inventory Found '+inven.ERP_Id__c);
                            Inventory__c inv = new Inventory__c();
                            inv.ERP_Id__c = inven.ERP_Id__c;
                            inv.Quantity_Remaining__c = invenIdQtyRemainMap.get(inven.ERP_Id__c);
                            invens.add(inv);
                        }
                    }
                }
                System.debug('invens '+invens);
                
                Schema.SObjectField ftoken = Inventory__c.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(invens,ftoken,false);
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
                            InventoryORDSJob thisJob = new InventoryORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('InventoryORDSJob');
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('InventoryORDSJob');    
            }
        } 
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            //JobScheduler.finishJob('ProductORDSJob'); 
        }
    }
}