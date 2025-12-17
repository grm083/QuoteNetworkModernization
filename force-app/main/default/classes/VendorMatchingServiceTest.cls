/**
 * @description Test class for VendorMatchingService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class VendorMatchingServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create vendor accounts
        List<Account> vendors = new List<Account>{
            new Account(
                Name = 'WM US Vendor',
                Vendor_ID__c = 'WM_US',
                Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR,
                Status__c = 'Active',
                Customer_Code__c = 'WM001'
            ),
            new Account(
                Name = 'WM Canada Vendor',
                Vendor_ID__c = 'WM_CA',
                Parent_Vendor_ID__c = Constant_Util.WM_CANADA_VENDOR,
                Status__c = 'Active',
                Customer_Code__c = 'WM002'
            ),
            new Account(
                Name = 'Third Party Vendor',
                Vendor_ID__c = 'TP001',
                Parent_Vendor_ID__c = 'TP_PARENT',
                Status__c = 'Active',
                Customer_Code__c = 'TP001'
            ),
            new Account(
                Name = 'WM Child Vendor',
                Vendor_ID__c = 'WM_CHILD',
                Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR,
                Status__c = 'Active',
                Customer_Code__c = 'WM003'
            )
        };
        insert vendors;

        // Create test account
        Account testAccount = new Account(
            Name = 'Test Customer',
            AccountNumber = 'CUST001'
        );
        insert testAccount;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Rolloff Container',
            ProductCode = 'ROLL001',
            Family = 'Rolloff',
            IsActive = true
        );
        insert testProduct;

        // Get vendor for quote line
        Account wmVendor = [SELECT Id FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];

        // Create quote lines with different vendor scenarios
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = wmVendor.Id,
                Type_of_Change__c = 'Rate Change'
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = wmVendor.Id,
                Type_of_Change__c = null // Missing Type_of_Change
            )
        };
        insert quoteLines;
    }

    /**
     * @description Test vendor matching with direct vendor ID match
     */
    @isTest
    static void testCompareQuoteLineVendor_DirectVendorMatch() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c != null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        VendorMatchingService.VendorMatchResult result = service.compareQuoteLineVendor(quoteLine, vendor);
        Test.stopTest();

        System.assertEquals(true, result.isMatch, 'Should match by direct vendor ID');
        System.assertEquals(false, result.isMismatch, 'Should not be a mismatch');
        System.assertEquals(null, result.mismatchReason, 'Should have no mismatch reason');
    }

    /**
     * @description Test vendor matching with parent vendor ID match
     */
    @isTest
    static void testCompareQuoteLineVendor_ParentVendorMatch() {
        Account wmUsVendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                              FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        Account wmChildVendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                                 FROM Account WHERE Vendor_ID__c = 'WM_CHILD' LIMIT 1];

        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c != null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        // QuoteLine has WM_US vendor, pricing request has WM_CHILD vendor
        // Both have same Parent_Vendor_ID__c (WM_US_VENDOR)
        VendorMatchingService.VendorMatchResult result = service.compareQuoteLineVendor(quoteLine, wmChildVendor);
        Test.stopTest();

        System.assertEquals(true, result.isMatch, 'Should match by parent vendor ID');
        System.assertEquals(false, result.isMismatch, 'Should not be a mismatch');
    }

    /**
     * @description Test vendor mismatch
     */
    @isTest
    static void testCompareQuoteLineVendor_VendorMismatch() {
        Account tpVendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                            FROM Account WHERE Vendor_ID__c = 'TP001' LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c != null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        VendorMatchingService.VendorMatchResult result = service.compareQuoteLineVendor(quoteLine, tpVendor);
        Test.stopTest();

        System.assertEquals(false, result.isMatch, 'Should not match different vendors');
        System.assertEquals(true, result.isMismatch, 'Should be a mismatch');
        System.assertNotEquals(null, result.mismatchReason, 'Should have mismatch reason');
    }

    /**
     * @description Test null vendor account
     */
    @isTest
    static void testCompareQuoteLineVendor_NullVendor() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c != null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        VendorMatchingService.VendorMatchResult result = service.compareQuoteLineVendor(quoteLine, null);
        Test.stopTest();

        System.assertEquals(false, result.isMatch, 'Null vendor should not match');
        System.assertEquals(true, result.isMismatch, 'Null vendor should be mismatch');
        System.assertEquals('Vendor account is null', result.mismatchReason, 'Should have correct mismatch reason');
    }

    /**
     * @description Test null quote line
     */
    @isTest
    static void testCompareQuoteLineVendor_NullQuoteLine() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        VendorMatchingService.VendorMatchResult result = service.compareQuoteLineVendor(null, vendor);
        Test.stopTest();

        System.assertEquals(false, result.isMatch, 'Null quote line should not match');
        System.assertEquals(true, result.isMismatch, 'Null quote line should be mismatch');
        System.assertEquals('Quote line is null', result.mismatchReason, 'Should have correct mismatch reason');
    }

    /**
     * @description Test missing Type_of_Change__c
     */
    @isTest
    static void testCompareQuoteLineVendor_MissingTypeOfChange() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c = null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        VendorMatchingService.VendorMatchResult result = service.compareQuoteLineVendor(quoteLine, vendor);
        Test.stopTest();

        System.assertEquals(false, result.isMatch, 'Missing Type_of_Change should not match');
        System.assertEquals(true, result.isMismatch, 'Missing Type_of_Change should be mismatch');
        System.assertEquals('Type of Change is not populated', result.mismatchReason, 'Should have correct mismatch reason');
    }

    /**
     * @description Test apply vendor mismatch result
     */
    @isTest
    static void testApplyVendorMismatchResult_Mismatch() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        VendorMatchingService.VendorMatchResult result = new VendorMatchingService.VendorMatchResult();
        result.isMismatch = true;
        result.mismatchReason = 'Test mismatch';

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        SBQQ__QuoteLine__c updatedLine = service.applyVendorMismatchResult(quoteLine, result);
        Test.stopTest();

        System.assertEquals(true, updatedLine.Is_Vendor_Mismatch__c, 'Should set mismatch flag');
        System.assertEquals('NO', updatedLine.BundleProcuredStatus__c, 'Should set procurement status to NO');
    }

    /**
     * @description Test apply vendor match result
     */
    @isTest
    static void testApplyVendorMismatchResult_Match() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        VendorMatchingService.VendorMatchResult result = new VendorMatchingService.VendorMatchResult();
        result.isMatch = true;
        result.isMismatch = false;

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        SBQQ__QuoteLine__c updatedLine = service.applyVendorMismatchResult(quoteLine, result);
        Test.stopTest();

        System.assertEquals(false, updatedLine.Is_Vendor_Mismatch__c, 'Should not set mismatch flag');
    }

    /**
     * @description Test apply mismatch with null inputs
     */
    @isTest
    static void testApplyVendorMismatchResult_NullInputs() {
        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        SBQQ__QuoteLine__c result1 = service.applyVendorMismatchResult(null, new VendorMatchingService.VendorMatchResult());
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        SBQQ__QuoteLine__c result2 = service.applyVendorMismatchResult(quoteLine, null);
        Test.stopTest();

        System.assertEquals(null, result1, 'Null quote line should return null');
        System.assertNotEquals(null, result2, 'Null result should return quote line unchanged');
    }

    /**
     * @description Test isVendorMatch with direct ID match
     */
    @isTest
    static void testIsVendorMatch_DirectMatch() {
        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean isMatch = service.isVendorMatch('WM_US', 'WM_US_VENDOR', 'WM_US', 'WM_US_VENDOR');
        Test.stopTest();

        System.assertEquals(true, isMatch, 'Should match by direct vendor ID');
    }

    /**
     * @description Test isVendorMatch with parent hierarchy match
     */
    @isTest
    static void testIsVendorMatch_ParentMatch() {
        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean isMatch = service.isVendorMatch('WM_US', 'WM_US_VENDOR', 'WM_CHILD', 'WM_US_VENDOR');
        Test.stopTest();

        System.assertEquals(true, isMatch, 'Should match by parent vendor ID');
    }

    /**
     * @description Test isVendorMatch with no match
     */
    @isTest
    static void testIsVendorMatch_NoMatch() {
        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean isMatch = service.isVendorMatch('WM_US', 'WM_US_VENDOR', 'TP001', 'TP_PARENT');
        Test.stopTest();

        System.assertEquals(false, isMatch, 'Should not match different vendors');
    }

    /**
     * @description Test isVendorMatch with null inputs
     */
    @isTest
    static void testIsVendorMatch_NullInputs() {
        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean result1 = service.isVendorMatch(null, 'WM_US_VENDOR', 'WM_US', 'WM_US_VENDOR');
        Boolean result2 = service.isVendorMatch('WM_US', 'WM_US_VENDOR', null, 'WM_US_VENDOR');
        Test.stopTest();

        System.assertEquals(false, result1, 'Null quote line vendor should not match');
        System.assertEquals(false, result2, 'Null pricing vendor should not match');
    }

    /**
     * @description Test isValidVendorForServiceModification for modify case
     */
    @isTest
    static void testIsValidVendorForServiceModification_ModifyCase() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c != null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean isValid = service.isValidVendorForServiceModification(
            quoteLine,
            vendor,
            Constant_Util.MODIFY_EXISTING_SERVICE_CASE_API
        );
        Test.stopTest();

        System.assertEquals(true, isValid, 'Valid vendor should be allowed for modify case');
    }

    /**
     * @description Test isValidVendorForServiceModification for non-modify case
     */
    @isTest
    static void testIsValidVendorForServiceModification_NonModifyCase() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'TP001' LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Type_of_Change__c != null LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean isValid = service.isValidVendorForServiceModification(
            quoteLine,
            vendor,
            'New_Service_Case'
        );
        Test.stopTest();

        System.assertEquals(true, isValid, 'Non-modify cases should not validate vendors');
    }

    /**
     * @description Test findVendorInMap
     */
    @isTest
    static void testFindVendorInMap_Success() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        Map<String, Account> vendorMap = new Map<String, Account>{
            'WM_US' => vendor
        };

        VendorMatchingService service = new VendorMatchingService();
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account foundVendor = service.findVendorInMap(vendorMap, 'WM_US|extra_data', repo);
        Test.stopTest();

        System.assertNotEquals(null, foundVendor, 'Should find vendor with pipe-delimited code');
        System.assertEquals('WM_US', foundVendor.Vendor_ID__c, 'Should return correct vendor');
    }

    /**
     * @description Test findVendorInMap with null inputs
     */
    @isTest
    static void testFindVendorInMap_NullInputs() {
        VendorMatchingService service = new VendorMatchingService();
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account result1 = service.findVendorInMap(null, 'WM_US', repo);
        Account result2 = service.findVendorInMap(new Map<String, Account>(), null, repo);
        Test.stopTest();

        System.assertEquals(null, result1, 'Null map should return null');
        System.assertEquals(null, result2, 'Null vendor code should return null');
    }

    /**
     * @description Test areVendorsEqual with matching vendors
     */
    @isTest
    static void testAreVendorsEqual_Match() {
        Account vendor1 = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                           FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        Account vendor2 = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                           FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean areEqual = service.areVendorsEqual(vendor1, vendor2);
        Test.stopTest();

        System.assertEquals(true, areEqual, 'Same vendors should be equal');
    }

    /**
     * @description Test areVendorsEqual with different vendors
     */
    @isTest
    static void testAreVendorsEqual_NoMatch() {
        Account vendor1 = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                           FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        Account vendor2 = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                           FROM Account WHERE Vendor_ID__c = 'TP001' LIMIT 1];

        VendorMatchingService service = new VendorMatchingService();

        Test.startTest();
        Boolean areEqual = service.areVendorsEqual(vendor1, vendor2);
        Test.stopTest();

        System.assertEquals(false, areEqual, 'Different vendors should not be equal');
    }

    /**
     * @description Test batchValidateVendors
     */
    @isTest
    static void testBatchValidateVendors_Success() {
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                               FROM SBQQ__QuoteLine__c];

        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        Map<String, Account> vendorMap = new Map<String, Account>{
            'WM_US' => vendor
        };

        VendorMatchingService service = new VendorMatchingService();
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Map<Id, VendorMatchingService.VendorMatchResult> results = service.batchValidateVendors(
            quoteLines,
            vendorMap,
            repo
        );
        Test.stopTest();

        System.assertEquals(quoteLines.size(), results.size(), 'Should return result for each quote line');
    }

    /**
     * @description Test batchValidateVendors with empty list
     */
    @isTest
    static void testBatchValidateVendors_EmptyList() {
        VendorMatchingService service = new VendorMatchingService();
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Map<Id, VendorMatchingService.VendorMatchResult> results = service.batchValidateVendors(
            new List<SBQQ__QuoteLine__c>(),
            new Map<String, Account>(),
            repo
        );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty list should return empty results');
    }
}
