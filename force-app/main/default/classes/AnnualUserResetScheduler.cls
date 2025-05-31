global class AnnualUserResetScheduler implements Schedulable {
    global void execute(SchedulableContext context) {
        Date today = Date.today();
        Integer day = today.day();
        Integer month = today.month();
        Integer year = today.year();

        List<External_User__c> usersToReset = [
            SELECT Id, FirstWorkingDate__c,
                   Used_Vacations__c, Used_Illnesses__c,
                   Used_Days_Off__c, Used_Budget__c
            FROM External_User__c
            WHERE 
                FirstWorkingDate__c != NULL
        ];

        List<External_User__c> updates = new List<External_User__c>();

        for (External_User__c user : usersToReset) {
            Date startDate = user.FirstWorkingDate__c;
            if (startDate.day() == day && startDate.month() == month) {
                // Only reset on the anniversary of the start date
                user.Used_Vacations__c = 0;
                user.Used_Illnesses__c = 0;
                user.Used_Days_Off__c = 0;
                user.Used_Budget__c = 0;
                updates.add(user);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}