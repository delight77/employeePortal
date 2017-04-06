({  
    getApprovalList : function(component, event, helper) {  
        var action = component.get("c.getApprovalData");
        action.setCallback(this, function(response) {  
            component.set("v.approvalList", response.getReturnValue());  
        });  
        $A.enqueueAction(action);  
    }, 
    getRequestList : function(component, event, helper) {  
        var actionSetRequestOptions = component.get("c.getRequestTypes");
        actionSetRequestOptions.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var ite = 0;
                for (var i = 0; i < response.getReturnValue().length; i++) {   
                    var requestIcon = $A.get('$Resource.SLDS') + '/assets/images/' + response.getReturnValue()[i] + '.jpg';
                    $A.createComponents( 
                    [
                        [
                            "ui:button",
                            {
                                "aura:id": response.getReturnValue()[i],
                                "press": component.getReference("c.onSelectChangeRequest"),
                                "id": response.getReturnValue()[i],
                                "class": "buttonIconRequest",
                                "name": response.getReturnValue()[i]
                            }
                        ],
                        [
                            "img",
                            {
                                "src": requestIcon,
                                "width":"50",
                                "height":"50"
                            }
                        ]
                    ],
                    function(components, status, errorMessage) {
                        //Add the new button to the body array
                        if (status === "SUCCESS") {
                            var divRequestId = response.getReturnValue()[ite];
                            var divRequestContainer = response.getReturnValue()[ite] + '-container';
                            var buttonRequest = components[0];
                            var iconForButton = components[1];
                            buttonRequest.set("v.body", iconForButton);

                            var mainDivRequestCmp = component.find(divRequestId);
                            var divRequestContainerCmp = component.find(divRequestContainer);
                            $A.util.removeClass(divRequestContainerCmp, 'show');
                            // Replace div body with the dynamic component
                            mainDivRequestCmp.set("v.body", buttonRequest);
                            ite++;
                            
                        }
                        else if (status === "ERROR") {
                            console.log("Error: " + errorMessage);
                            // Show error message
                        }
                    }
                );     
                }   
            }
        });
        $A.enqueueAction(actionSetRequestOptions);  
    }, 
})