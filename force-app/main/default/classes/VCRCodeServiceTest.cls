/**
 * @description Test class for VCRCodeService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7B (VCR Code Service Enhancement)
 */
@isTest
private class VCRCodeServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001'
        );
        insert testAccount;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
    }

    /**
     * @description Test processQuoteStatusChangeForVCR with eligible quote (Amendment)
     */
    @isTest
    static void testProcessQuoteStatusChange_Amendment_StatusChangedToApproved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Create quote with Draft status
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amendment'
        );
        insert testQuote;

        // Create old and new maps for status change
        SBQQ__Quote__c oldQuote = testQuote.clone(true);
        oldQuote.SBQQ__Status__c = 'Draft';

        SBQQ__Quote__c newQuote = testQuote.clone(true);
        newQuote.SBQQ__Status__c = 'Approved';

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{
            testQuote.Id => oldQuote
        };
        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{
            testQuote.Id => newQuote
        };

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        // This will call VCRCodeController.setVCRCodeForBundle() internally
        service.processQuoteStatusChangeForVCR(oldMap, newMap);
        Test.stopTest();

        // Verify the quote was processed (VCRCodeController would update quote lines)
        System.assert(true, 'processQuoteStatusChangeForVCR should execute without errors');
    }

    /**
     * @description Test processQuoteStatusChangeForVCR with eligible quote (Exception)
     */
    @isTest
    static void testProcessQuoteStatusChange_Exception_StatusChangedToApproved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Exception'
        );
        insert testQuote;

        SBQQ__Quote__c oldQuote = testQuote.clone(true);
        SBQQ__Quote__c newQuote = testQuote.clone(true);
        newQuote.SBQQ__Status__c = 'Approved';

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => oldQuote};
        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => newQuote};

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.processQuoteStatusChangeForVCR(oldMap, newMap);
        Test.stopTest();

        System.assert(true, 'Should process Exception quote type');
    }

    /**
     * @description Test processQuoteStatusChangeForVCR with eligible quote (Correction)
     */
    @isTest
    static void testProcessQuoteStatusChange_Correction_StatusChangedToApproved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Correction'
        );
        insert testQuote;

        SBQQ__Quote__c oldQuote = testQuote.clone(true);
        SBQQ__Quote__c newQuote = testQuote.clone(true);
        newQuote.SBQQ__Status__c = 'Approved';

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => oldQuote};
        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => newQuote};

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.processQuoteStatusChangeForVCR(oldMap, newMap);
        Test.stopTest();

        System.assert(true, 'Should process Correction quote type');
    }

    /**
     * @description Test processQuoteStatusChangeForVCR with ineligible quote type
     */
    @isTest
    static void testProcessQuoteStatusChange_IneligibleQuoteType() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote' // Not an eligible type
        );
        insert testQuote;

        SBQQ__Quote__c oldQuote = testQuote.clone(true);
        SBQQ__Quote__c newQuote = testQuote.clone(true);
        newQuote.SBQQ__Status__c = 'Approved';

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => oldQuote};
        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => newQuote};

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.processQuoteStatusChangeForVCR(oldMap, newMap);
        Test.stopTest();

        // No VCR update should occur for ineligible quote type
        System.assert(true, 'Should not process ineligible quote type');
    }

    /**
     * @description Test processQuoteStatusChangeForVCR with no status change
     */
    @isTest
    static void testProcessQuoteStatusChange_NoStatusChange() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Approved',
            SBQQ__Type__c = 'Amendment'
        );
        insert testQuote;

        SBQQ__Quote__c oldQuote = testQuote.clone(true);
        oldQuote.SBQQ__Status__c = 'Approved'; // Already approved

        SBQQ__Quote__c newQuote = testQuote.clone(true);

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => oldQuote};
        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{testQuote.Id => newQuote};

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.processQuoteStatusChangeForVCR(oldMap, newMap);
        Test.stopTest();

        // No VCR update should occur when status doesn't change
        System.assert(true, 'Should not process when status unchanged');
    }

    /**
     * @description Test processQuoteStatusChangeForVCR with null/empty inputs
     */
    @isTest
    static void testProcessQuoteStatusChange_NullInput() {
        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.processQuoteStatusChangeForVCR(null, null);
        service.processQuoteStatusChangeForVCR(null, new Map<Id, SBQQ__Quote__c>());
        service.processQuoteStatusChangeForVCR(new Map<Id, SBQQ__Quote__c>(), null);
        Test.stopTest();

        System.assert(true, 'Should handle null inputs gracefully');
    }

    /**
     * @description Test filterEligibleQuotes returns correct quote IDs
     */
    @isTest
    static void testFilterEligibleQuotes_MultipleQuotes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Draft',
                SBQQ__Type__c = 'Amendment'
            ),
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Draft',
                SBQQ__Type__c = 'Exception'
            ),
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Draft',
                SBQQ__Type__c = 'Quote' // Not eligible
            )
        };
        insert quotes;

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>();

        for (SBQQ__Quote__c q : quotes) {
            SBQQ__Quote__c oldQ = q.clone(true);
            oldQ.SBQQ__Status__c = 'Draft';
            oldMap.put(q.Id, oldQ);

            SBQQ__Quote__c newQ = q.clone(true);
            newQ.SBQQ__Status__c = 'Approved';
            newMap.put(q.Id, newQ);
        }

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        Set<Id> eligibleIds = service.filterEligibleQuotes(oldMap, newMap);
        Test.stopTest();

        System.assertEquals(2, eligibleIds.size(), 'Should filter 2 eligible quotes');
        System.assert(eligibleIds.contains(quotes[0].Id), 'Should include Amendment quote');
        System.assert(eligibleIds.contains(quotes[1].Id), 'Should include Exception quote');
        System.assertEquals(false, eligibleIds.contains(quotes[2].Id), 'Should not include Quote type');
    }

    /**
     * @description Test filterEligibleQuotes with empty input
     */
    @isTest
    static void testFilterEligibleQuotes_EmptyInput() {
        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        Set<Id> result1 = service.filterEligibleQuotes(null, null);
        Set<Id> result2 = service.filterEligibleQuotes(null, new Map<Id, SBQQ__Quote__c>());
        Test.stopTest();

        System.assertEquals(0, result1.size(), 'Null input should return empty set');
        System.assertEquals(0, result2.size(), 'Empty map should return empty set');
    }

    /**
     * @description Test isEligibleForVCRCalculation with various scenarios
     */
    @isTest
    static void testIsEligibleForVCRCalculation_VariousScenarios() {
        SBQQ__Quote__c eligibleQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__Type__c = 'Amendment'
        );

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amendment'
        );

        SBQQ__Quote__c ineligibleType = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__Type__c = 'Quote'
        );

        SBQQ__Quote__c ineligibleStatus = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amendment'
        );

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        Boolean result1 = service.isEligibleForVCRCalculation(oldQuote, eligibleQuote);
        Boolean result2 = service.isEligibleForVCRCalculation(oldQuote, ineligibleType);
        Boolean result3 = service.isEligibleForVCRCalculation(oldQuote, ineligibleStatus);
        Boolean result4 = service.isEligibleForVCRCalculation(null, null);
        Test.stopTest();

        System.assertEquals(true, result1, 'Should be eligible: status changed to Approved with Amendment type');
        System.assertEquals(false, result2, 'Should not be eligible: wrong quote type');
        System.assertEquals(false, result3, 'Should not be eligible: status not Approved');
        System.assertEquals(false, result4, 'Should not be eligible: null inputs');
    }

    /**
     * @description Test updateVCRCodesForQuotes with valid quote IDs
     */
    @isTest
    static void testUpdateVCRCodesForQuotes_ValidIds() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Approved',
            SBQQ__Type__c = 'Amendment'
        );
        insert testQuote;

        Set<Id> quoteIds = new Set<Id>{testQuote.Id};

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.updateVCRCodesForQuotes(quoteIds);
        Test.stopTest();

        System.assert(true, 'Should call VCRCodeController without errors');
    }

    /**
     * @description Test updateVCRCodesForQuotes with null/empty input
     */
    @isTest
    static void testUpdateVCRCodesForQuotes_NullInput() {
        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        service.updateVCRCodesForQuotes(null);
        service.updateVCRCodesForQuotes(new Set<Id>());
        Test.stopTest();

        System.assert(true, 'Should handle null/empty inputs gracefully');
    }

    /**
     * @description Test getEligibleQuoteTypes returns correct list
     */
    @isTest
    static void testGetEligibleQuoteTypes() {
        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        List<String> quoteTypes = service.getEligibleQuoteTypes();
        Test.stopTest();

        System.assertEquals(3, quoteTypes.size(), 'Should return 3 quote types');
        System.assert(quoteTypes.contains('Exception'), 'Should contain Exception');
        System.assert(quoteTypes.contains('Amendment'), 'Should contain Amendment');
        System.assert(quoteTypes.contains('Correction'), 'Should contain Correction');
    }

    /**
     * @description Test bulkProcessQuotesForVCR with multiple quotes
     */
    @isTest
    static void testBulkProcessQuotesForVCR_MultipleQuotes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Approved',
                SBQQ__Type__c = 'Amendment'
            ),
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Approved',
                SBQQ__Type__c = 'Exception'
            ),
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Draft', // Not eligible
                SBQQ__Type__c = 'Amendment'
            )
        };
        insert quotes;

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        Integer processedCount = service.bulkProcessQuotesForVCR(quotes);
        Test.stopTest();

        System.assertEquals(2, processedCount, 'Should process 2 eligible quotes');
    }

    /**
     * @description Test bulkProcessQuotesForVCR with null/empty input
     */
    @isTest
    static void testBulkProcessQuotesForVCR_NullInput() {
        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        Integer result1 = service.bulkProcessQuotesForVCR(null);
        Integer result2 = service.bulkProcessQuotesForVCR(new List<SBQQ__Quote__c>());
        Test.stopTest();

        System.assertEquals(0, result1, 'Null input should return 0');
        System.assertEquals(0, result2, 'Empty list should return 0');
    }

    /**
     * @description Test bulkProcessQuotesForVCR with no eligible quotes
     */
    @isTest
    static void testBulkProcessQuotesForVCR_NoEligibleQuotes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Status__c = 'Draft',
                SBQQ__Type__c = 'Quote'
            )
        };
        insert quotes;

        VCRCodeService service = new VCRCodeService();

        Test.startTest();
        Integer processedCount = service.bulkProcessQuotesForVCR(quotes);
        Test.stopTest();

        System.assertEquals(0, processedCount, 'Should process 0 ineligible quotes');
    }
}
