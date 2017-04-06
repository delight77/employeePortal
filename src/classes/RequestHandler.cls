public with sharing class RequestHandler {

    Set<Id> taskUsers = new Set<Id>();
    Set<Id> taskContacts = new Set<Id>();
    Map<String, Id> requestRecordTypesMap = new Map<String, Id>();
    Map<String, Id> taskRecordTypesMap = new Map<String, Id>();
    Set<Id> editVacationRequests = new Set<Id>();
    Set<String> employeesNames = new Set<String>();
    Set<Id> approvedVacationRequests = new Set<Id>();
    Set<Id> approvedRequestsUsers = new Set<Id>();
    Set<Id> userIds = new Set<Id>();
    Set<Id> ownerIds = new Set<Id>();
    List<Contact> contacts = new List<Contact>();
    Map<Id, Contact> userIdContactMap = new Map<Id, Contact>();
    Map<Id, Id> userMnagerMap = new Map<Id, Id>();
    Map<Id, List<Task>> contactTasksMap = new Map<Id, List<Task>>();

	public RequestHandler(List<Request__c> reqests, Map<Id,Request__c> oldMap, Boolean isUpdate) {
		for (RecordType rt : [
								SELECT Id, DeveloperName, SobjectType 
								FROM RecordType 
								WHERE IsActive = true 
									AND (
										SobjectType =:Request__c.SObjectType.getDescribe().getName() 
										OR SobjectType =:Task.SObjectType.getDescribe().getName()
									)
							]
			) {
	        if (rt.SobjectType == Request__c.SObjectType.getDescribe().getName()) {
	            requestRecordTypesMap.put(rt.DeveloperName, rt.Id);
	        }
	        else if (rt.SobjectType == Task.SObjectType.getDescribe().getName()) {
	            taskRecordTypesMap.put(rt.DeveloperName, rt.Id);
	        }
	    }
		for (Request__c rq : reqests) {
	        userIds.add(rq.OwnerId);
	        ownerIds.add(rq.OwnerId);
	        if (rq.Employee__c != NULL) {
	            userIds.add(rq.Employee__c);
	            if (rq.RecordTypeId == requestRecordTypesMap.get('Salary_Change') && !rq.Is_Approved__c && rq.Approval_Reason__c == 'Professional Growth') {
	                taskUsers.add(rq.Employee__c);
	            }
	        }

	        if (rq.RecordTypeId == requestRecordTypesMap.get('Vacation') && !rq.Is_Rejected__c) {
	            editVacationRequests.add(rq.Id);
	            if (rq.Is_Approved__c && isUpdate && !oldMap.get(rq.Id).Is_Approved__c) {
	                approvedVacationRequests.add(rq.Id);
	                approvedRequestsUsers.add(rq.OwnerId);
	            }
	        }
    	}	

	    String SOQLquery = 
	    'SELECT Id, Name, Hired_Date__c, Employee_User__c, PHG_Department__r.Name, PHG_Department__r.Head_Of_Department__c, Employee_User__r.ManagerId' +
	    ' FROM Contact WHERE Employee_User__c IN :userIds';
	    contacts = HelperWithoutSharing.getUserRelatedContacts(SOQLquery, userIds);
	    for (Contact c : contacts) {
	        userIdContactMap.put(c.Employee_User__c, c);
	        userMnagerMap.put(c.Employee_User__c, c.Employee_User__r.ManagerId);
	        if (approvedRequestsUsers.contains(c.Employee_User__c)) {
	            employeesNames.add(c.Name);
	        }
	        if (taskUsers.contains(c.Employee_User__c)) {
	            taskContacts.add(c.Id);
	        }
	    }
	    
	    if (!taskContacts.isEmpty()) {
	        for (Task userTask : [
                    SELECT Id, WhoId, WhatId, ActivityDate, Type
                    FROM Task 
                    WHERE RecordType.DeveloperName = 'HRM_Activity'
                        AND WhoId IN :taskContacts 
                        AND (
                        		(
	                        		Type = 'Professional Assessment' 
	                        		AND IsClosed = true
                        		) 
                        		OR 
                        		(
                        			Type = 'Personal Development Plan' 
                        			AND IsClosed = false
                        		)
                        	)
                    ORDER BY ActivityDate DESC
                ]
	            ) {
	            if (contactTasksMap.containsKey(userTask.WhoId)) {
	                contactTasksMap.get(userTask.WhoId).add(userTask);
	            } else {
	                contactTasksMap.put(userTask.WhoId, new List<Task>{userTask});
	            }
	        }
	    }
	}

	public void handleVacationDaysPut(List<Request__c> reqests) {
		Set<Date> NH = new Set<Date>();
        for (National_Holiday__c N : [SELECT Date__c FROM National_Holiday__c]) {
            NH.add(N.Date__c);
        }
        for (Request__c rq : reqests) {
            if (rq.RecordTypeId == requestRecordTypesMap.get('Vacation')) {
                rq.Vacation_Days__c = CalcDate(rq.Vacation_Start__c, rq.Vacation_End__c, NH);
            }
        }
        
	}

	public void handleVacationContactPut(List<Request__c> reqests) {
        Set<Id> OwnerIdSet = new Set<Id>();
        for (Request__c rq : reqests) {
            if (rq.RecordTypeId == requestRecordTypesMap.get('Vacation')) {
                OwnerIdSet.add(rq.OwnerId);
            }
        }
		Map<Id,Id> UserContact = new Map<Id,Id>();
        for (Contact c : [Select Id, Employee_User__c From Contact WHERE Employee_User__c IN :OwnerIdSet]) {
            UserContact.put(c.Employee_User__c, c.Id);
        }
        
        for (Request__c rq : reqests) {
            if (UserContact.containskey(rq.OwnerId) && rq.RecordTypeId == requestRecordTypesMap.get('Vacation')) {
                rq.Contact__c = UserContact.get(rq.OwnerId);
            }
        }
	}

	public void handleRequestUsersFieldsPut(List<Request__c> reqests) {
		for (Request__c rq : reqests) {
            if (userIdContactMap.containsKey(rq.OwnerId)) {
            	rq.Department_of_Creator__c = userIdContactMap.get(rq.OwnerId).PHG_Department__r.Name;
            }
            rq.Manager__c = rq.ManagerIdText__c;
            if (rq.Employee__c == NULL && rq.RecordTypeId != requestRecordTypesMap.get('Salary_Change')) {
                rq.Employee__c = rq.OwnerId;
            }
            if (rq.Employee__c != NULL && rq.RecordTypeId == requestRecordTypesMap.get('Sick_List') && userIdContactMap.containsKey(rq.Employee__c)) {
                rq.Contact__c = userIdContactMap.get(rq.Employee__c).Id;
                rq.Head_of_Department__c = userIdContactMap.get(rq.Employee__c) != NULL ? userIdContactMap.get(rq.Employee__c).PHG_Department__r.Head_Of_Department__c : NULL;
                rq.Manager__c = userMnagerMap.get(rq.Employee__c);
            }
            if (rq.Employee__c != NULL) {
                if (rq.RecordTypeId == requestRecordTypesMap.get('Salary_Change')) {
                    rq.Head_of_Department__c = userIdContactMap.get(rq.Employee__c) != NULL ? userIdContactMap.get(rq.Employee__c).PHG_Department__r.Head_Of_Department__c : NULL;
                }
            }
            if (rq.Head_of_Department__c == NULL) {
                rq.Head_of_Department__c = userIdContactMap.get(rq.OwnerId) != NULL ? userIdContactMap.get(rq.OwnerId).PHG_Department__r.Head_Of_Department__c : NULL;
            }
        }
	}
	public void handleRequestCreateTasks(List<Request__c> reqests, Map<Id,Request__c> oldMap, Boolean isUpdate) {
		Map<String, Set<String>> employeesWithProjects = new Map<String, Set<String>>();
        if (Trigger.isUpdate && !approvedVacationRequests.isEmpty()) {
            employeesWithProjects = HelperWithoutSharing.getProjectsByEmployeesNames (employeesNames);
        }
        //get all vacations request for checking vacations on overlapping
        Map<Id, List<Request__c>> ownerRequestsMap = new Map<Id, List<Request__c>>();
        if (!editVacationRequests.isEmpty()) {
            List<Request__c> existVacationRequests = [
                SELECT Id, Vacation_Start__c, Vacation_End__c, OwnerId
                FROM Request__c
                WHERE RecordType.DeveloperName = 'Vacation'
                    AND OwnerId IN: ownerIds
                    AND Id NOT IN: editVacationRequests
                    AND Is_Rejected__c = false
                LIMIT 1000
            ];
            for (Request__c oRequest : existVacationRequests) {
                if (ownerRequestsMap.containsKey(oRequest.OwnerId)) {
                    ownerRequestsMap.get(oRequest.OwnerId).add(oRequest);
                } else {
                    ownerRequestsMap.put(oRequest.OwnerId, new List<Request__c> { oRequest } );
                }
            }
        }
        List<Task> tasksForUpsert = new List<Task>();
        for (Request__c rq : reqests) {
            if (rq.RecordTypeId == requestRecordTypesMap.get('Salary_Change')) {
                if (rq.Is_Rejected__c) {
                    rq.Assignee__c = rq.Head_Of_Department__c;
                }
            }
            if (rq.Is_Rejected__c && rq.Assignee__c != rq.OwnerId && rq.Assignee__c != NULL) {
                if (rq.RecordTypeId != requestRecordTypesMap.get('Salary_Change')) {
                    rq.Assignee__c = NULL;
                }
            }

            //***********VACATION NEW WORKING YEAR OVERLAP***********//
            if (userIdContactMap.containsKey(rq.OwnerId) && userIdContactMap.get(rq.OwnerId).Hired_Date__c != NULL) {
                Map<String, Date> countVacationPeriodYTD = PHG_ReportVacationController.countVacationPeriodYTD(userIdContactMap.get(rq.OwnerId));
                if (rq.Vacation_Start__c <= countVacationPeriodYTD.get('end') && rq.Vacation_End__c > countVacationPeriodYTD.get('end')) {
                    rq.addError('The vacation request cannot extends into your the next working year. Please check End dates.');
                }
            }

            if (approvedVacationRequests.contains(rq.Id) && userIdContactMap.containsKey(rq.OwnerId)) {
                String empName = userIdContactMap.get(rq.OwnerId) != NULL ? userIdContactMap.get(rq.OwnerId).Name : '';
                if (isUpdate && !oldMap.get(rq.Id).Is_Approved__c && rq.Vacation_Start__c >= date.today()) {
                    if (!employeesWithProjects.isEmpty() && rq.Vacation_Start__c <= date.today().addDays(14) && rq.Vacation_Start__c > date.today()) {
                        for (String project :employeesWithProjects.get(empName)) {
                            Task knTransferTask = new Task();
                            knTransferTask.OwnerId = rq.OwnerId;
                            knTransferTask.ActivityDate = rq.Vacation_Start__c;
                            knTransferTask.WhoId = userIdContactMap.get(rq.OwnerId).Id;
                            knTransferTask.WhatId = rq.Id;
                            knTransferTask.Subject = 'Knowledge Transfer: ' + project;
                            knTransferTask.Description = 'Please choose a colleague in the \'Assigned To\' field to whom you want to transfer knowledge on the project.\nIf you accept to get this knowledge transfer, set the status of this task to Completed.';
                            knTransferTask.RecordTypeId = taskRecordTypesMap.get('Employee_Activity');
                            knTransferTask.Type = 'Knowledge Transfer';
                            knTransferTask.Status = 'In Progress';
                            tasksForUpsert.add(knTransferTask);
                        }
                    }

                    //Send Email Notification.
                    Task sendEmailTask = new Task();
                    sendEmailTask.Subject = 'Vacation Checklist: Send Email Notification';
                    sendEmailTask.Description = 'Please send an email notice to your colleagues letting them know that you\'re going to be out of the office.\nWhen you are done set the status of this task to Completed.';
                    sendEmailTask.Type = 'Vacation Checklist';
                    sendEmailTask.OwnerId = rq.OwnerId;
                    sendEmailTask.ActivityDate = rq.Vacation_Start__c;
                    sendEmailTask.WhoId = userIdContactMap.get(rq.OwnerId).Id;
                    sendEmailTask.WhatId = rq.Id;
                    sendEmailTask.RecordTypeId = taskRecordTypesMap.get('Employee_Activity');
                    sendEmailTask.Status = 'In Progress';
                    tasksForUpsert.add(sendEmailTask);

                    //Fill Timesheet.
                    if (rq.Paid__c == true) {
                        Task fillTimesheetTask = sendEmailTask.clone(true, false);
                        fillTimesheetTask.Subject = 'Vacation Checklist: Submit Timesheet';
                        fillTimesheetTask.Description = 'Please fill out and submit your Timesheet.\nWhen you are done set the status of this task to Completed.';
                        tasksForUpsert.add(fillTimesheetTask);
                    }


                    //Set Up Auto reply.
                    Task setAutoReply = sendEmailTask.clone(true, false);
                    setAutoReply.Subject = 'Vacation Checklist: Set up email Auto-reply';
                    setAutoReply.Description = 'Please set up an email auto reply in your email account when your vacation starts.\nWhen you are done set the status of this task to Completed.';
                    tasksForUpsert.add(setAutoReply);

                }
            }
        }
        if (!tasksForUpsert.isEmpty()) {
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.EmailHeader.TriggerUserEmail = true;
            Database.Insert(tasksForUpsert,dmlOptions);
        }
	}

	public void handleRequestCallApprovalProccess(List<Request__c> requests, Map<Id,Request__c> oldMap) {
		for (Request__c rq : requests) {
	        if (rq.RecordTypeId == requestRecordTypesMap.get('Vacation')) {
	        	String status = '';
	        	Map<Id,Request__c> requestMap = new Map<Id,Request__c>();
	        	requestMap = oldMap;
	        	if (requestMap != NULL) {
	        		status = requestMap.get(rq.Id).Status__c;
	        	}
	        	

	            if (rq.Count_Real_Approval__c == rq.Count_Approval__c && (status == rq.Status__c || status == '')) {
	                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
	                req1.setObjectId(rq.Id);
	                try {
	                    Approval.ProcessResult result = Approval.process(req1);
	                
	                } catch (Exception e) {
	                    System.debug(e.getMessage());
	                    
	                }
	            }
	        }
	    }
    }

    public void handleRequestSalaryChangeCreateTasks(List<Request__c> requests, Boolean isUpdate) {
    	List<Task> tasksPAForUpsert = new List<Task>();
		for (Request__c rq : requests) {
            if (rq.RecordTypeId == requestRecordTypesMap.get('Salary_Change')) {
                if (!rq.Is_Approved__c) {
                    if (rq.Approval_Reason__c == 'Professional Growth') {
                        List<Task> tasksPA = userIdContactMap.get(rq.Employee__c) != NULL ? contactTasksMap.get(userIdContactMap.get(rq.Employee__c).Id) : NULL;
                        Task taskPA;
                        Task taskPDP;
                        if (tasksPA != NULL) {
                            for (Task taskItem : tasksPA) {
                                if (taskItem.Type == 'Professional Assessment') {
                                    Boolean isOne = (taskItem.WhatId == rq.Id && isUpdate);
                                    Boolean isTwo = (taskPA == NULL && taskItem.WhatId == NULL);
                                    Boolean isThree = (taskPA != NULL && taskPA.WhatId == NULL && taskPA.ActivityDate < taskItem.ActivityDate && taskItem.WhatId == NULL);
                                    if (isOne || isTwo || isThree) {
                                        taskPA = taskItem;
                                    }
                                } else if (taskItem.Type == 'Personal Development Plan') {
                                    if (taskPDP == NULL) {
                                        taskPDP = taskItem;
                                        taskPDP.WhatId = rq.Id;
                                        tasksPAForUpsert.add(taskPDP);
                                    }
                                }
                            }
                        }
                        if (taskPA == NULL) {
                            rq.addError('Professional Assessment task not found for this employee. It should be created by HR prior creation of the the Salary Change request.');
                        }
                        else if (taskPA.ActivityDate < Date.today().addDays(-30)) {
                            rq.addError('Professional Assessment task has been expired.');
                        }
                        else if (taskPA.WhatId == NULL){
                            taskPA.WhatId = rq.Id;
                            tasksPAForUpsert.add(taskPA);
                        }
                    }
                }
            }
        }
        if (!tasksPAForUpsert.isEmpty()) {
            Database.Upsert(tasksPAForUpsert);
        }
    }
    
    public void handleRequestCreateShares(List<Request__c> requests, List<Request__c> requestsOld, Boolean isUpdate, Boolean isInsert) {
    	List<Request__Share> RequestShares = new List<Request__Share>();
        Integer cnt = 0;
        Set<Id> ShareReq = new Set<Id>();
        for (Request__c rq : requests) {
            if (Trigger.isInsert) {
                if (rq.Head_of_Department__c != NULL) {
                    Request__Share RequestShare = new Request__Share();
                    RequestShare.ParentId = rq.Id;
                    RequestShare.UserOrGroupId = rq.Head_of_Department__c;
                    RequestShare.AccessLevel = 'edit';
                    RequestShares.add(RequestShare);
                }
            }
            if ((isUpdate == true && rq.Assignee__c != NULL && requestsOld.get(cnt).Assignee__c != rq.Assignee__c) || (isInsert == true && rq.Assignee__c != NULL)) {
                Request__Share RequestShare = new Request__Share();
                RequestShare.ParentId = rq.Id;
                RequestShare.UserOrGroupId = rq.Assignee__c;
                RequestShare.AccessLevel = 'edit';
                RequestShares.add(RequestShare);
            }
            if (rq.Share_with_Approvers__c  == true && requestsOld.get(cnt).Share_with_Approvers__c == false) {
                ShareReq.add(rq.Id);
            }
            cnt++;
        }
        Database.SaveResult[] result = Database.Insert(RequestShares, false);
        List<ProcessInstanceStep> PIS_List = [Select SystemModstamp, StepStatus, ProcessInstance.TargetObjectId, ProcessInstanceId, OriginalActorId, Id, CreatedDate, CreatedById, Comments, ActorId From ProcessInstanceStep WHERE ProcessInstance.TargetObjectId IN :ShareReq];
    }

	public Integer CalcDate(Date DStart, Date DEnd, Set<Date> NH2) {
        Integer spent = 0;      
        while (DStart <= DEnd) {
            String dayOfWeek = DateTime.newInstance(DStart, Time.newInstance(0, 0, 0, 0)).format('EEEE');
            if (dayOfWeek != 'Sunday' && dayOfWeek != 'Saturday' && !NH2.contains(DStart)) {
                spent++;
            }
            DStart = DStart.addDays(1);        
        }
        return spent;
    }
}