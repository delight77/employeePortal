({
    getChoiceRequestFromEvent : function(component, event, helper) {
        component.set("v.body", []);

        $('#userVacationInfo').show();
        $('#afterSubmit').hide();

        helper.clearForm(component);
        var getSelectedRequestFronEvt = event.getParam("ChoiceRequest");
        component.set("v.GetChoiceRequest", getSelectedRequestFronEvt);
        if(getSelectedRequestFronEvt === 'Vacation') {
            $('#vacation-container').show();
        } else {
            $('#vacation-container').hide();
        }

        helper.getObjectInfo(component);
        helper.getUserProjects(component);
        
    },

    getDetailDefaultVacation : function(component, event, helper) {
        var dateStartVocation = component.find('dateStartVocation').get("v.value");
        var dateEndVocation = component.find('dateEndVocation').get("v.value");
        var replacementText = '';
        $('.outputUserName').each(function() {
            var valueForProject = $(this).val();
            if (valueForProject === '') {
                valueForProject = 'N/A';
            }
            replacementText += $(this).attr('id') + ': ' + valueForProject + '\n';
        });
        var paid = component.find('paid').get('v.value');
        var dateStart = new Date (dateStartVocation);
        var dateEnd = new Date (dateEndVocation);
        var daysVacation = (dateEnd.getTime() - dateStart.getTime())/(1000*60*60*24) + 1;
        component.set("v.daysVacation", daysVacation);

        if (paid === true) {
            var isPaidText = 'оплачиваемый'
        } else {
            var isPaidText = 'неоплачиваемый'
        }
        var defaultText = 'Здравствуйте,\nпредоставьте, пожалуйста, ' + isPaidText + ' отпуск на ' + daysVacation + ' д' + '.\n\n' + 'В моё отсутствие замена на проектах:\n' + replacementText + '\nЗаранее благодарю.' ;
        component.set("v.detailsDefaultVacation", defaultText);
    },
    submitApproveVacation : function(component, event, helper) {
        var dateStartVocation = component.find('dateStartVocation').get("v.value");
        var dateEndVocation = component.find('dateEndVocation').get("v.value");
        var paid = component.find('paid').get("v.value");
        var detail = component.find('detail').get("v.value");
        try {
            var submitApproveVar = component.get("c.submitApprove");

            submitApproveVar.setParams(
                {
                    "vacationStartDate": dateStartVocation,
                    "vacationEndDate": dateEndVocation,
                    "details" : detail,
                    "paid" : paid
                }
            );
            submitApproveVar.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var paid = component.find('paid').get("v.value");
                    var daysVocationForText = component.get('v.daysVacation');
                    var remainingYidForText = component.get('v.remainingYid');
                    var remainingCalculate = remainingYidForText - daysVocationForText;
                    component.set("v.remainingVacDaysAftAppr", remainingCalculate);
                    component.set("v.paidVrbl", paid);
                    var outputMessageText = 'Your request has been submitted. Please allow up to 48 hours for approval.';
                    $A.createComponents([
                        ["ui:message",{
                            "title" : "Success",
                            "severity" : "confirm",
                            "closable" : "true",
                            }
                        ],
                        ["ui:outputText",{
                            "value" : outputMessageText
                            }
                        ]
                        ],
                        function(components, status, errorMessage){
                            if (status === "SUCCESS") {
                                var message = components[0];
                                var outputText = components[1];
                                message.set("v.body", outputText);
                                var divMessage = component.find("divMessage");
                                divMessage.set("v.body", message);
                            }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                                // Show error message
                            }
                        }
                    ); 
                    $('#userVacationInfo').hide();
                    $('#afterSubmit').show();
                    
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
                        message.set("v.body", outputText);
                        var divError = component.find("divError");
                        divError.set("v.body", message);
                    }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
                }
            );
        }
        
    },
    cancel : function(component, event, helper) {
        component.set("v.body", []);
        helper.clearForm(component);  
    },

    backToHome : function(component, event, helper) {
        component.set("v.body", []);
        helper.clearForm(component); 
        $('#userVacationInfo').show();
        $('#afterSubmit').hide(); 

        var newApprovalList = component.get("c.getApprovalData");
        newApprovalList.setCallback(this, function(response) {  
            var evtApprovalList = $A.get("e.c:GetApproveListEvt");
            evtApprovalList.setParams({ "getApprovalList": response.getReturnValue()});
            evtApprovalList.fire(); 
        });  
        $A.enqueueAction(newApprovalList);  
    },
})