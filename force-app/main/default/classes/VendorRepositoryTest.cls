/**
 * @description Test class for VendorRepository
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class VendorRepositoryTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create parent vendor accounts
        List<Account> parentVendors = new List<Account>{
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
            )
        };
        insert parentVendors;

        // Create child vendor accounts
        List<Account> childVendors = new List<Account>{
            new Account(
                Name = 'WM Child Vendor 1',
                Vendor_ID__c = 'WM_CHILD_1',
                Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR,
                Status__c = 'Active',
                Customer_Code__c = 'WM003'
            ),
            new Account(
                Name = 'Inactive Vendor',
                Vendor_ID__c = 'INACTIVE_001',
                Parent_Vendor_ID__c = 'INACTIVE_PARENT',
                Status__c = 'Inactive',
                Customer_Code__c = 'INACT001'
            )
        };
        insert childVendors;

        // Create pricing requests with pipe-delimited vendor codes
        Account testAccount = new Account(
            Name = 'Test Customer',
            AccountNumber = 'CUST001'
        );
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;

        List<Pricing_Request__c> pricingRequests = new List<Pricing_Request__c>{
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Vendor_Code__c = 'WM_US|additional_info',
                Pricing_Type__c = 'AM'
            ),
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Vendor_Code__c = 'TP001',
                Pricing_Type__c = 'AM'
            )
        };
        insert pricingRequests;
    }

    /**
     * @description Test getActiveVendorsByIds with valid vendor IDs
     */
    @isTest
    static void testGetActiveVendorsByIds_Success() {
        Set<String> vendorIds = new Set<String>{'WM_US', 'TP001'};
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        List<Account> vendors = repo.getActiveVendorsByIds(vendorIds);
        Test.stopTest();

        System.assertEquals(2, vendors.size(), 'Should return 2 active vendors');
        for (Account vendor : vendors) {
            System.assertEquals('Active', vendor.Status__c, 'Should only return active vendors');
        }
    }

    /**
     * @description Test getActiveVendorsByIds excludes inactive vendors
     */
    @isTest
    static void testGetActiveVendorsByIds_ExcludesInactive() {
        Set<String> vendorIds = new Set<String>{'WM_US', 'INACTIVE_001'};
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        List<Account> vendors = repo.getActiveVendorsByIds(vendorIds);
        Test.stopTest();

        System.assertEquals(1, vendors.size(), 'Should only return active vendor');
        System.assertEquals('WM_US', vendors[0].Vendor_ID__c, 'Should return WM_US only');
    }

    /**
     * @description Test getActiveVendorsByIds with empty set
     */
    @isTest
    static void testGetActiveVendorsByIds_EmptySet() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        List<Account> vendors = repo.getActiveVendorsByIds(new Set<String>());
        Test.stopTest();

        System.assertEquals(0, vendors.size(), 'Empty set should return empty list');
    }

    /**
     * @description Test getActiveVendorMapByIds creates proper map
     */
    @isTest
    static void testGetActiveVendorMapByIds_Success() {
        Set<String> vendorIds = new Set<String>{'WM_US', 'TP001', 'WM_CHILD_1'};
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Map<String, Account> vendorMap = repo.getActiveVendorMapByIds(vendorIds);
        Test.stopTest();

        System.assertEquals(3, vendorMap.size(), 'Should return map with 3 vendors');
        System.assert(vendorMap.containsKey('WM_US'), 'Map should contain WM_US key');
        System.assert(vendorMap.containsKey('TP001'), 'Map should contain TP001 key');
        System.assertEquals('WM US Vendor', vendorMap.get('WM_US').Name, 'Map should have correct vendor');
    }

    /**
     * @description Test getVendorsByParentVendorIds
     */
    @isTest
    static void testGetVendorsByParentVendorIds_Success() {
        Set<String> parentIds = new Set<String>{Constant_Util.WM_US_VENDOR};
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        List<Account> vendors = repo.getVendorsByParentVendorIds(parentIds);
        Test.stopTest();

        System.assert(vendors.size() >= 2, 'Should return WM US vendors');
        for (Account vendor : vendors) {
            System.assertEquals(Constant_Util.WM_US_VENDOR, vendor.Parent_Vendor_ID__c,
                              'Should only return vendors with WM_US parent');
        }
    }

    /**
     * @description Test getActiveVendorById with valid ID
     */
    @isTest
    static void testGetActiveVendorById_Found() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account vendor = repo.getActiveVendorById('WM_US');
        Test.stopTest();

        System.assertNotEquals(null, vendor, 'Should find vendor');
        System.assertEquals('WM_US', vendor.Vendor_ID__c, 'Should return correct vendor');
        System.assertEquals('WM US Vendor', vendor.Name, 'Should return correct vendor name');
    }

    /**
     * @description Test getActiveVendorById with invalid ID
     */
    @isTest
    static void testGetActiveVendorById_NotFound() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account vendor = repo.getActiveVendorById('NONEXISTENT');
        Test.stopTest();

        System.assertEquals(null, vendor, 'Should return null for nonexistent vendor');
    }

    /**
     * @description Test getActiveVendorById with null input
     */
    @isTest
    static void testGetActiveVendorById_NullInput() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account vendor = repo.getActiveVendorById(null);
        Test.stopTest();

        System.assertEquals(null, vendor, 'Null input should return null');
    }

    /**
     * @description Test getVendorByAccountId
     */
    @isTest
    static void testGetVendorByAccountId_Success() {
        Account testVendor = [SELECT Id FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account vendor = repo.getVendorByAccountId(testVendor.Id);
        Test.stopTest();

        System.assertNotEquals(null, vendor, 'Should find vendor by Account ID');
        System.assertEquals('WM_US', vendor.Vendor_ID__c, 'Should return correct vendor');
    }

    /**
     * @description Test extractVendorCode with pipe-delimited value
     */
    @isTest
    static void testExtractVendorCode_WithPipe() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        String result = repo.extractVendorCode('WM_US|additional_info|more_data');
        Test.stopTest();

        System.assertEquals('WM_US', result, 'Should extract vendor code before pipe');
    }

    /**
     * @description Test extractVendorCode without pipe
     */
    @isTest
    static void testExtractVendorCode_NoPipe() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        String result = repo.extractVendorCode('WM_US');
        Test.stopTest();

        System.assertEquals('WM_US', result, 'Should return vendor code as-is');
    }

    /**
     * @description Test extractVendorCode with null input
     */
    @isTest
    static void testExtractVendorCode_Null() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        String result = repo.extractVendorCode(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Null input should return null');
    }

    /**
     * @description Test extractVendorCodesFromPricingRequests
     */
    @isTest
    static void testExtractVendorCodesFromPricingRequests_Success() {
        List<Pricing_Request__c> prs = [SELECT Id, Vendor_Code__c FROM Pricing_Request__c];
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Set<String> vendorCodes = repo.extractVendorCodesFromPricingRequests(prs);
        Test.stopTest();

        System.assertEquals(2, vendorCodes.size(), 'Should extract 2 vendor codes');
        System.assert(vendorCodes.contains('WM_US'), 'Should contain WM_US (extracted from pipe)');
        System.assert(vendorCodes.contains('TP001'), 'Should contain TP001');
    }

    /**
     * @description Test extractVendorCodesFromPricingRequests with empty list
     */
    @isTest
    static void testExtractVendorCodesFromPricingRequests_EmptyList() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Set<String> vendorCodes = repo.extractVendorCodesFromPricingRequests(
            new List<Pricing_Request__c>()
        );
        Test.stopTest();

        System.assertEquals(0, vendorCodes.size(), 'Empty list should return empty set');
    }

    /**
     * @description Test getVendorFromMap with valid map and code
     */
    @isTest
    static void testGetVendorFromMap_Success() {
        Set<String> vendorIds = new Set<String>{'WM_US', 'TP001'};
        VendorRepository repo = new VendorRepository();
        Map<String, Account> vendorMap = repo.getActiveVendorMapByIds(vendorIds);

        Test.startTest();
        Account vendor1 = repo.getVendorFromMap(vendorMap, 'WM_US|extra_data');
        Account vendor2 = repo.getVendorFromMap(vendorMap, 'TP001');
        Test.stopTest();

        System.assertNotEquals(null, vendor1, 'Should find vendor with pipe-delimited code');
        System.assertEquals('WM_US', vendor1.Vendor_ID__c, 'Should return correct vendor');
        System.assertNotEquals(null, vendor2, 'Should find vendor with simple code');
        System.assertEquals('TP001', vendor2.Vendor_ID__c, 'Should return correct vendor');
    }

    /**
     * @description Test getVendorFromMap with null map
     */
    @isTest
    static void testGetVendorFromMap_NullMap() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Account vendor = repo.getVendorFromMap(null, 'WM_US');
        Test.stopTest();

        System.assertEquals(null, vendor, 'Null map should return null');
    }

    /**
     * @description Test getAllActiveVendors
     */
    @isTest
    static void testGetAllActiveVendors_Success() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        List<Account> vendors = repo.getAllActiveVendors();
        Test.stopTest();

        System.assert(vendors.size() >= 4, 'Should return at least 4 active vendors');
        for (Account vendor : vendors) {
            System.assertEquals('Active', vendor.Status__c, 'Should only return active vendors');
            System.assertNotEquals(null, vendor.Vendor_ID__c, 'Should have Vendor_ID__c');
        }
    }

    /**
     * @description Test isWMVendor with US vendor
     */
    @isTest
    static void testIsWMVendor_USVendor() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Boolean isWM = repo.isWMVendor(Constant_Util.WM_US_VENDOR);
        Test.stopTest();

        System.assertEquals(true, isWM, 'WM US vendor should return true');
    }

    /**
     * @description Test isWMVendor with Canada vendor
     */
    @isTest
    static void testIsWMVendor_CanadaVendor() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Boolean isWM = repo.isWMVendor(Constant_Util.WM_CANADA_VENDOR);
        Test.stopTest();

        System.assertEquals(true, isWM, 'WM Canada vendor should return true');
    }

    /**
     * @description Test isWMVendor with third party vendor
     */
    @isTest
    static void testIsWMVendor_ThirdParty() {
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        Boolean isWM = repo.isWMVendor('TP_PARENT');
        Test.stopTest();

        System.assertEquals(false, isWM, 'Third party vendor should return false');
    }

    /**
     * @description Test getVendorsWithDetails
     */
    @isTest
    static void testGetVendorsWithDetails_Success() {
        Set<String> vendorIds = new Set<String>{'WM_US', 'TP001'};
        VendorRepository repo = new VendorRepository();

        Test.startTest();
        List<Account> vendors = repo.getVendorsWithDetails(vendorIds);
        Test.stopTest();

        System.assertEquals(2, vendors.size(), 'Should return 2 vendors with details');
        System.assertNotEquals(null, vendors[0].Customer_Code__c, 'Should include extended fields');
    }
}
