public without sharing class ExternalUserTriggerHandler {

    public static void validateEmailDomains(List<External_User__c> userList) {
        String allowedDomainsStr = MyTime_Settings__c.getOrgDefaults()?.Allowed_Domains__c;

        if (String.isBlank(allowedDomainsStr)) {
            for (External_User__c user : userList) {
                user.addError('No allowed domains configured in settings.');
            }
            return;
        }

        List<String> allowedDomains = new List<String>();
        for (String domain : allowedDomainsStr.split(';')) {
            allowedDomains.add(domain.trim().toLowerCase());
        }

        for (External_User__c user : userList) {
            String email = user.Email__c;
            if (String.isBlank(email) || !email.contains('@')) {
                user.addError('Invalid email format.');
                continue;
            }

            String domain = email.split('@')[1].toLowerCase();
            if (!allowedDomains.contains(domain)) {
                user.addError('Email domain "' + domain + '" is not allowed.');
            }
        }
    }

    public static void preventRoleDowngrade(Map<Id, External_User__c> oldMap, List<External_User__c> newList) {
        Set<Id> potentialManagers = new Set<Id>();
        Set<Id> potentialHRs = new Set<Id>();

        for (External_User__c newUser : newList) {
            External_User__c oldUser = oldMap.get(newUser.Id);

            if (oldUser.IsManager__c && !newUser.IsManager__c) {
                potentialManagers.add(newUser.Id);
            }
            if (oldUser.IsHR__c && !newUser.IsHR__c) {
                potentialHRs.add(newUser.Id);
            }
        }

        // Check Manager__c references
        Set<Id> referencedAsManager = new Set<Id>();
        if (!potentialManagers.isEmpty()) {
            List<External_User__c> managerRefs = [
                SELECT Id, Manager__c
                FROM External_User__c
                WHERE Manager__c IN :potentialManagers
            ];
            for (External_User__c user : managerRefs) {
                referencedAsManager.add(user.Manager__c);
            }
        }

        // Check HR__c references
        Set<Id> referencedAsHR = new Set<Id>();
        if (!potentialHRs.isEmpty()) {
            List<External_User__c> hrRefs = [
                SELECT Id, HR__c
                FROM External_User__c
                WHERE HR__c IN :potentialHRs
            ];
            for (External_User__c user : hrRefs) {
                referencedAsHR.add(user.HR__c);
            }
        }

        for (External_User__c user : newList) {
            if (referencedAsManager.contains(user.Id)) {
                user.addError('This user is assigned as a Manager to other users and cannot be downgraded.');
            }
            if (referencedAsHR.contains(user.Id)) {
                user.addError('This user is assigned as an HR to other users and cannot be downgraded.');
            }
        }
    }

    public static void preventDeletion(List<External_User__c> toDelete) {
        Set<Id> managerIds = new Set<Id>();
        Set<Id> hrIds = new Set<Id>();

        for (External_User__c user : toDelete) {
            if (user.IsManager__c) {
                managerIds.add(user.Id);
            }
            if (user.IsHR__c) {
                hrIds.add(user.Id);
            }
        }

        // Check if anyone reports to these managers
        Set<Id> referencedAsManager = new Set<Id>();
        if (!managerIds.isEmpty()) {
            List<External_User__c> users = [
                SELECT Id, Manager__c
                FROM External_User__c
                WHERE Manager__c IN :managerIds
            ];
            for (External_User__c u : users) {
                referencedAsManager.add(u.Manager__c);
            }
        }

        // Check if anyone is assigned to these HRs
        Set<Id> referencedAsHR = new Set<Id>();
        if (!hrIds.isEmpty()) {
            List<External_User__c> users = [
                SELECT Id, HR__c
                FROM External_User__c
                WHERE HR__c IN :hrIds
            ];
            for (External_User__c u : users) {
                referencedAsHR.add(u.HR__c);
            }
        }

        for (External_User__c user : toDelete) {
            if (referencedAsManager.contains(user.Id)) {
                user.addError('This user is assigned as a Manager to other users and cannot be deleted.');
            }
            if (referencedAsHR.contains(user.Id)) {
                user.addError('This user is assigned as an HR to other users and cannot be deleted.');
            }
        }
    }
}