/**
 * @description Service to collect and filter quote lines for delivery operations
 * Extracts quote line querying logic from createDelivery()
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3D
 */
public class QuoteLineCollectorService {

    /**
     * @description Container for collected quote lines
     */
    public class QuoteLineCollection {
        public List<SBQQ__QuoteLine__c> allQuoteLines { get; set; }
        public List<SBQQ__QuoteLine__c> deliveryQuoteLines { get; set; }
        public List<SBQQ__QuoteLine__c> parentQuoteLines { get; set; }
        public List<SBQQ__QuoteLine__c> pickupQuoteLines { get; set; }
        public Set<Id> surchargeIds { get; set; }
        public Set<Id> assetIds { get; set; }
        public Boolean isKeyDeliveryAdded { get; set; }

        public QuoteLineCollection() {
            this.allQuoteLines = new List<SBQQ__QuoteLine__c>();
            this.deliveryQuoteLines = new List<SBQQ__QuoteLine__c>();
            this.parentQuoteLines = new List<SBQQ__QuoteLine__c>();
            this.pickupQuoteLines = new List<SBQQ__QuoteLine__c>();
            this.surchargeIds = new Set<Id>();
            this.assetIds = new Set<Id>();
            this.isKeyDeliveryAdded = false;
        }
    }

    /**
     * @description Collect and filter quote lines for delivery creation
     * @param parentQLId Parent quote line ID
     * @param quoteId Quote ID
     * @param orderType Order type (e.g., "Delivery")
     * @return QuoteLineCollection with filtered quote lines
     */
    public QuoteLineCollection collectQuoteLines(Id parentQLId, Id quoteId, String orderType) {
        QuoteLineCollection collection = new QuoteLineCollection();

        // Get integration fields
        Set<String> setFields = getIntegrationFieldsOfQL();
        setFields.add('sbqq__Quote__r.SBQQ__Opportunity2__r.Case__c');

        // Additional fields for metadata
        Set<String> additionFieldsforMetadata = new Set<String>{
            'Vendor__c', 'LocationPositionName__c', 'Location_Position_Name__c',
            'SBQQ__PricingMethod__c', 'SBQQ__StartDate__c', 'AssetId__r.ParentId'
        };

        // Query all quote lines
        collection.allQuoteLines = QuoteLineSelector.getQuoteLinesByQuoteId(
            setFields,
            parentQLId,
            quoteId,
            additionFieldsforMetadata
        );

        // Filter and categorize quote lines
        categorizeQuoteLines(collection, orderType);

        return collection;
    }

    /**
     * @description Categorize quote lines into delivery, parent, pickup, etc.
     * @param collection Quote line collection to populate
     * @param orderType Order type to filter by
     */
    private void categorizeQuoteLines(QuoteLineCollection collection, String orderType) {
        for (SBQQ__QuoteLine__c quoteLine : collection.allQuoteLines) {
            // Identify delivery quote lines
            if (quoteLine.SBQQ__ProductName__c == orderType) {
                collection.deliveryQuoteLines.add(quoteLine);
            }

            // Identify haul away service lines (SDT-41624)
            if (quoteLine.SBQQ__ProductName__c.equalsIgnoreCase(Constant_Util.Haul_Away_Service)
                && quoteLine.SBQQ__RequiredBy__c != null) {
                collection.deliveryQuoteLines.add(quoteLine);
            }

            // Identify parent quote lines
            if (quoteLine.SBQQ__RequiredBy__c == null) {
                collection.parentQuoteLines.add(quoteLine);
            }

            // Check for surcharges and fees (SDT-30118)
            if (quoteLine.SBQQ__Product__r.Family == PricingJSONRequest.SURCHARGES_AND_FEES) {
                collection.surchargeIds.add(quoteLine.Id);
            }

            // Add keys for filtered bundle (SDT-30118)
            if (collection.surchargeIds.contains(quoteLine.SBQQ__RequiredBy__c)
                && !collection.isKeyDeliveryAdded) {
                collection.deliveryQuoteLines.add(quoteLine);
                collection.isKeyDeliveryAdded = true;
            }

            // Collect asset IDs
            if (quoteLine.AssetId__c != null) {
                collection.assetIds.add(quoteLine.AssetId__c);
            }

            // Identify pickup quote lines (SDT-41624)
            if (quoteLine.SBQQ__ProductName__c.equalsIgnoreCase(Constant_Util.PR_PICKUP)) {
                collection.pickupQuoteLines.add(quoteLine);
            }
        }
    }

