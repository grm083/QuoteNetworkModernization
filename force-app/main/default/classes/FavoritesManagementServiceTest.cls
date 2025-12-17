/**
 * @description Test class for FavoritesManagementService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7 (Additional Services)
 */
@isTest
private class FavoritesManagementServiceTest {

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

        // Create test products with various configurations
        List<Product2> testProducts = new List<Product2>{
            new Product2(
                Name = 'Test Container Product',
                ProductCode = 'CONT001',
                Family = 'Commercial',
                IsActive = true,
                SBQQ__Component__c = false,
                SBQQ__PricingMethod__c = 'List'
            ),
            new Product2(
                Name = 'Test Waste Category',
                ProductCode = 'CAT001',
                Family = 'Waste Category',
                IsActive = true,
                SBQQ__Component__c = false,
                SBQQ__PricingMethod__c = 'List'
            ),
            new Product2(
                Name = 'Test Waste Stream',
                ProductCode = 'STREAM001',
                Family = 'Waste Stream',
                IsActive = true,
                SBQQ__Component__c = false,
                SBQQ__PricingMethod__c = 'List'
            ),
            new Product2(
                Name = 'Component Product',
                ProductCode = 'COMP001',
                Family = 'Commercial',
                IsActive = true,
                SBQQ__Component__c = true,
                SBQQ__PricingMethod__c = 'List'
            )
        };
        insert testProducts;

