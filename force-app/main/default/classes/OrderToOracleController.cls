public without sharing class OrderToOracleController implements Database.AllowsCallouts
{
    public static final string SF_NAMED_CREDENTIAL = 'callout:ORDS';
    public static String path = '/ords/apps/xxkordersubmit/order1';  // '/ords/apps/orderreplication/order1'
    public static OracleStatus returnRes {get; set;}
    public static String oppRecordTypeName; 
    
    public class OracleStatus
    {
        @AuraEnabled public Integer statusCode {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String requestId {get; set;}
        @AuraEnabled public String response_msg {get; set;}
    }

    @AuraEnabled
    public static List<sObject> getoppItems(Id recordId)
    {
        String recordId_txt = String.valueOf(recordId);
        List<sObject> lineItems ;
        if(recordId_txt.left(3) == '006')
        {
            oppRecordTypeName = [SELECT Id, RecordType.developerName FROM Opportunity WHERE id =: recordId].RecordType.developerName;
            if(oppRecordTypeName == 'Customised_Engineering_Solution')
            {
                lineItems = [SELECT Id, New_Product__c, Code__c FROM Parent_Product__c WHERE Enquiry__c =: recordId]; 
            }
            else
            {
                lineItems = [SELECT Id, Product2.New_Product__c, Product2.ProductCode FROM OpportunityLineItem WHERE OpportunityId =: recordId]; 
            }
                
        }
        else if(recordId_txt.left(3) == '801')
        {
            lineItems = [SELECT Id, Product2.New_Product__c, Product2.ProductCode FROM OrderItem WHERE OrderId =: recordId];
        }
        return lineItems;
        
    }
    
    @AuraEnabled
    public static OracleStatus doProcess(Id recordId)
    {
        List<ORDSAPI.OrderItemData> OrderItemsReq;
        String res_msg;
        Map<String, Object> jsonMap; 
        ORDSAPI.OrderData OrderReq = setOrderRequest(recordId);
        System.debug('OrderReq : '+OrderReq);
        Opportunity opp;
        Order ord;
        String recordId_txt = String.valueOf(recordId);
        if(recordId_txt.left(3) == '006')
            oppRecordTypeName = [SELECT Id, RecordType.developerName FROM Opportunity WHERE id =: recordId].RecordType.developerName;
        
        try 
        {            
            string OutputOrder= JSON.serialize(OrderReq);
            System.debug(OutputOrder);
            returnRes = new OracleStatus();
            HttpResponse response = ORDSAPI.sendRequest(path, 'POST', OutputOrder);
            System.debug('Header : '+response);
            jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            res_msg = (String)jsonMap.get('RESPONSE_MSG');
            returnRes.response_msg = res_msg;
            returnRes.statusCode = response.getStatusCode();
            returnRes.status = response.getStatus();
            System.debug('Order response_msg : '+returnRes);
            
            /*-----------Send Order LineItems-----------------*/
            
            if(response.getStatusCode() == 200)
            {
                OrderItemsReq = setOrderItemRequest(recordId);
                System.debug(OrderItemsReq);
                for(ORDSAPI.OrderItemData oItem : OrderItemsReq)
                {
                    System.debug(oItem);
                    string OutputOrderItem = JSON.serialize(oItem);
                    System.debug(OutputOrderItem);
                    path = '/ords/apps/xxkordersubmit/order2';
                    response = ORDSAPI.sendRequest(path, 'POST', OutputOrderItem);
                    System.debug(response);
                    if(response.getStatusCode() != 200) 
                    {
                        jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        returnRes.response_msg = (String)jsonMap.get('Response_Messages');
                        returnRes.statusCode = response.getStatusCode();
                        returnRes.status = response.getStatus();
                        //if(recordId_txt.left(3) == '006') update opp = new Opportunity(Id = recordId, Submission_Status__c  = 'Not Successful');
                        //else update ord = new Order(Id = recordId, Oracle_Submission_Status__c  = 'Not Successful'); 
                        break;
                    }
                }
                
                String submit = '{"P_ORIG_SYS_DOCUMENT_REF": "'+recordId+'"}';
                path = '/ords/apps/xxkordersubmit/submit1';
                response = ORDSAPI.sendRequest(path, 'POST', submit);
                System.debug('Submit : '+response);
                
                System.debug('response.getbody() : '+response.getbody());
                ORDSAPI.ResponseOrder result = (ORDSAPI.ResponseOrder)JSON.deserialize(response.getbody(), ORDSAPI.ResponseOrder.class);
                
                System.debug('Request ID '+result);
                
                returnRes.statusCode = response.getStatusCode();
                returnRes.status = response.getStatus();
                returnRes.requestId = result.REQUEST_ID;
                
                if(returnRes.requestId != null)
                {
                    if(recordId_txt.left(3) == '006')
                        update opp = new Opportunity(Id = recordId, Oracle_Request_Id__c = returnRes.requestId, Submission_Status__c  = 'In Progress', InProgress__c = true, InProgress_TimeStamp__c = System.now());    
                    else if(recordId_txt.left(3) == '801')
                        update ord = new Order(Id = recordId, Oracle_Request_Id__c = returnRes.requestId, Oracle_Submission_Status__c  = 'In Progress', InProgress__c = true, InProgress_TimeStamp__c = System.now() );
                } 
                /*else
                {
                    if(recordId_txt.left(3) == '006') update opp = new Opportunity(Id = recordId, Submission_Status__c  = 'Not Successful');                            
                    else if(recordId_txt.left(3) == '801') update ord = new Order(Id = recordId, Oracle_Submission_Status__c  = 'Not Successful');
                }*/
            }
            /*else
            {
                if(recordId_txt.left(3) == '006') update opp = new Opportunity(Id = recordId, Submission_Status__c  = 'Not Successful');
                else update ord = new Order(Id = recordId, Oracle_Submission_Status__c  = 'Not Successful'); 
                system.debug('returnRes '+returnRes);
            }*/
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            ORDS_Log__c log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            system.debug(log);
            system.debug(log.Response__c);
            insert log;
            throw new AuraHandledException(e.getMessage());
        }
        
        return returnRes;
        
    }
    
    
    public static ORDSAPI.OrderData setOrderRequest(Id recordId)
    {
        try{
            String recordId_txt = String.valueOf(recordId);
            ORDSAPI.OrderData OrderReq = new ORDSAPI.OrderData();
            if(recordId_txt.left(3) == '006')
            {
                system.debug('Opportunity');
                
                List<Opportunity> opp = [SELECT Id, Name, AccountId, Account.ERP_Id__c, Account.Customer_Account_Type__c, Account.ParentId, Account.Parent.erp_id__c, StageName, Territory2Id, Submission_Status__c, Order_Type__r.Order_Type_ID__c, 
                                         Bill_To_Address__r.ERP_Id__c, Bill_To_Address__r.Name, Bill_To_Address__r.Street__c, Bill_To_Address__r.City__c, Bill_To_Address__r.State__c , Bill_To_Address__r.Country__c,Bill_To_Address__r.Postal_Code__c,
                                         AddressX1__r.ERP_Id__c, AddressX1__r.Name, AddressX1__r.Street__c, AddressX1__r.City__c, AddressX1__r.State__c, AddressX1__r.Country__c, AddressX1__r.Postal_Code__c,
                                         Enquiry_Type__c, Warehouse__r.code__c, Payment_Terms__c, Owner.Sales_Rep_Value__c,Enquiry_ID__c, WorkShop_Note__c,Sales_Rep__r.ID__c,
                                         Deliver_To_Address_1__c , Deliver_To_Address_2__c , Deliver_To_Address_3__c , Deliver_To_Address_4__c , Deliver_To_Contact__c,Shipping_Method__c,
                                         Bill_To_Address_1__c, Bill_To_Address_2__c, Bill_To_Address_3__c, Bill_To_Address_4__c, Bill_To_Cash_Customer__c,RecordType.developerName,
                                         Sold_To_Contact_ID__r.ERP_Id__c,Sales_Coordinator__c ,Sales_Coordinator__r.Sales_Rep_ID2__c,Customer_PO_Number__c,FOB_Point_Code__c,Customer_Category__c
                                         FROM Opportunity WHERE Id =: recordId];
                
                OrderReq.P_ORIG_SYS_DOCUMENT_REF = opp[0].Id;
                OrderReq.P_ORDER_TYPE_ID = opp[0].Order_Type__r.Order_Type_ID__c;
                OrderReq.P_PRICE_LIST_ID = '1000';
                OrderReq.P_TRANSACTIONAL_CURR_CODE = 'MYR';
                OrderReq.P_SALESREP_ID = opp[0].Sales_Rep__r.ID__c;
                if(opp[0].Sales_Coordinator__c != null) OrderReq.P_CO_SALESREP_ID = opp[0].Sales_Coordinator__r.Sales_Rep_ID2__c;
                else OrderReq.P_CO_SALESREP_ID = opp[0].Owner.Sales_Rep_Value__c;
                OrderReq.P_SO_TO_CON_ID = opp[0].Sold_To_Contact_ID__r.ERP_Id__c;
                OrderReq.P_PAYMENT_TERM_ID = opp[0].Payment_Terms__c;
                OrderReq.P_SHIPPING_METHOD_CODE = opp[0].Shipping_Method__c;
                OrderReq.P_SHIPPING_METHOD_CODE = opp[0].Shipping_Method__c;
                OrderReq.P_CUSTOMER_PO_NUMBER = opp[0].Customer_PO_Number__c;
                OrderReq.P_FOB_CODE_V1 = opp[0].FOB_Point_Code__c;
                OrderReq.P_SHIP_FROM_ORG_ID = opp[0].Warehouse__r.code__c;
                OrderReq.P_SHIP_TO_ORG_ID = opp[0].AddressX1__r.ERP_Id__c;
                OrderReq.P_INVOICE_TO_ORG_ID = opp[0].Bill_To_Address__r.ERP_Id__c;
                OrderReq.P_ATTRIBUTE12 = opp[0].Enquiry_ID__c;
                OrderReq.P_SA_CHANNEL_CODE = opp[0].Customer_Category__c;
                OrderReq.P_ATTRIBUTE11 = opp[0].Deliver_To_Address_1__c;
                OrderReq.P_ATTRIBUTE10 = opp[0].Deliver_To_Address_2__c;
                OrderReq.P_ATTRIBUTE8 = opp[0].Deliver_To_Address_3__c;
                OrderReq.P_ATTRIBUTE7 = opp[0].Deliver_To_Address_4__c;
                OrderReq.P_ATTRIBUTE9 = opp[0].Deliver_To_Contact__c;
                
                if(opp[0].Account.Customer_Account_Type__c == 'Cash')
                {
                    OrderReq.P_ATTRIBUTE13 = opp[0].Bill_To_Cash_Customer__c ;
                    OrderReq.P_ATTRIBUTE14 = opp[0].Bill_To_Address_1__c;
                    OrderReq.P_ATTRIBUTE15 = opp[0].Bill_To_Address_2__c;
                    OrderReq.P_ATTRIBUTE4 = opp[0].Bill_To_Address_3__c ;
                    OrderReq.P_ATTRIBUTE5 = opp[0].Bill_To_Address_4__c;
                    
                    if(opp[0].Account.ERP_Id__c == null && opp[0].Account.Parent.ERP_Id__c != null)
                        OrderReq.P_SOLD_TO_ORG_ID = opp[0].Account.Parent.ERP_Id__c;
                    else OrderReq.P_SOLD_TO_ORG_ID = opp[0].Account.ERP_Id__c;
                }
                else
                    OrderReq.P_SOLD_TO_ORG_ID = opp[0].Account.ERP_Id__c;
            }
            else if(recordId_txt.left(3) == '801')
            {
                system.debug('Order');
                List<Order> ord = [SELECT Id, OpportunityId, Opportunity.Enquiry_ID__c,AccountId,Account.Customer_Account_Type__c, Account.ParentId, Account.Parent.erp_id__c,Account.ERP_Id__c, Status, Opportunity.Territory2Id, Opportunity.Enquiry_Type__c, Order_Type__r.Order_Type_ID__c, 
                                   Bill_To_Address__r.ERP_Id__c, Bill_To_Address__r.Name, Bill_To_Address__r.Street__c, Bill_To_Address__r.City__c, Bill_To_Address__r.State__c , Bill_To_Address__r.Country__c,Bill_To_Address__r.Postal_Code__c,
                                   Address__r.ERP_Id__c, Address__r.Name, Address__r.Street__c, Address__r.City__c, Address__r.State__c, Address__r.Country__c, Address__r.Postal_Code__c,
                                   Warehouse__r.code__c, Payment_Terms__c, Sales_Rep__r.ID__c,Shipping_Method__c, Owner_SaleRepId__c,
                                   Deliver_To_Address_1__c, Deliver_To_Address_2__c, Deliver_To_Address_3__c, Deliver_To_Address_4__c, Deliver_To_Contact__c,
                                   Bill_To_Address_1__c, Bill_To_Address_2__c, Bill_To_Address_3__c, Bill_To_Address_4__c, Bill_To_Cash_Customer__c,
                                   Sold_To_Contact_ID__r.ERP_Id__c,Sales_Coordinator__c,Sales_Coordinator__r.Sales_Rep_ID2__c,PoNumber,FOB_Point_Code__c,Price_List_Type__c
                                   FROM Order WHERE Id =: recordId];
                
                OrderReq.P_ORIG_SYS_DOCUMENT_REF = ord[0].Id;
                OrderReq.P_ORDER_TYPE_ID = ord[0].Order_Type__r.Order_Type_ID__c;
                OrderReq.P_PRICE_LIST_ID = '1000';
                OrderReq.P_TRANSACTIONAL_CURR_CODE = 'MYR';
                OrderReq.P_SALESREP_ID = ord[0].Sales_Rep__r.ID__c;
                if(ord[0].Sales_Coordinator__c != null) OrderReq.P_CO_SALESREP_ID = ord[0].Sales_Coordinator__r.Sales_Rep_ID2__c;
                else OrderReq.P_CO_SALESREP_ID = ord[0].Owner_SaleRepId__c;
                OrderReq.P_SO_TO_CON_ID = ord[0].Sold_To_Contact_ID__r.ERP_Id__c;
                OrderReq.P_PAYMENT_TERM_ID = ord[0].Payment_Terms__c;
                OrderReq.P_SHIPPING_METHOD_CODE = ord[0].Shipping_Method__c;
                OrderReq.P_CUSTOMER_PO_NUMBER = ord[0].PoNumber;
                OrderReq.P_FOB_CODE_V1 = ord[0].FOB_Point_Code__c;
                OrderReq.P_SOLD_TO_ORG_ID = ord[0].Account.ERP_Id__c;
                OrderReq.P_SHIP_FROM_ORG_ID = ord[0].Warehouse__r.code__c;
                OrderReq.P_SHIP_TO_ORG_ID = ord[0].Address__r.ERP_Id__c;
                OrderReq.P_INVOICE_TO_ORG_ID = ord[0].Bill_To_Address__r.ERP_Id__c;
                OrderReq.P_ATTRIBUTE12 = ord[0].Opportunity.Enquiry_ID__c;
                OrderReq.P_SA_CHANNEL_CODE = ord[0].Price_List_Type__c;
                OrderReq.P_ATTRIBUTE11 = ord[0].Deliver_To_Address_1__c;
                OrderReq.P_ATTRIBUTE10 = ord[0].Deliver_To_Address_2__c;
                OrderReq.P_ATTRIBUTE8 = ord[0].Deliver_To_Address_3__c;
                OrderReq.P_ATTRIBUTE7 = ord[0].Deliver_To_Address_4__c;
                OrderReq.P_ATTRIBUTE9 = ord[0].Deliver_To_Contact__c;
                
                if(ord[0].Account.Customer_Account_Type__c == 'Cash' || OrderReq.P_SOLD_TO_ORG_ID.right(4) == '0000')
                {
                    OrderReq.P_ATTRIBUTE13 = ord[0].Bill_To_Cash_Customer__c ;
                    OrderReq.P_ATTRIBUTE14 = ord[0].Bill_To_Address_1__c;
                    OrderReq.P_ATTRIBUTE15 = ord[0].Bill_To_Address_2__c;
                    OrderReq.P_ATTRIBUTE4 = ord[0].Bill_To_Address_3__c ;
                    OrderReq.P_ATTRIBUTE5 = ord[0].Bill_To_Address_4__c;
                    
                    if(ord[0].Account.ERP_Id__c == null && ord[0].Account.Parent.ERP_Id__c != null)
                        OrderReq.P_SOLD_TO_ORG_ID = ord[0].Account.Parent.ERP_Id__c;
                    else OrderReq.P_SOLD_TO_ORG_ID = ord[0].Account.ERP_Id__c;
                }
                else
                    OrderReq.P_SOLD_TO_ORG_ID = ord[0].Account.ERP_Id__c;
            }
            
            return OrderReq;
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            ORDS_Log__c log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            system.debug(log);
            system.debug(log.Response__c);
            insert log;
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    public static List<ORDSAPI.OrderItemData> setOrderItemRequest(Id recordId)
    {
        try{
            Map<Id,String> productInventoryIdMap = new Map<Id,String>();
            Map<String,Product2> product2Map = new Map<String,Product2>();
            Set<Id> productIdSet = new Set<Id>();
            Set<String> productCodeSet = new Set<String>();
            List<ORDSAPI.OrderItemData> OrderItemsReq = new List<ORDSAPI.OrderItemData>();
            List<Inventory__c> Inventories;
            ORDSAPI.OrderItemData OrderItemReq;
            String wareHouseCode ;
            List<OpportunityLineItem> oppItems;
            List<OrderItem> orderItems;
            List<Parent_Product__c> oppItemsCoupled;
            
            String recordId_txt = String.valueOf(recordId);
            if(recordId_txt.left(3) == '006')
            {
                if(oppRecordTypeName == 'Customised_Engineering_Solution')
                {
                    system.debug('CoupledProduct');
                    oppItemsCoupled = [SELECT Id, Enquiry__c, Description__c, Cost_Price__c, Margin__c, Discount__c, Unit_Price__c, Quantity__c, Code__c, Enquiry__r.Delivery_Date_Formula__c,
                                       Additional_Description_Line_1__c, Additional_Description_Line_2__c, Additional_Description_Line_3__c, Additional_Description_Line_4__c, 
                                       Additional_Description_Para_1__c, Additional_Description_Para_2__c, Additional_Description_Para_3__c, Enquiry__r.Warehouse__r.code__c,Uom__c
                                       FROM Parent_Product__c WHERE Enquiry__c =: recordId Order By Id];
                    system.debug(oppItemsCoupled);
                }
                else
                {
                    system.debug('OpportunityLineItem');
                    oppItems =  [SELECT Id, Name, OpportunityId, Opportunity.AccountId, PricebookEntryId, Product2Id, Quantity, UnitPrice, ListPrice,List_Price__c ,
                                 Opportunity.Warehouse__r.Code__c,Product2.Uom__c,Opportunity.Delivery_Date_Formula__c ,Uom__c,
                                 Additional_Description_Line_1__c , Additional_Description_Line_2__c , Additional_Description_Line_3__c , Additional_Description_Line_4__c,
                                 Additional_Description_Para_1__c,Additional_Description_Para_2__c,Additional_Description_Para_3__c
                                 FROM OpportunityLineItem WHERE OpportunityId =: recordId Order By Id];
                }
            }
            else if(recordId_txt.left(3) == '801')
            {
                system.debug('OrderItem');
                orderItems =  [SELECT Id, OrderId, Order.AccountId, PricebookEntryId, Product2Id, Quantity, UnitPrice, ListPrice,List_Price__c ,
                               Order.Warehouse__r.Code__c,Product2.Uom__c,Order.Delivery_Date_Formula__c,Uom__c,
                               Additional_Description_Line_1__c , Additional_Description_Line_2__c , Additional_Description_Line_3__c , Additional_Description_Line_4__c,
                               Additional_Description_Para_1__c,Additional_Description_Para_2__c,Additional_Description_Para_3__c
                               FROM OrderItem WHERE OrderId =: recordId Order By Id];
            }
            
            
            if(recordId_txt.left(3) == '006')
            {  
                if((oppRecordTypeName == 'Customised_Engineering_Solution') && !oppItemsCoupled.isEmpty())
                {
                    for(Parent_Product__c oItem1 : oppItemsCoupled)
                        productCodeSet.add(oItem1.Code__c);
                    
                    if(!productCodeSet.isEmpty())
                    {
                        for(Product2 pro : [SELECT Id, ProductCode, Uom__c FROM Product2 WHERE ProductCode IN: productCodeSet])
                        {
                            product2Map.put(pro.ProductCode, pro);
                        }
                        system.debug('product2Map '+product2Map);
                    }
                    
                    
                    Integer itemNo = 1;
                    for(Parent_Product__c oItem : oppItemsCoupled)
                    {
                        OrderItemReq = new ORDSAPI.OrderItemData();
                        OrderItemReq.P_ORIG_SYS_DOCUMENT_REF = oItem.Enquiry__c;
                        OrderItemReq.P_ORIG_SYS_LINE_REF = oItem.Enquiry__c+String.valueOf(itemNo);
                        OrderItemReq.P_LINE_NUMBER = String.valueOf(itemNo);
                        //if(productInventoryIdMap.containsKey(oItem.Product2Id)) OrderItemReq.P_INVENTORY_ITEM_ID = productInventoryIdMap.get(oItem.Product2Id);
                        OrderItemReq.P_PROMISE_DATE = oItem.Enquiry__r.Delivery_Date_Formula__c;
                        OrderItemReq.P_ORDERED_QUANTITY = String.valueOf(oItem.Quantity__c);
                        OrderItemReq.P_ORDER_QUANTITY_UOM = oItem.Uom__c;
                        //if(product2Map.containsKey(oItem.code__c)) OrderItemReq.P_ORDER_QUANTITY_UOM = product2Map.get(oItem.code__c).Uom__c;
                        OrderItemReq.P_SHIP_FROM_ORG_ID = oItem.Enquiry__r.Warehouse__r.code__c;
                        //OrderItemReq.P_UNIT_LIST_PRICE = String.valueOf(oItem.ListPrice__c);
                        OrderItemReq.P_UNIT_LIST_PRICE = '0';
                        OrderItemReq.P_UNIT_SELLING_PRICE = String.valueOf(oItem.Unit_Price__c);
                        OrderItemReq.P_ATTRIBUTE15 = oItem.Additional_Description_Line_1__c;
                        OrderItemReq.P_ATTRIBUTE14 = oItem.Additional_Description_Line_2__c;
                        OrderItemReq.P_ATTRIBUTE13 = oItem.Additional_Description_Line_3__c;
                        OrderItemReq.P_ATTRIBUTE12 = oItem.Additional_Description_Line_4__c;
                        OrderItemReq.P_ATTRIBUTE11 = oItem.Additional_Description_Para_1__c;
                        OrderItemReq.P_ATTRIBUTE10 = oItem.Additional_Description_Para_2__c;
                        OrderItemReq.P_ATTRIBUTE9 = oItem.Additional_Description_Para_3__c;
                        system.debug('OppItemReq '+OrderItemReq);
                        OrderItemsReq.add(OrderItemReq);
                        itemNo = itemNo+1;
                    }
                    
                }
                else if((oppRecordTypeName != 'Customised_Engineering_Solution') && !oppItems.isEmpty())
                {
                    wareHouseCode = oppItems[0].Opportunity.Warehouse__r.Code__c;
                    for(OpportunityLineItem oItem1 : oppItems)
                        productIdSet.add(oItem1.Product2Id);
                    
                    if(!productIdSet.isEmpty())
                    {
                        for(Inventory__c Inven : [SELECT Id, Product__c, Warehouse__r.code__c, Inventory_Item_ID__c, Quantity_Remaining__c, Serial_Number__c 
                                                  FROM Inventory__c WHERE Warehouse__r.code__c =: wareHouseCode AND Product__c IN: productIdSet])
                        {
                            productInventoryIdMap.put(Inven.Product__c, Inven.Inventory_Item_ID__c);
                        }
                        system.debug('productInventoryIdMap '+productInventoryIdMap);
                    }
                    
                    Integer itemNo = 1;
                    for(OpportunityLineItem oItem : oppItems)
                    {
                        OrderItemReq = new ORDSAPI.OrderItemData();
                        OrderItemReq.P_ORIG_SYS_DOCUMENT_REF = oItem.OpportunityId;
                        OrderItemReq.P_ORIG_SYS_LINE_REF = oItem.OpportunityId+String.valueOf(itemNo);
                        OrderItemReq.P_LINE_NUMBER = String.valueOf(itemNo);
                        if(productInventoryIdMap.containsKey(oItem.Product2Id))  OrderItemReq.P_INVENTORY_ITEM_ID = productInventoryIdMap.get(oItem.Product2Id);
                        OrderItemReq.P_PROMISE_DATE = oItem.Opportunity.Delivery_Date_Formula__c;
                        OrderItemReq.P_ORDERED_QUANTITY = String.valueOf(oItem.Quantity);
                        OrderItemReq.P_ORDER_QUANTITY_UOM = oItem.Uom__c;
                        OrderItemReq.P_SHIP_FROM_ORG_ID = oItem.Opportunity.Warehouse__r.code__c;
                        OrderItemReq.P_UNIT_LIST_PRICE = String.valueOf(oItem.List_Price__c);
                        system.debug('P_UNIT_LIST_PRICE '+OrderItemReq.P_UNIT_LIST_PRICE);
                        OrderItemReq.P_UNIT_SELLING_PRICE = String.valueOf(oItem.UnitPrice);
                        OrderItemReq.P_ATTRIBUTE15 = oItem.Additional_Description_Line_1__c;
                        OrderItemReq.P_ATTRIBUTE14 = oItem.Additional_Description_Line_2__c;
                        OrderItemReq.P_ATTRIBUTE13 = oItem.Additional_Description_Line_3__c;
                        OrderItemReq.P_ATTRIBUTE12 = oItem.Additional_Description_Line_4__c;
                        OrderItemReq.P_ATTRIBUTE11 = oItem.Additional_Description_Para_1__c;
                        OrderItemReq.P_ATTRIBUTE10 = oItem.Additional_Description_Para_2__c;
                        OrderItemReq.P_ATTRIBUTE9 = oItem.Additional_Description_Para_3__c;
                        system.debug('OppItemReq '+OrderItemReq);
                        OrderItemsReq.add(OrderItemReq);
                        itemNo = itemNo+1;
                    }
                    
                }
                
                
            }
            else if(recordId_txt.left(3) == '801' && !orderItems.isEmpty())
            {
                wareHouseCode = orderItems[0].Order.Warehouse__r.Code__c;
                for(OrderItem oItem1 : orderItems)
                    productIdSet.add(oItem1.Product2Id);
                
                if(!productIdSet.isEmpty())
                {
                    for(Inventory__c Inven : [SELECT Id, Product__c, Warehouse__r.code__c, Inventory_Item_ID__c, Quantity_Remaining__c, Serial_Number__c 
                                              FROM Inventory__c WHERE Warehouse__r.code__c =: wareHouseCode AND Product__c IN: productIdSet])
                    {
                        productInventoryIdMap.put(Inven.Product__c, Inven.Inventory_Item_ID__c);
                    }
                    system.debug('productInventoryIdMap '+productInventoryIdMap);
                }
                
                Integer itemNo = 1;
                for(OrderItem oItem : orderItems)
                {
                    OrderItemReq = new ORDSAPI.OrderItemData();
                    OrderItemReq.P_ORIG_SYS_DOCUMENT_REF = oItem.OrderId;
                    OrderItemReq.P_ORIG_SYS_LINE_REF = oItem.OrderId+String.valueOf(itemNo);
                    OrderItemReq.P_LINE_NUMBER = String.valueOf(itemNo);
                    if(productInventoryIdMap.containsKey(oItem.Product2Id))  OrderItemReq.P_INVENTORY_ITEM_ID = productInventoryIdMap.get(oItem.Product2Id);
                    OrderItemReq.P_PROMISE_DATE = oItem.Order.Delivery_Date_Formula__c;
                    OrderItemReq.P_ORDERED_QUANTITY = String.valueOf(oItem.Quantity);
                    OrderItemReq.P_ORDER_QUANTITY_UOM = oItem.Uom__c;
                    OrderItemReq.P_SHIP_FROM_ORG_ID = oItem.Order.Warehouse__r.code__c;
                    OrderItemReq.P_UNIT_LIST_PRICE = String.valueOf(oItem.List_Price__c);
                        system.debug('P_UNIT_LIST_PRICE '+OrderItemReq.P_UNIT_LIST_PRICE);
                    OrderItemReq.P_UNIT_SELLING_PRICE = String.valueOf(oItem.UnitPrice);
                    OrderItemReq.P_ATTRIBUTE15 = oItem.Additional_Description_Line_1__c;
                    OrderItemReq.P_ATTRIBUTE14 = oItem.Additional_Description_Line_2__c;
                    OrderItemReq.P_ATTRIBUTE13 = oItem.Additional_Description_Line_3__c;
                    OrderItemReq.P_ATTRIBUTE12 = oItem.Additional_Description_Line_4__c;
                    OrderItemReq.P_ATTRIBUTE11 = oItem.Additional_Description_Para_1__c;
                    OrderItemReq.P_ATTRIBUTE10 = oItem.Additional_Description_Para_2__c;
                    OrderItemReq.P_ATTRIBUTE9 = oItem.Additional_Description_Para_3__c;
                    system.debug('OrderItemReq '+OrderItemReq);
                    OrderItemsReq.add(OrderItemReq);
                    itemNo = itemNo+1;
                }
                
            }
            
            return OrderItemsReq;
            
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            ORDS_Log__c log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            system.debug(log);
            system.debug(log.Response__c);
            insert log;
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
}