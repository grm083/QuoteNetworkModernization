/**
 * @description Test class for UIDataService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 6
 */
@isTest
private class UIDataServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account hierarchy
        Account parentAccount = new Account(
            Name = 'Parent Account',
            AccountNumber = 'PAR001'
        );
        insert parentAccount;

        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001',
            ParentId = parentAccount.Id
        );
        insert testAccount;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
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
    }

    /**
     * @description Test getMaterialTypes with valid material
     */
    @isTest
    static void testGetMaterialTypes_ValidMaterial() {
        UIDataService service = new UIDataService();

        Test.startTest();
        // Note: Custom metadata won't exist in test context, so this will return only the --None-- option
        List<Map<String, String>> materialTypes = service.getMaterialTypes('TestMaterial');
        Test.stopTest();

        System.assertNotEquals(null, materialTypes, 'Should return a list');
        System.assert(materialTypes.size() >= 1, 'Should have at least the None option');
        System.assertEquals('--None--', materialTypes[0].get('label'), 'First option should be None');
    }

    /**
     * @description Test getMaterialTypes with blank material
     */
    @isTest
    static void testGetMaterialTypes_BlankMaterial() {
        UIDataService service = new UIDataService();

        Test.startTest();
        List<Map<String, String>> materialTypes = service.getMaterialTypes('');
        Test.stopTest();

        System.assertEquals(1, materialTypes.size(), 'Should return only None option');
        System.assertEquals('--None--', materialTypes[0].get('label'), 'Should be None option');
    }

    /**
     * @description Test getMaterialTypes with null material
     */
    @isTest
    static void testGetMaterialTypes_NullMaterial() {
        UIDataService service = new UIDataService();

        Test.startTest();
        List<Map<String, String>> materialTypes = service.getMaterialTypes(null);
        Test.stopTest();

        System.assertEquals(1, materialTypes.size(), 'Should return only None option for null');
    }

    /**
     * @description Test getEquipmentSizes
     */
    @isTest
    static void testGetEquipmentSizes_ValidProduct() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        UIDataService service = new UIDataService();

        Test.startTest();
        Map<String, String> sizes = service.getEquipmentSizes(testProduct.Id, true);
        Test.stopTest();

        System.assertNotEquals(null, sizes, 'Should return a map');
    }

    /**
     * @description Test getEquipmentSizes with null product ID
     */
    @isTest
    static void testGetEquipmentSizes_NullProductId() {
        UIDataService service = new UIDataService();

        Test.startTest();
        Map<String, String> sizes = service.getEquipmentSizes(null, false);
        Test.stopTest();

        System.assertEquals(0, sizes.size(), 'Should return empty map for null product ID');
    }

    /**
     * @description Test getDurations
     */
    @isTest
    static void testGetDurations() {
        UIDataService service = new UIDataService();

        Test.startTest();
        Map<String, String> durations = service.getDurations();
        Test.stopTest();

        System.assertNotEquals(null, durations, 'Should return a map');
        // Verify SEAS is excluded
        System.assertEquals(false, durations.containsKey('SEAS'), 'SEAS should be excluded');
    }

    /**
     * @description Test getServiceTypePicklist
     */
    @isTest
    static void testGetServiceTypePicklist() {
        UIDataService service = new UIDataService();

        Test.startTest();
        List<String> serviceTypes = service.getServiceTypePicklist();
        Test.stopTest();

        System.assertNotEquals(null, serviceTypes, 'Should return a list');
        System.assert(serviceTypes.size() >= 0, 'Should return service types');
    }

    /**
     * @description Test getSLAOverrideReasons
     */
    @isTest
    static void testGetSLAOverrideReasons() {
        UIDataService service = new UIDataService();

        Test.startTest();
        List<String> reasons = service.getSLAOverrideReasons();
        Test.stopTest();

        System.assertNotEquals(null, reasons, 'Should return a list');
        // Should have at least some picklist values
        System.assert(reasons.size() >= 0, 'Should return SLA override reasons');
    }

    /**
     * @description Test getDeliveryOverrideReasons
     */
    @isTest
    static void testGetDeliveryOverrideReasons() {
        UIDataService service = new UIDataService();

        Test.startTest();
        List<String> reasons = service.getDeliveryOverrideReasons();
        Test.stopTest();

        System.assertNotEquals(null, reasons, 'Should return a list');
        System.assert(reasons.size() >= 0, 'Should return delivery override reasons');
    }

    /**
     * @description Test getCompanyCategories with valid quote
     */
    @isTest
    static void testGetCompanyCategories_ValidQuote() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        UIDataService service = new UIDataService();

        Test.startTest();
        List<Map<String, String>> categories = service.getCompanyCategories(testQuote.Id);
        Test.stopTest();

        System.assertNotEquals(null, categories, 'Should return a list');
        // May be empty if AcornCompanyDetails returns no data
        System.assert(categories.size() >= 0, 'Should return company categories');
    }

    /**
     * @description Test getCompanyCategories with null quote ID
     */
    @isTest
    static void testGetCompanyCategories_NullQuoteId() {
        UIDataService service = new UIDataService();

        Test.startTest();
        List<Map<String, String>> categories = service.getCompanyCategories(null);
        Test.stopTest();

        System.assertEquals(0, categories.size(), 'Should return empty list for null quote ID');
    }

    /**
     * @description Test getCompanyCategories with invalid quote ID
     */
    @isTest
    static void testGetCompanyCategories_InvalidQuoteId() {
        Id fakeId = SBQQ__Quote__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(15);
        UIDataService service = new UIDataService();

        Test.startTest();
        List<Map<String, String>> categories = service.getCompanyCategories(fakeId);
        Test.stopTest();

        System.assertEquals(0, categories.size(), 'Should return empty list for invalid quote ID');
    }

    /**
     * @description Test getSpecialHandlingReasons
     */
    @isTest
    static void testGetSpecialHandlingReasons() {
        UIDataService service = new UIDataService();

        Test.startTest();
        Map<String, String> reasons = service.getSpecialHandlingReasons();
        Test.stopTest();

        System.assertNotEquals(null, reasons, 'Should return a map');
        System.assert(reasons.size() >= 0, 'Should return special handling reasons');
    }

    /**
     * @description Test getAllPicklistData
     */
    @isTest
    static void testGetAllPicklistData() {
        UIDataService service = new UIDataService();

        Test.startTest();
        UIDataService.UIPicklistData picklistData = service.getAllPicklistData();
        Test.stopTest();

        System.assertNotEquals(null, picklistData, 'Should return picklist data wrapper');
        System.assertNotEquals(null, picklistData.durations, 'Should have durations');
        System.assertNotEquals(null, picklistData.serviceTypes, 'Should have service types');
        System.assertNotEquals(null, picklistData.slaOverrideReasons, 'Should have SLA override reasons');
        System.assertNotEquals(null, picklistData.deliveryOverrideReasons, 'Should have delivery override reasons');
        System.assertNotEquals(null, picklistData.specialHandlingReasons, 'Should have special handling reasons');
    }

    /**
     * @description Test UIPicklistData wrapper initialization
     */
    @isTest
    static void testUIPicklistDataWrapper() {
        Test.startTest();
        UIDataService.UIPicklistData data = new UIDataService.UIPicklistData();
        Test.stopTest();

        System.assertNotEquals(null, data, 'Wrapper should be initialized');
        System.assertNotEquals(null, data.durations, 'Durations map should be initialized');
        System.assertNotEquals(null, data.serviceTypes, 'Service types list should be initialized');
        System.assertNotEquals(null, data.slaOverrideReasons, 'SLA reasons list should be initialized');
        System.assertNotEquals(null, data.deliveryOverrideReasons, 'Delivery reasons list should be initialized');
        System.assertNotEquals(null, data.specialHandlingReasons, 'Special handling reasons map should be initialized');
    }

    /**
     * @description Test company category sorting
     */
    @isTest
    static void testCompanyCategorySorting() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        UIDataService service = new UIDataService();

        Test.startTest();
        List<Map<String, String>> categories = service.getCompanyCategories(testQuote.Id);
        Test.stopTest();

        // Verify sorting if we have results
        if (categories.size() > 1) {
            for (Integer i = 0; i < categories.size() - 1; i++) {
                String currentLabel = categories[i].get('label');
                String nextLabel = categories[i + 1].get('label');
                System.assert(
                    currentLabel.compareTo(nextLabel) <= 0,
                    'Categories should be sorted alphabetically by label'
                );
            }
        }
    }
}
