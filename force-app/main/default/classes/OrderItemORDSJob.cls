public without sharing class OrderItemORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c  cus = ORDS_Path__c.getValues('OrderItemORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'lineitem';
    public void execute(System.QueueableContext ctx)
    {         
        String path = cus.Path__c+ offset;
        ORDS_Log__c log;
        //String path = '/ords/apps/getorderline/'+ offset;
        try 
        {            
            HttpResponse response = ORDSAPI.sendRequest(path, 'GET', null);
            if(response.getStatusCode() == 200){
                String resBody = response.getbody();
                System.debug(resBody);
                ORDSAPI.ResponseOrderItemGetData result = (ORDSAPI.ResponseOrderItemGetData) JSON.deserialize(resBody, ORDSAPI.ResponseOrderItemGetData.class);
                System.debug(result);          
                Id pricebookId;
                Map<String,Decimal> invenIdQtyRemainMap = new Map<String,Decimal>();
                List<OrderItem> orderItems = new List<OrderItem>();
                List<OrderItem> orderItemsToDelete = new List<OrderItem>();
                List<String> productCode = new List<String>();
                Map<String,Id> productIdMap = new Map<String,Id>();
                List<String> orderErpIds = new List<String>();
                Map<Id,Opportunity> enquiryIdMap = new Map<Id,Opportunity>();
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                List<Order> ordersToUpdate = new List<Order>();
                if(!Test.isRunningTest()) pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].Id;
                else pricebookId = Test.getStandardPricebookId();
                
                for (ORDSAPI.OrderItemGetData item : result.items)
                {
                    productCode.add(item.order_line_product_code);
                    orderErpIds.add(item.order_erp_id);
                }
                
                If(!orderErpIds.isEmpty())
                {
                    System.debug('orderErpIds '+orderErpIds);
                    for(OrderItem oitem : [SELECT Id, Erp_Id__c FROM OrderItem WHERE Erp_Id__c = null
                                           AND Order.RecordType.DeveloperName = 'Recurring_Orders' AND Order.Erp_Id__c IN: orderErpIds])
                        orderItemsToDelete.add(oitem);
                }
                
                if(!orderItemsToDelete.isEmpty())
                {
                    try
                    {
                        delete orderItemsToDelete;
                    }
                    catch (Exception e) {
                        System.debug(e.getMessage());
                        insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
                    }
                }
                
                If(!productCode.isEmpty())
                {
                    for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, Product2.ProductCode
                                                  FROM PricebookEntry WHERE IsActive = true
                                                  AND Product2.ProductCode IN: productCode AND Pricebook2Id =: pricebookId])
                    {
                        productIdMap.put(pbEntry.Product2.ProductCode, pbEntry.id);
                    }
                }
                
                for (ORDSAPI.OrderItemGetData item : result.items)
                {
                    Order orderRef = new Order(ERP_Id__c = item.order_erp_id);
                    OrderItem ord = new OrderItem();
                    ord.Order = orderRef;
                    ord.ERP_Id__c = item.order_line_erp_id;
                    ord.PricebookEntryId = productIdMap.get(item.order_line_product_code);
                    ord.Item_No__c = Decimal.Valueof(item.order_line_item_no);
                    ord.quantity = Decimal.Valueof(item.order_line_quantity);
                    ord.UOM__c = item.order_line_uom;
                    ord.List_Price__c  = Decimal.Valueof(item.order_line_list_price);
                    ord.Cost_Price__c  = Decimal.Valueof(item.order_line_cost_price);
                    ord.unitprice = Decimal.Valueof(item.order_line_unit_price);
                    if (ord.unitprice != 0) {
                      ord.Margin__c = ((ord.unitprice - ord.Cost_Price__c) *100) / ord.unitprice;
                    } else {
                    
                      ord.Margin__c = 0;
                      
                    }
                    if(item.order_line_unit_discount != null) ord.Discount__c = Decimal.Valueof(item.order_line_unit_discount);
                    ord.Description2__c = item.order_line_additional_desc_1;
                    ord.Additional_Description_Line_1__c = item.order_line_add_desc_line1;
                    ord.Additional_Description_Line_2__c = item.order_line_add_desc_line2;
                    ord.Additional_Description_Line_3__c = item.order_line_add_desc_line3;
                    ord.Additional_Description_Line_4__c = item.order_line_add_desc_line4;
                    ord.Additional_Description_Para_1__c = item.order_line_add_desc_para1;
                    ord.Additional_Description_Para_2__c = item.order_line_add_desc_para2;
                    ord.Additional_Description_Para_3__c = item.order_line_add_desc_para3;
                    ord.Sales_Order_Status__c = item.order_line_status;
                    orderItems.add(ord);   
                }
                System.debug('orderItems size '+orderItems.size());

                Schema.SObjectField ftoken = OrderItem.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(orderItems,ftoken,false);
                for (Database.UpsertResult sr : uResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('fields that affected this error: ' + err.getFields());
                            insert log = new ORDS_Log__c(Request__c = path, Response__c = err.getMessage(), Error__c = true);
                        }
                    }    
                }

                for(Order orderToUpdate : [SELECT Id, OpportunityId ,Opportunity.Line_Item_Count__c, Line_Item_Count__c, ERP_Id__c, RecordType.DeveloperName FROM Order 
                                           WHERE Order.Erp_Id__c IN: orderErpIds])
                {
                    System.debug('orderErpIds '+orderToUpdate.ERP_Id__c);
                    System.debug('Opp Items Size '+orderToUpdate.Opportunity.Line_Item_Count__c);
                    System.debug('Order Items Size '+orderToUpdate.Line_Item_Count__c);
                    if(orderToUpdate.Opportunity.Line_Item_Count__c == orderToUpdate.Line_Item_Count__c)
                    {
                        Opportunity opp = new Opportunity();
                        opp.Id = orderToUpdate.OpportunityId;
                        opp.Submission_Status__c = 'Successful';
                        oppsToUpdate.add(opp);
                        System.debug(oppsToUpdate);
                        
                        if( orderToUpdate.RecordType.DeveloperName== 'Recurring_Orders')
                        {
                            Order order = new Order();
                            order.Id = orderToUpdate.Id;
                            order.Oracle_Submission_Status__c = 'Successful';
                            ordersToUpdate.add(Order);
                        } 
                    }
                }
                
                If(!oppsToUpdate.isEmpty()) Update oppsToUpdate;
                If(!ordersToUpdate.isEmpty()) Update ordersToUpdate;
                
                if (result.hasMore == true)
                {
                    List<ORDSAPI.LinkData> links = result.links;
                    for (ORDSAPI.LinkData link : links)
                    {
                        if (link.rel.equalsIgnoreCase('next'))
                        {
                            OrderItemORDSJob thisJob = new OrderItemORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('OrderItemORDSJob');    
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('OrderItemORDSJob');    
            }
        } 
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            //JobScheduler.finishJob('OrderItemORDSJob');
        }
    }
}