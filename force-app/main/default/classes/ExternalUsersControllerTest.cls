@isTest
private class ExternalUsersControllerTest {

    @testSetup
    static void setupTestData() {
        // Insert required MyTime_Settings__c for test context
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

        // Create test External_User__c records
        External_User__c hr = new External_User__c(Name = 'HR Person', Email__c = 'hr@example.com', IsHR__c = true);
        insert hr;

        External_User__c manager = new External_User__c(Name = 'Manager Person', Email__c = 'manager@example.com', IsManager__c = true);
        insert manager;

        External_User__c user = new External_User__c(
            Name = 'Test User',
            Email__c = 'testuser@example.com',
            Role__c = 'Developer',
            HR__c = hr.Id,
            Manager__c = manager.Id,
            IsHR__c = false,
            IsManager__c = false
        );
        insert user;
    }

    @isTest
    static void testGetAllExternalUsers() {
        List<External_User__c> users = ExternalUsersController.getAllExternalUsers();
        System.assert(users.size() > 0, 'Should return at least one user');
    }

    @isTest
    static void testGetAllExternalUsersByManager() {
        Id managerId = [SELECT Id FROM External_User__c WHERE IsManager__c = true LIMIT 1].Id;
        List<External_User__c> users = ExternalUsersController.getAllExternalUsersByManager(managerId);
        System.assert(users.size() > 0, 'Should return users with specified manager');
    }

    @isTest
    static void testGetExternalUserById() {
        External_User__c testUser = [SELECT Id FROM External_User__c WHERE Email__c = 'testuser@example.com' LIMIT 1];
        External_User__c user = ExternalUsersController.getExternalUserById(testUser.Id);
        System.assertEquals(testUser.Id, user.Id, 'User should match by Id');
    }

    @isTest
    static void testGetExternalUsersByIdBatch() {
        List<External_User__c> users = [SELECT Id FROM External_User__c LIMIT 2];
        Set<Id> ids = new Set<Id>();
        for (External_User__c u : users) ids.add(u.Id);

        Map<Id, External_User__c> result = ExternalUsersController.getExternalUsersByIdBatch(ids);
        System.assertEquals(users.size(), result.size(), 'All users should be returned in the map');
    }

    @isTest
    static void testGetUsersByFilters() {
        List<External_User__c> result = ExternalUsersController.getUsersByFilters(10, 1, 'Test', 'Developer', '', '');
        System.assert(result.size() > 0, 'Should return filtered users');
    }

    @isTest
    static void testGetTotalCount() {
        Integer count = ExternalUsersController.getTotalCount('Test', 'Developer', '', '');
        System.assert(count > 0, 'Should return total count > 0');
    }

    @isTest
    static void testGetManagers() {
        List<External_User__c> managers = ExternalUsersController.getManagers();
        System.assert(managers.size() > 0, 'Should return at least one manager');
    }

    @isTest
    static void testGetAllHRs() {
        List<External_User__c> hrs = ExternalUsersController.getAllHRs();
        System.assert(hrs.size() > 0, 'Should return at least one HR');
    }

    @isTest
    static void testSaveUser() {
        External_User__c newUser = new External_User__c(Name = 'Saved User', Email__c = 'save@example.com');
        Test.startTest();
        ExternalUsersController.saveUser(newUser);
        Test.stopTest();

        External_User__c saved = [SELECT Id, Email__c FROM External_User__c WHERE Email__c = 'save@example.com' LIMIT 1];
        System.assertNotEquals(null, saved, 'Saved user should exist');
    }
}