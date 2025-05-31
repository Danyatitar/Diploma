global class SalaryDetailsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        MyTime_Settings__c settings = MyTime_Settings__c.getOrgDefaults();
        if (settings == null || settings.Salary_Day_number_of_day__c == null) return;

        Integer scheduledDay = Integer.valueOf(settings.Salary_Day_number_of_day__c);
        Date today = Date.today();

        if (today.day() == scheduledDay) {
            GenerateSalaryDetailsBatch batch = new GenerateSalaryDetailsBatch();
            Database.executeBatch(batch, 200);
        }
    }
}