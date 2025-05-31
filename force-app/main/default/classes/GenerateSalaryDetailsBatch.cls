global class GenerateSalaryDetailsBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RatePerHour__c
            FROM External_User__c
            WHERE RatePerHour__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<External_User__c> users) {
        Date startOfLastMonth = Date.today().toStartOfMonth().addMonths(-1);
        Date endOfLastMonth = Date.today().toStartOfMonth().addDays(-1);

        Set<Id> userIds = new Set<Id>();
        Map<Id, Decimal> userRates = new Map<Id, Decimal>();

        for (External_User__c user : users) {
            userIds.add(user.Id);
            userRates.put(user.Id, user.RatePerHour__c);
        }

        // Aggregate hours per user from Report__c
        // Map<Id, Decimal> userHours = new Map<Id, Decimal>();
        // for (AggregateResult ar : [
        //     SELECT External_User__c extId, SUM(Hours__c) total
        //     FROM Report__c
        //     WHERE External_User__c IN :userIds
        //     AND Date__c >= :startOfLastMonth AND Date__c <= :endOfLastMonth AND TaskType__c != 'Day Off'
        //     GROUP BY External_User__c
        // ]) {
        //     userHours.put((Id) ar.get('extId'), (Decimal) ar.get('total'));
        // }

        Map<Id, Decimal> userHours = new Map<Id, Decimal>();
        for (Report__c report : [
            SELECT External_User__c, Hours__c, Minutes__c
            FROM Report__c
            WHERE External_User__c IN :userIds
            AND Date__c >= :startOfLastMonth AND Date__c <= :endOfLastMonth
            AND TaskType__c != 'Day Off'
        ]) {
            if (report.External_User__c == null) continue;
            
            Decimal totalTime = (report.Hours__c != null ? report.Hours__c : 0) +
                        (report.Minutes__c != null ? report.Minutes__c : 0) / 60;

            if (!userHours.containsKey(report.External_User__c)) {
                userHours.put(report.External_User__c, 0);
            }
            userHours.put(report.External_User__c, userHours.get(report.External_User__c) + totalTime);
        }


        // Aggregate compensation from Request__c
        Map<Id, Decimal> userCompensations = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT External_User__c extId, SUM(Budget__c) total
            FROM Request__c
            WHERE Type__c = 'Compensation'
            AND External_User__c IN :userIds
            AND Date__c >= :startOfLastMonth AND Date__c <= :endOfLastMonth
            GROUP BY External_User__c
        ]) {
            userCompensations.put((Id) ar.get('extId'), (Decimal) ar.get('total'));
        }

        List<Salary_Detail__c> detailsToInsert = new List<Salary_Detail__c>();

        for (Id userId : userIds) {
            Decimal rate = userRates.get(userId);
            Decimal hours = userHours.get(userId) != null ? userHours.get(userId) : 0;
            Decimal compensation = userCompensations.get(userId) != null ? userCompensations.get(userId) : 0;

            if (hours == 0 && compensation == 0) continue;

            Decimal amount = hours * rate;
            MyTime_Settings__c settings = MyTime_Settings__c.getOrgDefaults();
            Decimal taxRate = (settings != null && settings.Taxes__c != null) ? settings.Taxes__c : 20;
            Decimal tax = amount * (taxRate / 100);
            
            detailsToInsert.add(new Salary_Detail__c(
                External_User__c = userId,
                Date__c = startOfLastMonth,
                Amount__c = amount,
                Tax__c = tax,
                Rate__c = rate,
                Hours__c = hours,
                Compensation__c = compensation
            ));
        }

        if (!detailsToInsert.isEmpty()) {
            insert detailsToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: log or notify
    }
}