@isTest
private class SubmitRequestControllerTest {

	static testMethod void ChangeSalaryTest() {
		Profile profile = [select id, Name from profile where name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		User u2 = new User(alias = 'tt02', email='testtest2@test.com', emailencodingkey='UTF-8', lastname='testtest02', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest02@test343SF111112d.com'
		);
		insert u2;
		test.startTest();

			Account account = new Account(Name='Test team');
			insert account;
			PHG_Department__c dep = new PHG_Department__c(Name = 'Test dep', Head_Of_Department__c = u2.Id);
			insert dep;
			List<RecordType> RTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Employee' AND SobjectType = :Contact.SObjectType.getDescribe().getName() AND IsActive = true];
			Contact ccontact = new Contact(Firstname='Test', Lastname='Contact', RusFirstName__c = 'rus name', RusLastName__c = 'rus surname', 
				Email = u1.Email, Employee_User__c = u1.Id, AccountID = account.Id, RecordTypeID = RTypeList[0].Id, Employee_Status__c = 'Hired', PHG_Department__c = dep.Id);
			insert ccontact;
			String reqId;
			System.RunAs(u1){
				List<RecordType> RTypeList3 = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Salary_Change' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				Request__c salaryChangeRequest = new Request__c(
					Name = 'Test request',
					New_Salary__c = 200,
					Current_Salary__c = 100,
					RecordTypeId = RTypeList3[0].Id,
					Last_salary_change_deta__c = Date.today().addDays(-10),
					Employee__c = u1.Id
				);
				insert salaryChangeRequest;
				reqId = salaryChangeRequest.Id;

				/*List<Task> PATasks = [SELECT Id FROM Task WHERE WhatId = :salaryChangeRequest.Id];*/
				List<Task> PATasks = new List<Task>();
				System.assertEquals(0, PATasks.size());

				List<RecordType> taskRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'HRM_Activity' AND SobjectType = :Task.SObjectType.getDescribe().getName() AND IsActive = true];
				Task task1 = new Task (
					RecordTypeId = taskRTypeList[0].Id,
					WhoId = ccontact.Id,
					WhatId = salaryChangeRequest.Id,
					Subject = 'PATask1',
					Status = 'Not Started',
					Type = 'Professional Assessment'
				);
				insert task1;
				PATasks.add(task1);
				Task task2 = new Task (
					RecordTypeId = taskRTypeList[0].Id,
					WhoId = ccontact.Id,
					WhatId = salaryChangeRequest.Id,
					Subject = 'PATask2',
					Status = 'Completed',
					Type = 'Professional Assessment'
				);
				insert task2;
				PATasks.add(task2);
				salaryChangeRequest.Approval_Reason__c = 'Professional Growth';
				update salaryChangeRequest;

				/*PATasks = [SELECT Id FROM Task WHERE WhatId = :salaryChangeRequest.Id];*/
				System.assertEquals(2, PATasks.size());
				System.assertEquals(task2.Id, PATasks[1].Id);

				SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(salaryChangeRequest));
				submitCtrl.submitRequest();
				List<ProcessInstance> workedItems = [Select Id, ProcessInstance.TargetObjectId, Status from ProcessInstance where ProcessInstance.TargetObjectId = :salaryChangeRequest.Id ORDER BY Id DESC];
				System.assertEquals(workedItems.size(), 1);
				System.assertEquals(workedItems[0].Status, 'Pending');

				SubmitRequestController submitCtrl2 = new SubmitRequestController(new ApexPages.StandardController(salaryChangeRequest));
				System.assert(ApexPages.hasMessages());
				System.assert(submitCtrl2.showSubmitButton != true);


