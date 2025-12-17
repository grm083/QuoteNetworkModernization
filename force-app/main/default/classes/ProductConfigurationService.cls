/**
 * @description Service for managing Product Configuration operations
 * Replaces product configuration logic from QuoteProcurementController
 * Handles accessories, product options, configuration attributes
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class ProductConfigurationService {

    /**
     * @description Get accessories for a product
     * Replaces: QuoteProcurementController.getAccessories()
     * @param productId Product ID
     * @return List of product options (accessories)
     */
    public List<SBQQ__ProductOption__c> getAccessories(Id productId) {
        if (productId == null) {
            return new List<SBQQ__ProductOption__c>();
        }

        return [
            SELECT Id, SBQQ__ConfiguredSKU__r.Name, SBQQ__OptionalSKU__c,
                   SBQQ__OptionalSKU__r.Name, SBQQ__QuantityEditable__c, SBQQ__Quantity__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__ConfiguredSKU__c = :productId
            AND SBQQ__Feature__r.Name IN ('Additional Services', 'General Accessories')
            ORDER BY SBQQ__Number__c DESC
        ];
    }

    /**
     * @description Get padlock keys for padlock products
     * Replaces: QuoteProcurementController.getPadlockKeys()
     * @param padlockIds List of padlock product IDs
     * @return List of key product options
     */
    public List<SBQQ__ProductOption__c> getPadlockKeys(List<Id> padlockIds) {
        if (padlockIds == null || padlockIds.isEmpty()) {
            return new List<SBQQ__ProductOption__c>();
        }

        List<SBQQ__ProductOption__c> keys = [
            SELECT Id, SBQQ__ConfiguredSKU__r.Name, SBQQ__ConfiguredSKU__c,
                   SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name,
                   SBQQ__QuantityEditable__c, SBQQ__Quantity__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__ConfiguredSKU__c IN :padlockIds
        ];

        return keys.isEmpty() ? null : keys;
    }

    /**
     * @description Get configuration attributes for a product
     * Replaces: QuoteProcurementController.getConfigAttributes()
     * @param productId Product ID
     * @param quoteLineId Quote line ID
     * @return List of configuration attributes with picklist values
     */
    public List<SBQQ__ConfigurationAttribute__c> getConfigurationAttributes(Id productId, Id quoteLineId) {
        if (productId == null) {
            return new List<SBQQ__ConfigurationAttribute__c>();
        }

        // SDT-22447: Product-specific equipment style values to exclude
        Map<String, Set<String>> equipmentStyleExclusions = new Map<String, Set<String>>{
            'Dumpster' => new Set<String>{'Apartment Style', 'Pre-Crusher', 'Horizontal', 'Vertical'},
            'Compactor' => new Set<String>{'Slant Top', 'Tall', 'Split Container', 'Cathedral', 'Loading Dock', 'Slant-Top'}
        };

        // Get product name
        String productName;
        if (productId != null) {
            Product2 product = [SELECT Id, Name FROM Product2 WHERE Id = :productId LIMIT 1];
            if (product != null) {
                productName = product.Name;
            }
        }

        // Get configuration attributes
        List<SBQQ__ConfigurationAttribute__c> attributes = [
            SELECT Id, SBQQ__TargetField__c, SBQQ__ApplyToProductOptions__c,
                   SBQQ__Product__r.Name, SBQQ__ColumnOrder__c, SBQQ__DisplayOrder__c,
                   SBQQ__Feature__r.Name, Picklist_Values__c, Name
            FROM SBQQ__ConfigurationAttribute__c
            WHERE SBQQ__Product__c = :productId
            AND SBQQ__TargetField__c NOT IN (
                'Equipment_Size__c', 'Duration', 'Occurrence_Type__c',
                'Certificate_of_Destruction__c', 'Certificate_of_Disposal__c',
                'Description_of_Waste__c', 'Profile_Number__c', 'Vendor__c'
            )
            ORDER BY SBQQ__Feature__r.Name ASC, SBQQ__DisplayOrder__c ASC, SBQQ__ColumnOrder__c ASC
        ];

        // Build dynamic query to get current quote line values
        if (attributes.isEmpty() || String.isBlank(quoteLineId)) {
            return attributes;
        }

        Set<String> fields = new Set<String>();
        for (SBQQ__ConfigurationAttribute__c attr : attributes) {
            fields.add(attr.SBQQ__TargetField__c);
        }

        String queryString = 'SELECT Id, ' + String.join(new List<String>(fields), ', ') +
                           ' FROM SBQQ__QuoteLine__c WHERE Id = :quoteLineId LIMIT 1';
        SBQQ__QuoteLine__c quoteLine = Database.query(queryString);

        // Populate picklist values for each attribute
        for (SBQQ__ConfigurationAttribute__c attr : attributes) {
            List<PicklistSelect> picklistOptions = new List<PicklistSelect>();

            // Get picklist values from schema
            Schema.DescribeFieldResult fieldDescribe = SBQQ__QuoteLine__c.SObjectType
                .getDescribe()
                .fields
                .getMap()
                .get(attr.SBQQ__TargetField__c)
                .getDescribe();

            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();

            for (Schema.PicklistEntry entry : picklistEntries) {
                // SDT-22447: Filter equipment style values based on product
                if (attr.SBQQ__TargetField__c.equalsIgnoreCase('Equipment_Style__c')) {
                    if (!isEquipmentStyleValid(equipmentStyleExclusions, productName, entry.getValue())) {
                        continue;
                    }
                }

                PicklistSelect option = new PicklistSelect();
                option.value = entry.getValue();
                option.label = entry.getLabel();
                option.selected = (entry.getValue() == quoteLine.get(attr.SBQQ__TargetField__c));
                picklistOptions.add(option);
            }

            attr.Picklist_Values__c = JSON.serialize(picklistOptions);
        }

        return attributes;
    }

    /**
     * @description Update configuration attribute value
     * Replaces: QuoteProcurementController.updateConfigAttribute()
     * @param request Configuration request
     * @return SUCCESS or error message
     */
    public String updateConfigurationAttribute(ProductConfigRequest request) {
        if (request == null || !request.isValidForConfigUpdate()) {
            return 'Invalid request';
        }

        try {
            String queryString = 'SELECT Id, SBQQ__Quote__c, ' +
                String.escapeSingleQuotes(request.fieldName) +
                ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :request.quoteId';

            List<SBQQ__QuoteLine__c> quoteLines = Database.query(queryString);

            for (SBQQ__QuoteLine__c ql : quoteLines) {
                // Ownership field applies to all quote lines
                if (request.fieldName == 'Ownership__c') {
                    ql.Ownership__c = request.fieldValue;
                }
                // Other fields only apply to the specific quote line
                else if (ql.Id == request.quoteLineId) {
                    ql.put(request.fieldName, request.fieldValue);
                }
            }

            update quoteLines;
            return 'SUCCESS';
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

    /**
     * @description Add product option to quote line
     * Replaces: QuoteProcurementController.addProductOption()
     * @param request Product configuration request
     * @return Quote line ID or error message
     */
    public String addProductOption(ProductConfigRequest request) {
        if (request == null || !request.isValidForAddOption()) {
            return 'Invalid request';
        }

        try {
            // Get parent quote line and siblings
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, SBQQ__Number__c, SBQQ__StartDate__c, Equipment_Size__c,
                       SBQQ__Quote__c, SID__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :request.quoteLineId OR SBQQ__RequiredBy__c = :request.quoteLineId
                ORDER BY SBQQ__Number__c DESC
            ];

            if (quoteLines.isEmpty()) {
                return 'Quote line not found';
            }

            // Get product option details (SDT-31973)
            SBQQ__ProductOption__c prodOption = [
                SELECT Id, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name,
                       SBQQ__OptionalSKU__r.ProductCode, SBQQ__Quantity__c,
                       Occurrence_Type__c, CostModelType__c, Cost_Unit_of_Measure__c,
                       PriceUOM__c, Schedule_Frequency__c, Frequency_Interval__c
                FROM SBQQ__ProductOption__c
                WHERE Id = :request.productOptionId
            ];

            // Create new option quote line
            SBQQ__QuoteLine__c optionLine = new SBQQ__QuoteLine__c();
            optionLine.SBQQ__Quote__c = quoteLines[0].SBQQ__Quote__c;
            optionLine.SBQQ__Product__c = prodOption.SBQQ__OptionalSKU__c;
            optionLine.Equipment_Size__c = quoteLines[0].Equipment_Size__c;
            optionLine.SBQQ__RequiredBy__c = request.quoteLineId;
            optionLine.SBQQ__ProductOption__c = prodOption.Id;
            optionLine.SBQQ__OptionLevel__c = 1;
            optionLine.SBQQ__Number__c = quoteLines[0].SBQQ__Number__c + 1;
            optionLine.SBQQ__CostEditable__c = true;
            optionLine.SBQQ__PriceEditable__c = true;
            optionLine.SBQQ__Quantity__c = prodOption.SBQQ__Quantity__c;
            optionLine.Occurrence_Type__c = prodOption.Occurrence_Type__c;
            optionLine.CostModelType__c = prodOption.CostModelType__c;
            optionLine.Cost_Unit_of_Measure__c = prodOption.Cost_Unit_of_Measure__c;
            optionLine.PriceUOM__c = prodOption.PriceUOM__c;
            optionLine.Schedule_Frequency__c = prodOption.Schedule_Frequency__c;
            optionLine.Frequency_Interval__c = prodOption.Frequency_Interval__c;
            optionLine.SBQQ__StartDate__c = quoteLines[0].SBQQ__StartDate__c;
            optionLine.SID__c = quoteLines[0].SID__c;

            // SDT-31973: For Key lines, set end date same as start date
            if (prodOption.SBQQ__OptionalSKU__r.Name == Constant_Util.KEYS) {
                optionLine.SBQQ__EndDate__c = optionLine.SBQQ__StartDate__c;
            }

            insert optionLine;
            return String.valueOf(optionLine.Id);
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

    /**
     * @description Remove product option from quote line
     * Replaces: QuoteProcurementController.removeProductOption()
     * @param request Product configuration request
     * @return SUCCESS or error message
     */
    public String removeProductOption(ProductConfigRequest request) {
        if (request == null || !request.isValidForRemoveOption()) {
            return 'Invalid request';
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLinesToDelete = new List<SBQQ__QuoteLine__c>();

            // If key option ID provided, remove both accessory and keys (SDT-23055, SDT-31752)
            if (request.keyOptionId != null) {
                quoteLinesToDelete = [
                    SELECT Id
                    FROM SBQQ__QuoteLine__c
                    WHERE (
                        SBQQ__RequiredBy__c = :request.quoteLineId
                        AND SBQQ__ProductOption__r.SBQQ__OptionalSKU__c = :request.productOptionId
                    ) OR (
                        SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :request.quoteLineId
                        AND SBQQ__ProductOption__c = :request.keyOptionId
                    )
                    LIMIT 2
                ];
            } else {
                // Remove single option (SDT-31752)
                quoteLinesToDelete = [
                    SELECT Id
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__RequiredBy__c = :request.quoteLineId
                    AND SBQQ__ProductOption__r.SBQQ__OptionalSKU__c = :request.productOptionId
                    LIMIT 1
                ];
            }

            if (!quoteLinesToDelete.isEmpty()) {
                delete quoteLinesToDelete;
            }

            return 'SUCCESS';
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

    /**
     * @description Helper: Check if equipment style option is valid for product
     * SDT-22447
     * @param exclusions Equipment style exclusions map
     * @param productName Product name
     * @param equipmentStyleValue Equipment style value
     * @return True if valid
     */
    private Boolean isEquipmentStyleValid(
        Map<String, Set<String>> exclusions,
        String productName,
        String equipmentStyleValue
    ) {
        if (exclusions.containsKey(productName)) {
            return !exclusions.get(productName).contains(equipmentStyleValue);
        }
        return true;
    }

    /**
     * @description Inner class for picklist selection
     */
    public class PicklistSelect {
        public String value { get; set; }
        public String label { get; set; }
        public Boolean selected { get; set; }
    }

    // ========== Phase 12: Product Query/Configuration Methods ==========
    // Extracted from QuoteFavoritesController (lines 6-120)

    /**
     * @description Get all CPQ-eligible products
     * Replaces: QuoteFavoritesController.getProducts()
     * @return List of Product2 records
     * Phase 12: Extracted from QuoteFavoritesController
     */
    public List<Product2> getProducts() {
        List<Product2> productList = [SELECT Id, Name, ProductCode, Family, Description, Container_Size__c
                                      FROM Product2
                                      WHERE ProductCode != Null AND SBQQ__Component__c = false AND
                                      SBQQ__PricingMethod__c != Null
                                      ORDER BY Name];
        return productList;
    }

    /**
     * @description Search products using SOSL query
     * Replaces: QuoteFavoritesController.searchProducts()
     * @param queryString Search query string
     * @return List of Product2 records matching search
     * Phase 12: Extracted from QuoteFavoritesController
     */
    public List<Product2> searchProducts(String queryString){
        List<List<SObject>> queryResult = new List<List<SObject>>();
        List<Product2> queriedProducts = new List<Product2>();
        queryResult = [FIND :queryString IN ALL FIELDS
                       RETURNING Product2 (Id, Name, ProductCode, Family, Container_Size__c
                                           WHERE ProductCode != Null AND SBQQ__Component__c = false AND
                                           SBQQ__PricingMethod__c != Null)];

        queriedProducts = queryResult[0];

        return queriedProducts;
    }

    /**
     * @description Get preselected product by name
     * Replaces: QuoteFavoritesController.getPreselectedProduct()
     * @param selectedProductName Product name to search for
     * @return Product2 record or null if not found
     * Phase 12: Extracted from QuoteFavoritesController
     */
    public Product2 getPreselectedProduct(string selectedProductName){
        List<Product2> productList = new List<Product2>();
        productList = [SELECT Id, Name, ProductCode, Family
                       FROM Product2
                       WHERE ProductCode != Null
                       AND SBQQ__Component__c = false
                       AND SBQQ__PricingMethod__c != Null
                       AND Name =:selectedProductName LIMIT 1];
        if(productList.size()>0){
            return productList[0];
        }
        return null;
    }

    /**
     * @description Get waste streams (categories and materials) for a product
     * Replaces: QuoteFavoritesController.getWasteStreams()
     * @param productId Product ID
     * @return List of product options for waste streams
     * Phase 12: Extracted from QuoteFavoritesController
     */
    public List<SBQQ__ProductOption__c> getWasteStreams(Id productId) {
        List<SBQQ__ProductOption__c> eligibleStreams = [SELECT Id, Name, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.ProductCode
                                                        FROM SBQQ__ProductOption__c
                                                        WHERE SBQQ__ConfiguredSKU__c =: productId AND SBQQ__ProductFamily__c = 'Waste Category' And SBQQ__OptionalSKU__r.IsActive = true];
        Set<Id> categoryIds = new Set<Id>();
        for (SBQQ__ProductOption__c po : eligibleStreams) {
            categoryIds.add(po.SBQQ__OptionalSKU__c);
        }
        List<SBQQ__ProductOption__c> eligibleMaterials = [SELECT Id, Name, SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name,
                                                          SBQQ__OptionalSKU__r.ProductCode
                                                          FROM SBQQ__ProductOption__c
                                                          WHERE SBQQ__ConfiguredSKU__c IN :categoryIds
                                                          ORDER BY SBQQ__OptionalSKU__r.Name];
        return eligibleMaterials;
    }

    /**
     * @description Get equipment sizes for a product based on configuration attributes
     * Changes by - Toshender Kumar
     * Correction in logic to match the picklist values with shown and hidden values. Earlier the logic was to check the string contains (LIKE logic),
     * It is now amended to do exact match of equipment size. SDT-21768
     * Replaces: QuoteFavoritesController.getSizes()
     * @param productId Product ID
     * @param returnAll If true, return all sizes; if false, filter by configuration
     * @return Map of equipment size values to labels
     * Phase 12: Extracted from QuoteFavoritesController
     */
    public Map<String, String> getSizes(Id productId, Boolean returnAll) {
        Map<String, String> sizeMap = new Map<String, String>();
        List<SBQQ__ConfigurationAttribute__c> containerAtt = [SELECT Id, SBQQ__TargetField__c, SBQQ__Product__c, SBQQ__ShownValues__c, SBQQ__HiddenValues__c
                                                              FROM SBQQ__ConfigurationAttribute__c
                                                              WHERE SBQQ__Product__c =: productId AND SBQQ__TargetField__c = 'Equipment_Size__c'];
        List<Schema.PicklistEntry> sizePicklist = SBQQ__QuoteLine__c.Equipment_Size__c.getDescribe().getPicklistValues();
        if (returnAll){
            for (Schema.PicklistEntry ple: sizePicklist) {
                sizeMap.put(ple.value, ple.label);
            }
            return sizeMap;
        } else if (containerAtt.size() != 1) {
            sizeMap.put('UNK', 'Unknown');
            return sizeMap;
        } else {

            // The values in SBQQ__ShownValues__c and SBQQ__HiddenValues__c are stored with newline character separated.
            string SPLIT_KEY = '\n';

            String shownValues = containerAtt[0].SBQQ__ShownValues__c;
            List<String> lstShowValues = new List<String>();
            lstShowValues = Split(SPLIT_KEY,shownValues);   // Split by newline character

            system.debug('Shown Values are: ' + shownValues);
            String hiddenValues = containerAtt[0].SBQQ__HiddenValues__c;
            List<String> lsthiddenValues = new List<string>();
            lsthiddenValues = Split(SPLIT_KEY,hiddenValues); // Split by newline character

            for (Schema.PicklistEntry ple: sizePicklist) {
                if (!lstShowValues.isEmpty() && lstShowValues.contains(ple.value)) {
                    sizeMap.put(ple.value, ple.label);
                } else  if (!lsthiddenValues.isEmpty() && !lsthiddenValues.contains(ple.value)) {
                    sizeMap.put(ple.value, ple.label);
                } else if (lsthiddenValues.isEmpty() && lstShowValues.isEmpty()){
                    sizeMap.put(ple.value, ple.label);
                }
            }
            return sizeMap;
        }
    }

    /**
     * @description Splits the string based on the key provided
     * Changes by - Toshender Kumar
     * SDT-21768
     * Helper method for getSizes()
     * @param key Delimiter to split on
     * @param stringToSplit String to split
     * @return List of split strings
     * Phase 12: Extracted from QuoteFavoritesController
     */
    private List<String> Split(string key, string stringToSplit ){

        if(stringToSplit!=null && !string.isEmpty(stringToSplit)){
           return stringToSplit.split(key);
        }

        return new List<String>();
    }
}
