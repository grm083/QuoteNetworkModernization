/**
 * @description Service for comparing Assets with Quote Lines
 * Wraps AssetQuoteProcurementController.TransformationHelper logic
 * Extracts asset comparison from createDelivery() lines 2892-3008
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3C
 */
public class AssetComparisonService {

    private AssetQuoteProcurementController.TransformationHelper transformationHelper;

    /**
     * @description Constructor
     */
    public AssetComparisonService() {
        this.transformationHelper = new AssetQuoteProcurementController.TransformationHelper();
    }

    /**
     * @description Compare asset with quote line
     * Wraps TransformationHelper.compareAssetQuoteLines logic
     * @param asset Asset to compare
     * @param quoteLine Quote line to compare
     * @param parentQL Parent quote line
     * @return AssetComparisonResult
     */
    public AssetComparisonResult compareAssetWithQuoteLine(
        Asset asset,
        SBQQ__QuoteLine__c quoteLine,
        SBQQ__QuoteLine__c parentQL
    ) {
        if (asset == null || quoteLine == null) {
            return AssetComparisonResult.createMatched();
        }

        // Skip waste category and waste stream products
        if (quoteLine.SBQQ__ProductFamily__c == Constant_Util.WASTE_CATEGORY
            || quoteLine.SBQQ__ProductFamily__c == Constant_Util.WASTE_STREAM) {
            return AssetComparisonResult.createMatched();
        }

        try {
            // Get field sets for comparison (SDT-30514)
            Set<String> updateBaselineFields = transformationHelper.readFieldSet(
                'Update_Baseline',
                'SBQQ__QuoteLine__c'
            );
            Set<String> endAndExtendFields = transformationHelper.readFieldSet(
                'End_and_Extend_Baseline',
                'SBQQ__QuoteLine__c'
            );
            Set<String> excludedFields = transformationHelper.readFieldSet(
                'Integration_Excluded_Fields',
                'SBQQ__QuoteLine__c'
            );

            // Get asset-quoteline mappings
            List<Asset_Quoteline_Mapping__mdt> assetQLMappings = [
                SELECT AssetDataType__c, AssetField__c, AssetFieldValue__c,
                       IsActive__c, QuoteLineField__c, QuoteLineFieldValue__c
                FROM Asset_Quoteline_Mapping__mdt
                WHERE IsActive__c = true
            ];

            // Perform comparison using TransformationHelper
            AssetQuoteProcurementController.comparisonResponseModel responseModel =
                transformationHelper.compareAssetQuoteLines(
                    asset,
                    quoteLine,
                    parentQL,
                    false,
                    updateBaselineFields,
                    endAndExtendFields,
                    excludedFields,
                    assetQLMappings
                );

            // Convert to AssetComparisonResult
            return convertResponseModelToResult(responseModel, asset, quoteLine);

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error comparing asset with quote line: ' + ex.getMessage());
            // On error, assume matched to avoid breaking existing flow
            return AssetComparisonResult.createMatched();
        }
    }

    /**
     * @description Check if project codes match between asset and quote
     * Replaces logic from createDelivery() lines 2996-3006 (SDT-28571, SDT-29124)
     * @param asset Asset with project code
     * @param quoteLine Quote line with quote reference
     * @param comparisonResult Initial comparison result
     * @return Updated comparison result
     */
    public AssetComparisonResult validateProjectCodeMatch(
        Asset asset,
        SBQQ__QuoteLine__c quoteLine,
        AssetComparisonResult comparisonResult
    ) {
        if (asset == null || quoteLine == null || comparisonResult == null) {
            return comparisonResult;
        }

        // If already mismatched, return as-is
        if (!comparisonResult.isMatched) {
            return comparisonResult;
        }

        // Check project code match
        Boolean isAssetHasProject = (asset.Project_Code__c != null);

        if ((quoteLine.SBQQ__Quote__r != null
                && quoteLine.SBQQ__Quote__r.Project__c != asset.Project_Code__c)
            || (quoteLine.SBQQ__Quote__r.Project_Services_Request__c != isAssetHasProject)) {

            // Project code mismatch - mark as End and Extend
            return AssetComparisonResult.createEndAndExtend(
                new List<String>{'Project_Code__c', 'Project_Services_Request__c'}
            );
        }

        return comparisonResult;
    }