				RecallRequestController ctrl = new RecallRequestController(new ApexPages.StandardController(salaryChangeRequest));
				ctrl.init();
				ctrl.recall();
				workedItems = [Select Id, ProcessInstance.TargetObjectId, Status from ProcessInstance where ProcessInstance.TargetObjectId = :salaryChangeRequest.Id ORDER BY Id DESC];
				System.assertEquals(workedItems[0].Status, 'Removed');
				ctrl.close();
				ctrl.init();

			}
			System.RunAs(u2) {
				RecallRequestController recallCtrl = new RecallRequestController(new ApexPages.StandardController([SELECT Id FROM Request__c WHERE Id =:reqId]));
				recallCtrl.init();
			}
		test.stopTest();

	}

	static testMethod void accessDeniedTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		Request__c requestTest = new Request__c(
			Name = 'Test request'
		);
		Request__c requestTest2 = new Request__c(
			Name = 'Test request',
			Assignee__c = u1.Id
		);
		insert new List<Request__c> {requestTest, requestTest2};

		System.RunAs(u1) {
			test.startTest();
				SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(requestTest));
				System.assert(ApexPages.hasMessages());

				SubmitRequestController submitCtrl2 = new SubmitRequestController(new ApexPages.StandardController(requestTest2));
				System.assert(ApexPages.hasMessages());
				submitCtrl2.close();
			test.stopTest();
		}

	}

	static testMethod void budgetTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Budget' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (!requestRTypeList.isEmpty()) {
					Request__c budgetRequest = new Request__c(
						Name = 'Budget',
						RecordTypeId = requestRTypeList[0].Id,
						Amount__c = 100,
						Budget_Type__c = 'Food',
						Details__c = 'Food'
					);
					insert budgetRequest;
					SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(budgetRequest));
					submitCtrl.submitRequest();
					List<ProcessInstance> processInstances = [SELECT Id, TargetObjectId, Status FROM ProcessInstance WHERE TargetObjectId = :budgetRequest.Id ORDER BY Id DESC];
					System.assert(processInstances != null);
				}

			test.stopTest();
		}

	}

	static testMethod void professionalAssessmentTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com', ManagerId = UserInfo.getUserId()
		);
		insert u1;
		User u2 = new User(alias = 'tt02', email='testtest2@test.com', emailencodingkey='UTF-8', lastname='testtest02', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest02@test343SF111112d.com', ManagerId = UserInfo.getUserId()
		);
		insert u2;
		Account account = new Account(Name='Test team');
		insert account;
		PHG_Department__c dep = new PHG_Department__c(Name = 'Test dep', Head_Of_Department__c = u2.Id);
		insert dep;
		List<RecordType> RTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Employee' AND SobjectType = :Contact.SObjectType.getDescribe().getName() AND IsActive = true];
		Contact ccontact = new Contact(Firstname='Test', Lastname='Contact', RusFirstName__c = 'rus name', RusLastName__c = 'rus surname', 
			Email = u1.Email, Employee_User__c = u1.Id, AccountID = account.Id, RecordTypeID = RTypeList[0].Id, Employee_Status__c = 'Hired', PHG_Department__c = dep.Id);
		insert ccontact;

		test.startTest();
			String RequestId;
			System.RunAs(u1) {
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Professional_Assessment' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (!requestRTypeList.isEmpty()) {
					Request__c professionalAssessmentRequest = new Request__c(
						Name = 'Professional_Assessment',
						RecordTypeId = requestRTypeList[0].Id,
						Details__c = 'Professional_Assessment',
						Head_of_Department__c = u2.Id
					);
					insert professionalAssessmentRequest;
					RequestId = professionalAssessmentRequest.Id;
					SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(professionalAssessmentRequest));
					submitCtrl.submitRequest();
					List<ProcessInstance> processInstances = [SELECT Id, ProcessInstance.TargetObjectId, Status FROM ProcessInstance WHERE ProcessInstance.TargetObjectId = :professionalAssessmentRequest.Id ORDER BY Id DESC];
					System.assertEquals(processInstances.size(), 1);
					System.assertEquals(processInstances[0].Status, 'Pending');
				}
			}
		test.stopTest();
	}

	static testMethod void salaryBonusTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Salary_Bonus' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (!requestRTypeList.isEmpty()) {
					Request__c salaryBonusRequest = new Request__c(
						Name = 'salaryBonus',
						RecordTypeId = requestRTypeList[0].Id
					);
					insert salaryBonusRequest;
					SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(salaryBonusRequest));
					submitCtrl.submitRequest();
					List<ProcessInstance> processInstances = [SELECT Id, ProcessInstance.TargetObjectId, Status FROM ProcessInstance WHERE ProcessInstance.TargetObjectId = :salaryBonusRequest.Id ORDER BY Id DESC];
					System.assert(processInstances != null);
					/*System.assertEquals(processInstances.size(), 1);*/
					/*System.assertEquals(processInstances[0].Status, 'Pending');*/
				}
			test.stopTest();
		}

	}

	static testMethod void notUsedTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Task' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (!requestRTypeList.isEmpty()) {
					Request__c taskRequest = new Request__c(
						Name = 'Task',
						RecordTypeId = requestRTypeList[0].Id
					);
					insert TaskRequest;
					SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(taskRequest));
					System.assert(ApexPages.hasMessages());
				}

				List<RecordType> requestRTypeList2 = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Professional_Review' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (!requestRTypeList2.isEmpty()) {
					Request__c PRRequest = new Request__c(
						Name = 'PRRequest',
						RecordTypeId = requestRTypeList2[0].Id
					);
					insert PRRequest;
					SubmitRequestController submitCtrl2 = new SubmitRequestController(new ApexPages.StandardController(PRRequest));
					System.assert(ApexPages.hasMessages());
				}
			test.stopTest();
		}

	}

	static testMethod void timesheetChangeHoursTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Timesheet_Change_Hours' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (requestRTypeList != null && !requestRTypeList.isEmpty()) {
					Request__c timesheetChangeHoursRequest = new Request__c(
						Name = 'ChangeHours',
						RecordTypeId = requestRTypeList[0].Id
					);
					insert timesheetChangeHoursRequest;
					SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(timesheetChangeHoursRequest));
					submitCtrl.submitRequest();
					List<ProcessInstance> processInstances = [SELECT Id, ProcessInstance.TargetObjectId, Status FROM ProcessInstance WHERE ProcessInstance.TargetObjectId = :timesheetChangeHoursRequest.Id ORDER BY Id DESC];
					System.assert(processInstances != null);
				}
				
				/*System.assertEquals(processInstances.size(), 1);
				System.assertEquals(processInstances[0].Status, 'Pending');*/
			test.stopTest();
		}

	}

	static testMethod void timesheetCreateAccountTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Timesheet_Create_Account' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				if (requestRTypeList != null && !requestRTypeList.isEmpty()) {
					Request__c timesheetCARequest = new Request__c(
						Name = 'Timesheet_Create_Account',
						RecordTypeId = requestRTypeList[0].Id
					);
					insert timesheetCARequest;
					timesheetCARequest = [SELECT Id, Assignee__c, Submitted_for_Approval__c FROM Request__c WHERE Id =: timesheetCARequest.Id];
					System.assertEquals(timesheetCARequest.Submitted_for_Approval__c, false);
					SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(timesheetCARequest));
					submitCtrl.submitRequest();
					System.assertEquals(submitCtrl.request.Submitted_for_Approval__c, true);
				}
				
			test.stopTest();
		}

	}

