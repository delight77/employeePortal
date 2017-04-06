({
    getChoiceRequestProjectAccessFromEvent : function(component, event, helper) {
        var getSelectedRequestFronEvt = event.getParam("ChoiceRequest");
        $('#group_buttons').hide();
        $('#cancel_init').show();
        if(getSelectedRequestFronEvt === 'Helpdesk') {
            $('#helpdesk-container').show();
        } 
        else {
            $('#helpdesk-container').hide();
        }
        helper.getHelpdeskRequestType(component);
        helper.getCurrentUserForHelpdesk(component);
    },

    getInfForRequestType : function(component, event, helper) {
        component.set("v.detailsDefaultHelpdesk", '');
        component.set("v.typeRequestHelpdesk", '');
        var getSelectTypeVar = component.find("selectRequestType").get("v.value");
        $('#cancel_init').hide();
        $('#group_buttons').show();
        if (getSelectTypeVar === 'Team Project Access') {
            component.set("v.typeRequestHelpdesk", 'Team Project Access');
            $('#helpdeskAccessPart').show();
            $('#add_employee').hide();
            $('#block_employee').hide();
            $('#new_project').hide();
            helper.getProjectsSelectForRequestType(component, 'Team Project Access'); 
        }
        else if(getSelectTypeVar === 'New Employee') {
            component.set("v.typeRequestHelpdesk", 'New Employee');
            $('#helpdeskAccessPart').hide();
            $('#add_employee').show();
            $('#block_employee').hide();
            $('#new_project').hide();
            helper.getProjectsSelectForRequestType(component, 'New Employee');
            helper.getSelectTeam(component);
            helper.getRoleSelect(component);
        }
        else if(getSelectTypeVar === 'Block Employee') {
            component.set("v.typeRequestHelpdesk", 'Block Employee');
            $('#helpdeskAccessPart').hide();
            $('#add_employee').hide();
            $('#new_project').hide();
            $('#block_employee').show();
        }
        else if(getSelectTypeVar === 'New Project') {
            component.set("v.typeRequestHelpdesk", 'New Project');
            $('#helpdeskAccessPart').hide();
            $('#add_employee').hide();
            $('#block_employee').hide();
            $('#new_project').show();
        }
        
    },

    getDetailHelpdeskEmpl : function(component, event, helper) {
        var firstName = component.get("v.inputFirstName");
        var lastName = component.get("v.inputLastName");
        var role = component.find('selectRole').get("v.value");
        var dateEmpl = component.find('dateStartEmployee').get("v.value");
        var team = component.find('selectAccountTeam').get("v.value");
        var projects = String(component.get("v.projectMultiple"));
        var projectList = projects.split(";");
        var teamsForTempo = String(component.get("v.teamTempoMultiple"));
        var teamsForTempoList = teamsForTempo.split(";");
        var projectsString = '';
        var teamsString = '';
        for(var i=0;i<projectList.length;i++) {
            projectsString += ', ' + projectList[i];   
        }
        for(var i=0;i<teamsForTempoList.length;i++) {
            if(i === teamsForTempoList.length - 1) {
                teamsString += teamsForTempoList[i];
            } else {
                teamsString += teamsForTempoList[i] + ', '; 
            }   
        }
        var dateStartFormat = new Date(dateEmpl);
        var dateStartFormatString = dateStartFormat.toLocaleDateString("en-US", 
        {
            year: "numeric", month: "short",
            day: "numeric"
        });
        var defaultTextForNewEmpl = 'Создайте, пожалуйста, аккаунты в mail.vrpinc.com, jira, confluence для нового сотрудника - ' + firstName + ' ' + lastName + '(' + role + ').\n' + 'Предоставьте доступ к VRP Knowledge Base на confluence. Откройте доступ в Jira к проектам Onboarding, Holidays, Vacation, Training, Bench' + projectsString +'.\nДобавьте в ' + team + ' на почте, в ' + teamsString + ' в tempo.\nДата выхода на работу - ' + dateStartFormatString + '.'; 
        component.set("v.detailsDefaultHelpdeskEmpl", defaultTextForNewEmpl);
    },

    getDetailHelpdeskBlockEmpl : function(component, event, helper) {
        var blockUserVar = $('#blockUser').val();
        var dateTimeBlockEmpl = component.find('dateBlockEmployee').get("v.value");
        var dateTimeBlockFormat = new Date(dateTimeBlockEmpl);
        var dateBlockFormatString = dateTimeBlockFormat.toLocaleDateString("en-US", 
        {
            year: "numeric", 
            month: "short",
            day: "numeric"
        });
        var timeBlockFormatString = dateTimeBlockFormat.toLocaleTimeString();
        var defaultTextForBlockEmpl = 'Заблокируйте, пожалуйста, все аккаунты сотрудника - ' + blockUserVar + '.\nДата и время блокировки: ' + dateBlockFormatString + ' ' + timeBlockFormatString;
        component.set("v.detailsDefaultHelpdeskBlockEmpl", defaultTextForBlockEmpl);
    },

    getProjectAttribute : function(component, event, helper) {
        component.set("v.detailsDefaultHelpdesk", '');
        var getProjectFromSelect = component.find("inputSelectProject").get("v.value");
        var getProjectAtt = component.get("c.getProjectAttributes");

        getProjectAtt.setParams(
            {
                "projectName": getProjectFromSelect
            }
        );

        getProjectAtt.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.jiraKey", response.getReturnValue().jiraKey);
            }
        });
        $A.enqueueAction(getProjectAtt); 

    },

    handleComponentEventFromLookup : function(component, event, helper) {
        var selectedUserGetFromEvent = event.getParam("userByEvent");
        var selectedTypeUserGetFromEvent = event.getParam("typeUser");

        if(selectedTypeUserGetFromEvent === 'ProjectManager') {
            component.set("v.projectManagerUser", selectedUserGetFromEvent);
        } else {
            component.set("v.accountManagerUser", selectedUserGetFromEvent);
        }
    },

    handleComponentEvent : function(component, event, helper) {
        var typeRequestHelpdeskVar = component.get("v.typeRequestHelpdesk");
        var userName = component.get("v.currentUser");
        var selectedAccountGetFromEvent = event.getParam("userByEvent");
        var selectedNameGetFromEvent = event.getParam("userByEvent").Name;
        var selectedEmailGetFromEvent = event.getParam("userByEvent").Email;
        var outputTextEvt = '"' + selectedNameGetFromEvent + '"' + ' <' + selectedEmailGetFromEvent + '>\n';
        if(typeRequestHelpdeskVar === 'Team Project Access') {
            component.set("v.detailsDefaultHelpdesk", '');
            var getProjectFromSelect = component.find("inputSelectProject").get("v.value");
            var jiraKey = component.get("v.jiraKey");
            var headerText = 'Здравствуйте,\n' + 'предоставьте, пожалуйста, доступ к проекту ' + getProjectFromSelect + ' в JIRA & Confluence.\n' + 'Project key: ' + jiraKey + ' для всех нижеперечисленных:'; 
        } else {
            component.set("v.detailsHelpdeskNewProjectV", '');
            var projectManagerUserObj = component.get("v.projectManagerUser");
            var projectAccountUserObj = component.get("v.accountManagerUser");
            var outputTextForManagerEvt = '"' + projectManagerUserObj.Name + '"' + ' <' + projectManagerUserObj.Email + '>\n';
            var outputTextForAccountEvt = '"' + projectAccountUserObj.Name + '"' + ' <' + projectAccountUserObj.Email + '>\n';
            var getProjectFromSelect = component.find("inputSelectNewProject").get("v.value");
            var headerText = 'Здравствуйте,\n' + 'создайте, пожалуйста, новый проект ' + getProjectFromSelect + ' в JIRA & Confluence.\n' + 'Предоставьте права для:\n\nProject Manager: ' + outputTextForManagerEvt + 'Account Manager: ' + outputTextForAccountEvt + '\nДля нижеперечисленных пользователей:'; 
            
        }
        var footerText = 'Заранее благодарю.\n\n' + 'Best regards,\n' + userName; 
        var classProjectArray = getProjectFromSelect.split(' ');
        var classProject = '';
        for(var i=0; i<classProjectArray.length;i++){
            classProject += classProjectArray[i];
        }
        var listUsersInfo = [];
        $A.createComponent(
            "input",
            {
                "type":"text",
                "value": outputTextEvt,
                "class": classProject,
                "style":"display: none",
                "aura:id":"inputForDefaultText"
            },
            function(newButton, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newButton);
                    component.set("v.body", body);
                }
            }
        );


        $('.' + classProject).each(function() {
          listUsersInfo.push($(this).val());
        });
        listUsersInfo.push(outputTextEvt);
        var resultDetailsHelpdesk = headerText + '\n\n';
        for(var i=0;i<listUsersInfo.length;i++) {
            resultDetailsHelpdesk += listUsersInfo[i]+ '\n';
        }
        resultDetailsHelpdesk += footerText;
        if(typeRequestHelpdeskVar === 'Team Project Access') {
            component.set("v.detailsDefaultHelpdesk", resultDetailsHelpdesk);
        } else {
            component.set("v.detailsHelpdeskNewProjectV", resultDetailsHelpdesk); 
        }

    },

    cancelHelpdesk : function(component, event, helper) {
        helper.cancelHelpdeskHlp(component, helper);
    },

    cancelInit : function(component, event, helper) {
        $('#main-page').show();
        $('#helpdesk-container').hide();   
    },

    submitHelpdesk : function(component, event, helper) {
        var typeRequestHelpdeskVar = component.get("v.typeRequestHelpdesk");
        if(typeRequestHelpdeskVar === 'Team Project Access') {
            helper.submitHelpdesk(component,'Add access');
        }
        else if(typeRequestHelpdeskVar === 'New Employee') {
            helper.submitHelpdesk(component,'New Employee');
        }
        else if(typeRequestHelpdeskVar === 'Block Employee') {
            helper.submitHelpdesk(component,'Block Employee'); 
        }
        else if(typeRequestHelpdeskVar === 'New Project') {
            helper.submitHelpdesk(component,'New Project'); 
        }
    },
    
    backToHomeHelpdesk : function(component, event, helper) {
        $('#afterSubmitHelpdesk').hide();
        helper.cancelHelpdeskHlp(component, helper);   
    },

    onMultiSelectProjectChange: function(component) {
        var selectProjectCmp = component.find("inputSelectProjectMult").get("v.value");
        component.set("v.projectMultiple", selectProjectCmp);
     },

     onMultiSelectTeamChange: function(component) {
         var selectTeamCmp = component.find("selectAccountTeamTempo").get("v.value");
         component.set("v.teamTempoMultiple", selectTeamCmp);
     },
})