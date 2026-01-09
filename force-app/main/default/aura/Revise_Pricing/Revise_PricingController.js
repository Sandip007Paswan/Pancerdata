({
    Submit: function(component, event, helper) {
        //helper.ApprovalValidation(component, helper);
        //component.set("v.spinner", true);
        //var opportunity = component.get("v.opportunity");
        
        /*opportunity.StageName = "Pricing";
        opportunity.Branch_Manager_Approval__c = null;
        opportunity.Pricing_Completed__c = false;
        opportunity.Quotation_Accepted__c = false;
        opportunity.Quotation_Approved__c = false;
        opportunity.is_Revise_Pricing__c = true;
        
        component.find("record").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS"){
                component.set("v.spinner", false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Revise Pricing Successful",
                    "type": "success"
                });
                toastEvent.fire(); 
            }
            else if (saveResult.state === "INCOMPLETE") {
                console.log("Process is INCOMPLETE.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving contact, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        }));*/
        
        var flow = component.find("flowData");
        var inputVariables = [
            {
                name : "recordId",
                type : "String",
                value : component.get("v.recordId")
            }
        ];
        flow.startFlow("Enquires_Revise_Pricing_Lightning", inputVariables );
        var cmpTarget = component.find('flowData');
        $A.util.addClass(cmpTarget, 'changeMe');
    },
    
    handleStatusChange : function (component, event) {
        if(event.getParam("status") === "FINISHED_SCREEN") {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": "Revise Pricing Successful",
                "type": "success"
            });
            toastEvent.fire(); 
            
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        }
    },
    
    Cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})