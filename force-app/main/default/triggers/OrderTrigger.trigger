trigger OrderTrigger on Order (after insert, after update) {
    OrderTriggerHandler.run(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
}

