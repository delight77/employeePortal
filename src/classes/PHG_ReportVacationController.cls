public with sharing class PHG_ReportVacationController {

	public static Integer DaysDefaultAccrued { get {return 15;} set;}
	public static Date reportDate { get {return system.today();} set;}

	public PHG_ReportVacationController(PHG_ReportController ctrl) {}

	@RemoteAction
	@TestVisible public static List<ContactsWrapper> computeContactsDates(String accountId, String departmentId) {
		List<ContactsWrapper> result = computeContactsDates(accountId, departmentId, '');
		return result;
	}

	@TestVisible public static ContactsWrapper computeContactsDates(String userId) {
		List<ContactsWrapper> result = computeContactsDates('', '', userId);
		if (result.size() == 1) {
			return result[0];
		} else {
			return NULL;
		}
	}

	@TestVisible public static List<ContactsWrapper> computeContactsDates() {
		List<ContactsWrapper> result = computeContactsDates('', '', '');
		return result;
	}

	@TestVisible public static List<ContactsWrapper> computeContactsDates(Map<Id, Contact> contacts, Map<Id, Date> contactDateMap) {
		List<Contact> allContacts = contacts.values();
		List<Date> dates = contactDateMap.values();
		dates.sort();
		Date startDate = dates[0].addYears(-1).addDays(1);
		Date endDate = dates[dates.size() - 1];

		Set<Id> userids = new Set<Id>();
		List<ContactsWrapper> allContactsWrapper = new List<ContactsWrapper>();
		for (Contact cc : allContacts) {
			Integer additionalDays = 0;
			ContactsWrapper contactWrapper = new ContactsWrapper();
			contactWrapper.contact = cc;
			contactWrapper.VacationYearEnd = contactDateMap.get(cc.Id);		
			contactWrapper.VacationYearStart = contactWrapper.VacationYearEnd.addYears(-1).addDays(1);

			// count additional days
			for (Employee_Additional_Info__c dayAdded : cc.Employee_Additional_Info__r) {
				if (dayAdded.Date__c >= contactWrapper.VacationYearStart && dayAdded.Date__c <= contactWrapper.VacationYearEnd) {
					additionalDays += (Integer) dayAdded.Days__c;
				}
			}
			contactWrapper.DaysAdded = additionalDays;
			allContactsWrapper.add(contactWrapper);
			userids.add(cc.Employee_User__c);
		}

		List<Request__c> vacationRequests = getVacationRequests(startDate, endDate, userids);
		
		Map<Id,List<Request__c>> contactIdRequestsMap = new Map<Id,List<Request__c>>();
		for (Contact cont : contacts.values()) {
			List<Request__c> contactRequests = new List<Request__c>();
			for (Request__c vacationReq : vacationRequests) {
				if (cont.Employee_User__c == vacationReq.OwnerId && vacationReq.Vacation_Start__c > contactDateMap.get(cont.Id).addYears(-1).addDays(1)) {
					contactRequests.add(vacationReq);

				}
			}
			contactIdRequestsMap.put(cont.Id, contactRequests);
		}

		Set<Date> nationalHolidays = getHolidays(startDate, endDate);

		for (ContactsWrapper cw : allContactsWrapper) {
			cw.DaysAccrued = DaysDefaultAccrued + cw.DaysAdded;
			cw.DaysSpent = 0;
			cw.DaysRemaining = cw.DaysAccrued;
			if (contactIdRequestsMap.get(cw.contact.Id).size() > 0) {
				Integer countDays = 0;
				for (Request__c vacationReq : contactIdRequestsMap.get(cw.contact.Id)) {
					if (vacationReq.Vacation_Start__c >= cw.VacationYearStart) {
						countDays += daysBetweenExcludingWeekends(vacationReq.Vacation_Start__c, vacationReq.Vacation_End__c, nationalHolidays);
					}
				}
				cw.DaysSpent = countDays;
				cw.DaysRemaining = cw.DaysAccrued - cw.DaysSpent;
			}
		}
		return allContactsWrapper;
	}

	@TestVisible private static List<ContactsWrapper> computeContactsDates(String accountId, String departmentId, String userId) {
		List<Contact> allContacts = new List<Contact>();
		Map<Id, User> availableUsers = new Map<Id, User>([SELECT Id, Email, SmallPhotoUrl FROM User WHERE isActive = true]);
		String SOQLquery = 'SELECT Id, Name, Email, Employee_User__c, Birthdate, Hired_Date__c, PHG_Department__r.Head_Of_Department__c, PHG_Department__r.Head_Of_Department__r.Email, ' +
								+ ' (SELECT Days__c, Date__c FROM Employee_Additional_Info__r ORDER BY Name DESC) ' +
								+ ' FROM Contact ' +
								+ ' WHERE RecordType.DeveloperName = \'Employee\' AND Hired_Date__c != NULL AND Employee_Status__c = \'Hired\' AND Employee_User__c != NULL AND PHG_Department__r.Location__c = \'Offshore\' ';
		if ( !String.isBlank(userId) && !userId.equalsIgnoreCase('all') ) {
			SOQLquery += ' AND Employee_User__c = \''+String.escapeSingleQuotes(userId)+'\'';
		}
		if ( !String.isBlank(accountId) && !accountId.equalsIgnoreCase('all') ) {
			SOQLquery += ' AND AccountID = \''+String.escapeSingleQuotes(accountId)+'\'';
		}
		if ( !String.isBlank(departmentId) && !departmentId.equalsIgnoreCase('all')) {
			SOQLquery += ' AND PHG_Department__c IN (SELECT Id FROM PHG_Department__c WHERE Id = \''+String.escapeSingleQuotes(departmentId)+'\')';
		}
		SOQLquery += ' ORDER BY Name';
		
		//allContacts = Database.query(SOQLquery);
		allContacts = HelperWithoutSharing.getUserRelatedContacts(SOQLquery, availableUsers.keySet());
		Date minWorkingYearStartDate = system.today();
		Set<Id> userids = new Set<Id>();
		List<ContactsWrapper> allContactsWrapper = new List<ContactsWrapper>();

		for (Contact cc : allContacts) {
			Integer additionalDays = 0;
			ContactsWrapper contactWrapper = new ContactsWrapper();
			Map<String, Date> period = countVacationPeriodYTD(cc);
			if (period.get('begin') <= minWorkingYearStartDate) {
				minWorkingYearStartDate = period.get('begin');
			}
			contactWrapper.contact = cc;
			contactWrapper.VacationYearStart = period.get('begin');
			contactWrapper.VacationYearEnd = period.get('end');

			//count significant dates
			period = countEmployeesignificantDatesYTD(cc);

			contactWrapper.EmployeeBirthdayYTD = period.get('birthdate');
			contactWrapper.EmployeeBirthdayYearsCount = (contactWrapper.EmployeeBirthdayYTD != NULL) ?
				getOrdinalNumeralsEndings(contactWrapper.EmployeeBirthdayYTD.year() - cc.Birthdate.Year()) : NULL;
			contactWrapper.EmployeeAnniversaryYTD = period.get('anniversary');
			contactWrapper.EmployeeAnniversaryYearsCount = (contactWrapper.EmployeeAnniversaryYTD != NULL) ?
				getOrdinalNumeralsEndings(contactWrapper.EmployeeAnniversaryYTD.year() - cc.Hired_Date__c.Year()) : NULL;
			contactWrapper.EmployeeHired90Days = period.get('hired90');
			contactWrapper.EmployeeHired180Days = period.get('hired180');

			// count additional days
			for (Employee_Additional_Info__c dayAdded : cc.Employee_Additional_Info__r) {
				if (dayAdded.Date__c >= contactWrapper.VacationYearStart && dayAdded.Date__c <= contactWrapper.VacationYearEnd) {
					additionalDays += (Integer) dayAdded.Days__c;
				}
			}
			contactWrapper.DaysAdded = additionalDays;
			allContactsWrapper.add(contactWrapper);
			userids.add(cc.Employee_User__c);
		}

		List<Request__c> vacationRequests = getVacationRequests(minWorkingYearStartDate, reportDate, userids);
		
		Map<Id,List<Request__c>> contactIdRequestsMap = new Map<Id,List<Request__c>>();
		for (ContactsWrapper cw : allContactsWrapper) {
			List<Request__c> contactRequests = new List<Request__c>();
			for (Request__c vacationReq : vacationRequests) {
				if (cw.contact.Employee_User__c == vacationReq.OwnerId ) {
					contactRequests.add(vacationReq);
				}
			}
			contactIdRequestsMap.put(cw.contact.Id, contactRequests);
		}
		Set<Date> nationalHolidays = getHolidays(minWorkingYearStartDate, system.today());

		for (ContactsWrapper cw : allContactsWrapper) {
			cw.DaysAccrued = DaysDefaultAccrued + cw.DaysAdded;
			cw.DaysSpent = 0;
			cw.DaysRemaining = cw.DaysAccrued;
			if (contactIdRequestsMap.get(cw.contact.Id).size() > 0) {
				Integer countDays = 0;
				for (Request__c vacationReq : contactIdRequestsMap.get(cw.contact.Id)) {
					if (vacationReq.Vacation_Start__c >= cw.VacationYearStart) {
						countDays += daysBetweenExcludingWeekends(vacationReq.Vacation_Start__c, vacationReq.Vacation_End__c, nationalHolidays);
					}
				}
				cw.DaysSpent = countDays;
				cw.DaysRemaining = cw.DaysAccrued - cw.DaysSpent;
			}
		}
		return allContactsWrapper;
	}

	//method return vacation request from start date to end date for users
	@TestVisible private static List<Request__c> getVacationRequests (Date start, Date finish, Set<Id> userids) {
		return [
			SELECT OwnerId, Owner.Name, Vacation_Start__c, Vacation_End__c, Paid__c
			FROM Request__c
			WHERE RecordType.DeveloperName = 'Vacation'
			AND (
				Vacation_Start__c >= :start //AND Vacation_Start__c <= :finish
			)
			AND Is_Approved__c = true
			AND OwnerId IN :userids
			AND Paid__c = true
		];
	}

	//method count anniversaryYTD, birthdayYTD, 90 and 180 worked days
	//Keys: birthdate, hired90, hired180, anniversary
	@TestVisible private static Map<String, Date> countEmployeesignificantDatesYTD(Contact CurrentContact) {
		Map<String, Date> result = new Map<String, Date>();
		Date startDate = System.today();
		Date tmpDate = System.today();
		//Birthday
		if (CurrentContact.Birthdate != NULL) {
			if (startDate.year() != CurrentContact.Birthdate.year()) {
				tmpDate = Date.newInstance(startDate.year(), CurrentContact.Birthdate.month(), CurrentContact.Birthdate.day());
				result.put('birthdate', tmpDate);
			}
		}
		//hired90 hired180
		tmpDate = CurrentContact.Hired_Date__c.addMonths(3);
		result.put('hired90', tmpDate);
		tmpDate = CurrentContact.Hired_Date__c.addMonths(6);
		result.put('hired180', tmpDate);

		//anniversaryYTD
		if ((startDate.year() != CurrentContact.Hired_date__c.year())) {
			tmpDate = Date.newInstance(startDate.year(), CurrentContact.Hired_date__c.month(), CurrentContact.Hired_date__c.day());
			result.put('anniversary', tmpDate);
		} else {
			result.put('anniversary', NULL);
		}

		return result;
	}

	//method get Ordinal Numerals Endings
	@TestVisible private static String getOrdinalNumeralsEndings(Integer num) {
		if (num.format().endsWith('11')) return num + '-th';
		if (num.format().endsWith('12')) return num + '-th';
		if (num.format().endsWith('13')) return num + '-th';
		if (num.format().endsWith('1')) return num + '-st';
		if (num.format().endsWith('2')) return num + '-nd';
		if (num.format().endsWith('3')) return num + '-rd';
		return num + '-th';
	}

	//method returns map with Vacation Year Start, Vacation Year End
	//Keys: begin, end
	@TestVisible public static Map<String, Date> countVacationPeriodYTD(Contact CurrentContact) {
		Map<String, Date> periodYTD = new Map<String, Date>();
		Date startDate = System.today();
		Date dueDate = System.today(); //if use reportDate may be can get period for different date than today
		Integer numberDaysDue = 0;
		startDate = Date.newInstance(startDate.year(), CurrentContact.Hired_date__c.month(), CurrentContact.Hired_date__c.day());
		numberDaysDue = startDate.daysBetween(dueDate);
		Boolean isHiredDateInFuture = (CurrentContact.Hired_date__c > dueDate);
		if (isHiredDateInFuture) {
			periodYTD.put('begin', CurrentContact.Hired_date__c);
			periodYTD.put('end', CurrentContact.Hired_date__c.addYears(+1).addDays(-1));
		} else if (numberDaysDue >= 0) {
			periodYTD.put('begin', startDate);
			periodYTD.put('end', startDate.addYears(+1).addDays(-1));
		} else if (numberDaysDue < 0) {
			periodYTD.put('begin', startDate.addYears(-1));
			periodYTD.put('end', startDate.addDays(-1));
		}
		return periodYTD;
	}

	/*public static Map<String, Date> countOldVacationPeriodYTD(Contact CurrentContact, Date start, Date end) {
		Map<String, Date> periodYTD = new Map<String, Date>();
		Date startDate = System.today();
		Date dueDate = System.today();
	}*/

	@TestVisible private static Integer daysBetweenExcludingWeekends(Datetime startDate, Datetime endDate, Set<Date> nationalHolidays) {
		Integer i = 0;
		while (startDate <= endDate) { // && startDate <= system.today()) {
			if (startDate.format('EEE') != 'Sat' && startDate.format('EEE') != 'Sun' && !nationalHolidays.contains(startDate.date())) {
				i = i + 1;
			}
			startDate = startDate.addDays(1);
		}
		return i;
	}

	@TestVisible private static Set<Date> getHolidays(Date startDate, Date endDate) {
		Set<Date> result = new Set<Date>();
		for (National_Holiday__c nh : [SELECT Date__c FROM National_Holiday__c WHERE Date__c >= : startDate AND Date__c <= :endDate]) {
			result.add(nh.Date__c);
		}
		return result;
	}

	public class ContactsWrapper {
		public Contact contact {get; set;}

		public Date VacationYearStart { get; set; }
		public Date VacationYearEnd { get; set; }

		public Date EmployeeBirthdayYTD{ get; set; }
		public String EmployeeBirthdayYearsCount{ get; set; }
		public Date EmployeeAnniversaryYTD { get; set; }
		public String EmployeeAnniversaryYearsCount { get; set; }
		public Date EmployeeHired90Days { get; set; }
		public Date EmployeeHired180Days { get; set; }


		public Integer DaysWorkedOut { get; set; }
		public Integer ReqCount { get; set; }
		public Integer DaysAccrued { get; set; }
		public Integer DaysAdded { get; set; }
		public Integer DaysSpent { get; set;}
		public Integer DaysRemaining { get; set;}
	}
}