({
    doInit : function(component, event, helper) {        

        var recordId = component.get("v.recordId");
        var AccountId = component.get("v.simpleRecord").AccountId;
        var action = component.get("c.getOrderDetails");        
        action.setParams({ "recordId" : recordId, "accountId" : AccountId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {                
                var value = response.getReturnValue();
                console.log(value);
                if(value.length != 0)
                {
                    component.set("v.isItemsEmpty", false); 
                    component.set("v.orderTimelines", value); 
                }
                                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
        //https://pansar--dev.lightning.force.com/lightning/r/0011s00000KiYXjAAN/related/Orders/view
    },
    
    linkToRelatedAccount: function (component, event, helper) {
        var AccountId = component.get("v.simpleRecord").AccountId;
        window.open('/lightning/r/'+ AccountId + '/related/Orders/view')
        /*var AccountId = component.get("v.simpleRecord").AccountId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/lightning/r/'+ AccountId + '/related/Orders/view'
        });
        urlEvent.fire();*/
    }
})