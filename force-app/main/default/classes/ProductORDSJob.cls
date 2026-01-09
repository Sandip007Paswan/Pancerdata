public without sharing class ProductORDSJob implements Queueable, Database.AllowsCallouts
{
    ORDS_Path__c  cus = ORDS_Path__c.getValues('ProductORDSJob');
    public String offset = cus.Offset__c;
    //public String offset = 'materials';
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
                Id pricebookId ;
                ORDSAPI.ResponseProductData result = (ORDSAPI.ResponseProductData) JSON.deserialize(resBody, ORDSAPI.ResponseProductData.class);
                System.debug(result);     
                if (!Test.isRunningTest()) pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].Id;
                else pricebookId = Test.getStandardPricebookId();
                Id recordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Pansar_Products').getRecordTypeId();
                Map<String,ORDSAPI.ProductData> productMap = new Map<String,ORDSAPI.ProductData>();
                Map<String,ORDSAPI.ProductData> inventoryMap = new Map<String,ORDSAPI.ProductData>();
                List<Id> productUpsertId = new List<Id>();
                List<String> warehouseCode = new List<String>();
                List<PricebookEntry> pbes = new List<PricebookEntry>();
                Map<String,Id> warehouseIdMap = new Map<String,Id>();
                Map<String,Id> productIdMap = new Map<String,Id>();
                List<Inventory__c> invens = new List<Inventory__c>();
                List<Product2> products = new List<Product2>();
                List<Product2> genericProducts = new List<Product2>();
                List<Pansar_Product__c> panPros = new List<Pansar_Product__c>();
                List<ORDS_Log__c> logs = new List<ORDS_Log__c>();
                
                System.debug('result.items : '+result.items.size());
                
                for (ORDSAPI.ProductData item : result.items)
                {
                    if(!productMap.containsKey(item.inventory_item_id))
                        productMap.put(item.inventory_item_id, item);
                    
                    String inven_ERPID = item.product_warehouse_id+item.inventory_item_id;
                    //String inven_ERPID = item.product_warehouse_id+item.inventory_item_id+item.product_code;
                    if(!inventoryMap.containsKey(inven_ERPID))
                        inventoryMap.put(inven_ERPID, item);
                    
                    warehouseCode.add(item.product_warehouse_id);
                }
                System.debug('productMap size : '+productMap.size());
                System.debug('productMap : '+productMap);
                //System.debug('inventoryMap : '+inventoryMap.size());
                
                for (ORDSAPI.ProductData item : productMap.values ())
                {
                    Product2 product = new Product2();
                    product.Name = item.product_description;
                    product.Description = item.product_description;
                    product.ProductCode = item.product_code;
                    product.UOM__c = item.product_uom;
                    product.RecordTypeId = recordTypeId;
                    product.IsActive = true;
                    product.ERP_Id__c = item.inventory_item_id;
                    //product.ERP_Id__c = item.product_code;
                    product.Family = item.product_category;
                    product.Division__c = item.product_catgories_division;
                    product.IsActive = Boolean.valueOf(item.product_header_status);
                    
                    if(item.product_sf_record_id == null) // True Product from Oracle
                        products.add(product);
                    else
                    {
                        product.Id = item.product_sf_record_id;
                        product.New_Product__c = false;
                        //product.Generic_Product__c = false;
                        system.debug('Update product_sf_record_id : '+item.product_sf_record_id);
                        genericProducts.add(product); // Generic Product from SF
                    }
                    //warehouseCode.add(item.product_warehouse_id);
                    
                }
                
                Schema.SObjectField ftoken = Product2.Fields.ERP_Id__c;
                List<Database.upsertResult> uResults = Database.upsert(products,ftoken,false);
                for (Database.UpsertResult sr : uResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful
                        productUpsertId.add(sr.getId());
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
                if(!logs.isEmpty()) insert logs;
                
                List<Database.SaveResult> updateResults = Database.update(genericProducts,false);
                for (Database.SaveResult sr : updateResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful
                        productUpsertId.add(sr.getId());
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
                
                System.debug('productUpsertId size '+productUpsertId.size());
                                
                if(!warehouseCode.isEmpty())   
                {
                    for(Warehouse__c  ware : [SELECT Id, Name, Code__c FROM Warehouse__c WHERE Code__c IN: warehouseCode])
                    {
                        if(!warehouseIdMap.containsKey(ware.Code__c))
                            warehouseIdMap.put(ware.Code__c, ware.id);
                    }
                    System.debug('warehouseIdMap size '+warehouseIdMap.size());
                    System.debug('warehouseIdMap  '+warehouseIdMap);
                }
                
                if(!productUpsertId.isEmpty())   
                {
                    for(Product2 pro2 : [SELECT Id, Name, ProductCode, Description, IsActive, Cost_Price__c, UOM__c, ERP_Id__c FROM Product2 WHERE Id IN: productUpsertId])
                    {
                        PricebookEntry pbe = new PricebookEntry();
                        pbe.Pricebook2Id = pricebookId;
                        pbe.Product2Id = pro2.Id;
                        pbe.UnitPrice = Decimal.valueOf(productMap.get(pro2.ERP_Id__c).product_list_price);
                        pbe.IsActive = True;
                        pbe.ERP_Id__c = pro2.ERP_Id__c;
                        pbe.Cost_Price__c = Decimal.valueOf(productMap.get(pro2.ERP_Id__c).product_cost_price).setScale(2, RoundingMode.HALF_UP);
                        pbe.Maximum_End_User_Discount__c = Decimal.valueOf(productMap.get(pro2.ERP_Id__c).product_end_user_max_discount);
                        pbe.Dealer_List_Price__c = Decimal.valueOf(productMap.get(pro2.ERP_Id__c).product_dealer_list_price);
                        pbe.Dealer_Price_Discount__c = Decimal.valueOf(productMap.get(pro2.ERP_Id__c).product_dealer_discount);
                        pbe.Max_Dealer_Price_Discount__c = Decimal.valueOf(productMap.get(pro2.ERP_Id__c).product_dealer_max_discount);
                        pbe.UOM__c = productMap.get(pro2.ERP_Id__c).product_pricing_uom;
                        pbes.add(pbe);
                        System.debug('pbe '+ pbe);
                        productIdMap.put(pro2.ERP_Id__c, pro2.Id);
                        
                    }
                    System.debug('pbes size'+ pbes.size());
                    //System.debug('pbes '+ pbes);
  
                    for (ORDSAPI.ProductData item : inventoryMap.values())
                    {
                        Inventory__c inven = new Inventory__c();
                        if(item.product_warehouse_id != null && item.inventory_item_id != null){
                            if(warehouseIdMap.containsKey(item.product_warehouse_id)) inven.Warehouse__c = warehouseIdMap.get(item.product_warehouse_id);
                            inven.Inventory_Item_ID__c = item.inventory_item_id;
                            if(productIdMap.containsKey(item.inventory_item_id)) inven.Product__c = productIdMap.get(item.inventory_item_id);
                            inven.ERP_Id__c = item.product_warehouse_id+item.inventory_item_id;
                            //inven.ERP_Id__c = item.product_warehouse_id+item.inventory_item_id+item.product_code;
                            inven.Inventory_Status__c = item.product_status;
                            invens.add(inven);
                        }
                    }
                    //System.debug('invens '+invens.size());
                    
                    for (ORDSAPI.ProductData item : result.items)
                    {
                        Date Start_Date = null;
                        Date End_Date = null;
                        
                        if(item.product_list_price_eff_date_fr != null)
                        {
                            DateTime Start_DateTime = DateTime.valueOfGMT(item.product_list_price_eff_date_fr.replace('T', ' '));
                            Start_Date = Start_DateTime.date();
                        }
                        
                        if(item.product_list_price_eff_date_to != null)
                        {
                            DateTime End_DateTime = DateTime.valueOfGMT(item.product_list_price_eff_date_to.replace('T', ' '));
                            End_Date = End_DateTime.date();
                        }
                        
                        Product2 proRef = new Product2(ERP_Id__c = item.inventory_item_id);
                        Pansar_Product__c panPro = new Pansar_Product__c();
                        panPro.Product__r = proRef;
                        panPro.List_Price__c = Decimal.valueOf(item.product_list_price);
                        panPro.Active__c = True;
                        panPro.Price_Book__c = pricebookId;
                        panPro.ERP_Id__c = item.product_warehouse_id+item.product_pricing_uom+item.inventory_item_id;
                        panPro.Cost_Price__c = Decimal.valueOf(item.product_cost_price).setScale(2, RoundingMode.HALF_UP);
                        panPro.Maximum_End_User_Discount__c = Decimal.valueOf(item.product_end_user_max_discount);
                        panPro.Dealer_List_Price__c = Decimal.valueOf(item.product_dealer_list_price);
                        panPro.Dealer_Price_Discount__c = Decimal.valueOf(item.product_dealer_discount);
                        panPro.Max_Dealer_Price_Discount__c = Decimal.valueOf(item.product_dealer_max_discount);
                        panPro.UOM__c = item.product_pricing_uom;
                        panPro.Product_Code__c = item.product_code;
                        panPro.UOM_Active_Start_Date__c = Start_Date;
                        panPro.UOM_Active_End_Date__c = End_Date;
                        if(warehouseIdMap.containsKey(item.product_warehouse_id)) panPro.Warehouse__c = warehouseIdMap.get(item.product_warehouse_id);
                        panPros.add(panPro);
                    }

                    System.debug('panPros '+panPros.size());
   
                }
                
                List<Parent_Product__c> newCoupleProduts = new List<Parent_Product__c>();
                try
                {
                    if(!pbes.isEmpty()) upsert pbes ERP_Id__c;
                    for(Parent_Product__c newC : [SELECT Id, New_Product__c, Code__c FROM Parent_Product__c WHERE New_Product__c = true AND Code__c IN: productIdMap.keyset()])
                    {    
                        System.debug('newC '+newC);
                        newC.New_Product__c = false;
                        newCoupleProduts.add(newC);
                    }
                    if(!newCoupleProduts.isEmpty()) update newCoupleProduts;
                    //if(!invens.isEmpty()) upsert invens ERP_Id__c;
                    //if(!panPros.isEmpty()) upsert panPros ERP_Id__c;
                }
                catch(Exception e){
                    System.debug(e.getMessage());
                    insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
                }
                
                if(!invens.isEmpty()){
                    Schema.SObjectField ftoken_invens = Inventory__c.Fields.ERP_Id__c;
                    List<Database.upsertResult> uResults_invens = Database.upsert(invens,ftoken_invens,false);
                    for (Database.UpsertResult sr : uResults_invens) {
                        if (sr.isSuccess()) {
                            // Operation was successful
                            //productcreatedId.add(sr.getId());
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
                }
                
                if(!panPros.isEmpty()){
                    Schema.SObjectField ftoken_invens = Pansar_Product__c.Fields.ERP_Id__c;
                    List<Database.upsertResult> uResults_panPros = Database.upsert(panPros,ftoken_invens,false);
                    for (Database.UpsertResult sr : uResults_panPros) {
                        if (sr.isSuccess()) {
                            // Operation was successful
                            //productcreatedId.add(sr.getId());
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
                }
                                
                if (result.hasMore == true)
                {
                    List<ORDSAPI.LinkData> links = result.links;
                    for (ORDSAPI.LinkData link : links)
                    {
                        if (link.rel.equalsIgnoreCase('next'))
                        {
                            ProductORDSJob thisJob = new ProductORDSJob();
                            String href = link.href;
                            system.debug('link.href '+link.href);
                            href = href.substring(href.lastIndexOf('/')+1);
                            system.debug('href '+href);
                            thisJob.offset = href;
                            System.enqueueJob(thisJob);
                        }
                    }
                }
                else JobScheduler.finishJob('ProductORDSJob');    
            }
            else
            {
                if(response.getStatusCode() != 0) insert log = new ORDS_Log__c(Request__c = path, Response__c = response.getStatusCode() + response.getStatus(), Error__c = TRUE);
                JobScheduler.finishJob('ProductORDSJob');    
            }
        } 
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            insert log = new ORDS_Log__c(Request__c = path, Response__c = e.getStackTraceString() + '\n' + e.getMessage(), Error__c = TRUE);
            JobScheduler.finishJob('ProductORDSJob'); 
        }
    }
}