public without sharing class QuoteTemplateController 
{
    public Quote quote { get; set; }    
    public List<QuoteLineItem> products { get; set; }

    public QuoteTemplateController(ApexPages.StandardController controller) 
    {
        quote = (Quote) controller.getRecord();
        products = [SELECT Id, Item_No__c, Product2.ProductCode, Product2.Name, UOM__c, Quantity_Formula__c, UnitPrice, Total_Price2__c,
                    UOM_M_I__c ,Description_Quote_MI__c, TotalPrice,Description_Quote__c,Parts_Name_S_S__c,Parts_No_S_S__c,Sold_in_Packs__c,Delivery__c,
                    Additional_Description_Line_1__c, Additional_Description_Line_2__c, Additional_Description_Line_3__c, Additional_Description_Line_4__c,
                    Additional_Description_Para_1__c,Additional_Description_Para_2__c,Additional_Description_Para_3__c
                    FROM QuoteLineItem WHERE QuoteId =:quote.Id order by Item_No__c];
    }
}