public with sharing class OpportunityTriggerHandler {

    public static void handleBeforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Set<Id> oppsClosingWonIds = new Set<Id>();
        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldOpps.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                oppsClosingWonIds.add(opp.Id);
                oppById.put(opp.Id, opp);
            }
        }

        if (oppsClosingWonIds.isEmpty()) {
            return;
        }

        List<OpportunityLineItem> lines = [
            SELECT Id, OpportunityId, Quantity, Stock_Difference__c,
                   PricebookEntry.Product2Id,
                   PricebookEntry.Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppsClosingWonIds
        ];

        Set<Id> problemOppIds = new Set<Id>();
        for (OpportunityLineItem oli : lines) {
            if (oli.Stock_Difference__c < 0) {
                problemOppIds.add(oli.OpportunityId);
            }
        }

        for (Id problemOppId : problemOppIds) {
            oppById.get(problemOppId).addError(System.Label.lbl_Opportunity_Update_Error);
        }

        Map<Id, Product2> productsToUpdate = new Map<Id, Product2>();
        for (OpportunityLineItem oli : lines) {
            if (problemOppIds.contains(oli.OpportunityId)) {
                continue;
            }
            Id productId = oli.PricebookEntry.Product2Id;
            Decimal currentStock = productsToUpdate.containsKey(productId)
                ? productsToUpdate.get(productId).QuantityInStock__c
                : oli.PricebookEntry.Product2.QuantityInStock__c;
            productsToUpdate.put(productId, new Product2(
                Id = productId,
                QuantityInStock__c = currentStock - oli.Quantity
            ));
        }

        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate.values();
        }
    }
}
