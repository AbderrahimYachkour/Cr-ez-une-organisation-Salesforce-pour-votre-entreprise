@isTest
public class OpportunityProductControllerTest {

    @TestSetup
    static void setupData() {
        Product2 product = new Product2(
            Name = 'Test Audi',
            QuantityInStock__c = 100,
            IsActive = true
        );
        insert product;

        Id stdPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = product.Id,
            UnitPrice = 80000,
            IsActive = true
        );
        insert pbe;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = stdPricebookId
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 80000
        );
        insert oli;
    }

    @isTest
    static void testGetOpportunityProductsReturnsLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityProductController.getOpportunityProducts(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one OLI');
        System.assertEquals(5, result[0].Quantity, 'Quantity should be 5');
        System.assertEquals(80000, result[0].UnitPrice, 'UnitPrice should match');
        System.assertEquals('Test Audi', result[0].Product2.Name, 'Product name should match');
        System.assertEquals(100, result[0].Product2.QuantityInStock__c, 'Stock should match');
    }

    @isTest
    static void testGetOpportunityProductsReturnsEmptyForNoOLI() {
        Account acc = new Account(Name = 'Empty Account');
        insert acc;
        Opportunity emptyOpp = new Opportunity(
            Name = 'Empty Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert emptyOpp;

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityProductController.getOpportunityProducts(emptyOpp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for opp without OLI');
    }

    @isTest
    static void testGetCurrentUserProfileNameReturnsAdmin() {
        Test.startTest();
        String profileName = OpportunityProductController.getCurrentUserProfileName();
        Test.stopTest();

        System.assertNotEquals(null, profileName, 'Profile name should not be null');
        System.assert(
            profileName.contains('Administrator') || profileName.contains('Administrateur'),
            'Test should run as admin, got: ' + profileName
        );
    }

    @isTest
    static void testDeleteOpportunityLineItemRemovesRecord() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        Id oliId = oli.Id;

        Test.startTest();
        OpportunityProductController.deleteOpportunityLineItem(oliId);
        Test.stopTest();

        List<OpportunityLineItem> remaining = [SELECT Id FROM OpportunityLineItem WHERE Id = :oliId];
        System.assertEquals(0, remaining.size(), 'OLI should be deleted');
    }

    @isTest
    static void testDeleteOpportunityLineItemThrowsOnInvalidId() {
        Id fakeId = '00k000000000000AAA';

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            OpportunityProductController.deleteOpportunityLineItem(fakeId);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException should be thrown for invalid Id');
    }
}
