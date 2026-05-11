@isTest
public class OpportunityTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Product2 product = new Product2(
            Name = 'Test Vehicle',
            QuantityInStock__c = 50,
            IsActive = true
        );
        insert product;

        Id stdPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = product.Id,
            UnitPrice = 25000,
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
            Quantity = 10,
            UnitPrice = 25000
        );
        insert oli;
    }

    @isTest
    static void testStockDecrementOnClosedWon() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prodBefore = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        Decimal stockBefore = prodBefore.QuantityInStock__c;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        Product2 prodAfter = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        System.assertEquals(stockBefore - 10, prodAfter.QuantityInStock__c,
            'Stock should be decremented by the OLI quantity');
    }

    @isTest
    static void testStockInsufficientBlocksUpdate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        oli.Quantity = 100;
        update oli;

        Boolean exceptionThrown = false;
        Test.startTest();
        opp.StageName = 'Closed Won';
        try {
            update opp;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains(System.Label.lbl_Opportunity_Update_Error),
                'Error message should match the custom label, got: ' + e.getMessage()
            );
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'A DmlException should be thrown when stock is insufficient');

        Product2 prod = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        System.assertEquals(50, prod.QuantityInStock__c,
            'Stock should remain unchanged when update is blocked');
    }

    @isTest
    static void testStageChangeOtherThanClosedWonDoesNothing() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        opp.StageName = 'Negotiation/Review';
        update opp;
        Test.stopTest();

        Product2 prod = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        System.assertEquals(50, prod.QuantityInStock__c,
            'Stock should not change on stage other than Closed Won');
    }

    @isTest
    static void testAlreadyClosedWonDoesNotDecrementTwice() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Closed Won';
        update opp;

        Product2 prodAfterFirst = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        Decimal stockAfterFirst = prodAfterFirst.QuantityInStock__c;

        Test.startTest();
        opp.Description = 'Updating other field, still Closed Won';
        update opp;
        Test.stopTest();

        Product2 prodAfterSecond = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        System.assertEquals(stockAfterFirst, prodAfterSecond.QuantityInStock__c,
            'Stock should not be decremented again on subsequent updates');
    }
}
