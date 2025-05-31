@isTest
private class RequestControllerTest {

    @testSetup
    static void setupData() {
        
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
        // Create External User
         External_User__c user = new External_User__c(
            Name = 'Test User',
            Email__c = 'testuser1@example.com',
            IsManager__c = false,
            IsHR__c = false,
            Role__c = 'Developer'
        );
        insert user;
         Project__c socialProject = new Project__c(
            Name = 'Social package'
        );
        insert socialProject;

        // Create Requests for that user
        List<Request__c> requests = new List<Request__c>();

        // Vacation
        requests.add(new Request__c(
            StartDate__c = Date.today().addDays(-3),
            EndDate__c = Date.today().addDays(2),
            Status__c = 'Approved',
            Type__c = 'Vacation',
            External_User__c = user.Id,
            Duration__c = 4
        ));

        // Illness
        requests.add(new Request__c(
            StartDate__c = Date.today().addDays(-10),
            EndDate__c = Date.today().addDays(-8),
            Status__c = 'Pending',
            Type__c = 'Illness',
            External_User__c = user.Id,
            Duration__c = 2
        ));

        // Compensation
        requests.add(new Request__c(
            Date__c = Date.today().addDays(-1),
            Status__c = 'Approved',
            Type__c = 'Compensation',
            External_User__c = user.Id,
            Budget__c = 200,
            DocumentLink__c = 'https://example.com/doc',
            Subject__c = 'Extra work on weekend'
        ));

        insert requests;
    }

    @isTest
    static void testGetRequestsByDate() {
        External_User__c user = [SELECT Id FROM External_User__c LIMIT 1];

        List<Request__c> results = RequestController.getRequestsByDate(
            Date.today().addDays(-15),
            Date.today().addDays(5),
            user.Id
        );

        System.assert(results.size() > 0, 'Should return time off and compensation requests');
    }

    @isTest
    static void testGetAllRequests() {
        List<Request__c> results = RequestController.getAllRequests();
        System.assert(results.size() > 0, 'Should return approved non-compensation requests');
    }

    @isTest
    static void testCreateTimeOffRequest() {
        External_User__c user = [SELECT Id FROM External_User__c LIMIT 1];

        Test.startTest();
        RequestController.createTimeOffRequest(
            Date.today(),
            Date.today().addDays(2),
            user.Id,
            'Day Off'
        );
        Test.stopTest();

        List<Request__c> results = [
            SELECT Id, Type__c FROM Request__c
            WHERE External_User__c = :user.Id AND Type__c = 'Day Off'
        ];
        System.assertEquals(1, results.size(), 'Should create a time off request');
    }

    @isTest
    static void testCreateCompensationRequest() {
        External_User__c user = [SELECT Id FROM External_User__c LIMIT 1];

        Test.startTest();
        RequestController.createCompensationRequest(
            Date.today(),
            user.Id,
            150,
            'https://testlink.com',
            'Worked late'
        );
        Test.stopTest();

        List<Request__c> results = [
            SELECT Id, Type__c, Budget__c FROM Request__c
            WHERE External_User__c = :user.Id AND Type__c = 'Compensation' AND Budget__c = 150
        ];
        System.assertEquals(1, results.size(), 'Should create a compensation request');
        delete results;
    }

    @isTest
    static void testDeclineRequestStatus() {
        Request__c request = [SELECT Id, Status__c FROM Request__c WHERE Status__c = 'Pending' LIMIT 1];

        Test.startTest();
        RequestController.updateRequestStatus(request.Id, 'Declined');
        Test.stopTest();

        Request__c updated = [SELECT Status__c FROM Request__c WHERE Id = :request.Id];
        System.assertEquals('Declined', updated.Status__c, 'Status should be updated to Declined');
    }
    
       @isTest
    static void testApproveRequestStatus() {
        Request__c request = [SELECT Id, Status__c FROM Request__c WHERE Status__c = 'Pending' LIMIT 1];

        Test.startTest();
        RequestController.updateRequestStatus(request.Id, 'Approved');
        Test.stopTest();

        Request__c updated = [SELECT Status__c FROM Request__c WHERE Id = :request.Id];
        System.assertEquals('Approved', updated.Status__c, 'Status should be updated to Approved');
    }
}