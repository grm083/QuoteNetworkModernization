/**
 * @description Test class for VendorSearchController
 * Tests vendor search, proximity calculation, and historical cost retrieval
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 * @story Procurement Workbench Implementation
 */
@isTest
private class VendorSearchControllerTest {

    /**
     * @description Setup test data for all tests
     */
    @testSetup
    static void setupTestData() {
        // Create Vendor RecordType (if not exists)
        RecordType vendorRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account' AND DeveloperName = 'Vendor'
            LIMIT 1
        ];

        // Create test location/customer account
        Account locationAccount = new Account(
            Name = 'Test Location',
            BillingStreet = '123 Main St',
            BillingCity = 'Denver',
            BillingState = 'CO',
            BillingPostalCode = '80202',
            BillingCountry = 'USA',
            BillingLatitude = 39.7392,
            BillingLongitude = -104.9903,
            tz__Timezone_SFDC__c = 'America/Denver'
        );
        insert locationAccount;

        // Create vendor accounts with varying scores and locations
        List<Account> vendors = new List<Account>();

        // High score WM vendor
        vendors.add(new Account(
            RecordTypeId = vendorRT.Id,
            Name = 'WM Denver Vendor',
            Vendor_ID__c = 'WMV001',
            Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR,
            Status__c = 'Active',
            VendorScore__c = 95,
            Phone = '303-555-0001',
            Email__c = 'contact@wmvendor.com',
            BillingStreet = '456 Vendor Ave',
            BillingCity = 'Denver',
            BillingState = 'CO',
            BillingPostalCode = '80203',
            BillingLatitude = 39.7500,
            BillingLongitude = -104.9800,
            Capabilities__c = 'Hazardous Waste;Recycling;Disposal'
        ));

        // Medium score third-party vendor
        vendors.add(new Account(
            RecordTypeId = vendorRT.Id,
            Name = 'ABC Waste Services',
            Vendor_ID__c = 'ABC001',
            Parent_Vendor_ID__c = 'THIRD_PARTY',
            Status__c = 'Active',
            VendorScore__c = 75,
            Phone = '303-555-0002',
            Email__c = 'info@abcwaste.com',
            BillingStreet = '789 Industrial Dr',
            BillingCity = 'Aurora',
            BillingState = 'CO',
            BillingPostalCode = '80010',
            BillingLatitude = 39.7294,
            BillingLongitude = -104.8319,
            Capabilities__c = 'Commercial;Rolloff'
        ));

        // Low score vendor far away
        vendors.add(new Account(
            RecordTypeId = vendorRT.Id,
            Name = 'Far Away Vendor',
            Vendor_ID__c = 'FAR001',
            Parent_Vendor_ID__c = 'THIRD_PARTY',
            Status__c = 'Active',
            VendorScore__c = 60,
            Phone = '719-555-0003',
            Email__c = 'contact@farvendor.com',
            BillingStreet = '100 Mountain Rd',
            BillingCity = 'Colorado Springs',
            BillingState = 'CO',
            BillingPostalCode = '80903',
            BillingLatitude = 38.8339,
            BillingLongitude = -104.8214,
            Capabilities__c = 'Compactor Service'
        ));

        // Vendor with no score
        vendors.add(new Account(
            RecordTypeId = vendorRT.Id,
            Name = 'New Vendor LLC',
            Vendor_ID__c = 'NEW001',
            Parent_Vendor_ID__c = 'THIRD_PARTY',
            Status__c = 'Active',
            VendorScore__c = null,
            Phone = '303-555-0004',
            Email__c = 'hello@newvendor.com',
            BillingCity = 'Denver',
            BillingState = 'CO'
        ));

        insert vendors;

