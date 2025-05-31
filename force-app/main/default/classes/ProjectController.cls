public without sharing class ProjectController {


    @AuraEnabled
    public static List<Project__c> getProjectsTasksById(Id projectId){
        try {
            return [Select Id,TaskTypes__c from Project__c where id =:projectId];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Project_Member__c> getProjectsByUserId(Id userId){
        try {
            List<Project_Member__c> projects = [Select Project__c, Project__r.Name from Project_Member__c where Member__c = :userId];
            return projects;            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<Project__c> getProjectByName(String projectName){
        try {
            return [Select Id,Name from Project__c where Name =:projectName limit 1];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public static Project__c createSocialPackageProject(){
        try {
            Project__c p = new Project__c(Name='Social Package', Rate__c = 0); 
            p.TaskTypes__c = 'Vacation;Illness;Day Off';
            insert p; 
            return p;          
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveTaskTypes(Id projectId, String taskTypes) {
        Project__c proj = [Select Id,TaskTypes__c from Project__c where Id = :projectId];
        proj.TaskTypes__c = taskTypes;
        update proj;
    }


    @AuraEnabled
    public static void saveProjectMembers(Id projectId, List<Id> userIds) {
        List<Project_Member__c> existing = [
            SELECT Id, Member__c FROM Project_Member__c WHERE Project__c = :projectId
        ];
    
        Set<Id> currentIds = new Set<Id>();
        for (Project_Member__c pm : existing) {
            currentIds.add(pm.Member__c);
        }
    
        Set<Id> newIds = new Set<Id>(userIds);
    
        // Remove unselected
        List<Project_Member__c> toDelete = new List<Project_Member__c>();
        for (Project_Member__c pm : existing) {
            if (!newIds.contains(pm.Member__c)) {
                toDelete.add(pm);
            }
        }
    
        // Add new
        List<Project_Member__c> toAdd = new List<Project_Member__c>();
        for (Id uid : newIds) {
            if (!currentIds.contains(uid)) {
                toAdd.add(new Project_Member__c(Member__c = uid, Project__c = projectId));
            }
        }
    
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
        if (!toAdd.isEmpty()) {
            insert toAdd;
        }
    }


    @AuraEnabled
    public static Map<String, Object> getProjectData(Id projectId) {
        List<Project_Member__c> members = [
            SELECT Member__c FROM Project_Member__c WHERE Project__c = :projectId
        ];
        Project__c project = [SELECT TaskTypes__c FROM Project__c WHERE Id = :projectId LIMIT 1];

        List<Id> assignedUserIds = new List<Id>();
        for (Project_Member__c m : members) {
            assignedUserIds.add(m.Member__c);
        }

        Map<String, Object> result = new Map<String, Object>();
        result.put('assignedUserIds', assignedUserIds);
        result.put('taskTypesString', project.TaskTypes__c);

        return result;
    }


    





}