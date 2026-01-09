({
	validate : function(component, event) 
    {
        var totalRemainingItems = component.find('totalRemaining');
        var allValid = false;
        if (totalRemainingItems.length > 1)
        {
            allValid = component.find('totalRemaining').reduce(function (validSoFar, inputCmp)
                           {
                               inputCmp.reportValidity();
                               return validSoFar && inputCmp.checkValidity();
                            }, true);
        }
        else
        {
            totalRemainingItems.reportValidity();
            allValid = totalRemainingItems.checkValidity();
        }
        if (allValid) 
        {
            component.set("v.isValid", true);
        }
        else
        {
            component.set("v.isValid", false);
        }
        return allValid;
	},
    calculateTotal : function(component, event)
    {
        var contractLineItems = component.get("v.contractLineItems");
        var totalRemainingItems = component.find("totalRemaining");
        for (var i=0; i<totalRemainingItems.length; i++)
        {
            contractLineItems[i].New_Total__c = contractLineItems[i].Sales_Price__c * (1 - contractLineItems[i].Discount__c) * contractLineItems[i].Total_Quantity__c;
        }
        component.set("v.contractLineItems", contractLineItems);
        console.log(contractLineItems);        
    },
    getParameterByName: function(component, event, name)
    {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    showToast : function(type, title, message)
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
    	});
    	toastEvent.fire();            
	}
})