({
	getChoiceRequestSickOutFromEvent : function(component, event, helper) {
        component.find('dateStart').set("v.value", "");
        component.find('dateEnd').set("v.value", "");
        component.find('detailSick').set("v.value", "");
        var getSelectedRequestFronEvt = event.getParam("ChoiceRequest");
        component.set("v.GetChoiceRequest", getSelectedRequestFronEvt);
        if(getSelectedRequestFronEvt === 'Sick-List') {
        	$('#sick-container').show();
        } else {
        	$('#sick-container').hide();
        }
    },
    getDetailSickListDefault : function(component, event, helper) {
        var dateStart = component.find('dateStart').get("v.value");
        var dateEnd = component.find('dateEnd').get("v.value");
        var dateStartFormat = new Date(dateStart);
        var dateEndFormat = new Date(dateEnd);
        var dateStartFormatString = dateStartFormat.toLocaleDateString("en-US", 
        {
            year: "numeric", month: "short",
            day: "numeric"
        });
        var dateEndFormatString = dateEndFormat.toLocaleDateString("en-US", 
        {
            year: "numeric", month: "short",
            day: "numeric"
        });
        var defaultTextForSick = 'Здравствуйте.\nБуду отсутствовать по причине болезни с ' + dateStartFormatString + ' по ' + dateEndFormatString + '.\nСпасибо.' ;
        component.set("v.detailsDefaultSick", defaultTextForSick);
        

    },
    cancelSick : function(component, event, helper) {
        helper.cancelSick(component);
    },

    submitSickListMain : function(component, event, helper) {
        var detailSickDef = component.find('detailSick').get("v.value");
        var dateSickStart = component.find('dateStart').get("v.value");
        var dateSickEnd = component.find('dateEnd').get("v.value");
        try {
            var submitApproveSickVar = component.get("c.submitApproveSickList");
            submitApproveSickVar.setParams(
                {
                    "details" : detailSickDef,
                    "sickListStart" : dateSickStart,
                    "sickListEnd" : dateSickEnd
                }
            );
            submitApproveSickVar.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var outputMessageText = 'Your request has been submitted. We wish you a speedy recovery!';
                    $A.createComponents([
                        ["ui:message",{
                            "title" : "Success",
                            "severity" : "confirm",
                            "closable" : "true",
                        }],
                        ["ui:outputText",{
                            "value" : outputMessageText
                        }]
                        ],
                        function(components, status, errorMessage){
                            if (status === "SUCCESS") {
                                var message = components[0];
                                var outputText = components[1];
                                // set the body of the ui:message to be the ui:outputText
                                message.set("v.body", outputText);
                                var divMessageSickList = component.find("divMessageSick");
                                // Replace div body with the dynamic component
                                divMessageSickList.set("v.body", message);

                            }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                                // Show error message
                            }
                        }
                    ); 
                    $('#sick-container').hide();
                    $('#afterSubmitSick').show();
                }
            });
            $A.enqueueAction(submitApproveSickVar);
        }
        catch(e) {
            $A.createComponents([
                ["ui:message",{
                    "title" : "Sample Thrown Error",
                    "severity" : "error",
                }],
                ["ui:outputText",{
                    "value" : e.message
                }]
                ],
                function(components, status, errorMessage) {
                    if (status === "SUCCESS") {
                        var message = components[0];
                        var outputText = components[1];
                        // set the body of the ui:message to be the ui:outputText
                        message.set("v.body", outputText);
                        var divMessageSickListError = component.find("divMessageSick");
                        // Replace div body with the dynamic component
                        divMessageSickListError.set("v.body", message);
                    }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
                }
            );
        }
    },
})