    /**
     * @description Get assets for quote lines
     * Replaces logic from createDelivery() lines 2894-2960
     * @param assetIds Set of asset IDs
     * @return Map of asset ID to Asset
     */
    public Map<Id, Asset> getAssetsForComparison(Set<Id> assetIds) {
        Map<Id, Asset> assetMap = new Map<Id, Asset>();

        if (assetIds == null || assetIds.isEmpty()) {
            return assetMap;
        }

        // Query assets with all fields needed for comparison (SDT-38285, SDT-39662)
        List<Asset> assets = [
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
                   Contract_Notes__c, Cost_Center__c, Cost_Currency__c, Cost_Increment_1__c,
                   Cost_Increment_2__c, Cost_Increment_3__c, Cost_Increment_4__c,
                   Cost_Minimum_Quantity__c, Cost_Model_Type__c, Cost_Price_1__c,
                   Cost_Price_2__c, Cost_Price_3__c, Cost_Price_4__c, Cost_Total_Tax__c,
                   Cost_Unit__c, Cost_UpTo_1__c, Cost_UpTo_2__c, Cost_UpTo_3__c,
                   Cost_UpTo_4__c, Cost__c, Customer_Account_Number__c, EDI_Price_Source__c,
                   End_Date__c, Equipment_Owner__c, Equipment_Size__c, Equipment_Type__c,
                   Every__c, Exception_Comments__c, Exception_Effective_Date__c,
                   Exception_Reason_Detail__c, Exception_Reason__c, Exclude_Holidays__c,
                   Exclude_Saturdays__c, Exclude_Sundays__c, Frequency__c, Friday_AM__c,
                   Friday_Frequency__c, Friday_PM__c, Friday__c, GL_Code__c,
                   Generate_Service_Events__c, Has_Extra_Pickup__c, Is_Active__c,
                   Is_Core_Service__c, Is_Hold_Until_Posted__c, Is_Locally_Billed__c,
                   Is_Monitored__c, Is_Override_Rule__c, Location_Code__c,
                   MAS_Account_Number__c, MAS_Company_Code__c, MAS_Customer_Unique_Id__c,
                   MAS_Library__c, MAS_Line_Number__c, MAS_Setup_Comment__c,
                   MAS_VCR_Code__c, MAS_Waste_Stream__c, Market_Area__c, Material_Grade__c,
                   Material_Type__c, Monday_AM__c, Monday_Frequency__c, Monday_PM__c,
                   Monday__c, Monitored__c, Negotiater_ContactId__c, Negotiater_UserId__c,
                   Occurrence_Type__c, Occurrence__c, Occurs__c, Of_Every1__c, Of_Every2__c,
                   Of_Every3__c, Of_Every__c, Of_Month__c, On_Date__c, On_Day1__c,
                   On_Day2__c, On_Day3__c, On_Day__c, On_the__c, Override_UserId__c,
                   Price_Currency__c, Price_Increment_1__c, Price_Increment_2__c,
                   Price_Increment_3__c, Price_Increment_4__c, Price_Minimum_Quantity__c,
                   Price_Model_Type__c, Price_Price_1__c, Price_Price_2__c, Price_Price_3__c,
                   Price_Price_4__c, Price_Tax_Inclusive__c, Price_Total_Tax__c,
                   Price_Unit__c, Price_UpTo_1__c, Price_UpTo_2__c, Price_UpTo_3__c,
                   Price_UpTo_4__c, Price__c, Project__c, Quantity__c, Reason_for_Change__c,
                   Required_Time_of_Day__c, Saturday_AM__c, Saturday_Frequency__c,
                   Saturday_PM__c, Saturday__c, Schedule_A_Override__c, Schedule__c,
                   Send_Schedule_A__c, Sensitivity_Code__c, Service_Header_Id__c,
                   Service_Info__c, Service_Type__c, Start_Date__c, Sunday_AM__c,
                   Sunday_Frequency__c, Sunday_PM__c, Sunday__c, Supplier__c,
                   Supplier__r.Parent_Vendor_ID__c, Third_Party_Source__c, Thursday_AM__c,
                   Thursday_Frequency__c, Thursday_PM__c, Thursday__c, Time_of_Day_AM__c,
                   Time_of_Day_PM__c, Tuesday_AM__c, Tuesday_Frequency__c, Tuesday_PM__c,
                   Tuesday__c, Vendor_Account_Number__c, Vendor_BU__c, Vendor_ID__c,
                   Vendor_Service_Number__c, Waste_Profile__c, Wednesday_AM__c,
                   Wednesday_Frequency__c, Wednesday_PM__c, Wednesday__c, Weekly_Frequency__c,
                   Cost_Tax_Inclusive__c, MAS_Company_Account_Number__c, MAS_Unique_Text__c,
                   SBID_text_c__c, SCOD_text__c, Core_MAS_Unique__c, Core_Quantity__c,
                   Core_Schedule__c, Lower_Case_Asset_Details__c, Occurrence_Type_Formula__c,
                   Active__c, End_Date_Based_on_Project_code__c, End_Dated_Asset__c,
                   Project_Code__c, RootAsset.Project_Code__r.ProjectCode_Id__c,
                   Schedule_Type__c, Created_By_User_Id__c, End_Date_Warning__c,
                   Material_Prompt_ID__c, Voice_Prompt__c, Dumpster_Service_Style__c,
                   Dumpster_Style__c, Is_Null_End_Date__c, Originating_Case__c,
                   SBQQ__AdditionalDiscountAmount__c, Is_Self_Service__c,
                   SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Bundle__c,
                   SBQQ__BundledQuantity__c, SBQQ__Bundled__c, SBQQ__ChargeType__c,
                   SBQQ__CombineKey__c, SBQQ__ComponentDiscountedByPackage__c,
                   SBQQ__CreditProductId__c, SBQQ__CurrentSubscription__c, SBQQ__Dimension__c,
                   SBQQ__DiscountScheduleType__c, SBQQ__DiscountSchedule__c,
                   SBQQ__Discount__c, SBQQ__DistributorDiscount__c, SBQQ__DynamicOptionId__c,
                   SBQQ__FromServiceCloud__c, SBQQ__LatestQuoteLine__c, SBQQ__ListPrice__c,
                   SBQQ__MarkupAmount__c, SBQQ__MarkupRate__c, SBQQ__Number__c,
                   SBQQ__OptionDiscountAmount__c, SBQQ__OptionDiscount__c,
                   SBQQ__OptionLevel__c, SBQQ__OptionType__c, SBQQ__OrderProduct__c,
                   SBQQ__OriginalUnitCost__c, SBQQ__PackageProductCode__c,
                   SBQQ__PackageProductDescription__c, SBQQ__PartnerDiscount__c,
                   SBQQ__PriceDimension__c, SBQQ__PricingMethod__c, SBQQ__ProductOption__c,
                   SBQQ__QuoteLine__c, SBQQ__RegularPrice__c, SBQQ__RenewalUpliftRate__c,
                   SBQQ__RequiredByAsset__c, SBQQ__RequiredById__c,
                   SBQQ__RequiredByProduct__c, SBQQ__RequiredBySubscription__c,
                   SBQQ__RevisedAsset__c, SBQQ__RootAsset__c, SBQQ__RootId__c,
                   SBQQ__SegmentIndex__c, SBQQ__SegmentKey__c, SBQQ__SegmentLabel__c,
                   SBQQ__SubscriptionEndDate__c, SBQQ__SubscriptionQuoteLine__c,
                   SBQQ__SubscriptionStartDate__c, SBQQ__Subscription__c,
                   SBQQ__TermDiscountSchedule__c, SBQQ__UnitCost__c, SBQQ__VirtualAsset__c,
                   CPQ_Product__c, CPQ_Material__c, RecordType.DeveloperName,
                   Account_Position__c, MASBox__c, Material_Grade_Code__c,
                   Month_Relative_Interval__c, Month_Relative__c
            FROM Asset
            WHERE Id IN :assetIds
        ];

        // Build map
        for (Asset asset : assets) {
            if (asset != null) {
                assetMap.put(asset.Id, asset);
            }
        }

        return assetMap;
    }

    /**
     * @description Convert comparisonResponseModel to AssetComparisonResult
     * @param responseModel Response from TransformationHelper
     * @param asset Asset being compared
     * @param quoteLine Quote line being compared
     * @return AssetComparisonResult
     */
    private AssetComparisonResult convertResponseModelToResult(
        AssetQuoteProcurementController.comparisonResponseModel responseModel,
        Asset asset,
        SBQQ__QuoteLine__c quoteLine
    ) {
        if (responseModel == null) {
            return AssetComparisonResult.createMatched();
        }

        AssetComparisonResult result;

        if (responseModel.isQLMached) {
            result = AssetComparisonResult.createMatched();
        } else if (responseModel.isEndAndExtendBaseline) {
            result = AssetComparisonResult.createEndAndExtend(new List<String>());
        } else if (responseModel.isUpdateBaseline) {
            result = AssetComparisonResult.createUpdateBaseline(new List<String>());
        } else {
            // Default to End and Extend if not matched and no specific type
            result = AssetComparisonResult.createEndAndExtend(new List<String>());
        }

        result.asset = asset;
        result.quoteLine = quoteLine;

        return result;
    }
}
