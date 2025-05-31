trigger RequestTrigger on Request__c (before insert, before update, after insert, after update, after delete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            RequestTriggerHandler.calculateDuration(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            RequestTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            RequestTriggerHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            RequestTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
}