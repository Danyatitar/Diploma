public without sharing class ReportController {

    @AuraEnabled
    public static List<Report__c> getReportsByDate(String dateISO, Id userId) {
    Date reportDate = Date.valueOf(dateISO);
    return [SELECT Id, Name, Project__c, Project__r.Name,TaskType__c, Description__c, Hours__c, Minutes__c, CreatedDate, LastModifiedDate, isApproved__c, Date__c
            FROM Report__c
            WHERE Date__c = :reportDate AND External_User__c = :userId];
    }

    @AuraEnabled
    public static List<Report__c> getReportsByDatePeriod(Id userId, Date fromDate, Date toDate) {

    return [SELECT Id, Name, Project__c, Project__r.Name,TaskType__c, Description__c, Hours__c, Minutes__c, CreatedDate, LastModifiedDate, isApproved__c, Date__c, External_User__c
            FROM Report__c
            WHERE Date__c <= :toDate AND Date__c>=:fromDate AND External_User__c = :userId and Project__r.Name!='Social package'];
    }


    @AuraEnabled
    public static List<Report__c> getSocialPackageReportsByDatePeriod(Id userId, Date fromDate, Date toDate, String type) {

    return [SELECT Id, Name, Project__c, Project__r.Name,TaskType__c, Description__c, Hours__c, Minutes__c, CreatedDate, LastModifiedDate, isApproved__c, Date__c, External_User__c
            FROM Report__c
            WHERE Date__c <= :toDate AND Date__c>=:fromDate AND External_User__c = :userId and Project__r.Name ='Social package' and TaskType__c=:type];
    }


    @AuraEnabled
    public static Report__c getReportById(Id reportId) {
    return [SELECT Id, Name, Project__c, TaskType__c, Description__c, Hours__c, Minutes__c, CreatedDate, LastModifiedDate, isApproved__c, Date__c
            FROM Report__c
            WHERE Id=:reportId];
    }

    @AuraEnabled
    public static void createReport(String dateISO, String projectId, String task, String description, Integer minutesSpent, Integer hoursSpent, Id userId) {
        Date reportDate = Date.valueOf(dateISO);
        Report__c report = new Report__c(
            Date__c = reportDate,
            Project__c = projectId,
            TaskType__c = task,
            Description__c = description,
            Minutes__c = minutesSpent,
            Hours__c = hoursSpent,
            External_User__c = userId
        );
        insert report;
    }


    public static Report__c createReportWithoutInsert(Date reportDate, String projectId, String task, String description, Integer minutesSpent, Integer hoursSpent, Id userId) {
        Report__c report = new Report__c(
            Date__c = reportDate,
            Project__c = projectId,
            TaskType__c = task,
            Description__c = description,
            Minutes__c = minutesSpent,
            Hours__c = hoursSpent,
            External_User__c = userId,
            IsApproved__c = true

        );
        return report;
    }


    @AuraEnabled
    public static void updateReport(String reportId, String projectId, String task, String description, Integer minutesSpent, Integer hoursSpent) {
        Report__c report = [
            SELECT Id, Project__c, TaskType__c, Description__c, Hours__c, Minutes__c
            FROM Report__c
            WHERE Id = :reportId
            LIMIT 1
        ];

        report.Project__c = projectId;
        report.TaskType__c = task;
        report.Description__c = description;
        report.Minutes__c = minutesSpent;
        report.Hours__c = hoursSpent;

        update report;
    }

    @AuraEnabled
    public static void deleteReport(Id reportId) {
        Report__c report = [
            SELECT Id FROM Report__c WHERE Id = :reportId LIMIT 1
        ];
        delete report;
    }




    @AuraEnabled
    public static void updateReportStatus(Id reportId, Boolean value) {
        Report__c report = [
            SELECT Id, Project__c, TaskType__c, Description__c, Hours__c, Minutes__c, IsApproved__c
            FROM Report__c
            WHERE Id =:reportId
            LIMIT 1
        ];

        report.IsApproved__c = value;
        update report;
    }


    @AuraEnabled
    public static void updateReportsStatusesByWeek(String startDateISO, String endDateISO, Boolean value) {
        List<Report__c> reports = [
            SELECT Id, Project__c, TaskType__c, Description__c, Hours__c, Minutes__c, IsApproved__c
            FROM Report__c
            WHERE Date__c >= :Date.valueOf(startDateISO)
            AND Date__c <= :Date.valueOf(endDateISO)
        ];
        for (Report__c report : reports) {
            report.IsApproved__c = value;
        }
        update reports;
   
    }
}