@isTest
private class AnnualUserResetSchedulerTest {

    @isTest static void testExecute_ResetsOnAnniversary() {
        // Prepare test data
        Date today = Date.today();
        Integer day = today.day();
        Integer month = today.month();
        Integer year = today.year();
        
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

        // User with anniversary today — fields should reset
        External_User__c userToReset = new External_User__c(
             Name = 'Test User 1',
            Email__c = 'testuser1@example.com',
            FirstWorkingDate__c = Date.newInstance(year - 1, month, day), // anniversary today last year
            Used_Vacations__c = 5,
            Used_Illnesses__c = 3,
            Used_Days_Off__c = 2,
            Used_Budget__c = 100
        );
        insert userToReset;

        // User with different anniversary — fields should NOT reset
        External_User__c userNotToReset = new External_User__c(
             Name = 'Test User 2',
            Email__c = 'testuser2@example.com',
            FirstWorkingDate__c = Date.newInstance(year - 1, month, day == 1 ? 2 : day - 1), // different day
            Used_Vacations__c = 7,
            Used_Illnesses__c = 4,
            Used_Days_Off__c = 1,
            Used_Budget__c = 200
        );
        insert userNotToReset;

        Test.startTest();
        // Schedule and run the job synchronously for testing
        AnnualUserResetScheduler scheduler = new AnnualUserResetScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Reload records
        userToReset = [SELECT Used_Vacations__c, Used_Illnesses__c, Used_Days_Off__c, Used_Budget__c FROM External_User__c WHERE Id = :userToReset.Id];
        userNotToReset = [SELECT Used_Vacations__c, Used_Illnesses__c, Used_Days_Off__c, Used_Budget__c FROM External_User__c WHERE Id = :userNotToReset.Id];

        // Assert that fields were reset for user with anniversary today
        System.assertEquals(0, userToReset.Used_Vacations__c, 'Vacations should be reset to 0');
        System.assertEquals(0, userToReset.Used_Illnesses__c, 'Illnesses should be reset to 0');
        System.assertEquals(0, userToReset.Used_Days_Off__c, 'Days Off should be reset to 0');
        System.assertEquals(0, userToReset.Used_Budget__c, 'Budget should be reset to 0');

        // Assert that fields were NOT reset for other user
        System.assertEquals(7, userNotToReset.Used_Vacations__c, 'Vacations should remain unchanged');
        System.assertEquals(4, userNotToReset.Used_Illnesses__c, 'Illnesses should remain unchanged');
        System.assertEquals(1, userNotToReset.Used_Days_Off__c, 'Days Off should remain unchanged');
        System.assertEquals(200, userNotToReset.Used_Budget__c, 'Budget should remain unchanged');
    }
}