({
	doInit : function(component, event, helper) 
    {
        console.log('doInit');
        var recordId = component.get("v.recordId");
        console.log('recordId: ' + recordId);
        component.set("v.showSpinner", true);
        var action = component.get("c.validateQuote");
        action.setParams({ oppId : recordId });
        action.setCallback(this, function(response) 
                           {
                               component.set("v.showSpinner", false);
                               var state = response.getState();
                               if (state === "SUCCESS") 
                               {
                                   console.log(response.getReturnValue());
                                   var quoteWrapper = response.getReturnValue();
                                   component.set("v.quoteId", quoteWrapper.quoteId);
                                   component.set("v.opp", quoteWrapper.opp);
                                   
                                   var query = "SELECT Id, Sold_To_Contact_ID__c, Sold_To_Contact_Name__c, Sold_To_Contact_ERPID__c FROM Opportunity WHERE Id = '" + recordId+ "'" ;
                                   
                                   var action = component.get("c.search");
                                   action.setParams({ q: query,
                                                     sObjectType: "Contact",
                                                     iconName: "standard:contact",
                                                     title: "Sold_To_Contact_Name__c",
                                                     subtitle: "Sold_To_Contact_ERPID__c",
                                                     selectedIds: null });
                                   
                                   action.setCallback(this, function(response) 
                                                      {
                                                          component.set("v.showSpinner", false);
                                                          var state = response.getState();
                                                          if (state === "SUCCESS") 
                                                          {
                                                              console.log(response.getReturnValue());
                                                              var contact = response.getReturnValue();
                                                              console.log(contact[0].id);
                                                              if(typeof contact[0].id !== 'undefined'){
                                                                  component.set("v.contactId", contact[0].id);
                                                                  component.set("v.selectedContact", contact);
                                                              }
                                                              
                                                          }
                                                          else if (state === "INCOMPLETE") 
                                                          {
                                                              helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                                                          }
                                                              else if (state === "ERROR") 
                                                              {                
                                                                  //helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                                                                  var errors = response.getError();
                                                                  console.log(errors);
                                                                  if (errors) 
                                                                  {
                                                                      if (errors[0] && errors[0].message) 
                                                                      {
                                                                          console.log("Error message: " + errors[0].message);
                                                                          helper.showToast("error", "Error", errors[0].message);
                                                                          $A.get('e.force:refreshView').fire();
                                                                          $A.get("e.force:closeQuickAction").fire();                        
                                                                      }
                                                                  } 
                                                                  else 
                                                                  {
                                                                      console.log("Unknown error");
                                                                  }
                                                              }
                                                      });
                                   $A.enqueueAction(action); 
                                   
                               }
                               else if (state === "INCOMPLETE") 
                               {
                                   helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                               }
                                   else if (state === "ERROR") 
                                   {                
                                       //helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                                       var errors = response.getError();
                                       console.log(errors);
                                       if (errors) 
                                       {
                                           if (errors[0] && errors[0].message) 
                                           {
                                               console.log("Error message: " + errors[0].message);
                                               helper.showToast("error", "Error", errors[0].message);
                                               $A.get('e.force:refreshView').fire();
                                               $A.get("e.force:closeQuickAction").fire();                        
                                           }
                                       } 
                                       else 
                                       {
                                           console.log("Unknown error");
                                       }
                                   }
                           });
        $A.enqueueAction(action);	
        
    },
    
    inputChanged : function(component, event, helper) 
    {
        let fieldName = event.getSource().get("v.fieldName");
        let Value =  event.getSource().get("v.value");
        let searchTerm = event.getParam('searchTerm');
        var record = component.get("v.simpleRecord");
        
        if(fieldName != null && typeof searchTerm == 'undefined')
        {
            if(Value == "Other")
            {   
                if(fieldName == "Price_Validity__c") component.find("PriceValidityOther").set("v.disabled", false);
                else if(fieldName == "Delivery2__c") component.find("DeliveryOther").set("v.disabled", false);
                    else if(fieldName == "Payment_Method__c") component.find("PaymentMethodOther").set("v.disabled", false);
                        else if(fieldName == "Warranty_Period__c") component.find("WarrantyPeriodOther").set("v.disabled", false); 
            }
            else
            {
                if(fieldName == "Price_Validity__c") component.find("PriceValidityOther").set("v.disabled", true);
                else if(fieldName == "Delivery2__c") component.find("DeliveryOther").set("v.disabled", true);
                    else if(fieldName == "Payment_Method__c") component.find("PaymentMethodOther").set("v.disabled", true);
                        else if(fieldName == "Warranty_Period__c") component.find("WarrantyPeriodOther").set("v.disabled", true); 
            }
        }
        else if(typeof searchTerm != 'undefined')
        {
            var query = "SELECT Id, Name, ERP_Id__c FROM Contact WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = '" + record.AccountId +
                "') AND ERP_Id__c != null AND (Name LIKE '%" + searchTerm + "%' OR ERP_Id__c LIKE '%" +searchTerm+"%') limit 10";
    
        var action = component.get("c.search");
        action.setParams({ q: query,
        sObjectType: "Contact",
        iconName: "standard:contact",
        title: "Name",
        subtitle: "ERP_Id__c",
        selectedIds: null });
        
        action.setCallback(this, function(response) 
                           {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                console.log(response.getReturnValue());
                var contact = response.getReturnValue();
                component.find("lookupChild").setSearchResults(response.getReturnValue());
  
            }
            else if (state === "INCOMPLETE") 
            {
                helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
            }
            else if (state === "ERROR") 
            {                
                //helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                var errors = response.getError();
                console.log(errors);
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                        helper.showToast("error", "Error", errors[0].message);
                        $A.get('e.force:refreshView').fire();
                        $A.get("e.force:closeQuickAction").fire();                        
                    }
                } 
                else 
                {
                    console.log("Unknown error");
                }
            }
                           });
            $A.enqueueAction(action);
  
        }
        
    },

    
    handleSelectionChange : function(component, event, helper) 
    {
        let contactId = event.getParams();
        if (typeof contactId[0] !== "undefined") 
        {
            component.set("v.contactId", contactId[0]);
        }
    },
    
    createQuoteAction : function(component, event, helper) 
    {
        event.preventDefault();
        var quote = {};
        var record = component.get("v.simpleRecord");
        
        var eventFields = event.getParam("fields");
        quote.ContactId = component.get("v.contactId");
        quote.Contact_Name__c = eventFields["Contact_Name__c"];
        quote.Phone = eventFields["Phone"];
        quote.Fax = eventFields["Fax"];
        quote.Customer_Ref_No__c  = eventFields["Customer_Ref_No__c"];
        quote.BillingStreet = eventFields["BillingStreet"];
        quote.BillingCity = eventFields["BillingCity"];
        quote.BillingState = eventFields["BillingState"];
        quote.BillingPostalCode = eventFields["BillingPostalCode"];
        quote.BillingCountry = eventFields["BillingCountry"];
        /*quote.ShippingStreet = eventFields["ShippingStreet"];
        quote.ShippingCity = eventFields["ShippingCity"];
        quote.ShippingState = eventFields["ShippingState"];
        quote.ShippingPostalCode = eventFields["ShippingPostalCode"];
        quote.ShippingCountry = eventFields["ShippingCountry"];
        quote.Price_Validity__c = eventFields["Price_Validity__c"];
        quote.Price_Validity_Other__c  = eventFields["Price_Validity_Other__c"];
        quote.Delivery2__c = eventFields["Delivery2__c"];
        quote.Delivery_Other__c  = eventFields["Delivery_Other__c"];
        quote.Payment_Method__c   = eventFields["Payment_Method__c"];
        quote.Payment_Method_Other__c   = eventFields["Payment_Method_Other__c"];
        quote.Warranty_Period__c = eventFields["Warranty_Period__c"];
        quote.Warranty_Period_Other__c  = eventFields["Warranty_Period_Other__c"];*/
        quote.Description = eventFields["Description"];
        
        quote.Price_Validity__c = record.Price_Validity__c;
        quote.Price_Validity_Other__c  = record.Price_Validity_Other__c;
        quote.Delivery2__c = record.Delivery2__c;
        quote.Delivery_Other__c  = record.Delivery_Other__c;
        quote.Payment_Method__c   = record.Payment_Method__c;
        quote.Payment_Method_Other__c   = record.Payment_Method_Other__c;
        quote.Warranty_Period__c = record.Warranty_Period__c;
        quote.Warranty_Period_Other__c  = record.Warranty_Period_Other__c;
        
        var isValid  = true;
        /*if(quote.Price_Validity__c == 'Other'){
            var inputCmp = component.find("PriceValidityOther");
            var value = inputCmp.get("v.value");
            if (value === "" || value === null) {
                isValid = false;
                helper.showToast('error','error','Please input Price Validity (Other)');
            } 
        }
        else if(quote.Delivery2__c == 'Other'){
            var inputCmp = component.find("DeliveryOther");
            var value = inputCmp.get("v.value");
            if (value === "" || value === null) {
                isValid = false;
                helper.showToast('error','error','Please input Delivery (Other)');
            } 
        }
        else if(quote.Payment_Method__c == 'Other'){
            var inputCmp = component.find("PaymentMethodOther");
            var value = inputCmp.get("v.value");
            if (value === "" || value === null) {
                isValid = false;
                helper.showToast('error','error','Please input Payment Method (Other)');
            } 
        }
        else if(quote.Warranty_Period__c  == 'Other'){
            var inputCmp = component.find("WarrantyPeriodOther");
            var value = inputCmp.get("v.value");
            if (value === "" || value === null) {
                isValid = false;
                helper.showToast('error','error','Please input Warranty Period (Other)');
            } 
        }*/
 
        if(isValid){
            var recordId = component.get("v.recordId");
            console.log('recordId: ' + recordId);
            console.log(quote);
            component.set("v.showSpinner", true);
            //var contactId = component.get("v.contactId");
            //var expirationDate = component.get("v.expirationDate");
            var action = component.get("c.createQuote");        
            action.setParams({ oppId : recordId, qt : quote });
            action.setCallback(this, function(response) 
                               {
                                   component.set("v.showSpinner", false);
                                   var state = response.getState();
                                   if (state === "SUCCESS") 
                                   {
                                       console.log(response.getReturnValue());
                                       helper.showToast("success", "Success", "Quote created.");
                                       $A.get('e.force:refreshView').fire();
                                       $A.get("e.force:closeQuickAction").fire();
                                   }
                                   else if (state === "INCOMPLETE") 
                                   {
                                       helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                                   }
                                       else if (state === "ERROR") 
                                       {                
                                           //helper.showToast("error", "Error", "Quote creation failed. Contact your System Admin for help.");
                                           var errors = response.getError();
                                           console.log(errors);
                                           if (errors) 
                                           {
                                               if (errors[0] && errors[0].message) 
                                               {
                                                   console.log("Error message: " + errors[0].message);
                                                   helper.showToast("error", "Error", errors[0].message);
                                                   $A.get('e.force:refreshView').fire();
                                                   $A.get("e.force:closeQuickAction").fire();                        
                                               }
                                           } 
                                           else 
                                           {
                                               console.log("Unknown error");
                                           }
                                       }
                               });
            $A.enqueueAction(action);
        }
    }
})