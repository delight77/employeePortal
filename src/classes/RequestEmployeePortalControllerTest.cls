@isTest
private class RequestEmployeePortalControllerTest {
    private static String SOFTWARE_Developer_ROLE = 'Software Developer';

    @testSetup 
    static void setUpTestData() {
        User admin = TestHelper.createUser('System Administrator', 'admint', 'adminusertest@testorg.com', null);
        User employeeEnhanced = TestHelper.createUser('Employee Enhanced', 'empl1', 'employeeManager@testorg.com', null);
        User resourceUser = TestHelper.createUser('Employee', 'empl2', 'employeeResource@testorg.com', employeeEnhanced);

        Account resourceAccount = TestHelper.createAccount('resource account', '');
        Contact resourceContact = TestHelper.createContact(resourceAccount, resourceUser, TestHelper.EMPLOYEE_RECORD_TYPE_ID);

        Account customerAccount = TestHelper.createAccount('test customer', 'Customer');
        Entity__c entity = TestHelper.createEntity('test entity', resourceContact);
        NEW_Client__c client = TestHelper.createClient(customerAccount, entity);
        NEW_Project__c project = TestHelper.createProject(client, resourceContact);

        NEW_Project_Resource__c projectResource = TestHelper.createProjectResource(project, resourceContact);
    }
    
    @isTest static void getHelpdeskTypesTest() {

        List<String> requestTypes = new List<String>();
        List<String> typeHelpdeskList = new List<String>();
        requestTypes.add('Block Employee');
        requestTypes.add('New Employee');
        requestTypes.add('New Project');
        requestTypes.add('Team Project Access');
        typeHelpdeskList = RequestEmployeePortalController.getHelpdeskTypes();
        System.assertNotEquals(NULL, typeHelpdeskList);
        for (Integer i=0; i<typeHelpdeskList.size();i++) {
            System.assertEquals(requestTypes[i], typeHelpdeskList[i]);
        }
    }

