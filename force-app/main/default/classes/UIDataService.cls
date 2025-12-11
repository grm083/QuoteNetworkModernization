/**
 * @description Service for providing UI-related data and picklist values
 * Extracts UI helper methods from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 6
 */
public class UIDataService {

    /**
     * @description Get material types/grades for a given material
     * Replaces QuoteProcurementController.getMaterialTypes() line 325
     * @param material Material type to look up
     * @return List of material grade options
     */
    public List<Map<String, String>> getMaterialTypes(String material) {
        List<Map<String, String>> grades = new List<Map<String, String>>();

        // Add default "None" option
        grades.add(new Map<String, String>{
            'label' => '--None--',
            'value' => ''
        });

        if (String.isBlank(material)) {
            return grades;
        }

        try {
            // Query material type to grade mappings from custom metadata
            List<Material_type_Material_Grade_mapping__mdt> mappings = [
                SELECT Material_Type__c, Material_Grade__c, Material_Grade_Code__c
                FROM Material_type_Material_Grade_mapping__mdt
                WHERE Material_Type__c = :material
                ORDER BY Material_Grade__c
            ];

            for (Material_type_Material_Grade_mapping__mdt mapping : mappings) {
                grades.add(new Map<String, String>{
                    'label' => mapping.Material_Grade__c,
                    'value' => mapping.Material_Grade__c
                });
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting material types: ' + ex.getMessage());
        }

        return grades;
    }

    /**
     * @description Get equipment sizes for a product
     * Replaces QuoteProcurementController.getSizes() line 1763
     * @param productId Product ID
     * @param returnAll Whether to return all sizes
     * @return Map of equipment sizes
     */
    public Map<String, String> getEquipmentSizes(Id productId, Boolean returnAll) {
        if (productId == null) {
            return new Map<String, String>();
        }

        try {
            // Delegate to QuoteFavoritesController for backward compatibility
            return QuoteFavoritesController.getSizes(productId, returnAll);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting equipment sizes: ' + ex.getMessage());
            return new Map<String, String>();
        }
    }

    /**
     * @description Get duration picklist values
     * Replaces QuoteProcurementController.getDurations() line 4191
     * @return Map of duration values and labels
     */
    public Map<String, String> getDurations() {
        Map<String, String> durationMap = new Map<String, String>();

        try {
            List<Schema.PicklistEntry> durationEntries =
                Schema.SObjectType.SBQQ__QuoteLine__c.fields.Duration__c.getPicklistValues();

            for (Schema.PicklistEntry entry : durationEntries) {
                // Exclude 'SEAS' value per business logic
                if (entry.getValue() != 'SEAS') {
                    durationMap.put(entry.getValue(), entry.getLabel());
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting durations: ' + ex.getMessage());
        }

        return durationMap;
    }

    /**
     * @description Get service type picklist values
     * Replaces QuoteProcurementController.getPicklistSchema() line 2020
     * @return List of service type values
     */
    public List<String> getServiceTypePicklist() {
        List<String> options = new List<String>();

        try {
            Schema.DescribeFieldResult fieldResult = Quote_Order__c.Service_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    options.add(entry.getValue());
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting service type picklist: ' + ex.getMessage());
        }

        return options;
    }

    /**
     * @description Get SLA override reason picklist values
     * Replaces QuoteProcurementController.getSLAOverrideReasons() line 3600
     * @return List of SLA override reasons
     */
    public List<String> getSLAOverrideReasons() {
        List<String> slaReasons = new List<String>();

        try {
            Schema.DescribeFieldResult fieldResult =
                SBQQ__QuoteLine__c.SLA_Override_Reason__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    slaReasons.add(entry.getValue());
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting SLA override reasons: ' + ex.getMessage());
        }

        return slaReasons;
    }

    /**
     * @description Get delivery override reason picklist values
     * Replaces QuoteProcurementController.getDeliveryOverrideReasons() line 2230
     * @return List of delivery override reasons
     */
    public List<String> getDeliveryOverrideReasons() {
        List<String> deliveryOverrideReasons = new List<String>();

        try {
            Schema.DescribeFieldResult fieldResult =
                SBQQ__QuoteLine__c.AAV_Delivery_Override_Reason__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    deliveryOverrideReasons.add(entry.getValue());
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting delivery override reasons: ' + ex.getMessage());
        }

        return deliveryOverrideReasons;
    }

    /**
     * @description Get company categories for a quote
     * Replaces QuoteProcurementController.getCompanyCategory() line 4362
     * @param quoteId Quote ID
     * @return Sorted list of company category options
     */
    public List<Map<String, String>> getCompanyCategories(Id quoteId) {
        List<Map<String, String>> companyList = new List<Map<String, String>>();

        if (quoteId == null) {
            return companyList;
        }

        try {
            // Get parent account number from quote
            List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Account__r.Parent.AccountNumber
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if (quotes.isEmpty() || quotes[0].SBQQ__Account__r.Parent == null) {
                return companyList;
            }

            // Get company categories from Acorn
            Map<String, String> companyCategoriesMap =
                AcornCompanyDetails.getAcornCCMap(quotes[0].SBQQ__Account__r.Parent.AccountNumber);

            if (companyCategoriesMap == null || companyCategoriesMap.isEmpty()) {
                return companyList;
            }

            // Build sortable list
            List<CompanyCategorySortWrapper> sortedList = new List<CompanyCategorySortWrapper>();

            for (String categoryCode : companyCategoriesMap.keySet()) {
                Map<String, String> categoryMap = new Map<String, String>{
                    'label' => companyCategoriesMap.get(categoryCode),
                    'value' => categoryCode
                };
                sortedList.add(new CompanyCategorySortWrapper(categoryMap));
            }

            // Sort by label
            sortedList.sort();

            // Extract sorted maps
            for (CompanyCategorySortWrapper wrapper : sortedList) {
                companyList.add(wrapper.categoryMap);
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting company categories: ' + ex.getMessage());
        }

        return companyList;
    }

    /**
     * @description Get special handling reasons picklist
     * @return Map of special handling reason values
     */
    public Map<String, String> getSpecialHandlingReasons() {
        Map<String, String> reasonMap = new Map<String, String>();

        try {
            List<String> picklistValues =
                UTIL_Picklist.getPickListValuesIntoList('SBQQ__Quote__c', 'Special_Handling_Reason__c');

            for (String value : picklistValues) {
                List<String> parts = value.split(',');
                if (parts.size() >= 2) {
                    reasonMap.put(parts[1], parts[0]);
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting special handling reasons: ' + ex.getMessage());
        }

        return reasonMap;
    }

    /**
     * @description Get all UI picklist data in a single call (optimized for LWC)
     * @return Wrapper containing all common picklist values
     */
    public UIPicklistData getAllPicklistData() {
        UIPicklistData data = new UIPicklistData();

        data.durations = getDurations();
        data.serviceTypes = getServiceTypePicklist();
        data.slaOverrideReasons = getSLAOverrideReasons();
        data.deliveryOverrideReasons = getDeliveryOverrideReasons();
        data.specialHandlingReasons = getSpecialHandlingReasons();

        return data;
    }

    /**
     * @description Wrapper for company category sorting
     * Replaces QuoteProcurementController.sortingWrapper line 4398
     */
    private class CompanyCategorySortWrapper implements Comparable {
        public Map<String, String> categoryMap;

        public CompanyCategorySortWrapper(Map<String, String> categoryMap) {
            this.categoryMap = categoryMap;
        }

        public Integer compareTo(Object compareTo) {
            CompanyCategorySortWrapper other = (CompanyCategorySortWrapper)compareTo;
            String thisLabel = this.categoryMap.get('label');
            String otherLabel = other.categoryMap.get('label');

            if (thisLabel == null && otherLabel == null) return 0;
            if (thisLabel == null) return 1;
            if (otherLabel == null) return -1;

            return thisLabel.compareTo(otherLabel);
        }
    }

    /**
     * @description Wrapper containing all UI picklist data
     */
    public class UIPicklistData {
        public Map<String, String> durations { get; set; }
        public List<String> serviceTypes { get; set; }
        public List<String> slaOverrideReasons { get; set; }
        public List<String> deliveryOverrideReasons { get; set; }
        public Map<String, String> specialHandlingReasons { get; set; }

        public UIPicklistData() {
            this.durations = new Map<String, String>();
            this.serviceTypes = new List<String>();
            this.slaOverrideReasons = new List<String>();
            this.deliveryOverrideReasons = new List<String>();
            this.specialHandlingReasons = new Map<String, String>();
        }
    }
}
