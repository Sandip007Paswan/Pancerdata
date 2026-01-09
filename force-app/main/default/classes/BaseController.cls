public with sharing class BaseController {
    
    @AuraEnabled
    public static List<sObject> query(String q)
    {
        return Database.query(q);
    }
    
    @AuraEnabled
    public static List<sObject> searchInventory(List<sObject> items, String wareHouseCode)
    {
        Map<Id,Decimal> productInventoryIdMap = new Map<Id,Decimal>();
        Set<Id> productIdSet = new Set<Id>();
        List<Inventory__c> Inventories;
        List<SObject> castRecords;
        if(!items.isEmpty())
        {
            system.debug('items '+items);
            Schema.SObjectType sObjectType = items[0].getSObjectType();
            String listType = 'List<' + sObjectType + '>';
            system.debug('listType '+listType);
            castRecords = (List<SObject>)Type.forName(listType).newInstance();
            castRecords.addAll(items);
            
            for(SObject oItem1 : castRecords)
                productIdSet.add((String) oItem1.get('Product2Id'));
            
            system.debug('productIdSet '+productIdSet);
            
            if(!productIdSet.isEmpty())
            {
                for(Inventory__c Inven : [SELECT Id, Product__c, Warehouse__r.code__c, Inventory_Item_ID__c, Quantity_Remaining__c, Serial_Number__c 
                                          FROM Inventory__c WHERE Warehouse__r.code__c =: wareHouseCode AND Product__c IN: productIdSet])
                {
                    productInventoryIdMap.put(Inven.Product__c, Inven.Quantity_Remaining__c);
                }
                system.debug('productInventoryIdMap '+productInventoryIdMap);
                
                for(SObject oItem : castRecords)
                { 
                    if(productInventoryIdMap.containsKey((String)oItem.get('Product2Id')))
                        oItem.put('Quantity_Remaining__c', productInventoryIdMap.get((String)oItem.get('Product2Id')));
                    
                }
                
                system.debug('castRecords '+castRecords);
            }
        }
        
        return castRecords;
    }
    
    @AuraEnabled
    public static Decimal searchInventoryProductChanged(Id productId, String wareHouseCode)
    {
        Decimal Qty_Remain = 0;
        system.debug('wareHouseCode '+wareHouseCode);
        system.debug('productId '+productId);
        
        List<Inventory__c> Inven = [SELECT Id, Product__c, Warehouse__r.code__c, Inventory_Item_ID__c, Quantity_Remaining__c, Serial_Number__c 
                                    FROM Inventory__c WHERE Warehouse__r.code__c =: wareHouseCode AND Product__c =: productId Limit 1];
        
        if(Inven.size() > 0) Qty_Remain = Inven[0].Quantity_Remaining__c;
        
        system.debug('Qty_Remain '+Qty_Remain);
        
        return Qty_Remain;
    }
    
    @AuraEnabled
    public static List<LookupSearchResult> search(String q, String sObjectType, String iconName, String title, String subtitle, List<String> selectedIds)
    {
        Set<Id> proIds = new Set<Id>();
        List<sObject> newPansarPros = new List<sObject>();
        List<LookupSearchResult> searchResults = new List<LookupSearchResult>();
        List<sObject> results = Database.query(q);
        
        if(!results.isEmpty())
        {
            for(sObject pro : results)
                proIds.add((String)pro.get('Product__c'));
            
            system.debug('proIds : '+proIds);
            
            for(Id proId : proIds)
            {
                for(sObject pro : results)
                {
                    if(proId == (String)pro.get('Product__c'))
                    {
                        newPansarPros.add(pro);
                        break;
                    }
                }
            }
            system.debug('newPansarPros : '+newPansarPros);
        }
        
        system.debug('query Search '+q);
        Id pId;
        
        for (sObject result : newPansarPros) 
        {
            if(sObjectType == 'Inventory__c') pId = (Id)result.get('Product__c');
            else if(sObjectType == 'Product2') pId = result.id;
            searchResults.add(
                new LookupSearchResult(
                    pId,
                    sObjectType,
                    iconName,
                    (String)result.get(title),
                    (String)result.get(subtitle)
                )
            );
        }        
        return searchResults;
    }
    
    /*@AuraEnabled
public static Map<Id,List<String>> getPickListValues11(List<sObject> items, String wareHouseCode)
{
Map<Id,List<String>> productUOMMap = new Map<Id,List<String>>();
Set<Id> productIdSet = new Set<Id>();
List<SObject> castRecords;
if(!items.isEmpty())
{
//system.debug('items '+items);
Schema.SObjectType sObjectType = items[0].getSObjectType();
system.debug('sObjectType '+sObjectType);
String listType = 'List<' + sObjectType + '>';
//system.debug('listType '+listType);
castRecords = (List<SObject>)Type.forName(listType).newInstance();
castRecords.addAll(items);
system.debug('castRecords '+castRecords);

system.debug('wareHouseCode '+wareHouseCode);

for(SObject oItem1 : castRecords)
productIdSet.add((String) oItem1.get('Product2Id'));

system.debug('productIdSet '+productIdSet);

if(!productIdSet.isEmpty())
{
for(Pansar_Product__c item : [SELECT Id, Name, UOM__c, Product__c , Warehouse__c FROM Pansar_Product__c
WHERE Warehouse__r.code__c =: wareHouseCode AND Product__c IN: productIdSet])
{
if(!productUOMMap.containsKey(item.Product__c)){
productUOMMap.put(item.Product__c, new List<String>{item.UOM__c});
}
else{
productUOMMap.get(item.Product__c).add(item.UOM__c);
}  
}
system.debug('productUOMMap '+productUOMMap);
}
}

return productUOMMap;
}*/
    
    @AuraEnabled
    public static Map<Id,List<UomClass>> getPickListValues(Id recordId, String wareHouseCode)
    {
        system.debug('recordId '+recordId);
        Map<Id,List<UomClass>> productUOMMap = new Map<Id,List<UomClass>>();
        Set<Id> productIdSet = new Set<Id>();
        List<SObject> castRecords;
        String query ;
        String recordId_txt = String.valueOf(recordId);
        if(recordId_txt.left(3) == '006')
            query = 'SELECT Id, Opportunity.Warehouse__r.code__c , Product2Id FROM OpportunityLineItem where OpportunityId =\'' + recordId+'\'';
        else if(recordId_txt.left(3) == '801')
            query = 'SELECT Id, Order.Warehouse__r.code__c , Product2Id FROM OrderItem where OrderId =\'' + recordId+'\'';
        List<sObject> items = database.query(query);
        
        if(!items.isEmpty())
        {
            system.debug('wareHouseCode '+wareHouseCode);
            
            for(sObject oItem1 : items)
                productIdSet.add((String)oItem1.get('Product2Id'));
            
            system.debug('productIdSet '+productIdSet);
            UomClass uomC ;
            
            if(!productIdSet.isEmpty())
            {
                for(Pansar_Product__c item : [SELECT Id, Name, UOM__c, Product__c , Warehouse__c FROM Pansar_Product__c
                                              WHERE Warehouse__r.code__c =: wareHouseCode AND Product__c IN: productIdSet])
                {
                    uomC = new UomClass();
                    uomC.label = item.UOM__c;
                    uomC.value = item.UOM__c;
                    
                    if(!productUOMMap.containsKey(item.Product__c)){
                        productUOMMap.put(item.Product__c, new List<UomClass>{uomC});
                    }
                    else{
                        productUOMMap.get(item.Product__c).add(uomC);
                    }  
                }
                
                system.debug('productUOMMap '+productUOMMap);
            }
        }
        
        return productUOMMap;
    }
    
    @AuraEnabled
    public static Map<Id,List<UomClass>> testgetPickListValues1(Id productId, String wareHouseCode, Date createdDate)
    {
        Map<Id,List<UomClass>> productUOMMap = new Map<Id,List<UomClass>>();
        List<SObject> castRecords;
        
        system.debug('productId '+productId);
        UomClass uomC ;
        
        if(productId != null )
        {
            for(Pansar_Product__c item : [SELECT Id, Name, UOM__c, Product__c , Warehouse__c FROM Pansar_Product__c
                                          WHERE Warehouse__r.code__c =: wareHouseCode 
                                          AND Product__c =: productId 
                                          AND (UOM_Active_End_Date__c >=: createdDate OR UOM_Active_End_Date__c = null)])
            {
                uomC = new UomClass();
                uomC.label = item.UOM__c;
                uomC.value = item.UOM__c;
                
                if(!productUOMMap.containsKey(item.Product__c)){
                    productUOMMap.put(item.Product__c, new List<UomClass>{uomC});
                }
                else{
                    productUOMMap.get(item.Product__c).add(uomC);
                }  
            }
            
            system.debug('productUOMMap '+productUOMMap);
        }
        
        return productUOMMap;
    }
    
    @AuraEnabled
    public static void saveAndDelete(List<sObject> lineItems, List<sObject> deleteLineItems, String orderId, List<NewProductClass> newProducts)
    {
        //Map<Id,String> productCostPriceMap = new Map<Id,String>();
        //Set<Product2> prosSet = new Set<Product2>();
        //List<Product2> prosList = new List<Product2>();
        List<sObject> templineItems = new List<sObject>();
        List<sObject> tempnewLineItems = new List<sObject>();
        List<Product2> product2Insert = new List<Product2>();
        List<String> proCodes = new List<String>();
        List<sObject> oppProduct = new List<sObject>();
        List<PricebookEntry> pbs = new List<PricebookEntry>();
        Id pricebookId ;
        if (!Test.isRunningTest()) pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].Id;
        else pricebookId = Test.getStandardPricebookId();
        
        if(!newProducts.isEmpty()){
            for (NewProductClass temp : newProducts)
            {
                product2Insert.add(temp.newProduct);
                proCodes.add(temp.newProduct.ProductCode);
                oppProduct.add(temp.oppProduct);
            }
            system.debug('product2Insert '+product2Insert);
            system.debug('oppProduct '+oppProduct);
            system.debug('proCodes '+proCodes);
            
            List<Product2> dupPro2 = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN: proCodes];
            if(!dupPro2.isEmpty())
            {
				system.debug('dupPro2 '+dupPro2);
                String codeString;
                String[] tmp1 = New String[]{};
                for(Product2 p : dupPro2)
                    tmp1.add(p.ProductCode);
                codeString = string.join(tmp1,',');
                system.debug('codeString '+codeString);
                String errorMsg = 'Cannot save new product entry because the product code '+codeString+' already exists.';
                throw new AuraHandledException(errorMsg);                
            }
            else
                upsert product2Insert;
            
        }
        
        //List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();     
        for (NewProductClass temp : newProducts)
        {  
            PricebookEntry pbe = new PricebookEntry();
            pbe.Pricebook2Id = pricebookId;
            pbe.Product2Id = temp.newProduct.Id;
            pbe.UnitPrice = 0;
            pbe.IsActive = True;
            pbe.ERP_Id__c = temp.newProduct.ProductCode;
            
            temp.oppProduct.put('Product2Id', temp.newProduct.Id);
            templineItems.add(temp.oppProduct);
            pbs.add(pbe);
            
        }
        system.debug('pbs '+pbs);
        upsert pbs;
        
        for (sObject temp : templineItems)
        { 
            for (PricebookEntry pb : pbs)
            { 
                if(pb.Product2Id == (String)temp.get('Product2Id'))
                {
                    temp.put('PricebookEntryId', pb.Id);
                }
            }
        }
        
        system.debug('templineItems '+templineItems);
        //upsert oppLineItems; 
        
        
        if(!lineItems.isEmpty()){
            for(sObject temp : lineItems)
            {
                if(temp != null)
                {
                    templineItems.add(temp);
                    system.debug(temp);
                    system.debug(temp.get('UnitPrice'));
                }
            }
        }
        
        try{
            //Schema.SObjectType sObjectType = temps[0].getSObjectType();
            Order order;
            if(deleteLineItems != null && !deleteLineItems.isEmpty()) delete deleteLineItems;
            if(templineItems != null && !templineItems.isEmpty()) upsert templineItems;   
            
            if(orderId != null)
            { 
                update order = new Order(Id = orderId, Updated_OrderItem__c = true);
                system.debug('Updated_OrderItem__c '+order);
            }
        }
        catch (Exception e) 
        {
            System.debug(e.getMessage());
            ORDS_Log__c log = new ORDS_Log__c();
            log.Request__c = 'Add Product';
            log.Response__c = e.getStackTraceString() + '\n' + e.getMessage();
            log.Error__c = TRUE;
            insert log;
            throw new AuraHandledException(e.getMessage());
            
        }
    }
    
    public class UomClass
    {
        @AuraEnabled
        public String label { get; set; }        
        @AuraEnabled
        public String value { get; set; }
    }
    
    public class NewProductClass
    {
        @AuraEnabled
        public Product2 newProduct { get; set; }        
        @AuraEnabled
        public sObject oppProduct { get; set; }
    }
    
    
}