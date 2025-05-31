@isTest
private class GenerateSalaryDetailsBatchTest {

    @testSetup
    static void setupTestData() {
        // Tax settings
        MyTime_Settings__c settings = new MyTime_Settings__c(
            Days_Off__c = 10,
            Hours_per_week__c = 40,
            Illnesses__c = 5,
            Salary_Day_number_of_day__c = Date.today().day(),
            Taxes__c = 15,
            Vacancies__c = 3,
            Budget__c = 90,
            Allowed_Domains__c = 'example.com'
        );
        insert settings;

        // External User with valid work data
        External_User__c activeUser = new External_User__c(
            Name = 'Active User',
            Email__c = 'active@example.com',
            RatePerHour__c = 50
        );
        insert activeUser;

        // External User with no activity
        External_User__c inactiveUser = new External_User__c(
            Name = 'Inactive User',
            Email__c = 'inactive@example.com',
            RatePerHour__c = 60
        );
        insert inactiveUser;
        
        Project__c project1 = new Project__c(
            Name = 'Project Alpha'
        );
        insert project1;

        Project__c socialProject = new Project__c(
            Name = 'Social package'
        );
        insert socialProject;

        // Date values
        Date startOfLastMonth = Date.today().toStartOfMonth().addMonths(-1);
        Date midOfLastMonth = startOfLastMonth.addDays(10);

        // Report for active user
        Report__c report = new Report__c(
            External_User__c = activeUser.Id,
            Project__c = project1.Id,
            Date__c = midOfLastMonth,
            TaskType__c = 'Work',
            Hours__c = 10,
            Minutes__c = 30
        );
        insert report;

        // Compensation request for active user
        Request__c req = new Request__c(
            External_User__c = activeUser.Id,
            Date__c = midOfLastMonth,
            Type__c = 'Compensation',
            Budget__c = 150
        );
        insert req;
    }

    @isTest
    static void testSalaryDetailCreatedForActiveUser() {
        Test.startTest();
                new SalaryDetailsScheduler().execute(null);

        Test.stopTest();

        List<Salary_Detail__c> details = [
            SELECT External_User__c, Rate__c, Hours__c, Compensation__c, Amount__c, Tax__c
            FROM Salary_Detail__c
        ];

        System.assertEquals(1, details.size(), 'One Salary_Detail__c should be created');

        Salary_Detail__c detail = details[0];
        System.assertEquals(50, detail.Rate__c, 'Rate should be 50');
        System.assertEquals(10.5, detail.Hours__c, 'Hours should be 10.5');
        System.assertEquals(150, detail.Compensation__c, 'Compensation should be 150');
        System.assertEquals(525, detail.Amount__c, 'Amount = 10.5 * 50');
        System.assertEquals(78.75, detail.Tax__c, 'Tax = 15% of 525');
    }

    @isTest
    static void testNoSalaryDetailCreatedForInactiveUser() {
        Id inactiveUserId = [SELECT Id FROM External_User__c WHERE Email__c = 'inactive@example.com' LIMIT 1].Id;

        Test.startTest();
        GenerateSalaryDetailsBatch batch = new GenerateSalaryDetailsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Salary_Detail__c> details = [
            SELECT Id FROM Salary_Detail__c WHERE External_User__c = :inactiveUserId
        ];
        System.assertEquals(0, details.size(), 'No Salary_Detail__c should be created for inactive user');
    }
}