    @isTest static void getTeamTest() {
        // Implement test code
        Id recordTypeId = [SELECT Id FROM RecordType WHERE Sobjecttype = 'Account' AND Name = 'Team' LIMIT 1].Id;
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = recordTypeId    
        );
        insert testAccount;
        List<String> teams = RequestEmployeePortalController.getTeams();
        System.assertEquals(teams[0], 'Test Account');
    }

    @isTest static void getRolesTest() {
        List<UserRole> userRoles = [SELECT Id, Name FROM UserRole];
        List<String> roles = RequestEmployeePortalController.getRoles();
        System.assertEquals(roles.size(), userRoles.size());
    }

    @isTest static void getProjectsTest() {
        NEW_Project__c projectTest = [SELECT Id, Name FROM NEW_Project__c LIMIT 1];
        List<String> projs = RequestEmployeePortalController.getProjects();
        System.assertEquals(projs[0], projectTest.Name);
    }



    @isTest static void getCurrentUserTest() {
        System.assertNotEquals(NULL, RequestEmployeePortalController.getCurrentUser());  
    }

    @isTest static void getProjectAttTest() {
        NEW_Project__c project = [SELECT Id, JIRA_Key__c, Name FROM NEW_Project__c LIMIT 1];
        RequestEmployeePortalController.HelpdeskLetterWrap helpdeskWrap  = RequestEmployeePortalController.getProjectAttributes(String.valueOf(project.Name));
        System.assertEquals(helpdeskWrap.jiraKey, 'testkey');
    }


    @isTest static void getRequestTypesTest() {
        List<String> requestTypes = RequestEmployeePortalController.getRequestTypes();
        System.assertNotEquals(0, requestTypes.size());
    }

    @isTest static void submitApproveTest() {
        User currentUser = [SELECT Id, Profile.Name, Profile.Id, Name FROM User WHERE UserName = 'employeeResource@testorg.com' LIMIT 1];
        Contact currentContact = [SELECT Id FROM Contact WHERE Employee_User__c = :currentUser.Id LIMIT 1];
        List<NEW_Project__c> projects = [
            SELECT Id, Project_Manager__c  
            FROM NEW_Project__c
            WHERE Id IN(
                SELECT Project__c 
                FROM NEW_Project_Resource__c 
                WHERE Resource__c = :currentContact.Id
            )
        ];
        List<User> users = [SELECT Id FROM User WHERE Id IN(SELECT Employee_User__c FROM Contact WHERE Id = :projects[0].Project_Manager__c)];
        System.RunAs(currentUser) {
            String result = RequestEmployeePortalController.submitApprove(String.valueOf(System.today().addDays(-5)), String.valueOf(System.today()), 'Test', true);
            System.assertEquals(result, 'success');

            Request__c currentRequest = [SELECT Id, Count_Approval__c FROM Request__c WHERE Name = 'Vacation request'];
            System.assertEquals(1, currentRequest.Count_Approval__c);

            ProcessInstance pi = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :currentRequest.Id];
            System.assertNotEquals(NULL, pi);

            ProcessInstance processInstance = [
                SELECT Id, TargetObjectId, Status
                FROM ProcessInstance
                WHERE TargetObjectId = :currentRequest.Id
            ];
            ProcessInstanceWorkitem workItem = [
                SELECT Id, ProcessInstanceId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstanceId = :processInstance.Id
                LIMIT 1
            ];
            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
            request.setComments('Approving request.');
            request.setAction('Approve');
            request.setNextApproverIds(new Id[] { users[0].Id });
            request.setWorkitemId(workItem.Id);

            //approved resource
            Approval.process(request);

            Map<Id,ProcessInstance> piReq = RequestEmployeePortalController.getProcessHistory();
            System.assertNotEquals(NULL, piReq.values()[0]);

            RequestEmployeePortalController.ApprovalList approvalReq = RequestEmployeePortalController.getApprovalData();
            System.assertNotEquals(NULL, approvalReq);


        }
    }

    @isTest static void submitApproveHelpdeskTest() {
        String result = RequestEmployeePortalController.submitApproveHelpdesk('Test');
        Id recordId = RequestEmployeePortalController.getRecordTypeId('Request__c', 'Helpdesk');
        Request__c currentRequest = [SELECT Id, Details__c, RecordTypeId FROM Request__c WHERE Name = 'Helpdesk request'];
        System.assertEquals('success', result);
        System.assertNotEquals(NULL, currentRequest);
        System.assertEquals('Test', currentRequest.Details__c);
        System.assertEquals(recordId, currentRequest.RecordTypeId);
    }

    @isTest static void submitApproveSickListTest() {
        User currentUser = [SELECT Id, Profile.Name, Profile.Id, Name FROM User WHERE UserName = 'employeeResource@testorg.com' LIMIT 1];
        System.RunAs(currentUser) {
            String result = RequestEmployeePortalController.submitApproveSickList('Test', String.valueOf(System.today()), String.valueOf(System.today().addDays(5)));
            Id recordId = RequestEmployeePortalController.getRecordTypeId('Request__c', 'Sick-List');
            System.assertEquals('success', result);
            Request__c currentRequest = [SELECT Id, Details__c, RecordTypeId, Sick_List_Start__c, Sick_List_End__c FROM Request__c WHERE Name = 'Sick list request'];
            System.assertNotEquals(NULL, currentRequest);
            System.assertEquals(System.today(), currentRequest.Sick_List_Start__c);
            System.assertEquals(System.today().addDays(5), currentRequest.Sick_List_End__c);
            System.assertEquals('Test', currentRequest.Details__c);
            System.assertEquals(recordId, currentRequest.RecordTypeId);
        }
    }

    @isTest static void getProjectsForUserTest() {
        User currentUser = [SELECT Id, Profile.Name, Profile.Id, Name FROM User WHERE UserName = 'employeeResource@testorg.com' LIMIT 1];
        System.RunAs(currentUser) {
            List<String> projects = RequestEmployeePortalController.getProjectsForUser();
            System.assertEquals('TestProject', projects[0]);
        }
    }

    
}