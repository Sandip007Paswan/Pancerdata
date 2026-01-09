public without sharing class ORDSAPI 
{
    public static final string SF_NAMED_CREDENTIAL = 'callout:ORDS';

    //Call service endpoint for retrieving or posting data
    //Returns JSON response body
    public static HttpResponse sendRequest(String path, String action, String request)
    {
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        try{
            
            req.setEndpoint(SF_NAMED_CREDENTIAL + path);
            System.debug('SF_NAMED_CREDENTIAL + path : '+SF_NAMED_CREDENTIAL + path);
            req.setMethod(action);
            req.setTimeout(120000);
            if (action.equalsIgnoreCase('POST'))
            {
                req.setBody(request);
                req.setHeader('Content-Type', 'application/json');
            }
            Http http = new Http();
            res = http.send(req);
            System.debug(res.getStatusCode());
            System.debug(res.getStatus());
            //System.debug(res.getbody());
        }
        catch (CalloutException e) {
            System.debug('CalloutException : '+e.getMessage());
            ORDS_Log__c log = new ORDS_Log__c(Request__c = path, Response__c = e.getMessage(), Error__c = TRUE);
            insert log;
        }
        System.debug(res);
        
    return res;
}      

    //Deserialize response data
    /*public static ResponseData deserializeData(String jsonString)
    {
        ResponseData result = (ResponseData) JSON.deserialize(jsonString, ResponseData.class);
        return result;
    }*/

    public class ResponseAccountData
    {
        public List<AccountData> items { get; set; }
        public Boolean hasMore { get; set; }
        /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/     
        public List<LinkData> links { get; set; }
    }

    public class AccountData
    {
        public String customer_name { get; set; }
        public String customer_email { get; set; }
        public String customer_phone { get; set; }
        public String customer_category { get; set; }
        public String customer_description { get; set; }
        public String customer_account_id { get; set; }
        public String customer_account_number { get; set; }
        public String customer_location { get; set; }
        public String customer_payment_term { get; set; }
        public String customer_credit_status { get; set; }
        public String customer_current_month { get; set; }
        public String amount_30 { get; set; }
        public String amount_60 { get; set; }
        public String amount_90 { get; set; }
        public String amount_120 { get; set; }
        public String amount_180 { get; set; }
        public String amount_360 { get; set; }
        public String collector { get; set; }
        public String customer_sf_record_id { get; set; }
        
    }
    
    
     public class ResponseContactData
    {
        public List<ContactData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/          
        public List<LinkData> links { get; set; }
    }

    public class ContactData
    {
        public String contact_first_name { get; set; }
        public String contact_middle_name { get; set; }
        public String contact_last_name { get; set; }
        public String org_contact_id { get; set; }
        public String contact_job_title { get; set; }
        public String contact_email { get; set; }
        public String contact_fax_number { get; set; }
        public String contact_phone_number { get; set; }
        public String contact_mobile_number { get; set; }
        public String cust_account_id { get; set; }
    }
    
    public class ResponseAccCategoryData
    {
        public List<AccCategoryData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/          
        public List<LinkData> links { get; set; }
    }
    
    public class AccCategoryData
    {
        public String customer_id { get; set; }
        public String division_code { get; set; }
        public String customer_category { get; set; }
    }
    
    
    public class ResponseAddressData
    {
        public List<AddressData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/          
        public List<LinkData> links { get; set; }
    }
    
    public class AddressData
    {
        public String location { get; set; }
        //public String customer_name { get; set; }
        //public String registry_id { get; set; }
        public String site_use_id { get; set; }
        public String address_line_1 { get; set; }
        public String address_line_2 { get; set; }
        public String address_line_3 { get; set; }
        public String address_line_4 { get; set; }
        //public String address_line_5 { get; set; }
        public String customer_id { get; set; }
        //public String customer_number { get; set; }
        public String site_use_code { get; set; }
        public String bill_to_flag { get; set; }
        public String ship_to_flag { get; set; }
    }
    
    public class ResponseProductData
    {
        public List<ProductData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/       
        public List<LinkData> links { get; set; }
    }
    
     public class ProductData
    {
        public String product_warehouse_id { get; set; }
        public String inventory_item_id { get; set; }
        public String product_code { get; set; }
        public String product_description { get; set; }
        public String product_uom { get; set; }
        public String product_pricing_uom { get; set; }
        public String product_category { get; set; }
        //public String product_currency { get; set; }
        public String product_list_price { get; set; }
        public String product_end_user_max_discount { get; set; }
        public String product_dealer_list_price { get; set; }
        public String product_dealer_discount { get; set; }
        public String product_dealer_max_discount { get; set; }
        public String product_cost_price { get; set; }
        public String product_catgories_division { get; set; }
        public String product_sf_record_id { get; set; }
        public String product_status { get; set; }
   		public String product_list_price_eff_date_fr { get; set; }
        public String product_list_price_eff_date_to { get; set; }
        public String product_header_status { get; set; }
    }
    
    public class ResponseInventoryData
    {
        public List<InventoryData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/         
        public List<LinkData> links { get; set; }
    }
    
    public class InventoryData
    {
        public String inventory_warehouse_name { get; set; }
        public String inventory_warehouse_id { get; set; }
        public String inventory_item_id { get; set; }
        public String product_code { get; set; }
        public String inventory_available_quantity { get; set; }
    }
    
    public class ResponseOrderGetData
    {
        public List<OrderGetData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/         
        public List<LinkData> links { get; set; }
    }
    
    public class OrderGetData
    {
        public String order_erp_id { get; set; }
        public String order_type_id { get; set; }
        public String order_erp_number_id { get; set; }
        public String order_sf_enquiry_id { get; set; }
        public String order_date { get; set; }
        public String order_sold_to_erp_id { get; set; }
        public String order_ship_to_erp_id { get; set; }
        public String order_bill_to_erp_id { get; set; }
        public String order_owner_erp_id { get; set; }
        public String order_currency_code { get; set; }
        public String order_payment_term { get; set; }
        public String order_warehouse_id { get; set; }
        public String order_shipping_method { get; set; }
        public String order_status { get; set; }
        public String order_sf_enq_number { get; set; }
        public String order_cust_po_number { get; set; }
        public String order_sold_to_contact_id { get; set; }
        
        public String order_deliver_to_address1 { get; set; }
        public String order_deliver_to_address2 { get; set; }
        public String order_deliver_to_address3 { get; set; }
        public String order_deliver_to_address4 { get; set; }
        public String order_deliver_to_contact{ get; set; }
        
        public String order_bill_to_address1 { get; set; }
        public String order_bill_to_address2 { get; set; }
        public String order_bill_to_address3 { get; set; }
        public String order_bill_to_address4 { get; set; }
        public String order_bill_cash_customer{ get; set; }
        
        public String order_price_list_type{ get; set; }
        public String order_fob_point_code{ get; set; }
        
        
    }
    
    public class ResponseOrderItemGetData
    {
        public List<OrderItemGetData> items { get; set; }
        public Boolean hasMore { get; set; }
         /*public Integer reclimit { get; set; }
        public Integer offset { get; set; }
        public Integer count { get; set; }*/       
        public List<LinkData> links { get; set; }
    }
    
    public class OrderItemGetData
    {
        public String order_line_erp_id { get; set; }
        public String order_erp_id { get; set; }
        public String order_line_product_code { get; set; }
        public String order_line_item_no { get; set; }
        public String order_line_quantity { get; set; }
        public String order_line_uom { get; set; }
        public String order_line_cost_price { get; set; }
        public String order_line_list_price { get; set; }
        public String order_line_unit_price { get; set; }
        public String order_line_unit_discount { get; set; }
        public String order_line_additional_desc_1 { get; set; }
        
        public String order_line_add_desc_line1 { get; set; }
        public String order_line_add_desc_line2 { get; set; }
        public String order_line_add_desc_line3 { get; set; }
        public String order_line_add_desc_line4 { get; set; }
        public String order_line_add_desc_para1 { get; set; }
        public String order_line_add_desc_para2 { get; set; }
        public String order_line_add_desc_para3 { get; set; }
        
        public String order_line_status { get; set; } 
    }
    

    public class LinkData
    {
        public String rel { get; set; }
        public String href { get; set; }
    }
    
    public class OrderData
    {
        //public String P_ORDER_SOURCE_ID { get; set; }
        public String P_ORIG_SYS_DOCUMENT_REF { get; set; }
        //public String P_ORG_ID { get; set; }
        //public String P_ORDERED_DATE { get; set; }
        public String P_ORDER_TYPE_ID { get; set; }
        public String P_PRICE_LIST_ID { get; set; }
        public String P_TRANSACTIONAL_CURR_CODE { get; set; }
        public String P_SALESREP_ID { get; set; }
        public String P_CO_SALESREP_ID { get; set; }
        public String P_SO_TO_CON_ID { get; set; }
        public String P_PAYMENT_TERM_ID { get; set; }
        public String P_SHIPPING_METHOD_CODE { get; set; }
        public String P_CUSTOMER_PO_NUMBER { get; set; }
        public String P_FOB_CODE_V1 { get; set; }
        public String P_SOLD_TO_ORG_ID { get; set; }
        public String P_SHIP_FROM_ORG_ID { get; set; }
        public String P_SHIP_TO_ORG_ID { get; set; }
        public String P_INVOICE_TO_ORG_ID { get; set; }
        public String P_SA_CHANNEL_CODE { get; set; }
        public String P_ATTRIBUTE3 { get; set; } //Territory Code
        public String P_ATTRIBUTE4 { get; set; }//Bill To Address 4 ( Street)
        public String P_ATTRIBUTE5 { get; set; }//Bill To Address 3 (City)
        public String P_ATTRIBUTE6 { get; set; }//Workshop Note  (Free text up to 15 characters)
        public String P_ATTRIBUTE7 { get; set; }//Deliver To Address 4 (Country)
        public String P_ATTRIBUTE8 { get; set; }//Deliver To Address 3 (State & Postal Code) Split by ,
        public String P_ATTRIBUTE9 { get; set; }//Deliver To Contact (Ship To Address Name)
        public String P_ATTRIBUTE10 { get; set; }//Deliver To Address 2 (City)
        public String P_ATTRIBUTE11 { get; set; }//Deliver To Address 1 (Street)
        public String P_ATTRIBUTE12 { get; set; }
        public String P_ATTRIBUTE13 { get; set; }//Bill To Cash Customer (Bill To Address Name)
        public String P_ATTRIBUTE14 { get; set; }//Bill To Address 1 (State and Postal Code) Split by ,
        public String P_ATTRIBUTE15 { get; set; }//Bill To Address 2 (Country)     
        
    }
    
    public class OrderItemData
    {
        //public String P_ORDER_SOURCE_ID { get; set; }
        public String P_ORIG_SYS_DOCUMENT_REF { get; set; }
        public String P_ORIG_SYS_LINE_REF { get; set; }
        //public String P_ORG_ID { get; set; }
        public String P_LINE_NUMBER { get; set; }
        public String P_INVENTORY_ITEM_ID { get; set; }
        public String P_PROMISE_DATE { get; set; }
        public String P_ORDERED_QUANTITY { get; set; }
        public String P_ORDER_QUANTITY_UOM { get; set; }
        public String P_SHIP_FROM_ORG_ID { get; set; }
        public String P_UNIT_LIST_PRICE { get; set; }
        public String P_UNIT_SELLING_PRICE { get; set; }
        public String P_ATTRIBUTE15 { get; set; }
        public String P_ATTRIBUTE14 { get; set; }
        public String P_ATTRIBUTE13 { get; set; }
        public String P_ATTRIBUTE12 { get; set; }
        public String P_ATTRIBUTE11 { get; set; }
        public String P_ATTRIBUTE10 { get; set; }
        public String P_ATTRIBUTE9 { get; set; }
    }
    
    public class ResponseOrder
    {
        public String REQUEST_ID { get; set; }
    }
}