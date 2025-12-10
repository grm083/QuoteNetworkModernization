/**
 * @description Test class for Phase 3C Services
 * Tests AssetComparisonService, BaselineUpdateService, CommercialProductHandler
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3C
 */
@isTest
private class Phase3CServicesTest {

    // ==================================================================================
    // TEST DATA SETUP
    // ==================================================================================

    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amend',
            SBQQ__StartDate__c = Date.today()
        );
        insert testQuote;

        // Create test quote line
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__ProductName__c = 'Test Product',
            SBQQ__ProductFamily__c = 'Commercial',
            SBQQ__ProductCode__c = 'TEST001'
        );
        insert testQuoteLine;
    }

    // ==================================================================================
    // ASSET COMPARISON SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testAssetComparisonService_CompareWithNullAsset() {
        // Given: Quote line with no asset
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__ProductFamily__c FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetComparisonService service = new AssetComparisonService();

        // When: Compare with null asset
        Test.startTest();
        AssetComparisonResult result = service.compareAssetWithQuoteLine(null, quoteLine, quoteLine);
        Test.stopTest();

        // Then: Should return matched
        System.assert(result.isMatched, 'Should return matched for null asset');
    }

    @isTest
    static void testAssetComparisonService_GetAssetsForComparison() {
        // Given: Empty asset IDs set
        AssetComparisonService service = new AssetComparisonService();
        Set<Id> assetIds = new Set<Id>();

        // When: Get assets
        Test.startTest();
        Map<Id, Asset> assetMap = service.getAssetsForComparison(assetIds);
        Test.stopTest();

        // Then: Should return empty map
        System.assertEquals(0, assetMap.size(), 'Should return empty map for no asset IDs');
    }

    @isTest
    static void testAssetComparisonService_ValidateProjectCodeMatch() {
        // Given: Quote line and matched comparison result
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quote__r.Project__c, SBQQ__Quote__r.Project_Services_Request__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            Project_Code__c = null
        );

        AssetComparisonResult matchedResult = AssetComparisonResult.createMatched();
        AssetComparisonService service = new AssetComparisonService();

        // When: Validate project code match
        Test.startTest();
        AssetComparisonResult result = service.validateProjectCodeMatch(testAsset, quoteLine, matchedResult);
        Test.stopTest();

        // Then: Should handle null project codes
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    // ==================================================================================
    // BASELINE UPDATE SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testBaselineUpdateService_ApplyBaselineUpdate_Matched() {
        // Given: Matched comparison result
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetComparisonResult matchedResult = AssetComparisonResult.createMatched();
        BaselineUpdateService service = new BaselineUpdateService();

        // When: Apply baseline update for matched result
        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyBaselineUpdate(
            quoteLine,
            matchedResult,
            null,
            Date.today(),
            Date.today().addDays(30)
        );
        Test.stopTest();

        // Then: Quote line should be returned unchanged
        System.assertNotEquals(null, result, 'Should return quote line');
    }

    @isTest
    static void testBaselineUpdateService_TrackPickupLine() {
        // Given: Pickup quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__ProductName__c, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c LIMIT 1];
        quoteLine.SBQQ__ProductName__c = Constant_Util.PR_PICKUP;
        quoteLine.SBQQ__RequiredBy__c = quoteLine.Id;

        Map<Id, SBQQ__QuoteLine__c> pickupMap = new Map<Id, SBQQ__QuoteLine__c>();
        BaselineUpdateService service = new BaselineUpdateService();

        // When: Track pickup line
        Test.startTest();
        service.trackPickupLine(quoteLine, pickupMap);
        Test.stopTest();

        // Then: Should be added to map
        System.assertEquals(1, pickupMap.size(), 'Pickup line should be tracked');
    }

    @isTest
    static void testBaselineUpdateService_TrackExtraPickupLine() {
        // Given: Extra pickup quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__ProductName__c, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c LIMIT 1];
        quoteLine.SBQQ__ProductName__c = Constant_Util.PR_EXTRA_PICKUP;
        quoteLine.SBQQ__RequiredBy__c = quoteLine.Id;

        Map<Id, SBQQ__QuoteLine__c> extraPickupMap = new Map<Id, SBQQ__QuoteLine__c>();
        BaselineUpdateService service = new BaselineUpdateService();

        // When: Track extra pickup line
        Test.startTest();
        service.trackExtraPickupLine(quoteLine, extraPickupMap);
        Test.stopTest();

        // Then: Should be added to map
        System.assertEquals(1, extraPickupMap.size(), 'Extra pickup line should be tracked');
    }

    @isTest
    static void testBaselineUpdateService_IsExistingServiceCase() {
        // Given: Service
        BaselineUpdateService service = new BaselineUpdateService();

        // When/Then: Check case types
        Test.startTest();
        Boolean isExisting = service.isExistingServiceCase('Change Service');
        Boolean isNew = service.isExistingServiceCase(Constant_Util.New_Service_Case);
        Test.stopTest();

        System.assert(isExisting, 'Should be existing service case');
        System.assert(!isNew, 'Should not be existing service case');
    }

    @isTest
    static void testBaselineUpdateService_ApplyNewServiceUpdates() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductFamily__c, SBQQ__ProductName__c,
                   SBQQ__Quote__r.Name
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        BaselineUpdateService service = new BaselineUpdateService();

        // When: Apply new service updates
        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyNewServiceUpdates(
            quoteLine,
            Date.today(),
            Date.today().addDays(30)
        );
        Test.stopTest();

        // Then: Quote line should be updated
        System.assertNotEquals(null, result, 'Should return updated quote line');
    }

    @isTest
    static void testBaselineUpdateService_ApplyNewServiceCaseUpdates() {
        // Given: List of quote lines
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
        ];
        BaselineUpdateService service = new BaselineUpdateService();

        // When: Apply new service case updates
        Test.startTest();
        List<SBQQ__QuoteLine__c> result = service.applyNewServiceCaseUpdates(
            quoteLines,
            Date.today(),
            Date.today().addDays(30)
        );
        Test.stopTest();

        // Then: Should return updated lines
        System.assertNotEquals(null, result, 'Should return updated quote lines');
        System.assertEquals(quoteLines.size(), result.size(), 'Should return same number of lines');
    }

    // ==================================================================================
    // COMMERCIAL PRODUCT HANDLER TESTS
    // ==================================================================================

    @isTest
    static void testCommercialProductHandler_IsCommercialProduct() {
        // Given: Commercial product quote line
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductFamily__c, SBQQ__ProductCode__c, Equipment_Size__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        quoteLine.SBQQ__ProductFamily__c = Constant_Util.COMMERCIAL;

        CommercialProductHandler handler = new CommercialProductHandler();

        // When: Check if commercial
        Test.startTest();
        Boolean isCommercial = handler.isCommercialProduct(quoteLine);
        Test.stopTest();

        // Then: Should be commercial
        System.assert(isCommercial, 'Should be commercial product');
    }

    @isTest
    static void testCommercialProductHandler_IsCommercialProduct_Compactor() {
        // Given: Compactor quote line with size < 10
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductFamily__c, SBQQ__ProductCode__c, Equipment_Size__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        quoteLine.SBQQ__ProductCode__c = 'CMP';
        quoteLine.Equipment_Size__c = '8-9';
        quoteLine.SBQQ__ProductFamily__c = 'Industrial';

        CommercialProductHandler handler = new CommercialProductHandler();

        // When: Check if commercial
        Test.startTest();
        Boolean isCommercial = handler.isCommercialProduct(quoteLine);
        Test.stopTest();

        // Then: Should be commercial (compactor with size < 10)
        System.assert(isCommercial, 'Should be commercial (small compactor)');
    }

    @isTest
    static void testCommercialProductHandler_IsCommercialProduct_LargeCompactor() {
        // Given: Compactor quote line with size >= 10
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductFamily__c, SBQQ__ProductCode__c, Equipment_Size__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        quoteLine.SBQQ__ProductCode__c = 'CMP';
        quoteLine.Equipment_Size__c = '10-15';
        quoteLine.SBQQ__ProductFamily__c = 'Industrial';

        CommercialProductHandler handler = new CommercialProductHandler();

        // When: Check if commercial
        Test.startTest();
        Boolean isCommercial = handler.isCommercialProduct(quoteLine);
        Test.stopTest();

        // Then: Should not be commercial (large compactor)
        System.assert(!isCommercial, 'Should not be commercial (large compactor)');
    }

    @isTest
    static void testCommercialProductHandler_DetermineProductFamily() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductFamily__c, SBQQ__ProductCode__c, Equipment_Size__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        quoteLine.SBQQ__ProductFamily__c = Constant_Util.COMMERCIAL;

        CommercialProductHandler handler = new CommercialProductHandler();

        // When: Determine product family
        Test.startTest();
        String productFamily = handler.determineProductFamily(quoteLine);
        Test.stopTest();

        // Then: Should return commercial
        System.assertEquals(Constant_Util.COMMERCIAL, productFamily, 'Should return commercial family');
    }

    @isTest
    static void testCommercialProductHandler_DetermineProductFamily_Null() {
        // Given: Null quote line
        CommercialProductHandler handler = new CommercialProductHandler();

        // When: Determine product family for null
        Test.startTest();
        String productFamily = handler.determineProductFamily(null);
        Test.stopTest();

        // Then: Should return empty string
        System.assertEquals('', productFamily, 'Should return empty string for null');
    }

    @isTest
    static void testCommercialProductHandler_ShouldProcessCommercialProduct() {
        // Given: Commercial quote line and case type
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductFamily__c, SBQQ__ProductCode__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        quoteLine.SBQQ__ProductFamily__c = Constant_Util.COMMERCIAL;

        CommercialProductHandler handler = new CommercialProductHandler();

        // When: Check if should process
        Test.startTest();
        Boolean shouldProcess = handler.shouldProcessCommercialProduct(quoteLine, 'Change Service');
        Boolean shouldNotProcess = handler.shouldProcessCommercialProduct(quoteLine, Constant_Util.New_Service_Case);
        Test.stopTest();

        // Then: Should process for existing service, not for new service
        System.assert(shouldProcess, 'Should process for existing service case');
        System.assert(!shouldNotProcess, 'Should not process for new service case');
    }
}
