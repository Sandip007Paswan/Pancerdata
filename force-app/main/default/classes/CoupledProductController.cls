/** 
 * Custom component controller for M&I (Customized Engineering Solution) Opportunities
 * Each Opportunity Line Item is grouped/coupled via a custom object - Parent_Product__c
 * 
 * @author manu.voramontri@kliqxe.com
 * @since 07.10.2020
 */
public with sharing class CoupledProductController 
{
    /**
     * Insert/Update/Delete coupled products.
     * Handle error in lwc.
     */
    @AuraEnabled
    public static void saveCoupledProducts(List<CoupledProduct> coupledProducts, List<sObject> parentProductsToDelete, List<sObject> oppLineItemsToDelete)
    {
        //--Parent Products
        List<Parent_Product__c> parentProducts = new List<Parent_Product__c>();        
        for (CoupledProduct coupledProduct : coupledProducts)
        {
            parentProducts.add(coupledProduct.parentProduct);            
        }
        system.debug('parentProducts '+parentProducts);
        upsert parentProducts;
        delete parentProductsToDelete;
        //--

        //Opp Line Items
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();     
        for (CoupledProduct coupledProduct : coupledProducts)
        {
            for (OpportunityProduct oppProduct : coupledProduct.oppProducts)
            {                
                oppProduct.oppLineItem.Parent_Product__c = coupledProduct.parentProduct.Id;    
                oppLineItems.add(oppProduct.oppLineItem);                
            }
        }
        upsert oppLineItems;        
        delete oppLineItemsToDelete;
        //--
    }

    /**
     * Query coupled products on load of LWC.
     * Wrap it in custom class     
     */    
    @AuraEnabled
    public static List<CoupledProduct> getCoupledProducts(Id oppId)
    {
        List<Parent_Product__c> parentProducts = [SELECT Name, Quantity__c, Unit_Price__c, Cost_Price__c, Description__c, Discount__c, Margin__c, Enquiry__c, Code__c,UOM__c,
            (SELECT Id, Name, Description2__c, Product2.Name, Product2.ProductCode, Product2.Description, Product2Id,
            Product2.UOM__c, Product2.M_I_Configuration__c, Cost_Price__c, Amount_In_Supplier_Currency__c, 
            Quantity, Selling_Factor__c, Margin__c, UnitPrice, ListPrice, TotalPrice, Discount, OpportunityId, UOM__c,Total_Price_Discount__c,List_Price__c
            FROM Opportunity_Product__r ORDER BY CreatedDate ASC ) 
            FROM Parent_Product__c WHERE Enquiry__c = :oppId ORDER BY CreatedDate ASC];
        List<CoupledProduct> coupledProducts = new List<CoupledProduct>();
        for (Parent_Product__c parentProduct : parentProducts)
        {
            CoupledProduct coupledProduct = new CoupledProduct();
            coupledProduct.parentProduct = parentProduct;            
            coupledProduct.oppProducts = new List<OpportunityProduct>();
            for (OpportunityLineItem oppLineItem : parentProduct.Opportunity_Product__r)
            {
                OpportunityProduct oppProduct = new OpportunityProduct();
                oppProduct.oppLineItem = oppLineItem;                
                coupledProduct.oppProducts.add(oppProduct);
            }
            coupledProducts.add(coupledProduct);
        }
        return coupledProducts;
    }

    public class CoupledProduct
    {
        @AuraEnabled
        public Parent_Product__c parentProduct { get; set; }        
        @AuraEnabled
        public List<OpportunityProduct> oppProducts { get; set; }
    }

    public class OpportunityProduct
    {
        @AuraEnabled
        public OpportunityLineItem oppLineItem { get; set; }        
    }    
}