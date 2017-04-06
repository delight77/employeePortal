trigger Request on Request__c (before update, after update, before insert, after insert) {
    RequestHandler handler = new RequestHandler(trigger.New, Trigger.OldMap, Trigger.isUpdate);
    if (Trigger.isBefore && Trigger.isInsert) {
        handler.handleRequestUsersFieldsPut(trigger.New);
    } else if(Trigger.isBefore) {
        handler.handleVacationDaysPut(trigger.New);
        handler.handleVacationContactPut(trigger.New);
        handler.handleRequestCreateTasks(trigger.New, trigger.OldMap, trigger.isUpdate);
    } else if (Trigger.isAfter) {
        handler.handleRequestCallApprovalProccess(trigger.New, trigger.OldMap);
        handler.handleRequestSalaryChangeCreateTasks(trigger.New, trigger.isUpdate);    
        handler.handleRequestCreateShares(trigger.New, trigger.Old, trigger.isUpdate, trigger.isInsert);
    }
}