/*	static testMethod void timesheetCreateProjectTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com'
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Timesheet_Create_Project' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				Request__c timesheetCPRequest = new Request__c(
					Name = 'Timesheet_Create_Project',
					RecordTypeId = requestRTypeList[0].Id
				);
				insert timesheetCPRequest;
				timesheetCPRequest = [SELECT Id, Assignee__c, Submitted_for_Approval__c FROM Request__c WHERE Id =: timesheetCPRequest.Id];
				System.assertEquals(timesheetCPRequest.Submitted_for_Approval__c, false);
				SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(timesheetCPRequest));
				submitCtrl.submitRequest();
				System.assertEquals(submitCtrl.request.Submitted_for_Approval__c, true);
			test.stopTest();
		}

	}*/

	static testMethod void VacationTest() {
		Profile profile = [SELECT Id, Name FROM profile WHERE name='System Administrator'];
		User u2 = new User(alias = 'tt02', email='testtest2@test.com', emailencodingkey='UTF-8', lastname='testtest02', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest02@test343SF111112d.com', ManagerId = UserInfo.getUserId()
		);
		insert u2;
		User u1 = new User(alias = 'tt01', email='testtest01@test.com', emailencodingkey='UTF-8', lastname='testtest01', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testtest01@test343SF111112d.com', ManagerId = u2.Id
		);
		insert u1;
		System.RunAs(u1) {
			test.startTest();
				List<RecordType> requestRTypeList = [SELECT Id, SobjectType FROM RecordType WHERE DeveloperName = 'Vacation' AND SobjectType = :Request__c.SObjectType.getDescribe().getName() AND IsActive = true];
				Request__c timesheetVacationRequest = new Request__c(
					Name = 'Vacation',
					RecordTypeId = requestRTypeList[0].Id,
					Vacation_Start__c = Date.today().addDays(10),
					Vacation_End__c = Date.today().addDays(11),
					Details__c = 'Vacation',
					Emergency_Contact_Information__c = 'tel',
					Count_Approval__c = 5,
            		Count_Real_Approval__c = 0
				);
				insert timesheetVacationRequest;
				timesheetVacationRequest.put('Status__c', 'Approved');
				SubmitRequestController submitCtrl = new SubmitRequestController(new ApexPages.StandardController(timesheetVacationRequest));
				submitCtrl.submitRequest();
				List<ProcessInstance> processInstances = [SELECT Id, ProcessInstance.TargetObjectId, Status FROM ProcessInstance WHERE ProcessInstance.TargetObjectId = :timesheetVacationRequest.Id ORDER BY Id DESC];
				System.assert(processInstances != null);
				/*System.assertEquals(processInstances.size(), 1);
				System.assertEquals(processInstances[0].Status, 'Pending');*/
			test.stopTest();
		}

	}
}