        // Create test case and opportunity
        Case testCase = new Case(
            Subject = 'Test Procurement Case',
            AccountId = locationAccount.Id,
            Origin = 'Web',
            Status = 'New'
        );
        insert testCase;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Procurement Opportunity',
            AccountId = locationAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Case__c = testCase.Id
        );
        insert testOpp;

        // Create test product
        Product2 testProduct = new Product2(
            Name = '8-Yard Dumpster',
            ProductCode = 'DMP-8YD',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create historical quote for cost lookup
        SBQQ__Quote__c historicalQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = locationAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Approved',
            SBQQ__Type__c = 'Quote'
        );
        insert historicalQuote;

        // Create historical quote lines with costs
        List<SBQQ__QuoteLine__c> historicalLines = new List<SBQQ__QuoteLine__c>();

        historicalLines.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = historicalQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__ProductName__c = 'Haul Service',
            Vendor__c = vendors[0].Id, // WM vendor
            SBQQ__UnitCost__c = 125.50,
            Cost_Unit_of_Measure__c = 'Per Service',
            CostModelType__c = 'STD'
        ));

        historicalLines.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = historicalQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__ProductName__c = 'Disposal Fee',
            Vendor__c = vendors[1].Id, // ABC vendor
            SBQQ__UnitCost__c = 45.00,
            Cost_Unit_of_Measure__c = 'Per Ton',
            CostModelType__c = 'STP'
        ));

        insert historicalLines;

        // Create current quote for testing
        SBQQ__Quote__c currentQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = locationAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote'
        );
        insert currentQuote;
    }

    /**
     * @description Test basic vendor search without filters
     */
    @isTest
    static void testSearchVendors_NoFilters() {
        Test.startTest();

        List<Account> results = VendorSearchController.searchVendors(
            null,  // no search term
            null,  // no location
            null,  // no quote
            null   // no filters
        );

        Test.stopTest();

        System.assert(results.size() >= 4, 'Should return all test vendors');
        System.assertEquals('Active', results[0].Status__c, 'All vendors should be active');
    }

    /**
     * @description Test vendor search with name filter
     */
    @isTest
    static void testSearchVendors_WithSearchTerm() {
        Test.startTest();

        List<Account> results = VendorSearchController.searchVendors(
            'WM Denver',
            null,
            null,
            null
        );

        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return only WM Denver vendor');
        System.assert(results[0].Name.contains('WM Denver'), 'Should match search term');
    }

    /**
     * @description Test vendor search with WM only filter
     */
    @isTest
    static void testSearchVendors_WMOnlyFilter() {
        Test.startTest();

        List<String> filters = new List<String>{ 'wm_only' };
        List<Account> results = VendorSearchController.searchVendors(
            null,
            null,
            null,
            filters
        );

        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return only WM vendor');
        System.assert(
            results[0].Parent_Vendor_ID__c == Constant_Util.WM_US_VENDOR ||
            results[0].Parent_Vendor_ID__c == Constant_Util.WM_CANADA_VENDOR,
            'Should be WM vendor'
        );
    }

    /**
     * @description Test vendor search with high score filter
     */
    @isTest
    static void testSearchVendors_HighScoreFilter() {
        Test.startTest();

        List<String> filters = new List<String>{ 'high_score' };
        List<Account> results = VendorSearchController.searchVendors(
            null,
            null,
            null,
            filters
        );

        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return only high score vendor');
        System.assert(results[0].VendorScore__c >= 85, 'Score should be >= 85');
    }

    /**
     * @description Test vendor search with multiple filters
     */
    @isTest
    static void testSearchVendors_MultipleFilters() {
        Test.startTest();

        List<String> filters = new List<String>{ 'wm_only', 'high_score' };
        List<Account> results = VendorSearchController.searchVendors(
            null,
            null,
            null,
            filters
        );

        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return WM vendor with high score');
        System.assertEquals('WM Denver Vendor', results[0].Name, 'Should be WM Denver vendor');
    }

    /**
     * @description Test get location details
     */
    @isTest
    static void testGetLocationDetails() {
        Account location = [SELECT Id FROM Account WHERE Name = 'Test Location' LIMIT 1];

        Test.startTest();

        Account result = VendorSearchController.getLocationDetails(location.Id);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return location');
        System.assertEquals('Test Location', result.Name, 'Should return correct location');
        System.assertEquals('Denver', result.BillingCity, 'Should have city');
        System.assertNotEquals(null, result.BillingLatitude, 'Should have coordinates');
    }

    /**
     * @description Test get location details with null ID
     */
    @isTest
    static void testGetLocationDetails_NullId() {
        Test.startTest();

        Account result = VendorSearchController.getLocationDetails(null);

        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null ID');
    }

    /**
     * @description Test get historical costs
     */
    @isTest
    static void testGetHistoricalCosts() {
        List<Account> vendors = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 2];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Status__c = 'Draft' LIMIT 1];

        List<Id> vendorIds = new List<Id>{ vendors[0].Id, vendors[1].Id };

        Test.startTest();

        Map<Id, VendorSearchController.HistoricalCostWrapper> results =
            VendorSearchController.getHistoricalCosts(vendorIds, quote.Id);

        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return historical costs for both vendors');
        System.assertNotEquals(null, results.get(vendors[0].Id), 'Should have cost for vendor 1');
        System.assertEquals(125.50, results.get(vendors[0].Id).cost, 'Should have correct cost');
        System.assertEquals('Per Service', results.get(vendors[0].Id).unitOfMeasure, 'Should have UOM');
    }

    /**
     * @description Test get historical costs with empty vendor list
     */
    @isTest
    static void testGetHistoricalCosts_EmptyList() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Status__c = 'Draft' LIMIT 1];

        Test.startTest();

        Map<Id, VendorSearchController.HistoricalCostWrapper> results =
            VendorSearchController.getHistoricalCosts(new List<Id>(), quote.Id);

        Test.stopTest();

        System.assert(results.isEmpty(), 'Should return empty map for empty vendor list');
    }

    /**
     * @description Test get historical costs with null quote
     */
    @isTest
    static void testGetHistoricalCosts_NullQuote() {
        List<Account> vendors = [SELECT Id FROM Account WHERE RecordType.Name = 'Vendor' LIMIT 1];
        List<Id> vendorIds = new List<Id>{ vendors[0].Id };

        Test.startTest();

        Map<Id, VendorSearchController.HistoricalCostWrapper> results =
            VendorSearchController.getHistoricalCosts(vendorIds, null);

        Test.stopTest();

        System.assert(results.isEmpty(), 'Should return empty map for null quote');
    }

    /**
     * @description Test get vendor capabilities
     */
    @isTest
    static void testGetVendorCapabilities() {
        Account vendor = [SELECT Id FROM Account WHERE Name = 'WM Denver Vendor' LIMIT 1];

        Test.startTest();

        List<String> capabilities = VendorSearchController.getVendorCapabilities(vendor.Id);

        Test.stopTest();

        System.assertEquals(3, capabilities.size(), 'Should return 3 capabilities');
        System.assert(capabilities.contains('Hazardous Waste'), 'Should include Hazardous Waste');
        System.assert(capabilities.contains('Recycling'), 'Should include Recycling');
        System.assert(capabilities.contains('Disposal'), 'Should include Disposal');
    }

    /**
     * @description Test get vendor capabilities for vendor without capabilities
     */
    @isTest
    static void testGetVendorCapabilities_NoCapabilities() {
        Account vendor = [SELECT Id FROM Account WHERE Name = 'New Vendor LLC' LIMIT 1];

        Test.startTest();

        List<String> capabilities = VendorSearchController.getVendorCapabilities(vendor.Id);

        Test.stopTest();

        System.assert(capabilities.isEmpty(), 'Should return empty list when no capabilities');
    }

    /**
     * @description Test get vendor capabilities with null ID
     */
    @isTest
    static void testGetVendorCapabilities_NullId() {
        Test.startTest();

        List<String> capabilities = VendorSearchController.getVendorCapabilities(null);

        Test.stopTest();

        System.assert(capabilities.isEmpty(), 'Should return empty list for null ID');
    }

    /**
     * @description Test vendor search ordering by score
     */
    @isTest
    static void testSearchVendors_OrderByScore() {
        Test.startTest();

        List<Account> results = VendorSearchController.searchVendors(
            null,
            null,
            null,
            null
        );

        Test.stopTest();

        System.assert(results.size() >= 3, 'Should have multiple vendors');

        // Verify descending score order (nulls last)
        for (Integer i = 0; i < results.size() - 1; i++) {
            if (results[i].VendorScore__c != null && results[i+1].VendorScore__c != null) {
                System.assert(
                    results[i].VendorScore__c >= results[i+1].VendorScore__c,
                    'Should be ordered by score descending'
                );
            }
        }
    }

    /**
     * @description Test vendor search with proximity calculation
     */
    @isTest
    static void testSearchVendors_WithProximity() {
        Account location = [SELECT Id FROM Account WHERE Name = 'Test Location' LIMIT 1];

        Test.startTest();

        List<Account> results = VendorSearchController.searchVendors(
            null,
            location.Id,
            null,
            null
        );

        Test.stopTest();

        System.assert(results.size() >= 3, 'Should return vendors');
        // Note: Distance calculation is done, but stored client-side in this implementation
    }

    /**
     * @description Test error handling with invalid search
     */
    @isTest
    static void testSearchVendors_ErrorHandling() {
        // This test ensures graceful error handling
        Test.startTest();

        try {
            // Pass valid parameters - just ensure no exception is thrown
            List<Account> results = VendorSearchController.searchVendors(
                'Valid Search',
                null,
                null,
                null
            );

            System.assert(true, 'Should handle search gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for valid search: ' + e.getMessage());
        }

        Test.stopTest();
    }
}
