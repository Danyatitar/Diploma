public without sharing class SalaryDetailController {
   

    @AuraEnabled(cacheable=true)
    public static List<Salary_Detail__c> getAllSalaryDetails(Id userId) {
        return [
            SELECT Id, Date__c, Rate__c, Compensation__c, Hours__c, Tax__c, Final__c
            FROM Salary_Detail__c
            WHERE External_User__c = :userId
            ORDER BY Date__c DESC
        ];
    }

}