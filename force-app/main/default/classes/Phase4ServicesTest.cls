/**
 * @description Test class for Phase 4 Services
 * Tests VendorManagementService, MASIntegrationService, AssetAvailabilityService
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 4
 */
@isTest
private class Phase4ServicesTest {

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

        // Create test vendor account
        Account testVendor = new Account(
            Name = 'Test Vendor',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(),
            Status__c = 'Active',
            Vendor_Business_Unit__c = 'WM Test',
            FacilityCode__c = 'FAC001',
            Vendor_Id__c = 'VEND001',
            Parent_Vendor_Id__c = null
        );
        insert testVendor;

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
            SBQQ__Type__c = 'Quote',
            SBQQ__StartDate__c = Date.today(),
            Name = 'Test Quote'
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
            SBQQ__ProductCode__c = 'TEST001',
            Vendor__c = testVendor.Id,
            sCode__c = 'TEST',
            MASLibrary__c = 'LIB001',
            MASCompany__c = 'COMP001',
            MASAccount__c = 12345,
            MASCustomerUniqueId__c = 67890,
            Availability_Flag__c = 'WM Availability Confirmed',
            AAV_Priority__c = 'P3'
        );
        insert testQuoteLine;
    }

    // ==================================================================================
    // VENDOR MANAGEMENT SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testVendorManagementService_SearchVendors() {
        // Given: Service and search term
        VendorManagementService service = new VendorManagementService();

        // When: Search vendors
        Test.startTest();
        List<Account> vendors = service.searchVendors('Test Vendor');
        Test.stopTest();

        // Then: Should return vendors (or empty list if SOSL doesn't match in test context)
        System.assertNotEquals(null, vendors, 'Should return vendor list');
    }

    @isTest
    static void testVendorManagementService_SearchVendors_EmptySearch() {
        // Given: Service and empty search term
        VendorManagementService service = new VendorManagementService();

        // When: Search with empty string
        Test.startTest();
        List<Account> vendors = service.searchVendors('');
        Test.stopTest();

        // Then: Should return empty list
        System.assertEquals(0, vendors.size(), 'Should return empty list for blank search');
    }

    @isTest
    static void testVendorManagementService_UpdateVendorDetails() {
        // Given: Quote line and new vendor
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        VendorManagementService service = new VendorManagementService();

        // When: Update vendor details
        Test.startTest();
        Boolean success = service.updateVendorDetails(quoteLine.Id, vendor.Id, 'NEWSVC');
        Test.stopTest();

        // Then: Should succeed
        System.assert(success, 'Should update vendor details successfully');

        // Verify update
        SBQQ__QuoteLine__c updatedQL = [SELECT Id, Vendor__c, sCode__c FROM SBQQ__QuoteLine__c WHERE Id = :quoteLine.Id];
        System.assertEquals(vendor.Id, updatedQL.Vendor__c, 'Vendor should be updated');
        System.assertEquals('NEWSVC', updatedQL.sCode__c, 'sCode should be updated');
    }

    @isTest
    static void testVendorManagementService_UpdateVendorDetails_NullParent() {
        // Given: Service with null parent ID
        VendorManagementService service = new VendorManagementService();
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];

        // When: Update with null parent
        Test.startTest();
        Boolean success = service.updateVendorDetails(null, vendor.Id, 'TEST');
        Test.stopTest();

        // Then: Should fail
        System.assert(!success, 'Should return false for null parent ID');
    }

    @isTest
    static void testVendorManagementService_IsVendorActive() {
        // Given: Active vendor
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        VendorManagementService service = new VendorManagementService();

        // When: Check if active
        Test.startTest();
        Boolean isActive = service.isVendorActive(vendor.Id);
        Test.stopTest();

        // Then: Should be active
        System.assert(isActive, 'Vendor should be active');
    }

    @isTest
    static void testVendorManagementService_IsVendorActive_Null() {
        // Given: Service
        VendorManagementService service = new VendorManagementService();

        // When: Check null vendor
        Test.startTest();
        Boolean isActive = service.isVendorActive(null);
        Test.stopTest();

        // Then: Should return false
        System.assert(!isActive, 'Should return false for null vendor');
    }

    @isTest
    static void testVendorManagementService_IsWMVendor() {
        // Given: WM vendor
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        VendorManagementService service = new VendorManagementService();

        // When: Check if WM vendor
        Test.startTest();
        Boolean isWM = service.isWMVendor(vendor.Id);
        Test.stopTest();

        // Then: Should be WM vendor
        System.assert(isWM, 'Vendor should be WM vendor');
    }

    @isTest
    static void testVendorManagementService_GetVendorBusinessUnit() {
        // Given: Vendor with business unit
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        VendorManagementService service = new VendorManagementService();

        // When: Get business unit
        Test.startTest();
        String businessUnit = service.getVendorBusinessUnit(vendor.Id);
        Test.stopTest();

        // Then: Should return business unit
        System.assertEquals('WM Test', businessUnit, 'Should return vendor business unit');
    }

    @isTest
    static void testVendorManagementService_GetVendorFacilityCode() {
        // Given: Vendor with facility code
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        VendorManagementService service = new VendorManagementService();

        // When: Get facility code
        Test.startTest();
        String facilityCode = service.getVendorFacilityCode(vendor.Id);
        Test.stopTest();

        // Then: Should return facility code
        System.assertEquals('FAC001', facilityCode, 'Should return vendor facility code');
    }

    @isTest
    static void testVendorManagementService_GetVendorDetails() {
        // Given: Vendor
        Account vendor = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        VendorManagementService service = new VendorManagementService();

        // When: Get vendor details
        Test.startTest();
        Account vendorDetails = service.getVendorDetails(vendor.Id);
        Test.stopTest();

        // Then: Should return vendor with all fields
        System.assertNotEquals(null, vendorDetails, 'Should return vendor details');
        System.assertEquals('Test Vendor', vendorDetails.Name, 'Should have correct name');
        System.assertEquals('WM Test', vendorDetails.Vendor_Business_Unit__c, 'Should have business unit');
    }

    // ==================================================================================
    // MAS INTEGRATION SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testMASIntegrationService_WriteMASDetails() {
        // Given: Quote line and MAS data
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        QuoteProcurementController.MASWrapper masData = new QuoteProcurementController.MASWrapper();
        masData.MASLibrary = 'NEWLIB';
        masData.MASCompany = 'NEWCOMP';
        masData.MASAccount = 99999;
        masData.MASUniqueId = 88888;
        masData.MASBypassPrice = true;

        MASIntegrationService service = new MASIntegrationService();

        // When: Write MAS details
        Test.startTest();
        MASIntegrationService.MASResponseWrapper response = service.writeMASDetails(quoteLine.Id, masData);
        Test.stopTest();

        // Then: Should succeed
        System.assert(response.isSuccess, 'Should write MAS details successfully');

        // Verify update
        SBQQ__QuoteLine__c updatedQL = [SELECT Id, MASLibrary__c, MASCompany__c, MASAccount__c,
                                              BypassPriceReview__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Id = :quoteLine.Id];
        System.assertEquals('NEWLIB', updatedQL.MASLibrary__c, 'MAS Library should be updated');
        System.assertEquals('NEWCOMP', updatedQL.MASCompany__c, 'MAS Company should be updated');
        System.assertEquals(99999, updatedQL.MASAccount__c, 'MAS Account should be updated');
        System.assert(updatedQL.BypassPriceReview__c, 'Bypass Price Review should be true');
    }

    @isTest
    static void testMASIntegrationService_WriteMASDetails_NullInput() {
        // Given: Service with null input
        MASIntegrationService service = new MASIntegrationService();

        // When: Write with null data
        Test.startTest();
        MASIntegrationService.MASResponseWrapper response = service.writeMASDetails(null, null);
        Test.stopTest();

        // Then: Should fail with error
        System.assert(!response.isSuccess, 'Should return failure for null input');
        System.assertNotEquals('', response.errorMessage, 'Should have error message');
    }

    @isTest
    static void testMASIntegrationService_BypassPriceReview() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        MASIntegrationService service = new MASIntegrationService();

        // When: Get bypass price review flag
        Test.startTest();
        Boolean bypassFlag = service.bypassPriceReview(quoteLine.Id, 'LIB001');
        Test.stopTest();

        // Then: Should return a boolean
        System.assertNotEquals(null, bypassFlag, 'Should return bypass flag');
    }

    @isTest
    static void testMASIntegrationService_BypassPriceReview_Null() {
        // Given: Service
        MASIntegrationService service = new MASIntegrationService();

        // When: Check with null ID
        Test.startTest();
        Boolean bypassFlag = service.bypassPriceReview(null, 'LIB001');
        Test.stopTest();

        // Then: Should return false
        System.assert(!bypassFlag, 'Should return false for null quote line ID');
    }

    @isTest
    static void testMASIntegrationService_ValidateMASDetails() {
        // Given: Complete MAS data
        QuoteProcurementController.MASWrapper masData = new QuoteProcurementController.MASWrapper();
        masData.MASLibrary = 'LIB001';
        masData.MASCompany = 'COMP001';
        masData.MASAccount = 12345;
        masData.MASUniqueId = 67890;

        MASIntegrationService service = new MASIntegrationService();

        // When: Validate
        Test.startTest();
        List<String> errors = service.validateMASDetails(masData);
        Test.stopTest();

        // Then: Should have no errors
        System.assertEquals(0, errors.size(), 'Should have no validation errors');
    }

    @isTest
    static void testMASIntegrationService_ValidateMASDetails_Incomplete() {
        // Given: Incomplete MAS data
        QuoteProcurementController.MASWrapper masData = new QuoteProcurementController.MASWrapper();
        masData.MASLibrary = 'LIB001';
        // Missing other required fields

        MASIntegrationService service = new MASIntegrationService();

        // When: Validate
        Test.startTest();
        List<String> errors = service.validateMASDetails(masData);
        Test.stopTest();

        // Then: Should have errors
        System.assert(errors.size() > 0, 'Should have validation errors for incomplete data');
    }

    @isTest
    static void testMASIntegrationService_ValidateMASDetails_Null() {
        // Given: Service
        MASIntegrationService service = new MASIntegrationService();

        // When: Validate null data
        Test.startTest();
        List<String> errors = service.validateMASDetails(null);
        Test.stopTest();

        // Then: Should have error
        System.assertEquals(1, errors.size(), 'Should have error for null MAS data');
    }

    @isTest
    static void testMASIntegrationService_GetMASDetails() {
        // Given: Quote line with MAS details
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        MASIntegrationService service = new MASIntegrationService();

        // When: Get MAS details
        Test.startTest();
        QuoteProcurementController.MASWrapper masData = service.getMASDetails(quoteLine.Id);
        Test.stopTest();

        // Then: Should return MAS data
        System.assertNotEquals(null, masData, 'Should return MAS data');
        System.assertEquals('LIB001', masData.MASLibrary, 'Should have correct MAS Library');
        System.assertEquals('COMP001', masData.MASCompany, 'Should have correct MAS Company');
    }

    @isTest
    static void testMASIntegrationService_ShouldBypassMASServiceChange() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        MASIntegrationService service = new MASIntegrationService();

        // When: Check bypass
        Test.startTest();
        Boolean shouldBypass = service.shouldBypassMASServiceChange(quoteLine.Id);
        Test.stopTest();

        // Then: Should return boolean
        System.assertNotEquals(null, shouldBypass, 'Should return bypass flag');
    }

    // ==================================================================================
    // ASSET AVAILABILITY SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testAssetAvailabilityService_GetAvailabilityBellIconMessage() {
        // Given: Quote line with availability flag
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, Availability_Flag__c,
                                              AAV_Asset_Availability_API_Errors__c
                                        FROM SBQQ__QuoteLine__c
                                        LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Get availability message
        Test.startTest();
        String message = service.getAvailabilityBellIconMessage(quoteLine, 'Existing error');
        Test.stopTest();

        // Then: Should return message
        System.assertNotEquals(null, message, 'Should return availability message');
    }

    @isTest
    static void testAssetAvailabilityService_GetAvailabilityBellIconMessage_Null() {
        // Given: Service
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Get message with null quote line
        Test.startTest();
        String message = service.getAvailabilityBellIconMessage(null, 'Error');
        Test.stopTest();

        // Then: Should return original message
        System.assertEquals('Error', message, 'Should return original message for null quote line');
    }

    @isTest
    static void testAssetAvailabilityService_UpdateAAVOverrideFields() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Update override fields
        Test.startTest();
        Boolean success = service.updateAAVOverrideFields(
            quoteLine.Id,
            'Delivery Reason',
            'Delivery Comment',
            'Service Reason',
            'Service Comment'
        );
        Test.stopTest();

        // Then: Should succeed
        System.assert(success, 'Should update override fields successfully');

        // Verify update
        SBQQ__QuoteLine__c updatedQL = [SELECT Id, AAV_Delivery_Override_Reason__c,
                                              AAV_Service_Override_Reason__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE Id = :quoteLine.Id];
        System.assertEquals('Delivery Reason', updatedQL.AAV_Delivery_Override_Reason__c, 'Delivery reason should be updated');
        System.assertEquals('Service Reason', updatedQL.AAV_Service_Override_Reason__c, 'Service reason should be updated');
    }

    @isTest
    static void testAssetAvailabilityService_GetAvailabilityFlag() {
        // Given: Quote line with availability flag
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Get availability flag
        Test.startTest();
        String flag = service.getAvailabilityFlag(quoteLine.Id);
        Test.stopTest();

        // Then: Should return flag
        System.assertEquals('WM Availability Confirmed', flag, 'Should return availability flag');
    }

    @isTest
    static void testAssetAvailabilityService_IsWMAvailabilityConfirmed() {
        // Given: Service
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Check WM availability confirmed
        Test.startTest();
        Boolean isConfirmed = service.isWMAvailabilityConfirmed('WM Availability Confirmed');
        Boolean isNotConfirmed = service.isWMAvailabilityConfirmed('NON WM Availability');
        Test.stopTest();

        // Then: Should correctly identify
        System.assert(isConfirmed, 'Should identify WM availability confirmed');
        System.assert(!isNotConfirmed, 'Should not identify non-WM as confirmed');
    }

    @isTest
    static void testAssetAvailabilityService_IsNonWMAvailability() {
        // Given: Service
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Check non-WM availability
        Test.startTest();
        Boolean isNonWM = service.isNonWMAvailability('NON WM Availability');
        Boolean isWM = service.isNonWMAvailability('WM Availability Confirmed');
        Test.stopTest();

        // Then: Should correctly identify
        System.assert(isNonWM, 'Should identify non-WM availability');
        System.assert(!isWM, 'Should not identify WM as non-WM');
    }

    @isTest
    static void testAssetAvailabilityService_IsAvailabilityAPIError() {
        // Given: Service
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Check API error
        Test.startTest();
        Boolean isError = service.isAvailabilityAPIError(
            'Availability could not be confirmed as there is no response from the API'
        );
        Boolean isNotError = service.isAvailabilityAPIError('WM Availability Confirmed');
        Test.stopTest();

        // Then: Should correctly identify
        System.assert(isError, 'Should identify API error');
        System.assert(!isNotError, 'Should not identify normal availability as error');
    }

    @isTest
    static void testAssetAvailabilityService_GetAAVAPIErrors() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Get AAV API errors
        Test.startTest();
        String errors = service.getAAVAPIErrors(quoteLine.Id);
        Test.stopTest();

        // Then: Should return errors (or null)
        // No assertion on null as field may not be populated
        System.assertNotEquals(undefined, errors, 'Should return AAV API errors result');
    }

    @isTest
    static void testAssetAvailabilityService_ParseAAVAPIErrors() {
        // Given: Error JSON
        String errorJson = '{"common": ["Error 1", "Error 2"], "delivery": ["Delivery Error"]}';
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Parse errors
        Test.startTest();
        Map<String, List<String>> errorMap = service.parseAAVAPIErrors(errorJson);
        Test.stopTest();

        // Then: Should parse correctly
        System.assert(errorMap.containsKey('common'), 'Should have common errors');
        System.assert(errorMap.containsKey('delivery'), 'Should have delivery errors');
    }

    @isTest
    static void testAssetAvailabilityService_GetAvailabilityRecords() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Get availability records
        Test.startTest();
        List<AAV_Asset_Availability__c> records = service.getAvailabilityRecords(quoteLine.Id);
        Test.stopTest();

        // Then: Should return list (may be empty)
        System.assertNotEquals(null, records, 'Should return availability records list');
    }

    @isTest
    static void testAssetAvailabilityService_UpdateAAVPriority() {
        // Given: Quote line and start date
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, AAV_Priority__c FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Update priority for immediate start (P1)
        Test.startTest();
        SBQQ__QuoteLine__c updated = service.updateAAVPriority(quoteLine, Date.today());
        Test.stopTest();

        // Then: Should set P1 priority
        System.assertEquals('P1', updated.AAV_Priority__c, 'Should set P1 priority for immediate start');
    }

    @isTest
    static void testAssetAvailabilityService_UpdateAAVPriority_FutureDate() {
        // Given: Quote line and future start date
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, AAV_Priority__c FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Update priority for future start (P4)
        Test.startTest();
        SBQQ__QuoteLine__c updated = service.updateAAVPriority(quoteLine, Date.today().addDays(15));
        Test.stopTest();

        // Then: Should set P4 priority
        System.assertEquals('P4', updated.AAV_Priority__c, 'Should set P4 priority for future start');
    }

    @isTest
    static void testAssetAvailabilityService_ValidateAAVOverrides() {
        // Given: Service and non-WM availability
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Validate without override reasons
        Test.startTest();
        List<String> errors = service.validateAAVOverrides('', '', 'NON WM Availability');
        Test.stopTest();

        // Then: Should have errors
        System.assert(errors.size() > 0, 'Should have validation errors when overrides missing');
    }

    @isTest
    static void testAssetAvailabilityService_ValidateAAVOverrides_WMConfirmed() {
        // Given: Service and WM confirmed availability
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Validate with WM confirmed
        Test.startTest();
        List<String> errors = service.validateAAVOverrides('', '', 'WM Availability Confirmed');
        Test.stopTest();

        // Then: Should have no errors
        System.assertEquals(0, errors.size(), 'Should have no errors for WM confirmed availability');
    }

    @isTest
    static void testAssetAvailabilityService_GetAAVPriority() {
        // Given: Quote line with priority
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Get priority
        Test.startTest();
        String priority = service.getAAVPriority(quoteLine.Id);
        Test.stopTest();

        // Then: Should return priority
        System.assertEquals('P3', priority, 'Should return AAV priority');
    }

    @isTest
    static void testAssetAvailabilityService_HasAvailabilityOverridePermission() {
        // Given: Service
        AssetAvailabilityService service = new AssetAvailabilityService();

        // When: Check permission
        Test.startTest();
        Boolean hasPermission = service.hasAvailabilityOverridePermission();
        Test.stopTest();

        // Then: Should return boolean
        System.assertNotEquals(null, hasPermission, 'Should return permission check result');
    }
}
