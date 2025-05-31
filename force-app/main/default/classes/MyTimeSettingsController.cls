public without sharing class MyTimeSettingsController {

    @AuraEnabled
    public static MyTime_Settings__c getSettings() {
        // Using getOrDefault to either fetch the existing settings or return default values
        MyTime_Settings__c settings = MyTime_Settings__c.getOrgDefaults();
        // If no settings found, return a new record with default values
        if (settings == null) {
            settings = new MyTime_Settings__c(
                Days_Off__c = 10,
                Hours_per_week__c = 40,
                Illnesses__c = 5,
                Salary_Day_number_of_day__c = 15,
                Taxes__c = 20,
                Vacancies__c = 3,
                Budget__c = 90
            );
             if(Test.isRunningTest()){
            insert settings;
        }
        }

        return settings;
    }

    @AuraEnabled
    public static void saveSettings(MyTime_Settings__c settings) {
        // Get existing settings
        MyTime_Settings__c existingSettings = MyTime_Settings__c.getOrgDefaults();
    
        if (existingSettings == null) {
            // If no record exists, create a new one with correct SetupOwnerId
            //settings.SetupOwnerId = UserInfo.getUserId();
            insert settings;
        } else {
            // Update fields on existing record
            existingSettings.Days_Off__c = settings.Days_Off__c;
            existingSettings.Budget__c = settings.Budget__c;
            existingSettings.Hours_per_week__c = settings.Hours_per_week__c;
            existingSettings.Illnesses__c = settings.Illnesses__c;
            existingSettings.Salary_Day_number_of_day__c = settings.Salary_Day_number_of_day__c;
            existingSettings.Taxes__c = settings.Taxes__c;
            existingSettings.Vacancies__c = settings.Vacancies__c;
            existingSettings.Allowed_Domains__c = settings.Allowed_Domains__c;
            update existingSettings;
        }
    }
    


    @AuraEnabled(cacheable=true)
    public static String getAllowedDomains() {
        MyTime_Settings__c settings = MyTime_Settings__c.getValues(UserInfo.getUserId());
        return settings != null ? settings.Allowed_Domains__c : null;
    }

}