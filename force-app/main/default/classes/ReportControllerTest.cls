@isTest
public class ReportControllerTest {
    
    @testSetup
    static void setup() {
        
         MyTime_Settings__c settings = new MyTime_Settings__c(
            Days_Off__c = 10,
            Hours_per_week__c = 40,
            Illnesses__c = 5,
            Salary_Day_number_of_day__c = 15,
            Taxes__c = 20,
            Vacancies__c = 3,
            Budget__c = 90,
            Allowed_Domains__c = 'example.com'
        );
        insert settings;
        // Create External_User__c records
        External_User__c user1 = new External_User__c(
            Name = 'Test User 1',
            Email__c = 'testuser1@example.com',
            IsManager__c = false,
            IsHR__c = false,
            Role__c = 'Developer'
        );
        insert user1;

        External_User__c manager = new External_User__c(
            Name = 'Manager User',
            Email__c = 'manager@example.com',
            IsManager__c = true,
            Role__c = 'Manager'
        );
        insert manager;

        // Create Project__c records
        Project__c project1 = new Project__c(
            Name = 'Project Alpha'
        );
        insert project1;

        Project__c socialProject = new Project__c(
            Name = 'Social package'
        );
        insert socialProject;

        // Create Report__c records
        Date today = Date.today();

        Report__c report1 = new Report__c(
            Date__c = today,
            Project__c = project1.Id,
            TaskType__c = 'Development',
            Description__c = 'Worked on feature X',
            Hours__c = 5,
            Minutes__c = 30,
            External_User__c = user1.Id,
            IsApproved__c = false
        );

        Report__c report2 = new Report__c(
            Date__c = today.addDays(-3),
            Project__c = socialProject.Id,
            TaskType__c = 'Social Work',
            Description__c = 'Community outreach',
            Hours__c = 3,
            Minutes__c = 0,
            External_User__c = user1.Id,
            IsApproved__c = true
        );

        insert new List<Report__c>{report1, report2};
    }
    
    @isTest
    static void testGetReportsByDate() {
        External_User__c user = [SELECT Id FROM External_User__c WHERE Name = 'Test User 1' LIMIT 1];
        Date today = Date.today();
        String isoDate = String.valueOf(today.year()) + '-' + 
                 (today.month() < 10 ? '0' + String.valueOf(today.month()) : String.valueOf(today.month())) + '-' + 
                 (today.day() < 10 ? '0' + String.valueOf(today.day()) : String.valueOf(today.day()));
        
        
        List<Report__c> reports = ReportController.getReportsByDate(isoDate, user.Id);
        System.assert(!reports.isEmpty(), 'Reports by date should not be empty');
        for (Report__c r : reports) {
            System.assertEquals(today, r.Date__c);
        }
    }
    
    @isTest
    static void testGetReportsByDatePeriod() {
        External_User__c user = [SELECT Id FROM External_User__c WHERE Name = 'Test User 1' LIMIT 1];
        Date fromDate = Date.today().addDays(-5);
        Date toDate = Date.today();
        List<Report__c> reports = ReportController.getReportsByDatePeriod(user.Id, fromDate, toDate);
        System.assert(!reports.isEmpty(), 'Reports by date period should not be empty');
        for (Report__c r : reports) {
            System.assert(r.Date__c >= fromDate && r.Date__c <= toDate);
            System.assertEquals(user.Id, r.External_User__c);
            System.assertNotEquals('Social package', r.Project__r.Name, 'Should exclude Social package projects');
        }
    }
    
    @isTest
    static void testGetSocialPackageReportsByDatePeriod() {
        External_User__c user = [SELECT Id FROM External_User__c WHERE Name = 'Test User 1' LIMIT 1];
        Date fromDate = Date.today().addDays(-10);
        Date toDate = Date.today();
        List<Report__c> reports = ReportController.getSocialPackageReportsByDatePeriod(user.Id, fromDate, toDate, 'Social Work');
        System.assert(!reports.isEmpty(), 'Social package reports should not be empty');
        for (Report__c r : reports) {
            System.assertEquals('Social package', r.Project__r.Name);
            System.assertEquals('Social Work', r.TaskType__c);
        }
    }
    
    @isTest
    static void testGetReportById() {
        Report__c report = [SELECT Id FROM Report__c LIMIT 1];
        Report__c fetchedReport = ReportController.getReportById(report.Id);
        System.assertEquals(report.Id, fetchedReport.Id);
    }
    
