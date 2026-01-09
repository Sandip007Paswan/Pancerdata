public without sharing class OrderORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c  cus = ORDS_Path__c.getValues('OrderORDSJob');
    public String offset = cus.Offset__c;
    public String offset2 ;
    public List<Id> EnquiryIds = new List<Id>();
    //public String offset = 'orderreplication';
    public void execute(System.QueueableContext ctx)
    {         
        String path = cus.Path__c+ offset;
        ORDS_Log__c log;
        //String path = '/ords/apps/getorder/'+ offset;
        try 
        {            
            HttpResponse response = ORDSAPI.sendRequest(path, 'GET', null);
            if(response.getStatusCode() == 200){
                String resBody = response.getbody();
                System.debug(resBody);
                ORDSAPI.ResponseOrderGetData result = (ORDSAPI.ResponseOrderGetData) JSON.deserialize(resBody, ORDSAPI.ResponseOrderGetData.class);
                System.debug(result);
                Id pricebookId;
                if(!Test.isRunningTest()) pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].Id;
                else pricebookId = Test.getStandardPricebookId();
                Map<String,Decimal> invenIdQtyRemainMap = new Map<String,Decimal>();
                List<Order> orders = new List<Order>();
                List<Order> standaloneOrders = new List<Order>();
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                List<String> warehouseCode = new List<String>();
                Map<String,Id> warehouseIdMap = new Map<String,Id>();
                //List<Id> EnquiryIds = new List<Id>();
                List<String> OwnerIds = new List<String>();
                List<Id> successOrderIds = new List<Id>();
                Map<Id,Opportunity> enquiryIdMap = new Map<Id,Opportunity>();
                Map<String,String> userIdMap = new Map<String,String>();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();

                for (ORDSAPI.OrderGetData item : result.items)
                {
                    warehouseCode.add(item.order_warehouse_id);
                    EnquiryIds.add(item.order_sf_enquiry_id);
                    //OwnerIds.add(item.order_owner_erp_id);
                }
                system.debug('EnquiryIds '+EnquiryIds);
                
                if(!warehouseCode.isEmpty())   
                {
                    for(Warehouse__c  ware : [SELECT Id, Name, Code__c FROM Warehouse__c WHERE Code__c IN: warehouseCode])
                    {
                        if(!warehouseIdMap.containsKey(ware.Code__c))
                            warehouseIdMap.put(ware.Code__c, ware.id);
                    }
                }
                
                if(!EnquiryIds.isEmpty())   
                {
                    for(Opportunity opp : [SELECT Id, Territory2Id, Division__c, RecordType.Name, RecordTypeId, OwnerId, Location__c FROM Opportunity WHERE Id IN: EnquiryIds]){
                        if(!enquiryIdMap.containsKey(opp.Id)) enquiryIdMap.put(opp.Id, opp);
                    }
                    system.debug('enquiryIdMap : '+enquiryIdMap);
                }
                
                /*if(!OwnerIds.isEmpty())   
                {
                    for(User user : [SELECT Id, Sales_Rep_Value__c, toLabel(Sales_Rep_ID2__c) FROM User WHERE Sales_Rep_ID2__c IN: OwnerIds]){
                        if(!userIdMap.containsKey(user.Sales_Rep_Value__c)) userIdMap.put(user.Sales_Rep_Value__c, user.Sales_Rep_ID2__c);
                    }
                    system.debug('userIdMap : '+userIdMap);
                    
                    if(!userIdMap.isEmpty())   
                    {
                        for(User user : [SELECT Id, Sales_Rep_ID2__c FROM User WHERE Sales_Rep_ID2__c IN: userIdMap.keyset()]){
                            if(userIdMap.containsKey(user.Sales_Rep_ID2__c)) userIdMap.put(user.Sales_Rep_ID2__c, user.Id);
                        }
                        system.debug('userIdMap1 : '+userIdMap);
                    }
                }*/
                
                for (ORDSAPI.OrderGetData item : result.items)
                {
                    Order_Type__c orderTypeRef = new Order_Type__c(Order_Type_ID__c = item.order_type_id);
                    Account accRef = new Account(ERP_Id__c = item.order_sold_to_erp_id);
                    Address__c shipToRef = new Address__c(ERP_Id__c = item.order_ship_to_erp_id);
                    Address__c BillToRef = new Address__c(ERP_Id__c = item.order_bill_to_erp_id);
                    Contact ContactRef = new Contact(ERP_Id__c = item.order_sold_to_contact_id);
                    Order_Status_Mapping__c cus = Order_Status_Mapping__c.getValues(item.order_status);
                    String orderStage = cus.SF_Stage__c;
                    
                    Order ord = new Order();
                    ord.ERP_Id__c = item.order_erp_id;
                    if(item.order_type_id != null) ord.Order_Type__r = orderTypeRef;
                    if(item.order_sold_to_erp_id != null) ord.Account = accRef;
                    ord.Status = orderStage;
                    ord.ERP_Number_Id__c = item.order_erp_number_id;
                    ord.EffectiveDate = Date.Valueof(item.order_date.left(10));
                    if(item.order_ship_to_erp_id != null) ord.Address__r = shipToRef;
                    if(item.order_bill_to_erp_id != null) ord.Bill_To_Address__r = BillToRef;
                    //if(userIdMap.containsKey(item.order_owner_erp_id)) ord.OwnerId = userIdMap.get(item.order_owner_erp_id);
                    if(enquiryIdMap.containsKey(item.order_sf_enquiry_id)) ord.OwnerId = enquiryIdMap.get(item.order_sf_enquiry_id).OwnerId;
                    ord.Payment_Terms__c = item.order_payment_term;
                    if(warehouseIdMap.containsKey(item.order_warehouse_id)) ord.Warehouse__c = warehouseIdMap.get(item.order_warehouse_id);
                    ord.Shipping_Method__c = item.order_shipping_method;
                    if(item.order_sold_to_contact_id != null) ord.Sold_To_Contact_ID__r = ContactRef;
                    ord.Pricebook2Id = pricebookId;
                    ord.Deliver_To_Address_1__c = item.order_deliver_to_address1;
                    ord.Deliver_To_Address_2__c = item.order_deliver_to_address2;
                    ord.Deliver_To_Address_3__c = item.order_deliver_to_address3;
                    ord.Deliver_To_Address_4__c = item.order_deliver_to_address4;
                    ord.Deliver_To_Contact__c = item.order_deliver_to_contact;
                    ord.Bill_To_Address_1__c = item.order_bill_to_address1;
                    ord.Bill_To_Address_2__c = item.order_bill_to_address2;
                    ord.Bill_To_Address_3__c = item.order_bill_to_address3;
                    ord.Bill_To_Address_4__c = item.order_bill_to_address4;
                    ord.Bill_To_Cash_Customer__c = item.order_bill_cash_customer;
                    ord.Price_List_Type__c = item.order_price_list_type;
                    ord.FOB_Point_Code__c = item.order_fob_point_code;
                    
                    if(enquiryIdMap.containsKey(item.order_sf_enquiry_id)) //From Enquiry Submit
                    {
                        ord.OpportunityId = item.order_sf_enquiry_id; ord.Division__c = enquiryIdMap.get(item.order_sf_enquiry_id).Division__c; ord.Location__c = enquiryIdMap.get(item.order_sf_enquiry_id).Location__c;
                        String EnquiryRTName = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById().get(enquiryIdMap.get(item.order_sf_enquiry_id).RecordTypeId).getDeveloperName();
                        if(EnquiryRTName == 'Customised_Engineering_Solution') {
                            ord.recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Customised_Engineering_Solutions_Order').getRecordTypeId();
                            //ord.Enquiry_Number__c = item.order_sf_enq_number; ord.PoNumber = item.order_cust_po_number;
                        }
                        else {
                            ord.recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Single_Order').getRecordTypeId();
                        }
                        ord.Enquiry_Number__c = item.order_sf_enq_number; ord.PoNumber = item.order_cust_po_number;
                        orders.add(ord);
                    }
                    else //From Standalone Order Submit
                    {
                        ord.Enquiry_Number__c = item.order_sf_enq_number;
                        ord.PoNumber = item.order_cust_po_number;
                        ord.Id = item.order_sf_enquiry_id;
                        standaloneOrders.add(ord);
                    }
                }
                
                system.debug('orders size '+orders.size());
                Schema.SObjectField ftoken = Order.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(orders,ftoken,false);
                for (Database.UpsertResult sr : uResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful
                        successOrderIds.add(sr.id);
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
                
                system.debug('standaloneOrders size '+standaloneOrders.size());
                List<Database.SaveResult> updateResults = Database.update(standaloneOrders,false);
                for (Database.SaveResult sr : updateResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful
                        successOrderIds.add(sr.getId());
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
                
                if(!successOrderIds.isEmpty())
                {
                    system.debug(successOrderIds);
                    for(Order mOrder : [SELECT Id, OpportunityId FROM Order WHERE Id IN: successOrderIds])
                    {
                        Opportunity opp = new Opportunity(); opp.id = mOrder.OpportunityId; opp.StageName = 'Closed Won';
                        oppsToUpdate.add(opp);
                    }
                    
                    if(!oppsToUpdate.isEmpty()){
                        try
                        {
                            System.debug(oppsToUpdate);
                            update oppsToUpdate;
                        }
                        catch (Exception e) {
                            System.debug(e.getMessage());
                            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
                        }
                    }
                }
                
                if (result.hasMore == true)
                {
                    List<ORDSAPI.LinkData> links = result.links;
                    for (ORDSAPI.LinkData link : links)
                    {
                        if (link.rel.equalsIgnoreCase('next'))
                        {
                            OrderORDSJob thisJob = new OrderORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('OrderORDSJob');    
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('OrderORDSJob');    
            }
        } 
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            //JobScheduler.finishJob('OrderORDSJob'); 
        }
    }
}