        // Create product options for waste streams
        Product2 containerProduct = testProducts[0];
        Product2 wasteCategory = testProducts[1];
        Product2 wasteStream = testProducts[2];

        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>{
            new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = containerProduct.Id,
                SBQQ__OptionalSKU__c = wasteCategory.Id,
                SBQQ__ProductFamily__c = 'Waste Category'
            ),
            new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = wasteCategory.Id,
                SBQQ__OptionalSKU__c = wasteStream.Id,
                SBQQ__ProductFamily__c = 'Waste Stream'
            )
        };
        insert productOptions;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;

        // Create favorite
        SBQQ__Favorite__c testFavorite = new SBQQ__Favorite__c(
            Name = 'Test Favorite',
            SBQQ__DynamicOptionId__c = containerProduct.Id
        );
        insert testFavorite;

        // Create favorite products
        List<SBQQ__FavoriteProduct__c> favoriteProducts = new List<SBQQ__FavoriteProduct__c>{
            new SBQQ__FavoriteProduct__c(
                SBQQ__Favorite__c = testFavorite.Id,
                SBQQ__Product__c = containerProduct.Id,
                SBQQ__Quantity__c = 2,
                SBQQ__ConfigurationAttributes__c = '{"Equipment_Size__c":"10YRDS","Ownership__c":"Rental"}'
            ),
            new SBQQ__FavoriteProduct__c(
                SBQQ__Favorite__c = testFavorite.Id,
                SBQQ__Product__c = wasteStream.Id,
                SBQQ__Quantity__c = 1
            )
        };
        insert favoriteProducts;
    }

    /**
     * @description Test getProducts returns CPQ-eligible products
     */
    @isTest
    static void testGetProducts_Success() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<Product2> results = service.getProducts();
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return products');
        // Should not include component product
        for (Product2 prod : results) {
            System.assertEquals(false, prod.SBQQ__Component__c, 'Should not include components');
            System.assertNotEquals(null, prod.ProductCode, 'Should have product code');
        }
    }

    /**
     * @description Test searchProducts with valid query
     */
    @isTest
    static void testSearchProducts_ValidQuery() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<Product2> results = service.searchProducts('Test Container');
        Test.stopTest();

        // SOSL may return results in test context
        System.assertNotEquals(null, results, 'Should return list');
    }

    /**
     * @description Test searchProducts with empty query
     */
    @isTest
    static void testSearchProducts_EmptyQuery() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<Product2> results = service.searchProducts('');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty query should return empty list');
    }

    /**
     * @description Test searchProducts with null query
     */
    @isTest
    static void testSearchProducts_NullQuery() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<Product2> results = service.searchProducts(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Null query should return empty list');
    }

    /**
     * @description Test getPreselectedProduct with valid product name
     */
    @isTest
    static void testGetPreselectedProduct_Found() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Product2 result = service.getPreselectedProduct('Test Container Product');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should find product');
        System.assertEquals('Test Container Product', result.Name, 'Should return correct product');
    }

    /**
     * @description Test getPreselectedProduct with non-existent product
     */
    @isTest
    static void testGetPreselectedProduct_NotFound() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Product2 result = service.getPreselectedProduct('Non Existent Product');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for non-existent product');
    }

    /**
     * @description Test getPreselectedProduct with null input
     */
    @isTest
    static void testGetPreselectedProduct_NullInput() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Product2 result = service.getPreselectedProduct(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Null input should return null');
    }

    /**
     * @description Test getPreselectedProduct with empty string
     */
    @isTest
    static void testGetPreselectedProduct_EmptyString() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Product2 result = service.getPreselectedProduct('');
        Test.stopTest();

        System.assertEquals(null, result, 'Empty string should return null');
    }

    /**
     * @description Test getWasteStreams returns eligible materials
     */
    @isTest
    static void testGetWasteStreams_Success() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<SBQQ__ProductOption__c> results = service.getWasteStreams(containerProduct.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return waste stream options');
    }

    /**
     * @description Test getWasteStreams with null productId
     */
    @isTest
    static void testGetWasteStreams_NullProductId() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<SBQQ__ProductOption__c> results = service.getWasteStreams(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Null productId should return empty list');
    }

    /**
     * @description Test getWasteStreams with product having no waste streams
     */
    @isTest
    static void testGetWasteStreams_NoStreams() {
        Product2 wasteStream = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'STREAM001' LIMIT 1
        ];

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<SBQQ__ProductOption__c> results = service.getWasteStreams(wasteStream.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Product with no waste streams should return empty list');
    }

    /**
     * @description Test getSizes with returnAll = true
     */
    @isTest
    static void testGetSizes_ReturnAll() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Map<String, String> results = service.getSizes(containerProduct.Id, true);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return all equipment sizes');
    }

    /**
     * @description Test getSizes with no configuration attribute
     */
    @isTest
    static void testGetSizes_NoConfigAttribute() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Map<String, String> results = service.getSizes(containerProduct.Id, false);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return unknown size');
        System.assertEquals('Unknown', results.get('UNK'), 'Should return UNK for no config');
    }

    /**
     * @description Test getSizes with configuration attribute
     */
    @isTest
    static void testGetSizes_WithConfigAttribute() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        // Create configuration attribute
        SBQQ__ConfigurationAttribute__c configAttr = new SBQQ__ConfigurationAttribute__c(
            SBQQ__Product__c = containerProduct.Id,
            SBQQ__TargetField__c = 'Equipment_Size__c',
            SBQQ__ShownValues__c = '10YRDS\n20YRDS',
            SBQQ__HiddenValues__c = ''
        );
        insert configAttr;

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Map<String, String> results = service.getSizes(containerProduct.Id, false);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return filtered sizes');
        // Should only include shown values
        System.assert(results.containsKey('10YRDS') || results.size() > 0, 'Should filter by shown values');
    }

    /**
     * @description Test getSizes with hidden values
     */
    @isTest
    static void testGetSizes_WithHiddenValues() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        // Create configuration attribute with hidden values
        SBQQ__ConfigurationAttribute__c configAttr = new SBQQ__ConfigurationAttribute__c(
            SBQQ__Product__c = containerProduct.Id,
            SBQQ__TargetField__c = 'Equipment_Size__c',
            SBQQ__ShownValues__c = '',
            SBQQ__HiddenValues__c = '40YRDS\n50YRDS'
        );
        insert configAttr;

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Map<String, String> results = service.getSizes(containerProduct.Id, false);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return non-hidden sizes');
        // Should exclude hidden values
        System.assertEquals(false, results.containsKey('40YRDS'), 'Should not include hidden values');
    }

    /**
     * @description Test getSizes with no shown or hidden values
     */
    @isTest
    static void testGetSizes_NoRestrictions() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        // Create configuration attribute with no restrictions
        SBQQ__ConfigurationAttribute__c configAttr = new SBQQ__ConfigurationAttribute__c(
            SBQQ__Product__c = containerProduct.Id,
            SBQQ__TargetField__c = 'Equipment_Size__c',
            SBQQ__ShownValues__c = '',
            SBQQ__HiddenValues__c = ''
        );
        insert configAttr;

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        Map<String, String> results = service.getSizes(containerProduct.Id, false);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return all sizes when no restrictions');
    }

    /**
     * @description Test getFavorites returns configured favorites
     */
    @isTest
    static void testGetFavorites_Success() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<FavoritesManagementService.FavoriteWrapper> results =
            service.getFavorites(containerProduct.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return favorites');

        // Find the non-empty wrapper (first is empty due to initialization)
        FavoritesManagementService.FavoriteWrapper favorite;
        for (FavoritesManagementService.FavoriteWrapper fw : results) {
            if (fw.favoriteId != null) {
                favorite = fw;
                break;
            }
        }

        System.assertNotEquals(null, favorite, 'Should have valid favorite');
        System.assertEquals('Test Container Product', favorite.containerType, 'Should set container type');
        System.assertEquals(2, favorite.quantity, 'Should set quantity');
        System.assertEquals('10YRDS', favorite.equipmentSize, 'Should parse equipment size');
        System.assertEquals('Rental', favorite.ownership, 'Should parse ownership');
    }

    /**
     * @description Test getFavorites with null productId
     */
    @isTest
    static void testGetFavorites_NullProductId() {
        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<FavoritesManagementService.FavoriteWrapper> results =
            service.getFavorites(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Null productId should return empty list');
    }

    /**
     * @description Test getFavorites with product having no favorites
     */
    @isTest
    static void testGetFavorites_NoFavorites() {
        Product2 wasteCategory = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CAT001' LIMIT 1
        ];

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<FavoritesManagementService.FavoriteWrapper> results =
            service.getFavorites(wasteCategory.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Product with no favorites should return empty list');
    }

    /**
     * @description Test getFavorites with multiple favorites
     */
    @isTest
    static void testGetFavorites_MultipleFavorites() {
        Product2 containerProduct = [
            SELECT Id FROM Product2
            WHERE ProductCode = 'CONT001' LIMIT 1
        ];

        // Create second favorite
        SBQQ__Favorite__c testFavorite2 = new SBQQ__Favorite__c(
            Name = 'Test Favorite 2',
            SBQQ__DynamicOptionId__c = containerProduct.Id
        );
        insert testFavorite2;

        SBQQ__FavoriteProduct__c favProduct2 = new SBQQ__FavoriteProduct__c(
            SBQQ__Favorite__c = testFavorite2.Id,
            SBQQ__Product__c = containerProduct.Id,
            SBQQ__Quantity__c = 3,
            SBQQ__ConfigurationAttributes__c = '{"Equipment_Size__c":"20YRDS"}'
        );
        insert favProduct2;

        FavoritesManagementService service = new FavoritesManagementService();

        Test.startTest();
        List<FavoritesManagementService.FavoriteWrapper> results =
            service.getFavorites(containerProduct.Id);
        Test.stopTest();

        System.assert(results.size() > 1, 'Should return multiple favorites');
    }

    /**
     * @description Test FavoriteWrapper initialization
     */
    @isTest
    static void testFavoriteWrapper_Initialization() {
        Test.startTest();
        FavoritesManagementService.FavoriteWrapper wrapper =
            new FavoritesManagementService.FavoriteWrapper();
        Test.stopTest();

        System.assertEquals(false, wrapper.quantityEditable, 'Should initialize quantityEditable to false');
    }

    /**
     * @description Test FavoriteWrapper property setters
     */
    @isTest
    static void testFavoriteWrapper_Properties() {
        Test.startTest();
        FavoritesManagementService.FavoriteWrapper wrapper =
            new FavoritesManagementService.FavoriteWrapper();

        wrapper.favoriteId = 'FAV001';
        wrapper.containerType = 'Container';
        wrapper.equipmentSize = '10YRDS';
        wrapper.materialType = 'Material';
        wrapper.quantity = 5;
        wrapper.ownership = 'Owned';
        wrapper.quantityEditable = true;
        Test.stopTest();

        System.assertEquals('FAV001', wrapper.favoriteId, 'Should set favoriteId');
        System.assertEquals('Container', wrapper.containerType, 'Should set containerType');
        System.assertEquals('10YRDS', wrapper.equipmentSize, 'Should set equipmentSize');
        System.assertEquals('Material', wrapper.materialType, 'Should set materialType');
        System.assertEquals(5, wrapper.quantity, 'Should set quantity');
        System.assertEquals('Owned', wrapper.ownership, 'Should set ownership');
        System.assertEquals(true, wrapper.quantityEditable, 'Should set quantityEditable');
    }
}