    @isTest
    static void testCreateReport() {
        External_User__c user = [SELECT Id FROM External_User__c WHERE Name = 'Test User 1' LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Project Alpha' LIMIT 1];
        Date today = Date.today();
		String isoDate = String.valueOf(today.year()) + '-' + 
                 (today.month() < 10 ? '0' + String.valueOf(today.month()) : String.valueOf(today.month())) + '-' + 
                 (today.day() < 10 ? '0' + String.valueOf(today.day()) : String.valueOf(today.day()));
        
        Test.startTest();
        ReportController.createReport(
            isoDate,
            project.Id,
            'Testing',
            'Created by testCreateReport',
            15,
            2,
            user.Id
        );
        Test.stopTest();
        
        List<Report__c> reports = [SELECT Id, Description__c FROM Report__c WHERE Description__c = 'Created by testCreateReport' LIMIT 1];
        System.assertEquals(1, reports.size(), 'New report should be created');
        delete reports;
    }
    
       @isTest
    static void testCreateReportWithoutInsert() {
        External_User__c user = [SELECT Id FROM External_User__c WHERE Name = 'Test User 1' LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Project Alpha' LIMIT 1];
        Date today = Date.today();
		String isoDate = String.valueOf(today.year()) + '-' + 
                 (today.month() < 10 ? '0' + String.valueOf(today.month()) : String.valueOf(today.month())) + '-' + 
                 (today.day() < 10 ? '0' + String.valueOf(today.day()) : String.valueOf(today.day()));
        
        Test.startTest();
        ReportController.createReportWithoutInsert(
            today,
            project.Id,
            'Testing',
            'Created by testCreateReport',
            15,
            2,
            user.Id
        );
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testUpdateReport() {
        Report__c report = [SELECT Id, Project__c, TaskType__c, Description__c FROM Report__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Project Alpha' LIMIT 1];
        
        Test.startTest();
        ReportController.updateReport(report.Id, project.Id, 'Updated Task', 'Updated Description', 45, 3);
        Test.stopTest();
        
        Report__c updated = [SELECT TaskType__c, Description__c, Minutes__c, Hours__c FROM Report__c WHERE Id = :report.Id];
        System.assertEquals('Updated Task', updated.TaskType__c);
        System.assertEquals('Updated Description', updated.Description__c);
        System.assertEquals(45, updated.Minutes__c);
        System.assertEquals(3, updated.Hours__c);
    }
    
    @isTest
    static void testDeleteReport() {
        Report__c report = [SELECT Id FROM Report__c LIMIT 1];
        
        Test.startTest();
        ReportController.deleteReport(report.Id);
        Test.stopTest();
        
        Integer countReports = [SELECT count() FROM Report__c WHERE Id = :report.Id];
        System.assertEquals(0, countReports, 'Report should be deleted');
    }
    
    @isTest
    static void testUpdateReportStatus() {
        Report__c report = [SELECT Id, IsApproved__c FROM Report__c LIMIT 1];
        Boolean originalStatus = report.IsApproved__c;
        
        Test.startTest();
        ReportController.updateReportStatus(report.Id, !originalStatus);
        Test.stopTest();
        
        Report__c updated = [SELECT IsApproved__c FROM Report__c WHERE Id = :report.Id];
        System.assertEquals(!originalStatus, updated.IsApproved__c, 'Report approval status should be updated');
    }
    
    @isTest
    static void testUpdateReportsStatusesByWeek() {
        Date fromDate = Date.today().addDays(-7);
        String isoFromDate = String.valueOf(fromDate.year()) + '-' + 
                 (fromDate.month() < 10 ? '0' + String.valueOf(fromDate.month()) : String.valueOf(fromDate.month())) + '-' + 
                 (fromDate.day() < 10 ? '0' + String.valueOf(fromDate.day()) : String.valueOf(fromDate.day()));
        Date toDate = Date.today();
        String isoToDate = String.valueOf(toDate.year()) + '-' + 
                 (toDate.month() < 10 ? '0' + String.valueOf(toDate.month()) : String.valueOf(toDate.month())) + '-' + 
                 (toDate.day() < 10 ? '0' + String.valueOf(toDate.day()) : String.valueOf(toDate.day()));
        
        Test.startTest();
        ReportController.updateReportsStatusesByWeek(isoFromDate, isoToDate, true);
        Test.stopTest();
        
        List<Report__c> reports = [SELECT IsApproved__c, Date__c FROM Report__c WHERE Date__c >= :fromDate AND Date__c <= :toDate];
        for (Report__c r : reports) {
            System.assertEquals(true, r.IsApproved__c, 'All reports within the week should be approved');
        }
    }
}