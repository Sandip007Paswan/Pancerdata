public without sharing class CsvController {
    
    public static Boolean isNumeric(String s){
        Boolean ReturnValue;
        try{
            Decimal.valueOf(s);
            ReturnValue = TRUE; 
        } catch (Exception e) {
            ReturnValue = FALSE;
        }
        return ReturnValue;
    }

    @AuraEnabled
    public static list<OpportunityLineItem> readCSVFile(Id idContentDocument, Id recordId){
        list<OpportunityLineItem> lstItemToInsert = new list<OpportunityLineItem>();
        Map<String, Id> productIdMap = new Map<String, Id>();
        Map<String, List<String>> productToInsertMap = new Map<String, List<String>>();
        Map<String, List<String>> productCodeRowtMap = new Map<String, List<String>>();
        List<String> productCodeSet = new List<String>();
        List<String> productCodeToInsert = new List<String>();
        list<String> lstCSVLines  = new List<String>();
        List<List<String>> lines = new List<List<String>>();
        List<OpportunityLineItem> items;
        System.debug('recordId====> '+recordId);
        Id recordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Pansar_Products').getRecordTypeId();
        CsvReader reader;
        list<String> header;
        Id pricebookId ;
        if (!Test.isRunningTest()) pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].Id;
        else pricebookId = Test.getStandardPricebookId();
        
        if(idContentDocument != null) {
            
            // getting File Data based on document id 
            ContentVersion objVersion = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId =:idContentDocument];
            // split the file data
            lstCSVLines = objVersion.VersionData.toString().split('\n');
            //system.debug('Original lstCSVLines '+lstCSVLines);
            //reader = new CsvReader(objVersion.VersionData.toString());
            //system.debug('reader '+reader);
            Map<String, Integer> fieldIndexMap = new Map<String, Integer>();
            Integer readerSize = 0;
                 
            reader = new CsvReader(objVersion.VersionData.toString());
            header = reader.readLine();
            for (Integer i=1; i<1000; i++)
            {
                list<String> csvRowData = reader.readLine();
                if(csvRowData != null && csvRowData[1].trim() != ''){
                    system.debug('csvRowData '+csvRowData);
                    productCodeSet.add(csvRowData[1].trim());
                    if(!productCodeRowtMap.containsKey(csvRowData[1].trim())){
                        productCodeRowtMap.put(csvRowData[1].trim(), new list<String>(csvRowData));
                    }
                    readerSize = readerSize+1;
                }
                else break;
            }
            system.debug('productCodeSet '+productCodeSet);
            system.debug('readerSize '+readerSize);
            system.debug('productCodeRowtMap '+productCodeRowtMap);
            
            
            if(!productCodeSet.isEmpty()){
                for(String key : productCodeRowtMap.keySet())
                {
                    system.debug('key '+key);
                    Boolean found  = false; 
                    for(PricebookEntry  pb : [SELECT Product2Id, Product2.ProductCode, Product2.Name, Product2.Cost_Price__c ,Product2.Description, UnitPrice 
                                              FROM PricebookEntry where Product2.ProductCode IN: productCodeSet])
                    {
                        if(!productIdMap.containsKey(pb.Product2.ProductCode)){
                            productIdMap.put(pb.Product2.ProductCode, pb.Product2Id);
                        }
                        
                        system.debug('pb.Product2.ProductCode '+ pb.Product2.ProductCode);
                        if(pb.Product2.ProductCode == key) found  = true; 
                    }
                    
                    if(found == false)
                    {
                        system.debug('ProductCode Not found '+ key);
                        if(!productToInsertMap.containsKey(key)){
                            productToInsertMap.put(key, new list<String>(productCodeRowtMap.get(key)));
                        }   
                    }  
                }
            }
            system.debug('productToInsertMap '+productToInsertMap);
            system.debug('productIdMap '+productIdMap);
            
            reader = new CsvReader(objVersion.VersionData.toString());
            header = reader.readLine();
            for (Integer i=1; i<1000; i++)
            {
                list<String> csvRowData = reader.readLine();
                if(csvRowData != null && csvRowData[1].trim() != '')
                { 
                    OpportunityLineItem objItem = new OpportunityLineItem();
                    System.debug('csvRowData 0====> '+csvRowData[0]); // Product Name
                    System.debug('csvRowData 1====> '+csvRowData[1]); // Product Code
                    System.debug('csvRowData 2====> '+csvRowData[2]); // Quantity
                    System.debug('csvRowData 3====> '+csvRowData[3]); // UnitPrice
                    System.debug('csvRowData 4====> '+csvRowData[4]); // S/S
                    System.debug('csvRowData 5====> '+csvRowData[5]); // Parts No S/S
                    System.debug('csvRowData 6====> '+csvRowData[6]); // Parts Name
                    System.debug('csvRowData 7====> '+csvRowData[7]); // Sold in Packs
                    objItem.OpportunityId = recordId;
                    
                    if(csvRowData[0].trim() != null && csvRowData[0].trim() != ''){
                    }
                    else
                        throw new AuraHandledException('Product Name Line '+i+' : '+csvRowData[0]+ ' cannot be empty.');
                    
                    if(csvRowData[1].trim() != null && csvRowData[1].trim() != ''){
                        if(productIdMap.containsKey(csvRowData[1].trim()))
                            objItem.Product2Id = productIdMap.get(csvRowData[1].trim());
                        else if(productToInsertMap.containsKey(csvRowData[1].trim())) ///////////// Create Not valid product
                        {
                            Product2 product = new Product2();
                            product.Name = csvRowData[0].trim();
                            product.Description = csvRowData[0].trim();
                            product.ProductCode = csvRowData[1].trim();
                            product.UOM__c = 'EA';
                            product.RecordTypeId = recordTypeId;
                            product.IsActive = True;
                            product.New_Product__c = true;
                            product.ERP_Id__c = product.ProductCode;
                            insert product;
                            
                            PricebookEntry pbe = new PricebookEntry();
                            pbe.Pricebook2Id = pricebookId;
                            pbe.Product2Id = product.id;
                            pbe.UnitPrice = 0;
                            pbe.IsActive = True;
                            pbe.ERP_Id__c = product.ProductCode;
                            insert pbe;
                            
                            objItem.Product2Id = product.Id;
                        }
                        ///////////////////////////////////////////////////////////////////////

                        /*else 
                            throw new AuraHandledException('Product Code Line '+i+' : '+csvRowData[1]+ ' cannot be found.');*/
                    }
                    else
                        throw new AuraHandledException('Product Code Line '+i+' : '+csvRowData[1]+ ' cannot be empty.');
                    
                    
                    if(csvRowData[2].trim() != null && csvRowData[2].trim() != ''){
                        Boolean isValid = isNumeric(csvRowData[2].trim());
                        if(isValid == true) 
                            objItem.Quantity = Decimal.valueOf(csvRowData[2].trim());
                        else 
                            throw new AuraHandledException('Quantity Line '+i+' : '+csvRowData[1]+ ' is not Numeric.');
                    }
                    else
                        throw new AuraHandledException('Quantity Line '+i+' : '+csvRowData[1]+ ' cannot be empty.');
                    
                    
                    if(csvRowData[3].trim() != null && csvRowData[3].trim() != ''){
                        Boolean isValid = isNumeric(csvRowData[3].trim());
                        if(isValid == true) 
                            objItem.UnitPrice = Decimal.valueOf(csvRowData[3].trim());
                        else 
                            throw new AuraHandledException('UnitPrice Line '+i+' : '+csvRowData[3]+ ' is not Numeric.');
                    }
                    else
                        throw new AuraHandledException('UnitPrice Line '+i+' : '+csvRowData[3]+ ' cannot be empty.');
                    
                    objItem.S_S__c = Boolean.valueOf(csvRowData[4].trim());
                    objItem.Parts_No_S_S__c = csvRowData[5].trim();
                    objItem.Parts_Name_S_S__c = csvRowData[6].trim();
                    objItem.Sold_In_Packs__c = Boolean.valueOf(csvRowData[7].trim());
                    objItem.Delivery__c = csvRowData[8].trim();
                    lstItemToInsert.add(objItem);
                }
                else break; 
            }
        
            /*for(Integer i = 1; i < lstCSVLines.size(); i++){
                OpportunityLineItem objItem = new OpportunityLineItem();
                list<String> csvRowData = lstCSVLines[i].split(',');
                System.debug('csvRowData 0====> '+csvRowData[0]); // Product Name
                System.debug('csvRowData 1====> '+csvRowData[1]); // Product Code
                System.debug('csvRowData 2====> '+csvRowData[2]); // Quantity
                System.debug('csvRowData 3====> '+csvRowData[3]); // UnitPrice
                System.debug('csvRowData 4====> '+csvRowData[4]); // S/S
                System.debug('csvRowData 5====> '+csvRowData[5]); // Parts No S/S
                System.debug('csvRowData 6====> '+csvRowData[6]); // Parts Name
                System.debug('csvRowData 7====> '+csvRowData[7]); // Sold in Packs
                objItem.OpportunityId = recordId;
                
                if(csvRowData[0].trim() != null && csvRowData[0].trim() != ''){
                }
                else
                    throw new AuraHandledException('Product Name Line '+i+' : '+csvRowData[0]+ ' cannot be empty.');
                
                
                if(csvRowData[1].trim() != null && csvRowData[1].trim() != ''){
                if(productIdMap.containsKey(csvRowData[1].trim()))
                    objItem.Product2Id = productIdMap.get(csvRowData[1].trim());
                else 
                    throw new AuraHandledException('Product Code Line '+i+' : '+csvRowData[1]+ ' cannot be found.');
                }
                else
                    throw new AuraHandledException('Product Code Line '+i+' : '+csvRowData[1]+ ' cannot be empty.');
                
                
                if(csvRowData[2].trim() != null && csvRowData[2].trim() != ''){
                    Boolean isValid = isNumeric(csvRowData[2].trim());
                    if(isValid == true) 
                        objItem.Quantity = Decimal.valueOf(csvRowData[2].trim());
                    else 
                        throw new AuraHandledException('Quantity Line '+i+' : '+csvRowData[1]+ ' is not Numeric.');
                }
                else
                    throw new AuraHandledException('Quantity Line '+i+' : '+csvRowData[1]+ ' cannot be empty.');
                
                
                if(csvRowData[3].trim() != null && csvRowData[3].trim() != ''){
                    Boolean isValid = isNumeric(csvRowData[3].trim());
                    if(isValid == true) 
                        objItem.UnitPrice = Decimal.valueOf(csvRowData[3].trim());
                    else 
                        throw new AuraHandledException('UnitPrice Line '+i+' : '+csvRowData[3]+ ' is not Numeric.');
                }
                else
                    throw new AuraHandledException('UnitPrice Line '+i+' : '+csvRowData[3]+ ' cannot be empty.');
                
                objItem.S_S__c = Boolean.valueOf(csvRowData[4].trim());
                objItem.Parts_No_S_S__c = csvRowData[5].trim();
                objItem.Parts_Name_S_S__c = csvRowData[6].trim();
                objItem.Sold_In_Packs__c = Boolean.valueOf(csvRowData[7].trim());
                objItem.Delivery__c = csvRowData[8].trim();
                lstItemToInsert.add(objItem);
            }*/
            system.debug('lstItemToInsert '+lstItemToInsert);

            try{    
                if(!lstItemToInsert.isEmpty()) {
                    insert lstItemToInsert;
                    items = [SELECT Id, Name, Description2__c, Product2.Name, Quantity,UnitPrice,ProductCode,
                             S_S__c,Parts_No_S_S__c,Parts_Name_S_S__c,Sold_In_Packs__c,TotalPrice,Delivery__c
                             FROM OpportunityLineItem WHERE Id IN : lstItemToInsert];
                    
                }
            }
            catch (Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }
        return items;    
    }
}