    /**
     * @description Get integration fields for quote line query
     * @return Set of field names
     */
    private Set<String> getIntegrationFieldsOfQL() {
        Set<String> setFields = new Set<String>();

        try {
            // Query integration metadata
            List<Integration_Fields__mdt> integrationFields = [
                SELECT Field_API_Name__c, Is_Active__c
                FROM Integration_Fields__mdt
                WHERE Is_Active__c = true
            ];

            for (Integration_Fields__mdt field : integrationFields) {
                if (String.isNotBlank(field.Field_API_Name__c)) {
                    setFields.add(field.Field_API_Name__c);
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting integration fields: ' + ex.getMessage());
        }

        // Always include essential fields
        if (setFields.isEmpty()) {
            setFields.addAll(getDefaultFields());
        }

        return setFields;
    }

    /**
     * @description Get default essential fields if metadata query fails
     * @return Set of default field names
     */
    private Set<String> getDefaultFields() {
        return new Set<String>{
            'Id', 'Name', 'SBQQ__ProductName__c', 'SBQQ__ProductFamily__c',
            'SBQQ__ProductCode__c', 'SBQQ__RequiredBy__c', 'SBQQ__Quote__c',
            'SBQQ__Quote__r.Name', 'SBQQ__Quote__r.SBQQ__Type__c',
            'SBQQ__Quote__r.Project__c', 'SBQQ__Quote__r.Project_Services_Request__c',
            'AssetId__c', 'Location_Position_Name__c',
            'Location_Position_Name__r.Container_Position__c',
            'Occurrence_Type__c', 'Duration__c', 'SBQQ__StartDate__c',
            'SBQQ__EndDate__c', 'Equipment_Size__c', 'Vendor__c'
        };
    }

    /**
     * @description Get case record type from parent quote line
     * @param parentQuoteLines List of parent quote lines
     * @return Case record type name
     */
    public String getCaseRecordType(List<SBQQ__QuoteLine__c> parentQuoteLines) {
        if (parentQuoteLines == null || parentQuoteLines.isEmpty()) {
            return Constant_Util.EMPTY_STRING;
        }

        SBQQ__QuoteLine__c parentQL = parentQuoteLines[0];
        if (parentQL.SBQQ__Quote__r != null
            && parentQL.SBQQ__Quote__r.SBQQ__Opportunity2__r != null
            && parentQL.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r != null
            && parentQL.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType != null) {
            return parentQL.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.Name;
        }

        return Constant_Util.EMPTY_STRING;
    }

    /**
     * @description Query assets for the given asset IDs
     * @param assetIds Set of asset IDs
     * @return Map of asset ID to Asset record
     */
    public Map<Id, Asset> getAssetProductMap(Set<Id> assetIds) {
        Map<Id, Asset> assetProductMap = new Map<Id, Asset>();

        if (assetIds == null || assetIds.isEmpty()) {
            return assetProductMap;
        }

        try {
            // Query assets with all required fields (SDT-38285, SDT-39662)
            List<Asset> assetDetails = [
                SELECT Id, ContactId, AccountId, ParentId, RootAssetId, Product2Id,
                      ProductCode, ProductFamily, ProductDescription, IsCompetitorProduct,
                      CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                      SystemModstamp, IsDeleted, CurrencyIsoCode, Name, SerialNumber,
                      InstallDate, ManufactureDate, StatusReason, Uuid, ExternalIdentifier,
                      PurchaseDate, UsageEndDate, Status, DigitalAssetStatus, Price,
                      Quantity, Description, OwnerId, RecordTypeId, LocationId,
                      AssetProvidedById, AssetServicedById, IsInternal, AssetLevel,
                      StockKeepingUnit, LastViewedDate, LastReferencedDate, Duration__c,
                      Location__c, Acorn_SBID__c, Acorn_SCOD__c, Acorn_SID__c,
                      Acorn_Update_Datetime__c, Acorn_Vendor_Id__c, BusinessUnit_Name__c,
                      Bypass_Cost_Grid__c, Bypass_MAS__c, Category__c, Container_Position__c,
                      Contract_Notes__c, Cost_Center__c, Equipment_Size__c, Equipment_Type__c,
                      Material_Type__c, Start_Date__c, End_Date__c, Supplier__c,
                      Supplier__r.Parent_Vendor_ID__c, Project_Code__c,
                      RootAsset.Project_Code__r.ProjectCode_Id__c, RecordType.DeveloperName,
                      Account_Position__c, MASBox__c, Material_Grade_Code__c,
                      Month_Relative_Interval__c, Month_Relative__c
                FROM Asset
                WHERE Id IN :assetIds
            ];

            // Build map
            for (Asset asset : assetDetails) {
                if (asset != null) {
                    assetProductMap.put(asset.Id, asset);
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error querying assets: ' + ex.getMessage());
        }

        return assetProductMap;
    }
}
