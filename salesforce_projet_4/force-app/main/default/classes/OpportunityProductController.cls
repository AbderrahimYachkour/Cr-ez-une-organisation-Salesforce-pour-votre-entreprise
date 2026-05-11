public without sharing class OpportunityProductController {

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityProducts(Id opportunityId) {
        return [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   Product2Id, Product2.Name, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            ORDER BY Product2.Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileName() {
        Id profileId = UserInfo.getProfileId();
        Profile profile = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
        return profile.Name;
    }

    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        try {
            delete new OpportunityLineItem(Id = lineItemId);
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
