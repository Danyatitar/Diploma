public without sharing class ExternalUsersController {



    @AuraEnabled
    public static List<External_User__c> getAllExternalUsers() {
        return [SELECT Id, Name, Manager__c, Role__c FROM External_User__c];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<External_User__c> getAllExternalUsersByManager(Id managerId) {
        return [SELECT Id, Name, Manager__c, Role__c FROM External_User__c where Manager__c = :managerId];
    }    

    @AuraEnabled
    public static External_User__c getExternalUserById(Id userId){
        External_User__c user = [SELECT Id,Name, Used_Budget__c, Used_Days_Off__c, Used_Illnesses__c, Used_Vacations__c, FirstWorkingDate__c, HR__r.Name, EnglishLevel__c, IsHR__c, Manager__r.Name, Manager__c, HR__c, IsManager__c, Role__c, Level__c, Email__c, Phone__c   FROM External_User__c WHERE Id = :userId LIMIT 1];
        return user;
    }

    public static Map<Id, External_User__c> getExternalUsersByIdBatch(Set<Id> userIds){
        Map<Id, External_User__c> usersMap = new Map<Id, External_User__c>([SELECT Id,Name, Used_Budget__c, Used_Days_Off__c, Used_Illnesses__c, Used_Vacations__c, FirstWorkingDate__c, HR__r.Name, EnglishLevel__c, IsHR__c, Manager__r.Name, Manager__c, HR__c, IsManager__c, Role__c, Level__c, Email__c, Phone__c   FROM External_User__c WHERE Id in :userIds]);
        return usersMap;
    }
      

    @AuraEnabled(cacheable=true)
    public static List<External_User__c> getUsersByFilters(Integer pageSize, Integer pageNumber, String nameFilter, String roleFilter, String leadFilter, String clientFilter) {
        String baseQuery = 'SELECT Id, Name, Email__c, Role__c, Manager__r.Name, HR__r.Name FROM External_User__c WHERE Email__c != null';
        System.debug('hello');
        if (String.isNotBlank(nameFilter)) {
            baseQuery += ' AND Name LIKE \'%' + String.escapeSingleQuotes(nameFilter) + '%\'';
        }
        if (String.isNotBlank(roleFilter)) {
            baseQuery += ' AND Role__c = \'' + String.escapeSingleQuotes(roleFilter) + '\'';
        }
        if (String.isNotBlank(leadFilter)) {
            baseQuery += ' AND Manager__c = \'' + String.escapeSingleQuotes(leadFilter) + '\'';
        }

        Integer offsetSize = Integer.valueOf(pageSize) * (Integer.valueOf(pageNumber)-1);
   

        baseQuery += ' ORDER BY Name LIMIT :pageSize OFFSET :offsetSize';
        System.debug(baseQuery);
        return Database.query(baseQuery);
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalCount(String nameFilter, String roleFilter, String leadFilter, String clientFilter) {
        String baseQuery = 'SELECT COUNT() FROM External_User__c WHERE Email__c != null';

        if (String.isNotBlank(nameFilter)) {
            baseQuery += ' AND Name LIKE \'%' + String.escapeSingleQuotes(nameFilter) + '%\'';
        }
        if (String.isNotBlank(roleFilter)) {
            baseQuery += ' AND Role__c = \'' + String.escapeSingleQuotes(roleFilter) + '\'';
        }
        if (String.isNotBlank(leadFilter)) {
            baseQuery += ' AND Manager__c = \'' + String.escapeSingleQuotes(leadFilter) + '\'';
        }

        return (Integer)Database.countQuery(baseQuery);
    }


    @AuraEnabled
    public static List<External_User__c> getManagers() {
        return [
            SELECT Id, Name 
            FROM External_User__c 
            WHERE IsManager__c = TRUE 
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static List<External_User__c> getAllHRs() {
        return [SELECT Id, Name FROM External_User__c WHERE IsHR__c = TRUE ORDER BY Name];
    }

    @AuraEnabled
    public static void saveUser(External_User__c userRecord) {
        upsert userRecord;
    }


}