({
    doInit : function(component, event, helper) {   
        var recordId = component.get("v.recordId");
    	var action = component.get("c.getQuotePDFId");
        component.set("v.showSpinner", true);
        action.setParams({ "parentId" : recordId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {                
                var cv = response.getReturnValue();
                console.log(cv);
                console.log('ConentDocumentId: ' + cv.ContentDocumentId);
                component.set("v.drawingId", cv.ContentDocumentId);

                console.log('ConentDocumentId: ' + cv.ContentSize);
                if (cv.ContentSize)
                {
                    let bytes = cv.ContentSize;
                    let decimals = 2;
                    let size;

                    if (bytes === 0) return '0 Bytes';
                
                    const k = 1024;
                    const dm = decimals < 0 ? 0 : decimals;
                    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
                
                    const i = Math.floor(Math.log(bytes) / Math.log(k));
                
                    size = parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
                    component.set("v.drawingSize", size);
                }
				component.find('lwc').navigateToFiles();                
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
    },
    closeQuickAction : function(component, event, helper) 
    {
		$A.get("e.force:closeQuickAction").fire();
	}
})