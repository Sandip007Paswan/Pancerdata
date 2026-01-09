({
	init : function(component, event, helper) 
    {
        component.set("v.spinner", true);
        
        var recordId = component.get("v.recordId");
        if (typeof recordId === 'undefined')
        {
            var value = helper.getParameterByName(component, event, 'inContextOfRef');
            var context = JSON.parse(window.atob(value));
            component.set("v.recordId", context.attributes.recordId);
            component.set("v.fullPageMode", true);
    	}
    
        var flow = component.find("Query_Contract_Products");
        var inputVariables = [
            {
                name : "Contract_Id",
                type : "String",
                value: component.get("v.recordId")
            },
            {
                name : "Type",
                type : "String",
                value: "Query_Contract_Products"                
            }
        ];
        var results = flow.startFlow("Generate_Order_Products", inputVariables);
	},
    handleQueryContractProducts : function (component, event) 
    {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED_SCREEN") 
        {
            var outputVariables = event.getParam("outputVariables");
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) 
            {
                outputVar = outputVariables[i];
                // Pass the values to the component's attributes
                if(outputVar.name === "Existing_Contract_Products") 
                {
                    component.set("v.contractLineItems", outputVar.value);
                    console.log(outputVar.value);
                }
            }
        }
        component.set("v.spinner", false);
    },
    createOrder : function (component, event, helper)
    {
    	component.set("v.spinner", true);
        
        var form = component.find("recordEditForm");
        var newContractLineItemFieldsCmp = component.find('newContractLineItemFields');
        if (typeof newContractLineItemFieldsCmp !== 'undefined')
        {
            var allValid = newContractLineItemFieldsCmp.reduce(function (validSoFar, inputCmp)
                                                               {
                                                                   inputCmp.reportValidity();
                                                                   return validSoFar && inputCmp.reportValidity();
                                                               }, true);
            if (allValid && helper.validate(component, event))
            {
                //Duplicate check
                var values1 = component.get("v.newContractLineItems");
                var values2 = component.get("v.contractLineItems");
                var values = values1.concat(values2);
                for (var i=0; i<values.length; i++)
                {
                    var discount = values[i].Discount__c;
                    if (typeof discount === 'undefined' || discount == null)
                    {
                        values[i].duplicateKey = values[i].Sales_Price__c;
                    }
                    else
                    {
                    	values[i].duplicateKey = values[i].Sales_Price__c * (1 - (discount/100));    
                    }                    
                    values[i].duplicateKey = values[i].Product__c + "_" + values[i].duplicateKey;
                    console.log(values[i].duplicateKey);
                }                                
                var valueArr = values.map(function(item){ return item.duplicateKey });
                var isDuplicate = valueArr.some(function(item, idx){ 
                    return valueArr.indexOf(item) != idx 
                });
                if (isDuplicate)
                {
                    helper.showToast("error", "Error", "Cannot add duplicate products with the same price.");
                    component.set("v.spinner", false); 
                    return;
                }
                //                
                if (form.length)
                {
                    component.set("v.newProductsQueue", form.length);
                    for(var i=0; i<form.length; i++)
                    {
                        form[i].submit();
                    }
                }
                else
                {
                    component.set("v.newProductsQueue", 1);
                    form.submit();
                }
            }
            else
            {
                component.set("v.spinner", false);
            }            
        }
        else
        {
            if (helper.validate(component, event))
            {
                var contractLineItems = component.get("v.contractLineItems");
                var totalRemainingItems = component.find("totalRemaining");                
                //var contractLineItemDescriptionList = component.find("contractLineItemDescription");
                if (typeof totalRemainingItems.length !== 'undefined')
                {
                    var allZeroQuantity = true;
                    for (var i=0; i<totalRemainingItems.length; i++)
                    {
                        var quantityValue = totalRemainingItems[i].get("v.value");
                        if (quantityValue != 0 && quantityValue != "0")
                        {
                            allZeroQuantity = false;
                        }
                    }
                    if (allZeroQuantity == true)
                    {
                        console.log('allZeroQuantity');
                        component.set("v.spinner", false);
                        helper.showToast("error", "Error", "Please add the new order quantity to atleast one product to create an order.");
                        return;
                    }                    
                    for (var i=0; i<totalRemainingItems.length; i++)
                    {
                        contractLineItems[i].New_Order_Quantity__c = parseFloat(totalRemainingItems[i].get("v.value"));
                        contractLineItems[i].Total_Ordered__c = contractLineItems[i].Total_Ordered__c + contractLineItems[i].New_Order_Quantity__c;
                    	//contractLineItems[i].Product_Description__c = contractLineItemDescriptionList[i].get("v.value");
                    }
                    console.log(contractLineItems);                
                }
                else
                {
                    var quantityValue = totalRemainingItems.get("v.value");
                    if (quantityValue == 0 || quantityValue == "0")
                    {
                        console.log('allZeroQuantity');
                        component.set("v.spinner", false);
                        helper.showToast("error", "Error", "Please add the new order quantity to atleast one product to create an order.");
                        return;
                    }                      
                    contractLineItems[0].New_Order_Quantity__c = parseFloat(totalRemainingItems.get("v.value"));
                    contractLineItems[0].Total_Ordered__c = contractLineItems[0].Total_Ordered__c + contractLineItems[0].New_Order_Quantity__c;
                    //contractLineItems[0].Product_Description__c = contractLineItemDescriptionList.get("v.value");
                }
                
                var flow = component.find("Create_Order");
                var inputVariables = [
                    {
                        name : "Contract_Id",
                        type : "String",
                        value: component.get("v.recordId")
                    },
                    {
                        name : "Type",
                        type : "String",
                        value: "Create_Order"                
                    },
                    {
                        name : "Contract_Products",
                        type : "SObject",
                        value: contractLineItems               
                    }            
                ];
                var results = flow.startFlow("Generate_Order_Products", inputVariables);  
                
            } 
            else
            {
                component.set("v.spinner", false);
            }
        }

    },
    handleCreateOrder : function (component, event) 
    {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED_SCREEN") 
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "Order created successfully.",
                "type": "success"
            });
            toastEvent.fire();            
        }
        else
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Cannot create order. Please contact System Administrator.",
                "type": "error"
            });
            toastEvent.fire();            
        }
        component.set("v.spinner", false);        
		$A.get("e.force:closeQuickAction").fire();
		var recordId = component.get("v.recordId");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        var navService = component.find("navService");  
        navService.navigate(pageReference);
        
    },
    addProduct : function (component, event, helper)
    {
        var newContractLineItem = {};
        var newContractLineItems = component.get("v.newContractLineItems");
        newContractLineItem.Contract__c = component.get("v.recordId");
        newContractLineItem.New_Order_Quantity__c = 0;
		newContractLineItems.push(newContractLineItem);
        component.set("v.newContractLineItems", newContractLineItems);
    },
    productChanged : function (component, event, helper)
    {
    	component.set("v.spinner", true);
        
        var productId = event.getParam("value")[0];
        var index = event.getSource().get("v.class");
        console.log('productId: ' + productId);
        console.log('index: ' + index);        
        if (typeof productId === 'undefined')
        {
            var newContractLineItems = component.get("v.newContractLineItems");
            var updatedContractLineItems = [];
            for (var i=0; i<newContractLineItems.length; i++)
            {
                if (index == i)
                {
                    continue;
                }
                updatedContractLineItems.push(newContractLineItems[i]);
            }
            component.set("v.newContractLineItems", updatedContractLineItems);
            component.set("v.spinner", false);
            return;
        }
        
        component.set("v.currentNewProductIndex", index);
        var recordId = component.get("v.recordId");
    
        var flow = component.find("Query_Product");
        var inputVariables = [
            {
                name : "Contract_Id",
                type : "String",
                value: recordId
            },
            {
                name : "Product_Id",
                type : "String",
                value: productId
            },
            {
                name : "Type",
                type : "String",
                value: "Query_Product"                
            }
        ];
        var results = flow.startFlow("Generate_Order_Products", inputVariables);        
    },
    handleQueryProduct : function (component, event, helper)
    {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED_SCREEN") 
        {
            var outputVariables = event.getParam("outputVariables");
            var outputVar;
            var index = component.get("v.currentNewProductIndex");
            var newContractLineItems = component.get("v.newContractLineItems");
            for(var i = 0; i < outputVariables.length; i++) 
            {
                outputVar = outputVariables[i];
                // Pass the values to the component's attributes
                if(outputVar.name === "Product") 
                {
                    newContractLineItems[index].Product_Code__c = outputVar.value.Product_Code__c;
                    //newContractLineItems[index].Product_Description__c = outputVar.value.Description;
                    console.log(outputVar.value);
                }
                else if(outputVar.name === "Unit_Price") 
                {
                    
                    newContractLineItems[index].Sales_Price__c = outputVar.value;
                    console.log(outputVar.value);
                }  
                else if(outputVar.name === "Pricebookentry_Id") 
                {
                    
                    newContractLineItems[index].PriceBookEntry_Id__c = outputVar.value;
                    console.log(outputVar.value);
                } 
                else if(outputVar.name === "Estimated_Discount") 
                {
                    
                    newContractLineItems[index].Discount__c = outputVar.value;
                    console.log(outputVar.value);
                }                
            }
            component.set("v.newContractLineItems", newContractLineItems);
        }
        component.set("v.spinner", false);        
    },
    removeProduct : function(component, event, helper)
    {
        var index = event.getSource().get("v.class");
        var newContractLineItems = component.get("v.newContractLineItems");
        var updatedContractLineItems = [];
        for (var i=0; i<newContractLineItems.length; i++)
        {
            if (index == i)
            {
                continue;
            }
            updatedContractLineItems.push(newContractLineItems[i]);
        }
        component.set("v.newContractLineItems", updatedContractLineItems);        
    },
    handleSuccessCreateContractLineItem : function(component, event, helper)
    {
        var createProductsOnly = component.get("v.createProductsOnly");
		if (createProductsOnly == true)
        {
            var newProductsQueue = component.get("v.newProductsQueue");
            var newProductsQueueIndex = component.get("v.newProductsQueueIndex");
            newProductsQueueIndex = newProductsQueueIndex + 1;            
            component.set("v.newProductsQueueIndex", newProductsQueueIndex);
            if (newProductsQueue == newProductsQueueIndex)
            {
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Product(s) created successfully.",
                        "type": "success"
                    });
                    toastEvent.fire();            
                }
                component.set("v.spinner", false);        
                $A.get("e.force:closeQuickAction").fire();
                var recordId = component.get("v.recordId");
                var pageReference = {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        actionName: 'view'
                    }
                };
                var navService = component.find("navService");  
                navService.navigate(pageReference);
            }
		}
        else
        {
            var newProductsQueue = component.get("v.newProductsQueue");
            var newProductsQueueIndex = component.get("v.newProductsQueueIndex");
            newProductsQueueIndex = newProductsQueueIndex + 1;
            component.set("v.newProductsQueueIndex", newProductsQueueIndex);
    
            var payload = event.getParams();
            console.log(JSON.stringify(payload));         
            var newContractLineItem = {};
            newContractLineItem.Id = payload.response.id;
            newContractLineItem.Product__c = payload.response.fields.Product__c.value;
            //newContractLineItem.Product_Description__c = payload.response.fields.Product_Description__c.value;
            newContractLineItem.New_Order_Quantity__c = payload.response.fields.New_Order_Quantity__c.value;
            newContractLineItem.Sales_Price__c = payload.response.fields.Sales_Price__c.value;
            newContractLineItem.Total_Ordered__c = payload.response.fields.New_Order_Quantity__c.value;
            newContractLineItem.PriceBookEntry_Id__c = payload.response.fields.PriceBookEntry_Id__c.value;
            newContractLineItem.Discount__c = payload.response.fields.Discount__c.value;
            newContractLineItem.Populated_Discount__c = payload.response.fields.Discount__c.value;
            var contractLineItems = component.get("v.contractLineItems");
            contractLineItems.push(newContractLineItem);
            
            if (newProductsQueue == newProductsQueueIndex)
            {
                var totalRemainingItems = component.find("totalRemaining");
                if (typeof totalRemainingItems.length !== 'undefined')
                {
                    for (var i=0; i<totalRemainingItems.length; i++)
                    {
                        contractLineItems[i].New_Order_Quantity__c = parseInt(totalRemainingItems[i].get("v.value"));
                        contractLineItems[i].Total_Ordered__c = contractLineItems[i].Total_Ordered__c + contractLineItems[i].New_Order_Quantity__c;
                    }
                    console.log(contractLineItems);                
                }
                else
                {
                    contractLineItems[0].New_Order_Quantity__c = parseInt(totalRemainingItems.get("v.value"));
                    contractLineItems[0].Total_Ordered__c = contractLineItems[0].Total_Ordered__c + contractLineItems[0].New_Order_Quantity__c;                
                }
                
                var flow = component.find("Create_Order");
                var inputVariables = [
                    {
                        name : "Contract_Id",
                        type : "String",
                        value: component.get("v.recordId")
                    },
                    {
                        name : "Type",
                        type : "String",
                        value: "Create_Order"                
                    },
                    {
                        name : "Contract_Products",
                        type : "SObject",
                        value: contractLineItems               
                    }            
                ];
                var results = flow.startFlow("Generate_Order_Products", inputVariables);  
                
            }                
        }            
    },
    handleErrorCreateContractLineItem : function(component, event, helper)
    {
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Cannot create order. Please contact System Administrator.",
                "type": "error"
            });
            toastEvent.fire();            
        }
        component.set("v.spinner", false);        
		$A.get("e.force:closeQuickAction").fire();
		var recordId = component.get("v.recordId");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        var navService = component.find("navService");  
        navService.navigate(pageReference);
    },
    createProducts : function (component, event, helper)
    {
        component.set("v.spinner", true);        
        
        var form = component.find("recordEditForm");
        var newContractLineItemFieldsCmp = component.find('newContractLineItemFields');
        if (typeof newContractLineItemFieldsCmp !== 'undefined')
        {
            var allValid = newContractLineItemFieldsCmp.reduce(function (validSoFar, inputCmp)
                                                               {
                                                                   inputCmp.reportValidity();
                                                                   return validSoFar && inputCmp.reportValidity();
                                                               }, true);
            if (allValid)
            {
                //Duplicate check
                var values1 = component.get("v.newContractLineItems");
                var values2 = component.get("v.contractLineItems");
                var values;
                if (values2 != null)
                {
                    values = values1.concat(values2);
                }
                else
                {
                    values = values1;
                }
                for (var i=0; i<values.length; i++)
                {
                    var discount = values[i].Discount__c;
                    if (typeof discount === 'undefined' || discount == null)
                    {
                        values[i].duplicateKey = values[i].Sales_Price__c;
                    }
                    else
                    {
                    	values[i].duplicateKey = values[i].Sales_Price__c * (1 - (discount/100));    
                    }                    
                    values[i].duplicateKey = values[i].Product__c + "_" + values[i].duplicateKey;
                    console.log(values[i].duplicateKey);
                }                                
                var valueArr = values.map(function(item){ return item.duplicateKey });
                var isDuplicate = valueArr.some(function(item, idx){ 
                    return valueArr.indexOf(item) != idx 
                });
                if (isDuplicate)
                {
                    helper.showToast("error", "Error", "Cannot add duplicate products with the same price.");
                    component.set("v.spinner", false); 
                    return;
                }
                //
                component.set("v.createProductsOnly", true);
                if (form.length)
                {
                    component.set("v.newProductsQueue", form.length);
                    for(var i=0; i<form.length; i++)
                    {
                        form[i].submit();
                    }
                }
                else
                {
                    component.set("v.newProductsQueue", 1);                    
                    form.submit();
                }
            }
            else
            {
                component.set("v.spinner", false);
            }            
        }
        else
        {
            component.set("v.spinner", false);
        }
    },
    searchProductChanged : function (component, event, helper)
    {
		var inputCmp = component.find("searchProduct");
        var value = inputCmp.get("v.value");     
        console.log('searchProductChanged: ' + value);
        var contractLineItems = component.get("v.contractLineItems");
        if (contractLineItems.length)
        {
            var elements = document.getElementsByClassName("contractLineItems");              
            for (var i=0;i<elements.length;i++)
            {
                elements[i].style.display = 'none';
            }
            for (var i=0;i<contractLineItems.length;i++)
            {
                var str = contractLineItems[i].Product_Name__c.toLowerCase();
                if (str.includes(value))
                {
                    var matchedElements = document.getElementsByClassName("contractLineItem_" + contractLineItems[i].Product__c);                    
                    for (var j=0;j<matchedElements.length;j++)
                    {
                        matchedElements[j].style.display = 'table-row';
                    }                    
                }
            }
        }
       
    },
    goBack : function(component, event, helper)
    {
		var recordId = component.get("v.recordId");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        var navService = component.find("navService");  
        navService.navigate(pageReference);        
    }
})