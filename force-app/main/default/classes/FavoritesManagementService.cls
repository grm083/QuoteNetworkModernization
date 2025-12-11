/**
 * @description Service for managing product favorites and related product searches
 * Extracts business logic from QuoteFavoritesController for future LWC migration
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7 (Additional Services)
 */
public class FavoritesManagementService {

    /**
     * @description Get all CPQ-eligible products from catalog
     * Extracted from QuoteFavoritesController.getProducts()
     * @return List of products that are CPQ eligible
     */
    public List<Product2> getProducts() {
        try {
            List<Product2> productList = [
                SELECT Id, Name, ProductCode, Family, Description, Container_Size__c
                FROM Product2
                WHERE ProductCode != null
                AND SBQQ__Component__c = false
                AND SBQQ__PricingMethod__c != null
                ORDER BY Name
            ];
            return productList;
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'FavoritesManagementService', 'getProducts');
            return new List<Product2>();
        }
    }

    /**
     * @description Search for products using SOSL
     * Extracted from QuoteFavoritesController.searchProducts()
     * @param queryString Search term for SOSL query
     * @return List of products matching search criteria
     */
    public List<Product2> searchProducts(String queryString) {
        if (String.isEmpty(queryString)) {
            return new List<Product2>();
        }

        try {
            List<List<SObject>> queryResult = [
                FIND :queryString IN ALL FIELDS
                RETURNING Product2 (
                    Id, Name, ProductCode, Family, Container_Size__c
                    WHERE ProductCode != null
                    AND SBQQ__Component__c = false
                    AND SBQQ__PricingMethod__c != null
                )
            ];

            if (queryResult != null && !queryResult.isEmpty()) {
                return (List<Product2>) queryResult[0];
            }
            return new List<Product2>();
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'FavoritesManagementService', 'searchProducts');
            return new List<Product2>();
        }
    }

    /**
     * @description Get a single product by name
     * Extracted from QuoteFavoritesController.getPreselectedProduct()
     * @param selectedProductName Name of product to retrieve
     * @return Product record or null if not found
     */
    public Product2 getPreselectedProduct(String selectedProductName) {
        if (String.isEmpty(selectedProductName)) {
            return null;
        }

        try {
            List<Product2> productList = [
                SELECT Id, Name, ProductCode, Family
                FROM Product2
                WHERE ProductCode != null
                AND SBQQ__Component__c = false
                AND SBQQ__PricingMethod__c != null
                AND Name = :selectedProductName
                LIMIT 1
            ];

            return productList.isEmpty() ? null : productList[0];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'FavoritesManagementService', 'getPreselectedProduct');
            return null;
        }
    }

    /**
     * @description Get waste streams for a container product
     * Extracted from QuoteFavoritesController.getWasteStreams()
     * @param productId Product ID for container
     * @return List of eligible waste stream product options
     */
    public List<SBQQ__ProductOption__c> getWasteStreams(Id productId) {
        if (productId == null) {
            return new List<SBQQ__ProductOption__c>();
        }

        try {
            // Get eligible waste categories for the product
            List<SBQQ__ProductOption__c> eligibleStreams = [
                SELECT Id, Name, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name,
                       SBQQ__OptionalSKU__r.ProductCode
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__ConfiguredSKU__c = :productId
                AND SBQQ__ProductFamily__c = 'Waste Category'
                AND SBQQ__OptionalSKU__r.IsActive = true
            ];

            // Get category IDs for material lookup
            Set<Id> categoryIds = new Set<Id>();
            for (SBQQ__ProductOption__c po : eligibleStreams) {
                categoryIds.add(po.SBQQ__OptionalSKU__c);
            }

            // Get eligible materials for categories
            List<SBQQ__ProductOption__c> eligibleMaterials = [
                SELECT Id, Name, SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c,
                       SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.ProductCode
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__ConfiguredSKU__c IN :categoryIds
                ORDER BY SBQQ__OptionalSKU__r.Name
            ];

            return eligibleMaterials;
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'FavoritesManagementService', 'getWasteStreams');
            return new List<SBQQ__ProductOption__c>();
        }
    }

    /**
     * @description Get equipment sizes for a product
     * Extracted from QuoteFavoritesController.getSizes()
     * SDT-21768: Exact match logic for equipment size picklist values
     * @param productId Product ID to get sizes for
     * @param returnAll If true, return all sizes; if false, filter by configuration attributes
     * @return Map of equipment size values to labels
     */
    public Map<String, String> getSizes(Id productId, Boolean returnAll) {
        Map<String, String> sizeMap = new Map<String, String>();

        try {
            List<Schema.PicklistEntry> sizePicklist =
                SBQQ__QuoteLine__c.Equipment_Size__c.getDescribe().getPicklistValues();

            // Return all sizes if requested
            if (returnAll) {
                for (Schema.PicklistEntry ple : sizePicklist) {
                    sizeMap.put(ple.value, ple.label);
                }
                return sizeMap;
            }

            // Get configuration attributes for product
            List<SBQQ__ConfigurationAttribute__c> containerAtt = [
                SELECT Id, SBQQ__TargetField__c, SBQQ__Product__c,
                       SBQQ__ShownValues__c, SBQQ__HiddenValues__c
                FROM SBQQ__ConfigurationAttribute__c
                WHERE SBQQ__Product__c = :productId
                AND SBQQ__TargetField__c = 'Equipment_Size__c'
            ];

            // Return unknown if no configuration attribute found
            if (containerAtt.size() != 1) {
                sizeMap.put('UNK', 'Unknown');
                return sizeMap;
            }

            // Parse shown and hidden values
            String SPLIT_KEY = '\n';
            String shownValues = containerAtt[0].SBQQ__ShownValues__c;
            List<String> lstShowValues = splitString(SPLIT_KEY, shownValues);

            String hiddenValues = containerAtt[0].SBQQ__HiddenValues__c;
            List<String> lstHiddenValues = splitString(SPLIT_KEY, hiddenValues);

            System.debug('Shown Values are: ' + shownValues);

            // Filter picklist values based on shown/hidden configuration
            for (Schema.PicklistEntry ple : sizePicklist) {
                if (!lstShowValues.isEmpty() && lstShowValues.contains(ple.value)) {
                    // Explicitly shown
                    sizeMap.put(ple.value, ple.label);
                } else if (!lstHiddenValues.isEmpty() && !lstHiddenValues.contains(ple.value)) {
                    // Not explicitly hidden
                    sizeMap.put(ple.value, ple.label);
                } else if (lstHiddenValues.isEmpty() && lstShowValues.isEmpty()) {
                    // No restrictions
                    sizeMap.put(ple.value, ple.label);
                }
            }

            return sizeMap;
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'FavoritesManagementService', 'getSizes');
            sizeMap.put('UNK', 'Unknown');
            return sizeMap;
        }
    }

    /**
     * @description Get favorites for a product
     * Extracted from QuoteFavoritesController.getFavorites()
     * @param productId Product to get favorites for
     * @return List of favorite wrappers containing favorite configuration details
     */
    public List<FavoriteWrapper> getFavorites(Id productId) {
        List<FavoriteWrapper> productFavorites = new List<FavoriteWrapper>();

        if (productId == null) {
            return productFavorites;
        }

        try {
            List<SBQQ__FavoriteProduct__c> productFavoriteDetails = [
                SELECT Id, SBQQ__Favorite__r.Name, SBQQ__Favorite__c,
                       SBQQ__ConfigurationAttributes__c, SBQQ__Product__r.Family,
                       SBQQ__Product__r.Name, SBQQ__Quantity__c, SBQQ__Product__c
                FROM SBQQ__FavoriteProduct__c
                WHERE SBQQ__Product__c = :productId
                OR SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c = :productId
                ORDER BY SBQQ__Favorite__c ASC
            ];

            if (productFavoriteDetails.isEmpty()) {
                return productFavorites;
            }

            // Parse favorite products into wrapper objects
            Id favoriteIndex;
            FavoriteWrapper favoriteConfig = new FavoriteWrapper();

            System.debug('productFavoriteDetails--->' + productFavoriteDetails);

            for (SBQQ__FavoriteProduct__c fp : productFavoriteDetails) {
                System.debug('favoriteIndex--->' + favoriteIndex);

                // New favorite detected, add previous and start new wrapper
                if (favoriteIndex != fp.SBQQ__Favorite__c) {
                    productFavorites.add(favoriteConfig);
                    favoriteConfig = new FavoriteWrapper();
                    favoriteIndex = fp.SBQQ__Favorite__c;
                    favoriteConfig.favoriteId = fp.SBQQ__Favorite__c;
                }

                // Set material type for waste streams
                if (fp.SBQQ__Product__r.Family == 'Waste Stream') {
                    favoriteConfig.materialType = fp.SBQQ__Product__r.Name;
                }

                // Set container configuration for main product
                if (fp.SBQQ__Product__c == productId) {
                    favoriteConfig.containerType = fp.SBQQ__Product__r.Name;
                    favoriteConfig.quantity = fp.SBQQ__Quantity__c;

                    // Parse configuration attributes
                    String confAttributes = fp.SBQQ__ConfigurationAttributes__c;
                    if (!String.isEmpty(confAttributes)) {
                        Map<String, Object> attributes =
                            (Map<String, Object>) JSON.deserializeUntyped(confAttributes);
                        favoriteConfig.equipmentSize = (String) attributes.get('Equipment_Size__c');
                        favoriteConfig.ownership = (String) attributes.get('Ownership__c');
                    }
                }
            }

            // Add final favorite wrapper
            productFavorites.add(favoriteConfig);

            return productFavorites;
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'FavoritesManagementService', 'getFavorites');
            return new List<FavoriteWrapper>();
        }
    }

    /**
     * @description Split a string by a delimiter
     * Extracted from QuoteFavoritesController.Split()
     * SDT-21768: Helper for parsing configuration values
     * @param key Delimiter to split on
     * @param stringToSplit String to split
     * @return List of split strings
     */
    private List<String> splitString(String key, String stringToSplit) {
        if (stringToSplit != null && !String.isEmpty(stringToSplit)) {
            return stringToSplit.split(key);
        }
        return new List<String>();
    }

    /**
     * @description Wrapper class for favorite product configuration
     * Extracted from QuoteFavoritesController.FavoriteWrapper
     */
    public class FavoriteWrapper {
        @AuraEnabled public String favoriteId {get; set;}
        @AuraEnabled public String containerType {get; set;}
        @AuraEnabled public String equipmentSize {get; set;}
        @AuraEnabled public String materialType {get; set;}
        @AuraEnabled public Decimal quantity {get; set;}
        @AuraEnabled public String ownership {get; set;}
        @AuraEnabled public Boolean quantityEditable {get; set;}

        public FavoriteWrapper() {
            // Initialize with defaults
            this.quantityEditable = false;
        }
    }
}
