({
	clearFormHelpdesk : function(component) {
		component.set("v.detailsDefaultHelpdesk", '');
		component.set("v.selectRequestType", '');
		component.set("v.inputSelectProject", '');
        $('#main-page').show();
        $('#helpdesk-container').hide(); 
        $('#helpdeskAccessPart').hide(); 
	},
    clearFormForNewEmpl : function(component) {
        component.set("v.detailsDefaultHelpdeskEmpl", '');
        component.find("inputSelectProjectMult").set("v.value", '');
        component.find("selectAccountTeam").set("v.value", '');
        component.find("dateStartEmployee").set("v.value", '');
        component.set("v.inputFirstName", '');
        component.set("v.inputLastName", '');
        $('#main-page').show();
        $('#helpdesk-container').hide();
        $('#add_employee').hide();
    },
    clearFormForBlockEmpl : function(component) {
        component.set("v.detailsDefaultHelpdeskBlockEmpl", '');
        component.find("dateBlockEmployee").set("v.value", '');
        $('#main-page').show();
        $('#helpdesk-container').hide();
        $('#block_employee').hide();

    },
    clearFormForNewProject : function(component) {
        component.set("v.detailsHelpdeskNewProjectV", '');
        component.find("inputSelectNewProject").set("v.value", '');
        $('#main-page').show();
        $('#helpdesk-container').hide();
        $('#new_project').hide();

    },

    cancelHelpdeskHlp : function(component, helper) {
        var typeRequestHelpdeskVar = component.get("v.typeRequestHelpdesk");
        if(typeRequestHelpdeskVar === 'Team Project Access') {
            helper.clearFormHelpdesk(component); 
        }
        else if(typeRequestHelpdeskVar === 'New Employee') {
            helper.clearFormForNewEmpl(component); 

        }
        else if(typeRequestHelpdeskVar === 'Block Employee') {
            helper.clearFormForBlockEmpl(component);
            helper.callClearEvent(component); 
        }
        else if(typeRequestHelpdeskVar === 'New Project') {
            helper.clearFormForNewProject(component); 
            helper.callClearEvent(component); 
            
        }
    },

    callClearEvent : function(component) {
        var evtCancelRequest = $A.get("e.c:ClearCustomLookupAfterCancelEvt");
        evtCancelRequest.setParams({ "clearAttr": "YES"});
        evtCancelRequest.fire();
    },

    getHelpdeskRequestType : function(component) {
        var requestOptions = [];
        var inputSelectRequestVar = component.find("selectRequestType");
        var actionSetRequestOptions = component.get("c.getHelpdeskTypes");
        actionSetRequestOptions.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                requestOptions.push({"class": "optionClass", label: "", value: ""});
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    requestOptions.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
                }
                inputSelectRequestVar.set("v.options", requestOptions);
                
            }
        });
        $A.enqueueAction(actionSetRequestOptions);
    },

    getCurrentUserForHelpdesk : function(component) {
        var actionGetCurrentUser = component.get("c.getCurrentUser");
        actionGetCurrentUser.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.currentUser", response.getReturnValue());
                
            }
        });
        $A.enqueueAction(actionGetCurrentUser);
    },

    getProjectsSelectForRequestType : function(component, typeRequest) {
        var projectOptions = [];
        if (typeRequest === 'Team Project Access') {
            var inputSelectProjectVar = component.find("inputSelectProject");
        } else if(typeRequest === 'New Employee') {
            var inputSelectProjectVar = component.find("inputSelectProjectMult");
        }
        
        var actionSetProjectOptions = component.get("c.getProjects");
        actionSetProjectOptions.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    projectOptions.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
                }
                inputSelectProjectVar.set("v.options", projectOptions);
                
            }
        });
        $A.enqueueAction(actionSetProjectOptions);    
    },
    getSelectTeam : function(component) {
        var teamOptions = [];
        var teamOptionsMulti = [];
        var inputSelectTeam = component.find("selectAccountTeam");
        var inputSelectTeamTempo = component.find("selectAccountTeamTempo");
        var actionSetTeamOptions = component.get("c.getTeams");
        actionSetTeamOptions.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    teamOptions.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
                    teamOptionsMulti.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
                }
                inputSelectTeam.set("v.options", teamOptions);
                inputSelectTeamTempo.set("v.options", teamOptionsMulti); 
            }
        });
        $A.enqueueAction(actionSetTeamOptions);
    },

    getRoleSelect : function(component) {
        var roleOptions = [];
        var inputSelectRole = component.find("selectRole");
        var actionSetRoleOptions = component.get("c.getRoles");
        actionSetRoleOptions.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    roleOptions.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
                }
                inputSelectRole.set("v.options", roleOptions);
                
            }
        });
        $A.enqueueAction(actionSetRoleOptions);
    },

    submitHelpdesk : function(component, param) {
        
        if (param === 'New Employee') {
            var detail = component.find('detailHelpdeskEmpl').get("v.value");
        }
        else if(param === 'Add access'){
           var detail = component.find('detailHelpdesk').get("v.value"); 
        }
        else if(param === 'Block Employee'){
           var detail = component.find('detailHelpdeskBlockEmpl').get("v.value"); 
        }
        else if(param === 'New Project'){
           var detail = component.find('detailHelpdeskNewProject').get("v.value"); 
        }
        try {
            component.set("v.detailsAfterSubmit", detail);

            var submitApproveVar = component.get("c.submitApproveHelpdesk");

            submitApproveVar.setParams(
                {
                    "details" : detail
                }
            );

            submitApproveVar.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    
                    var outputMessageText = 'Your request has been sent to Helpdesk team. Please allow up to 24 hours for completion.';
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
                                var divMessage = component.find("divMessageHelpdesk");
                                // Replace div body with the dynamic component
                                divMessage.set("v.body", message);
                            }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                                // Show error message
                            }
                        }
                    ); 
                    $('#helpdesk-container').hide();
                    $('#afterSubmitHelpdesk').show();
                    
                }
            });
            $A.enqueueAction(submitApproveVar); 
            
        }
        catch(e) {
            helper.clearForm(component);
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
                        var divMessage = component.find("divMessageHelpdesk");
                        // Replace div body with the dynamic component
                        divMessage.set("v.body", message);
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