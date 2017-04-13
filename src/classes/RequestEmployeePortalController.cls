public with sharing class RequestEmployeePortalController {  
    public static final List<String> RQUESTS_NAME_FOR_HELPDESK = new List<String> {'Team_Project_Access', 'Block_Employee', 'New_Employee', 'New_Project'};
    public static final List<String> RQUESTS_NAME_FOR_REQUEST_MANAGER = new List<String> {'Vacation', 'Sick-List', 'Helpdesk'};
    public static final List<String> RQUESTS_NAME_FOR_REQUEST_EMPLOYEER = new List<String> {'Vacation', 'Sick-List', 'Helpdesk'};
    public static final String ACCOUNTANT_NAME = 'Olga Tristen';

    public static Id getRecordTypeId(String objectName, String recordTypeName) {
        return [SELECT Id FROM RecordType WHERE Sobjecttype = :objectName AND Name = :recordTypeName LIMIT 1].Id;
    }

    public static User getLoggedUser() {
        User currentUser = [SELECT Id, Profile.Name, Profile.Id, Name FROM User WHERE Id = :Userinfo.getUserId()];
        return currentUser;
    }

    public static void sendEmail(String[] addresses, String emailBody, String subject) {
        try {
            Messaging.reserveSingleEmailCapacity(2);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setCharset('UTF-8');
            mail.setToAddresses(addresses);
            mail.setSubject(subject);
            mail.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
        } catch(DmlException dmlEx) {
            System.debug('Email Failed: ' + dmlEx);
        }
        catch(System.EmailException emlEx) {
            System.debug('Email Failed: ' + emlEx);
        }
        
    }


    @AuraEnabled
    public static List<String> getCurrentContactInfo() {
        Id currentUserId = UserInfo.getUserId();
        List<String> contactInfo = new List<String>();
        PHG_ReportVacationController.ContactsWrapper contactWrapper = PHG_ReportVacationController.computeContactsDates(currentUserId);
        contactInfo.add(String.valueOf(contactWrapper.VacationYearStart));
        contactInfo.add(String.valueOf(contactWrapper.VacationYearEnd));
        contactInfo.add(String.valueOf(contactWrapper.DaysAccrued));
        contactInfo.add(String.valueOf(contactWrapper.DaysSpent));
        contactInfo.add(String.valueOf(contactWrapper.DaysRemaining));

        return contactInfo;
    }

    @AuraEnabled
    public static List<String> getHelpdeskTypes() {
        
        List<String> requestTypes = new List<String>();
        List<RecordType> recordTypeRequestList = new List<RecordType>();
        String recordTypeRequestListSoql = 
        'SELECT Id, Name ' +
            'FROM RecordType ' +
            'WHERE Sobjecttype = \'Request__c\' ' +
            'AND DeveloperName IN :RQUESTS_NAME_FOR_HELPDESK';
        recordTypeRequestList = Database.query(recordTypeRequestListSoql);
        for (RecordType recordTypeRequest : recordTypeRequestList) {
            requestTypes.add(String.valueOf(recordTypeRequest.Name));
        }
        return requestTypes;
    }

    @AuraEnabled
    public static List<String> getTeams() {
        
        List<String> accountTeams = new List<String>();
        List<Account> accounts = new List<Account>();
        Id recordId = getRecordTypeId('Account','Team');
        accounts = [SELECT Id, Name FROM Account WHERE RecordTypeId = :recordId];
        for (Account acc : accounts) {
            accountTeams.add(String.valueOf(acc.Name));
        }
        return accountTeams;
    }

    @AuraEnabled
    public static List<String> getRoles() {
        List<String> userRolesString = new List<String>();
        List<UserRole> userRoles = new List<UserRole>();
        userRoles = [SELECT Id, Name FROM UserRole];
        for (UserRole role : userRoles) {
            userRolesString.add(String.valueOf(role.Name));
        }
        return userRolesString;
    }

    @AuraEnabled
    public static List<String> getProjects() {
        List<String> projectNames = new List<String>();
        List<NEW_Project__c> projects = [SELECT  Id, Name FROM NEW_Project__c];
        for (NEW_Project__c project : projects) {
            projectNames.add(String.valueOf(project.Name));
        }
        return projectNames;
    }

    @AuraEnabled
    public static String getCurrentUser() {
      User user = getLoggedUser();
      return user.Name;
    }

    @AuraEnabled
    public static HelpdeskLetterWrap getProjectAttributes(String projectName) {
        NEW_Project__c project = [SELECT Id, JIRA_Key__c FROM NEW_Project__c WHERE Name = :projectName LIMIT 1];
        HelpdeskLetterWrap helpdeskWrap  = new HelpdeskLetterWrap(String.valueOf(project.JIRA_Key__c));
        return helpdeskWrap;
    }

    @AuraEnabled
    public static List<String> getRequestTypes() {
        User currentLoggedInUser = getLoggedUser();
        String profleName = currentLoggedInUser.Profile.Name;
        List<String> requestTypes = new List<String>();
        List<RecordType> recordTypeRequests = new List<RecordType>();
        // for test: in future Helpdesk will not visible for employee!
        if (profleName == 'HR Manager') {
            String recordTypeRequestListSoql = 
            'SELECT Id, Name ' +
                'FROM RecordType ' +
                'WHERE Sobjecttype = \'Request__c\' ' +
                'AND Name IN :RQUESTS_NAME_FOR_REQUEST_MANAGER';
            recordTypeRequests = Database.query(recordTypeRequestListSoql);
        }
        else {
            String recordTypeRequestListSoql = 
            'SELECT Id, Name ' +
                'FROM RecordType ' +
                'WHERE Sobjecttype = \'Request__c\' ' +
                'AND Name IN :RQUESTS_NAME_FOR_REQUEST_EMPLOYEER';
            recordTypeRequests = Database.query(recordTypeRequestListSoql);
        } 
        for (RecordType recordTypeRequest : recordTypeRequests) {
            requestTypes.add(String.valueOf(recordTypeRequest.Name));
        }

        return requestTypes;
    }

    @AuraEnabled
    public static String submitApprove(String vacationStartDate, String vacationEndDate, String details, Boolean paid, Map<String,String> projectUsers) {
        List<NEW_Project_Replacement_Resource__c> projectReplResources = new List<NEW_Project_Replacement_Resource__c>();
        Id recordId = getRecordTypeId('Request__c', 'Vacation');
        User currentLoggedInUser = getLoggedUser();
        Contact currentContact = [SELECT Id FROM Contact WHERE Employee_User__c = :currentLoggedInUser.Id LIMIT 1];
        AggregateResult[] groupedResultsProject = [
            SELECT COUNT(Project_Manager__c) project_cnt  
            FROM NEW_Project__c
            WHERE Id IN(
                SELECT Project__c 
                FROM NEW_Project_Resource__c 
                WHERE Resource__c = :currentContact.Id
            )
        ];
        Request__c newRequestVacation = new Request__c (
            Name = 'Vacation request',
            Vacation_Start__c = Date.valueOf(vacationStartDate),
            Vacation_End__c = Date.valueOf(vacationEndDate),
            Details__c = details,
            Paid__c = paid,
            RecordTypeId = recordId,
            Status__c = 'New',
            Count_Approval__c = Integer.valueOf(groupedResultsProject[0].get('project_cnt')),
            Count_Real_Approval__c = 0
        );
        insert newRequestVacation;

        for (String projectName : projectUsers.keySet()) {
            String userName = projectUsers.get(projectName);
            User userForReplacement = [SELECT Id FROM User WHERE Name = :userName LIMIT 1];
            NEW_Project__c projectForReplacement = [SELECT Id FROM NEW_Project__c WHERE Name = :projectName];

            NEW_Project_Replacement_Resource__c newProjectResourcesReplacement = new NEW_Project_Replacement_Resource__c (
                Name = 'Project replacement',
                Project__c = projectForReplacement.Id,
                User__c = userForReplacement.Id,
                Request__c = newRequestVacation.Id,
                Status__c = 'Wait',
                Description__c = projectName + ' - ' + userName
            );
            projectReplResources.add(newProjectResourcesReplacement);

        }
        System.debug(projectReplResources);
        insert projectReplResources;

        List<NEW_Project__c> projects = [
            SELECT Id, Project_Manager__c  
            FROM NEW_Project__c
            WHERE Id IN(
                SELECT Project__c 
                FROM NEW_Project_Resource__c 
                WHERE Resource__c = :currentContact.Id
            )
        ];
        List<Approval.ProcessSubmitRequest> submitRequestList = new List<Approval.ProcessSubmitRequest>();

        for (NEW_Project__c prj : projects) {
            Approval.ProcessSubmitRequest reqProccess = new Approval.ProcessSubmitRequest();
            reqProccess.setObjectId(newRequestVacation.Id);
            reqProccess.setNextApproverIds(new Id[] {[SELECT Id FROM User WHERE Id IN(SELECT Employee_User__c FROM Contact WHERE Id = :prj.Project_Manager__c)].Id});
            submitRequestList.add(reqProccess);
        }
        List<Approval.ProcessResult> results = Approval.process(submitRequestList);
        return 'success';
    }

    @AuraEnabled
    public static String submitApproveHelpdesk(String details) {
        Id recordId = getRecordTypeId('Request__c', 'Helpdesk');
        Request__c newRequestHelpdesk = new Request__c(
            Name = 'Helpdesk request',
            Status__c = 'New',
            Details__c = details,
            RecordTypeId = recordId
        );
        insert newRequestHelpdesk;

        Profile sysAdmProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User sysAdm = [SELECT id, Email FROM User WHERE ProfileId = :sysAdmProfile.Id AND IsActive = true LIMIT 1];
        String[] toAddresses = new String[] {sysAdm.Email};

        sendEmail(toAddresses, details, 'Helpdesk request');

        return 'success';
    }

    @AuraEnabled
    public static String submitApproveSickList(String details, String sickListStart, String sickListEnd) {
        Id recordId = getRecordTypeId('Request__c', 'Sick-List');
        Request__c newRequestSick = new Request__c(
            Name = 'Sick list request',
            Status__c = 'New',
            Details__c = details,
            Sick_List_Start__c = Date.valueOf(sickListStart),
            Sick_List_End__c = Date.valueOf(sickListEnd),
            RecordTypeId = recordId
        );
        insert newRequestSick;

        List<String> emailManagerList = new List<String>();

        User currentLoggedInUser = getLoggedUser();
        Contact currentContact = [SELECT Id FROM Contact WHERE Employee_User__c = :currentLoggedInUser.Id LIMIT 1];
        List<NEW_Project__c> projects = [
            SELECT Id, Project_Manager__c  
            FROM NEW_Project__c
            WHERE Id IN(
                SELECT Project__c 
                FROM NEW_Project_Resource__c 
                WHERE Resource__c = :currentContact.Id
            )
        ];
     
        emailManagerList.add([SELECT Email FROM User WHERE Name = :ACCOUNTANT_NAME LIMIT 1].Email);
        for (NEW_Project__c prj : projects) {
            if (prj.Project_Manager__c != NULL) {
                emailManagerList.add([SELECT Email FROM User WHERE Id IN(SELECT Employee_User__c FROM Contact WHERE Id = :prj.Project_Manager__c)].Email);    
            } 
        }

        sendEmail(emailManagerList, details, 'Sick list request');

        return 'success';
    }

    @AuraEnabled
    public static List<String> getProjectsForUser() {
        List<String> userProjectList = new List<String>();
        User currentLoggedInUser = getLoggedUser();
        Contact currentContact = [SELECT Id FROM Contact WHERE Employee_User__c = :currentLoggedInUser.Id LIMIT 1];
        List<NEW_Project__c> projects = [
            SELECT Id, Name  
            FROM NEW_Project__c
            WHERE Id IN(
                SELECT Project__c 
                FROM NEW_Project_Resource__c 
                WHERE Resource__c = :currentContact.Id
            )
        ];
      
        for(NEW_Project__c prj : projects) {
            userProjectList.add(prj.Name);
        }

        return userProjectList;
    }

    @AuraEnabled  
    public static ApprovalList getApprovalData() {   
        ApprovalList approvalResultForObject = new ApprovalList();  
        List<ApprovalStepWrapper> aprovalSWList = new List<ApprovalStepWrapper>();  
        String recallApprovalProcessLink;  
        Boolean isSubmitForApproval = true;  
        for(ProcessInstance pI : getProcessHistory().values())  
        {  
            Map<Id,List<ProcessInstanceHistory>> mapOfProcessNodeIdAndProcessInstanceHistory = new Map<Id,List<ProcessInstanceHistory>>();  
            Set<Id> processNodeId = new Set<Id>();  
            for(ProcessInstanceHistory sWI : pI.StepsAndWorkitems)  
            {  
                if(processNodeId.size() == 0) {
                    processNodeId.add(sWI.ProcessNodeId);  
                }
                else if(processNodeId.size() > 0 && processNodeId.contains(sWI.ProcessNodeId)!= NULL) {
                    processNodeId.add(sWI.ProcessNodeId);  
                }
            }  
            for(Id pNId: processNodeId)  
            {  
                ApprovalStepWrapper approvalSWr = new ApprovalStepWrapper();  
                for(ProcessInstanceHistory sWI : pI.StepsAndWorkitems)  
                {  
                    if(sWI.processNodeId == pNID) {  
                        approvalSWr.listOfSteps.add(new ApprovalHistoryWrap(sWI.CreatedDate, sWI.OriginalActor.Name, sWI.StepStatus,sWI.Actor.Name, sWI.TargetObject.Name));  
                    }  
                    if(sWI.StepStatus == 'Pending') {  
                        isSubmitForApproval = false;  
                    }  
                }  
                aprovalSWList.add(approvalSWr);  
            }  
        }  
        approvalResultForObject.approvals = aprovalSWList;   
        approvalResultForObject.isSubmitForApproval = isSubmitForApproval;  
        return approvalResultForObject;  
    }  

    /*  
    * This method queries the processinstance and workitem for the record   
    * Returns: Map of all processinstance related to the record id  
    */  
    @AuraEnabled  
    public static Map<Id,ProcessInstance> getProcessHistory() {  
        User currentLoggedInUser = getLoggedUser();
        return new Map<Id,ProcessInstance>(
            [
                SELECT Id, (
                            SELECT  ID, 
                                    ProcessNodeId, 
                                    StepStatus,
                                    Comments,
                                    TargetObjectId,
                                    ActorId,
                                    CreatedById,
                                    IsDeleted,
                                    IsPending,
                                    OriginalActorId,
                                    ProcessInstanceId,
                                    RemindersSent,
                                    CreatedDate,
                                    Actor.Name,  
                                    OriginalActor.Name, 
                                    ProcessNode.Name,
                                    TargetObject.Name 
                            FROM StepsAndWorkitems 
                            WHERE OriginalActor.Name = :currentLoggedInUser.Name 
                            ORDER BY CreatedDate DESC 
                            LIMIT 1
                            )   
                FROM ProcessInstance 
                ORDER BY CreatedDate DESC 
                LIMIT 10
            ]
        );  
    }

    /*  
    * Wrapper class  
    */  
    public class ApprovalStepWrapper {  
        @AuraEnabled  
        public List<ApprovalHistoryWrap> listOfSteps {get;set;}  
        public ApprovalStepWrapper() {  
            listOfSteps = new List<ApprovalHistoryWrap>();  
        }  
    }  

    /*  
    * Wrapper class  
    */  
    @TestVisible
    public class ApprovalHistoryWrap {  
        @AuraEnabled  
        public Date createdDate { get; set; }  
        @AuraEnabled  
        public String createdDateStr { get; set; }
        @AuraEnabled  
        public String actorName { get; set; }  
        @AuraEnabled  
        public String steps { get; set; }  
        @AuraEnabled  
        public String assignedTo { get; set; } 
        @AuraEnabled  
        public String objectName { get; set; }  
        public ApprovalHistoryWrap(DateTime crDate, String name, String stp, String actor, String objectNamePar)  
        {  
            createdDate = crDate.date();
            createdDateStr = DateTime.newInstance(createdDate.year(),createdDate.month(),createdDate.day()).format('MMM d, yyyy');
            actorName = name;  
            steps = stp;  
            assignedTo = actor; 
            objectName = objectNamePar;
        }  
    }

    /*  
    * Wrapper class  
    */  
    @TestVisible
    public class ApprovalList {   
        @AuraEnabled  
        public List<ApprovalStepWrapper> approvals { get; set; }  
        @AuraEnabled    
        public Boolean isSubmitForApproval { get; set; }  
        @AuraEnabled  
        public Id recordId { get; set; }  
        public ApprovalList() {  
            approvals = new List<ApprovalStepWrapper>();  
            isSubmitForApproval = true;  
        }  
    }
    @TestVisible
    public class HelpdeskLetterWrap {  
        @AuraEnabled  
        public String jiraKey { get; set; }  
        public HelpdeskLetterWrap(String jiraKey) {  
            this.jiraKey = jiraKey;   
        }  
    }  
}