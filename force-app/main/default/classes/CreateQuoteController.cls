public without sharing class CreateQuoteController 
{
	@AuraEnabled
    public static QuoteWrapper validateQuote(Id oppId)
    {
        Opportunity opp = [SELECT Account.Name,
        Bill_To_Address__c,
        Bill_To_Address__r.Street__c, 
        Bill_To_Address__r.City__c, 
        Bill_To_Address__r.State__c, 
        Bill_To_Address__r.Postal_Code__c,
        Bill_To_Address__r.Country__c,    
        Quotation_Approved__c, StageName, RecordType.DeveloperName, Sold_To_Contact_ID__c FROM Opportunity WHERE Id = :oppId];
        if (!opp.RecordType.DeveloperName.equalsIgnoreCase('Spare_Parts_Order') && (opp.Quotation_Approved__c == FALSE || !opp.StageName.equalsIgnoreCase('Quotation')))
        {
            throw new AuraHandledException('Please submit pricing for approval before Create Quote.');
        }
        else if (opp.RecordType.DeveloperName.equalsIgnoreCase('Spare_Parts_Order') && !opp.StageName.equalsIgnoreCase('Quotation'))
        {
            throw new AuraHandledException('Please move to Quotation stage before Create Quote.');
        }
        List<Quote> quotes = [SELECT Id FROM Quote WHERE OpportunityId = :opp.Id];
        QuoteWrapper quoteWrapper = new quoteWrapper();        
        quoteWrapper.opp = opp;
        if(!quotes.isEmpty())
        {            
            quoteWrapper.quoteId = quotes.get(0).Id;            
        }        
        return quoteWrapper;
    }   

	@AuraEnabled
    public static void createQuote(Id oppId, Quote qt)
    {
        Opportunity opp = [SELECT Id, Account.Name, Quotation_Approved__c, StageName, RecordType.DeveloperName FROM Opportunity WHERE Id = :oppId];
        if (!opp.RecordType.DeveloperName.equalsIgnoreCase('Spare_Parts_Order') && (opp.Quotation_Approved__c == FALSE || !opp.StageName.equalsIgnoreCase('Quotation')))
        {
            throw new AuraHandledException('Please submit pricing for approval before Create Quote.');
        }
        else if (opp.RecordType.DeveloperName.equalsIgnoreCase('Spare_Parts_Order') && !opp.StageName.equalsIgnoreCase('Quotation'))
        {
            throw new AuraHandledException('Please move to Quotation stage before Create Quote.');
        }

        Quote quote = new Quote();        
        
        //Get existing quote and update it instead of creating new quote to use the Quote PDF versioning feature.
        List<Quote> quotes = [SELECT Id,Quote_Version__c FROM Quote WHERE OpportunityId = :opp.Id];
        List<QuoteLineItem> quoteLines = new List<QuoteLineItem>();
        
        try{
        if(!quotes.isEmpty())
        {
            quote = quotes.get(0);
            //Delete existing quotes
            quoteLines = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quote.Id];   
            delete quoteLines;         
        }
        else {
            quote.Name = 'Quote for '+opp.Account.Name;
            quote.OpportunityId = opp.Id;
            quote.Quote_Version__c = 0;
            insert quote;
        }
        quote.ContactId = qt.ContactId;
        //quote.ExpirationDate = qt.ExpirationDate;
        quote.Customer_Ref_No__c  = qt.Customer_Ref_No__c;
        quote.Contact_Name__c  = qt.Contact_Name__c;
        quote.Phone  = qt.Phone;
        quote.Fax  = qt.Fax;
        quote.BillingStreet = qt.BillingStreet;
        quote.BillingCity = qt.BillingCity;
        quote.BillingState = qt.BillingState;
        quote.BillingPostalCode = qt.BillingPostalCode;
        quote.BillingCountry = qt.BillingCountry;
        /*quote.ShippingStreet = qt.ShippingStreet;
        quote.ShippingCity = qt.ShippingCity;
        quote.ShippingState = qt.ShippingState;
        quote.ShippingPostalCode = qt.ShippingPostalCode;
        quote.ShippingCountry = qt.ShippingCountry;*/
        quote.Price_Validity__c = qt.Price_Validity__c;
        quote.Price_Validity_Other__c = qt.Price_Validity_Other__c ;
        quote.Delivery2__c = qt.Delivery2__c;
        quote.Delivery_Other__c = qt.Delivery_Other__c;
        quote.Payment_Method__c  = qt.Payment_Method__c;
        quote.Payment_Method_Other__c  = qt.Payment_Method_Other__c ;
        quote.Warranty_Period__c = qt.Warranty_Period__c;
        quote.Warranty_Period_Other__c  = qt.Warranty_Period_Other__c ;
        quote.Description = qt.Description;
        quote.Quote_Version__c = quote.Quote_Version__c+1;
        //quote.Payment_Terms_Days__c = qt.Payment_Terms_Days__c;
        update quote;

        if (!opp.RecordType.DeveloperName.equalsIgnoreCase('Customised_Engineering_Solution'))
        {        
            List<OpportunityLineItem> olis = [SELECT Id, Item_No__c, Description,Discount,PricebookEntryId,Product2Id,Quantity,UnitPrice,
                                              Additional_Description_Line_1__c, Additional_Description_Line_2__c, Additional_Description_Line_3__c, Additional_Description_Line_4__c,
                                              Additional_Description_Para_1__c,Additional_Description_Para_2__c,Additional_Description_Para_3__c,
                                              Delivery__c, Description2__c,List_Price__c, Parts_Name_S_S__c, Parts_No_S_S__c, S_S__c, Sold_In_Packs__c, Total_List_Price__c, Total_Price_Discount__c,UOM__c
                                              FROM OpportunityLineItem WHERE OpportunityId = :opp.Id Order by Product2.Name ASC];                
            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            system.debug('olis '+olis);
            for (OpportunityLineItem oli : olis)
            {
                system.debug('oli.Id '+oli.Id);
                QuoteLineItem qli = new QuoteLineItem();
                qli.QuoteId = quote.Id;
                qli.Description = oli.Description;
                qli.Discount = oli.Discount;
                qli.OpportunityLineItemId = oli.Id;
                qli.PricebookEntryId = oli.PricebookEntryId;
                qli.Product2Id = oli.Product2Id;
                qli.Quantity = oli.Quantity;
                qli.UnitPrice = oli.UnitPrice;
                qli.Item_No__c = oli.Item_No__c;
                qli.Additional_Description_Line_1__c = oli.Additional_Description_Line_1__c;
                qli.Additional_Description_Line_2__c = oli.Additional_Description_Line_2__c;
                qli.Additional_Description_Line_3__c = oli.Additional_Description_Line_3__c;
                qli.Additional_Description_Line_4__c = oli.Additional_Description_Line_4__c;
                qli.Additional_Description_Para_1__c = oli.Additional_Description_Para_1__c;
                qli.Additional_Description_Para_2__c = oli.Additional_Description_Para_2__c;
                qli.Additional_Description_Para_3__c = oli.Additional_Description_Para_3__c;
                
                qli.Delivery__c = oli.Delivery__c;
                qli.Description__c = oli.Description2__c;
                qli.List_Price__c = oli.List_Price__c;
                qli.Parts_Name_S_S__c = oli.Parts_Name_S_S__c;
                qli.Parts_No_S_S__c = oli.Parts_No_S_S__c;
                qli.S_S__c = oli.S_S__c;
                qli.Sold_in_Packs__c = oli.Sold_in_Packs__c;
                qli.Total_List_Price__c = oli.Total_List_Price__c;
                qli.Total_Price2__c = oli.Total_Price_Discount__c;
                qli.UOM__c = oli.UOM__c;

                qlis.add(qli);
                system.debug('qli.OpportunityLineItemId '+qli.OpportunityLineItemId );
            }
            insert qlis;
        }
        else 
        {
            List<Parent_Product__c> parentProducts = [SELECT Name, Quantity__c, Unit_Price__c, Cost_Price__c, Description__c, Discount__c, Margin__c,
                                                      Additional_Description_Line_1__c, Additional_Description_Line_2__c, Additional_Description_Line_3__c, Additional_Description_Line_4__c,
                                                      Additional_Description_Para_1__c,Additional_Description_Para_2__c,Additional_Description_Para_3__c
                                                      FROM Parent_Product__c WHERE Enquiry__c = :opp.Id Order by Name];
            PricebookEntry pbe = [SELECT Product2Id FROM PricebookEntry WHERE Product2.Name = 'Coupled Parent'];
            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            for (Parent_Product__c parentProduct : parentProducts)
            {
                QuoteLineItem qli = new QuoteLineItem();
                qli.QuoteId = quote.Id;
                qli.Description = parentProduct.Description__c;
                qli.Discount = parentProduct.Discount__c;                
                qli.PricebookEntryId = pbe.Id;
                qli.Product2Id = pbe.Product2Id;
                qli.Quantity = parentProduct.Quantity__c;
                qli.UnitPrice = parentProduct.Unit_Price__c;
                qli.Parent_Product__c = parentProduct.Id;
                qli.Additional_Description_Line_1__c = parentProduct.Additional_Description_Line_1__c;
                qli.Additional_Description_Line_2__c = parentProduct.Additional_Description_Line_2__c;
                qli.Additional_Description_Line_3__c = parentProduct.Additional_Description_Line_3__c;
                qli.Additional_Description_Line_4__c = parentProduct.Additional_Description_Line_4__c;
                qli.Additional_Description_Para_1__c = parentProduct.Additional_Description_Para_1__c;
                qli.Additional_Description_Para_2__c = parentProduct.Additional_Description_Para_2__c;
                qli.Additional_Description_Para_3__c = parentProduct.Additional_Description_Para_3__c;
                qlis.add(qli);
            }
            insert qlis; 
        }
      
        insertQuoteTemplate(quote.Id, opp.Id, opp.RecordType.DeveloperName);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<LookupSearchResult> search(String q, String sObjectType, String iconName, String title, String subtitle, List<String> selectedIds)
    {
        Set<Id> proIds = new Set<Id>();
        List<sObject> newPansarPros = new List<sObject>();
        List<LookupSearchResult> searchResults = new List<LookupSearchResult>();
        system.debug('query '+q);
        List<sObject> results = Database.query(q);
        
        if(!results.isEmpty()){
            Schema.SObjectType qObjType = results[0].getSObjectType();
            system.debug('qObjType '+qObjType);
            
            system.debug('query Search '+q);
            Id pId;

            for (sObject result : results) 
            {
                if(String.valueOf(qObjType) == 'Contact') pId = result.id; else pId = (String)result.get('Sold_To_Contact_ID__c');
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
        }
            return searchResults;
        
    }
    
    @future(callout=true)
    public static void insertQuoteTemplate(Id recordId, Id oppId, String recordTypeName) {
        
        try{
            PageReference pdf = Page.StandardQuoteTemplate;
            pdf.getParameters().put('id', recordId);
            pdf.getParameters().put('attachPDF','true');
            Blob body;        
            try 
            {
                if(!test.isRunningTest())
                    body = pdf.getContentAsPDF(); 
                else
                    body = blob.valueof('TEST');
            }
            catch (VisualforceException e) 
            {
                body = Blob.valueOf('Exception Hit!');
                system.debug(e.getMessage());
            }
            
            QuoteDocument qd = new QuoteDocument();
            qd.Document = body;
            qd.QuoteId = recordId;
            insert qd;
            
            Id quoteConVerDocumentId = [SELECT Id, QuoteId, ContentVersionDocumentId, Document FROM QuoteDocument WHERE Id =: qd.Id].ContentVersionDocumentId;
            ContentDocumentLink oppFile = new ContentDocumentLink();
            oppFile.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: quoteConVerDocumentId].ContentDocumentId;
            oppFile.ShareType = 'V';
            oppFile.Visibility = 'AllUsers';
            oppFile.LinkedEntityId = oppId;
            insert oppFile;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        
    } 
    
    @InvocableMethod(label='Generate Quote PDF' description='Generates Quote PDF asynchronously givem Quote Id' category='Quote')
    public static void getAccountNames(List<ID> ids) 
    {
        for (Id quoteId : ids)
        {
	        insertQuoteTemplate(quoteId, null, null);   
        }        	
    }
            
    public class QuoteWrapper
    {
        @AuraEnabled
        public Id quoteId { get ; set; }
        @AuraEnabled
        public Opportunity opp { get; set; }
    }
}