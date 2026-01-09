({
    ValidateOpportunity : function (response, component, helper){
        var quoteList = {};
        var status = response.getState();
        if(status == "SUCCESS")
        {
            quoteList = response.getReturnValue();
            if(quoteList != null)
            { 
                if (quoteList[0].SGTProfile__c == false)
                {
                    helper.showToast("error","User Profile","Only SGT Profiles can submit inquiry");
                }
                else if (quoteList[0].Quote_SAP_Status__c  == 'In Progress')
                {
                    helper.showToast("Warning","Quote SAP Status","Quote Creation is In Progress...");
                }
                /*else if (quoteList[0].Quote_SAP_Status__c  == 'Completed')
                {
                    helper.showToast("Warning","Quote SAP Status","Inquiry has been already created in SAP");
                }*/
                else if (quoteList[0].StageName != 'Bid Preparation' && quoteList[0].StageName != 'Negotiation')
                {
                    helper.showToast("error","Opportunity Stage","Only Bid Preparation and Negotiation Stage can be submitted");
                }
                else if (typeof quoteList[0].Shipping_Address__c == 'undefined')
                {
                    helper.showToast("error","Shipping Address","Shipping Address is Empty");
                }
               	else if (typeof quoteList[0].Division__c == 'undefined')
                {
                    helper.showToast("error","Division","Division is Empty");
                }
                else if (typeof quoteList[0].Channel__c == 'undefined')
                {
                    helper.showToast("error","Distribution Channel","Distribution Channel is Empty");
                }
                else if (typeof quoteList[0].Expected_Delivery_Date__c == 'undefined')
                {
                    helper.showToast("error","Expected Delivery Date","Expected Delivery Date is Empty ");
                }
                else if (typeof quoteList[0].QuoteLineItems == 'undefined')
                {
                    helper.showToast("error","Error!","There is no Quote Product");
                }
                else if (quoteList[0].QuoteLineItems.length > 0)
                { 
                    //alert("QuoteLineItems.length "+quoteList[0].QuoteLineItems.length);
                    var allProductHasMaterial = true;
                    var allvcFormCompleted = true;
                    var allvcMaterialhasVcForm = true;
                    for(var i=0; i<quoteList[0].QuoteLineItems.length; i++)
                    {  
                        var itemNo = i+1;
                        if(typeof quoteList[0].QuoteLineItems[i].Material_Number__c == 'undefined')
                        {
                            allProductHasMaterial = false;
                            helper.showToast("error","Material Number","Quote Item No."+itemNo+" has no Material Number");
                            break;
                        }
                        
                        
                        if(quoteList[0].QuoteLineItems[i].Is_VC_Material__c == true &&
                           typeof quoteList[0].QuoteLineItems[i].Variable_Configurator__c == 'undefined')
                        {
                            allvcMaterialhasVcForm = false;
                            helper.showToast("error","VC Products","Quote Item No."+itemNo+" no VC form related with VC Material");
                            break;
                        }
                        
                    }
                    
                    if(allProductHasMaterial == true && allvcFormCompleted == true && allvcMaterialhasVcForm == true)  
                    {
                        component.set("v.isValidated",true);                                                       
                    }
                }
            }
        }
    },
    
    showToast : function (type, title, message) {
        $A.get("e.force:closeQuickAction").fire()
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "type": type,
            "title": title,
            "message": message});
        resultsToast.fire();
    },
})