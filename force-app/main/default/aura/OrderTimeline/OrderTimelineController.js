({
    
    doInit : function(component, event, helper) { 
        var order = component.get("v.order");
        console.log(order);
        console.log(order.OrderItems);
    },
    
    toggleAcitivity : function(component, event, helper) {
        // toggle 'slds-is-open' class to expand/collapse activity section
        $A.util.toggleClass(component.find('expId'), 'slds-is-open');
    },
    
    linkToRecord: function (component, event, helper) {
        var order = component.get("v.order");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": order.Id
        });
        navEvt.fire();
    }
    
})