@isTest
private class MyTimeSettingsControllerTest {

    @isTest static void testGetSettings_NoSettings() {
        // Ensure no MyTime_Settings__c records exist
        delete [SELECT Id FROM MyTime_Settings__c];

        Test.startTest();
        MyTime_Settings__c settings = MyTimeSettingsController.getSettings();
        Test.stopTest();

        System.assertNotEquals(null, settings, 'Settings should not be null');
        // When no org defaults exist, default values should be set
        System.assertEquals(null, settings.Days_Off__c);
    }

    @isTest static void testGetSettings_WithSettings() {
        MyTime_Settings__c setting = new MyTime_Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            Days_Off__c = 7,
            Hours_per_week__c = 38,
            Illnesses__c = 2,
            Salary_Day_number_of_day__c = 20,
            Taxes__c = 15,
            Vacancies__c = 1,
            Budget__c = 80
        );
        insert setting;

        Test.startTest();
        MyTime_Settings__c result = MyTimeSettingsController.getSettings();
        Test.stopTest();

        System.assertEquals(null, result.Days_Off__c);

    }

    

    @isTest static void testGetAllowedDomains_NoSettings() {
        delete [SELECT Id FROM MyTime_Settings__c];

        Test.startTest();
        String domains = MyTimeSettingsController.getAllowedDomains();
        Test.stopTest();

        System.assertEquals(null, domains, 'No settings exist, so allowed domains should be null');
    }

    @isTest static void testGetAllowedDomains_WithSettings() {
        MyTime_Settings__c setting = new MyTime_Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            Allowed_Domains__c = 'test.com'
        );
        insert setting;

        Test.startTest();
        String domains = MyTimeSettingsController.getAllowedDomains();
        Test.stopTest();

        System.assertEquals('test.com', domains);
    }
}