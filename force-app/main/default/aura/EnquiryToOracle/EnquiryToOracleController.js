({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var oppLineItems = {};
        var ErrorMessage = '';
        var MessageRequiredField = '';        
        component.set("v.spinner", true);
        var action = component.get("c.getoppItems");
        action.setParams({"recordId":recordId});
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS")
            {
                oppLineItems = response.getReturnValue();
                var record = component.get("v.simpleRecord");
                console.log(JSON.stringify(record));
                
                if (record.Submission_Status__c == 'Successful')
                    helper.showToast("error","OracleStatus","The Enquiry is already submitted to Oracle");
                else if (record.Submission_Status__c == 'In Progress')
                    helper.showToast("error","OracleStatus","In Progress to create the Order in Oracle");
                else if (record.StageName != 'Submit')
                    helper.showToast("error","Stage","Only Submit Stage can submit to Oracle");
                    else if(record.Account.Customer_Account_Type__c == 'Credit' && record.Account.ERP_Id__c == null)
                    helper.showToast("error","Account.ERPID","Account ERPID cannot be empty");
                    else if(record.Account.Customer_Account_Type__c == 'Cash' && record.Account.ERP_Id__c == null &&
                            (record.Account.ParentId == null || record.Account.Parent.ERP_Id__c == null))
                        helper.showToast("error","ParentAccount.ERPID","Parent Account ERPID cannot be empty");
                        else if (record.Sales_Rep__c == null)
                            helper.showToast("error","SalesRepId","Sales Rep ID cannot be empty");
                            else if (record.AddressX1__c == null || record.AddressX1__r.ERP_Id__c == null)
                                helper.showToast("error","ShipTo ERPID","ShipTo ERPID cannot be empty");
                                else if (record.Bill_To_Address__c == null || record.Bill_To_Address__r.ERP_Id__c == null)
                                    helper.showToast("error","BillTo ERPID","BillTo ERPID cannot be empty");
                                    else if (record.Warehouse__c == null || record.Warehouse__r.Code__c == null)
                                        helper.showToast("error","Warehouse.Code","Warehouse Code cannot be empty");
                                        else if (record.Order_Type__c == null|| record.Order_Type__r.Order_Type_ID__c == null)
                                            helper.showToast("error","OrderTypeID","Order Type ID cannot be empty");
                                            else if (record.Payment_Terms__c == null)
                                                helper.showToast("error","PaymentTerms","Payment Terms cannot be empty");
                                                else if (record.Estimated_Delivery_Date__c == null)
                                                    helper.showToast("error","Estimated Delivery Date","Estimated Delivery Date cannot be empty");
                                                    else if (oppLineItems.length == 0)
                                                        helper.showToast("error","Line Items","Please add some Product");
                                                        else if (oppLineItems.length > 0)
                                                        { 
                                                            var productValidated = true;
                                                            for(var i=0; i<oppLineItems.length; i++)
                                                            {  
                                                                var itemNo = i+1;
                                                                var isNewProduct;
                                                                var productCode;
                                                                if(record.RecordType.DeveloperName !== 'Customised_Engineering_Solution'){
                                                                    isNewProduct = oppLineItems[i].Product2.New_Product__c;
                                                                    productCode = oppLineItems[i].Product2.ProductCode;
                                                                }
                                                                else{
                                                                    isNewProduct = oppLineItems[i].New_Product__c;
                                                                    productCode = oppLineItems[i].Code__c;
                                                                }
                                                                
                                                                
                                                                if(isNewProduct == true)
                                                                {
                                                                    helper.showToast("error","New Product","Cannot submit New Product to Oracle, Product Code "+productCode);
                                                                    productValidated = false;
                                                                    break;
                                                                }  
                                                            }
                                                           
                                                            if(productValidated == true)
                                                            {
                                                                var action1 = component.get("c.doProcess");
                                                                action1.setParams({"recordId":recordId});
                                                                action1.setCallback(this,function(response){
                                                                    var state = response.getState();
                                                                    if(state === "SUCCESS")
                                                                    {
                                                                        var oracleStatus = response.getReturnValue();
                                                                        component.set("v.Status", oracleStatus.response_msg);
                                                                        component.set("v.StatusCode", oracleStatus.statusCode);
                                                                        component.set("v.RequestId", oracleStatus.requestId);
                                                                        if(oracleStatus.statusCode == 200)
                                                                            component.set("v.SentSuccess",true);
                                                                        component.set("v.oppSent", true);
                                                                        component.set("v.spinner", false);
                                                                        window.setTimeout($A.getCallback(function() {
                                                                            $A.get("e.force:closeQuickAction").fire()
                                                                            $A.get('e.force:refreshView').fire();
                                                                        }), 10000);
                                                                    
                                                                }
                                                                else if(state === "ERROR")
                                                                {
                                                                    var errors = action1.getError();
                                                                    if (errors) {
                                                                        if (errors[0] && errors[0].message) {
                                                                            component.set("v.ErrorMessage", errors[0].message);
                                                                            /*var toastEvent = $A.get("e.force:showToast");
                                                   toastEvent.setParams({
                                                       "title": "Error",
                                                       "message": errors[0].message,
                                                       "type": "error"
                                                   });
                                                   toastEvent.fire(); */
                                                                        }
                                                                    }
                                                                    component.set("v.SendToSAPSuccess",false);
                                                                    component.set("v.oppSent", true);
                                                                    component.set("v.spinner", false);
                                                                }
                                                                    else if (status === "INCOMPLETE") {
                                                                        alert('No response from server or client is offline.');
                                                                    }
                                                            });       
                                                                $A.enqueueAction(action1);
                                                            }
                                                        }                                   
            }
            else if (status === "INCOMPLETE") {
                alert('No response from server or client is offline.');
            }
        });       
        $A.enqueueAction(action);
    }
})