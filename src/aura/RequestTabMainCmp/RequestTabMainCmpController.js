({
    
    doInit : function(component, event, helper) {
        component.set("v.vacationLabel", 'Vacation&PTO');
        component.set("v.sickLabel", 'Sick-List');
        component.set("v.helpdeskLabel", 'Helpdesk');
        helper.getApprovalList(component, event, helper);
        helper.getRequestList(component, event, helper);
        
    },

    onSelectChangeRequest : function(component, event, helper) {
        var idRequest = event.getSource().getLocalId();
        var evtSelectedRequest = $A.get("e.c:ChoiceRequestFromSelectEvt");
        evtSelectedRequest.setParams({ "ChoiceRequest": idRequest});
        evtSelectedRequest.fire();
        $('#main-page').hide(); 
    },

    getApprovalListFromEvent : function(component, event, helper) {
        var getApprovalListFromEvt = event.getParam("getApprovalList");
        component.set("v.approvalList", getApprovalListFromEvt);
    },
})