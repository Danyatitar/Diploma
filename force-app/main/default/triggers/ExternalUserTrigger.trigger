trigger ExternalUserTrigger on External_User__c (before insert, before update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ExternalUserTriggerHandler.validateEmailDomains(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ExternalUserTriggerHandler.preventRoleDowngrade(Trigger.oldMap, Trigger.new);
        }
        if (Trigger.isDelete) {
            ExternalUserTriggerHandler.preventDeletion(Trigger.old);
        }
    }
}