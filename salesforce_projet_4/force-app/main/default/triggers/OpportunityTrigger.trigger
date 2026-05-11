trigger OpportunityTrigger on Opportunity (before update) {
    OpportunityTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
}
