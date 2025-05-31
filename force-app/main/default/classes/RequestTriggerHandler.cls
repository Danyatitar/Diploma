public without sharing class RequestTriggerHandler {


    public static void calculateDuration(List<Request__c> requests) {
        for (Request__c req : requests) {
            if (req.Type__c != 'Compensation' && req.StartDate__c != null && req.EndDate__c != null) {
                Integer duration = 0;
                Date currentDate = req.StartDate__c;
                while (currentDate <= req.EndDate__c) {
                    Integer dayOfWeek = currentDate.toStartOfWeek().daysBetween(currentDate); // 0 = Sunday, 6 = Saturday
                    if (dayOfWeek != 0 && dayOfWeek != 6) {
                        duration++;
                    }
                    currentDate = currentDate.addDays(1);
                }
                req.Duration__c = duration;
            }
        }
    }

    public static void handleAfterInsert(List<Request__c> newRequests) {
        Set<Id> userIds = new Set<Id>();
        for (Request__c r : newRequests) {
            userIds.add(r.External_User__c);
        }

        Map<Id, External_User__c> usersMap = ExternalUsersController.getExternalUsersByIdBatch(userIds);

        for (Request__c req : newRequests) {
            External_User__c user = usersMap.get(req.External_User__c);
            if (user == null) continue;

            switch on req.Type__c {
                when 'Vacation' { user.Used_Vacations__c += req.Duration__c; }
                when 'Day Off'  { user.Used_Days_Off__c += req.Duration__c; }
                when 'Illness'  { user.Used_Illnesses__c += req.Duration__c; }
                when 'Compensation' { user.Used_Budget__c += req.Budget__c; }
            }
        }

        update usersMap.values();
    }

    public static void handleAfterUpdate(Map<Id, Request__c> oldMap, Map<Id, Request__c> newMap) {
        Set<Id> userIds = new Set<Id>();
        for (Request__c newReq : newMap.values()) {
            userIds.add(newReq.External_User__c);
        }

        Map<Id, External_User__c> usersMap = ExternalUsersController.getExternalUsersByIdBatch(userIds);


        List<Report__c> reportsToInsert = new List<Report__c>();
        List<Project__c> socialPackageProjects = ProjectController.getProjectByName('Social Package');
        Project__c socialProject = socialPackageProjects.isEmpty() ? ProjectController.createSocialPackageProject() : socialPackageProjects[0];

        for (Request__c newReq : newMap.values()) {
            Request__c oldReq = oldMap.get(newReq.Id);
            if (oldReq.Status__c != 'Approved' && newReq.Status__c == 'Approved' && newReq.Type__c != 'Compensation') {
                Date currentDate = newReq.StartDate__c;
                Integer createdReports = 0;
                while (createdReports < newReq.Duration__c) {
                    Integer dayOfWeek = currentDate.toStartOfWeek().daysBetween(currentDate);
                    if (dayOfWeek != 0 && dayOfWeek != 6) {
                        reportsToInsert.add(ReportController.createReportWithoutInsert(
                            currentDate,
                            socialProject.Id,
                            newReq.Type__c,
                            newReq.Status__c,
                            0,
                            8,
                            newReq.External_User__c
                        ));
                        createdReports++;
                    }
                    currentDate = currentDate.addDays(1);
                }
            }

            if (oldReq.Status__c != newReq.Status__c && newReq.Status__c == 'Declined') {
                External_User__c user = usersMap.get(newReq.External_User__c);
                if (user != null) {
                    switch on newReq.Type__c {
                        when 'Vacation'  { user.Used_Vacations__c -= newReq.Duration__c; }
                        when 'Day Off'   { user.Used_Days_Off__c -= newReq.Duration__c; }
                        when 'Illness'   { user.Used_Illnesses__c -= newReq.Duration__c; }
                        when 'Compensation' { user.Used_Budget__c -= newReq.Budget__c; }
                    }
                }
            }
        }

        if (!reportsToInsert.isEmpty()) {
            insert reportsToInsert;
        }

        update usersMap.values();
    }

    public static void handleAfterDelete(List<Request__c> deletedRequests) {
        Set<Id> userIds = new Set<Id>();
        for (Request__c r : deletedRequests) {
            userIds.add(r.External_User__c);
        }

        Map<Id, External_User__c> usersMap = ExternalUsersController.getExternalUsersByIdBatch(userIds);

        List<Date> allStartDates = new List<Date>();
        List<Date> allEndDates = new List<Date>();
        for (Request__c req : deletedRequests) {
            if (req.StartDate__c != null && req.EndDate__c != null) {
                allStartDates.add(req.StartDate__c);
                allEndDates.add(req.EndDate__c);
            }
        }

        List<Project__c> socialProjects = ProjectController.getProjectByName('Social Package');
        if (socialProjects.isEmpty()) return;

        List<Report__c> reportsToDelete;

        for (Request__c req : deletedRequests) {
            External_User__c user = usersMap.get(req.External_User__c);
            if (user == null) continue;
            if(req.Type__c !='Compensation'){
                Date fromDate = req.StartDate__c;
                Date toDate = req.EndDate__c;
                reportsToDelete = ReportController.getSocialPackageReportsByDatePeriod(user.Id, fromDate, toDate, req.Type__c);
            }

            switch on req.Type__c {
                when 'Vacation'  { user.Used_Vacations__c -= req.Duration__c; }
                when 'Day Off'   { user.Used_Days_Off__c -= req.Duration__c; }
                when 'Illness'   { user.Used_Illnesses__c -= req.Duration__c; }
                when 'Compensation' { user.Used_Budget__c -= req.Budget__c; }
            }
        }

        if(reportsToDelete != null && reportsToDelete.size()!=0){
            delete reportsToDelete;

        }

        update usersMap.values();
    }
}