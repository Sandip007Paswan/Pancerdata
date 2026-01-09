({
	init : function(component, event, helper) 
    {
		
	},
    submitOrder : function(component, event, helper) 
    {
        var flow = component.find("Cancel_Order");
        var inputVariables = [
            {
                name : "Order_Id",
                type : "String",
                value: component.get("v.recordId")
            },
            {
                name : "Type",
                type : "String",
                value: "Cancel_Order"                
            }           
        ];
        var results = flow.startFlow("Generate_Order_Products", inputVariables);  		
	},
    handleCancelOrder : function(component, event, helper)
    {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED_SCREEN") 
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "Order cancel successfully.",
                "type": "success"
            });
            toastEvent.fire();            
        }
        else
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Cannot cancel order. Please contact System Administrator.",
                "type": "error"
            });
            toastEvent.fire();            
        }
        component.set("v.spinner", false);        
		$A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
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
    cancelOrder: function(component, event, helper) 
    {
        var viewRecordEvent = $A.get("e.force:navigateToURL");
        viewRecordEvent.setParams({
            "url": "/" + component.get("v.recordId")
        });
        viewRecordEvent.fire();    
    }
})