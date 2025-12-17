/**
 * @description Orchestration service for delivery creation workflow
 * Coordinates all Phase 3 services to execute createDelivery() logic
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3D
 */
public class DeliveryOrchestrationService {

    // Phase 3 service instances
    private QuoteLineCollectorService collectorService;
    private AssetComparisonService assetComparisonService;
    private BaselineUpdateService baselineUpdateService;
    private ServiceDateManager dateManager;
    private QuoteOrderFactory orderFactory;
    private CommercialProductHandler commercialProductHandler;

    /**
     * @description Constructor
     */
    public DeliveryOrchestrationService() {
        this.collectorService = new QuoteLineCollectorService();
        this.assetComparisonService = new AssetComparisonService();
        this.baselineUpdateService = new BaselineUpdateService();
        this.dateManager = new ServiceDateManager();
        this.orderFactory = new QuoteOrderFactory();
        this.commercialProductHandler = new CommercialProductHandler();
    }

    /**
     * @description Execute delivery creation orchestration
     * @param ow Order wrapper with delivery details
     * @param orderType Order type (e.g., "Delivery")
     * @param placementInstructions Placement instructions
     * @return QuoteSummaryWrapper with results
     */
    public QuoteProcurementController.QuoteSummaryWrapper executeDeliveryCreation(
        QuoteProcurementController.OrderWrapper ow,
        String orderType,
        String placementInstructions
    ) {
        QuoteProcurementController.QuoteSummaryWrapper wrapper = new QuoteProcurementController.QuoteSummaryWrapper();
        wrapper.isAssetChanged = false;

        try {
            // Step 1: Collect and filter quote lines
            QuoteLineCollectorService.QuoteLineCollection collection =
                collectorService.collectQuoteLines(ow.parentQuoteLine, ow.quoteId, orderType);

            if (collection.parentQuoteLines.isEmpty()) {
                wrapper.result = 'ERROR: No parent quote line found';
                return wrapper;
            }

            // Step 2: Get case record type
            String caseRecordType = collectorService.getCaseRecordType(collection.parentQuoteLines);

            // Step 3: Process quote lines based on case type
            List<SBQQ__QuoteLine__c> quoteLinesForUpdate = new List<SBQQ__QuoteLine__c>();

            if (caseRecordType != Constant_Util.New_Service_Case) {
                // Get asset product map
                Map<Id, Asset> assetProductMap = collectorService.getAssetProductMap(collection.assetIds);

                // Process quote lines with asset comparison
                quoteLinesForUpdate = processQuoteLinesWithAssetComparison(
                    collection,
                    assetProductMap,
                    ow,
                    wrapper
                );
            } else {
                // New service case - no asset comparison needed
                quoteLinesForUpdate = processQuoteLinesForNewService(
                    collection.allQuoteLines,
                    ow,
                    wrapper
                );
            }

            // Step 4: Update quote lines
            if (!quoteLinesForUpdate.isEmpty()) {
                // Prevent recursion (SDT-41184)
                if (ow.serviceEndDate != null) {
                    RecurrsiveTriggerHandler.isSkipEndDateUpdate = true;
                }

                RecurrsiveTriggerHandler.isSkipValidateQLCostPrice = true;
                update quoteLinesForUpdate;
                RecurrsiveTriggerHandler.isSkipValidateQLCostPrice = false;
            }

            // Step 5: Handle haul and removal lines
            handleHaulRemovalLines(ow.parentQuoteLine, ow.serviceEndDate);

            // Step 6: Create quote orders
            wrapper.result = createQuoteOrders(
                collection,
                ow,
                placementInstructions,
                caseRecordType
            );

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in DeliveryOrchestrationService: ' + ex.getMessage());
            wrapper.result = ex.getMessage();
        }

        return wrapper;
    }

    /**
     * @description Process quote lines with asset comparison for existing services
     * @param collection Quote line collection
     * @param assetProductMap Map of asset IDs to assets
     * @param ow Order wrapper
     * @param wrapper Summary wrapper
     * @return List of quote lines to update
     */
    private List<SBQQ__QuoteLine__c> processQuoteLinesWithAssetComparison(
        QuoteLineCollectorService.QuoteLineCollection collection,
        Map<Id, Asset> assetProductMap,
        QuoteProcurementController.OrderWrapper ow,
        QuoteProcurementController.QuoteSummaryWrapper wrapper
    ) {
        List<SBQQ__QuoteLine__c> quoteLinesForUpdate = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c parentQL = collection.parentQuoteLines[0];

        Map<Id, SBQQ__QuoteLine__c> pickupMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> extraPickupMap = new Map<Id, SBQQ__QuoteLine__c>();

        for (SBQQ__QuoteLine__c ql : collection.allQuoteLines) {
            Asset asset = assetProductMap.get(ql.AssetId__c);

            // Calculate end date
            Date endDateFromAsset = ql.SBQQ__EndDate__c;
            Date endDateFromIntake = dateManager.calculateEndDate(
                ql.SBQQ__ProductName__c,
                ow.serviceDate,
                ow.serviceEndDate,
                endDateFromAsset
            );
            ql.SBQQ__EndDate__c = endDateFromIntake != null ? endDateFromIntake : endDateFromAsset;

            // Skip waste category/stream products
            if (asset != null
                && ql.SBQQ__ProductFamily__c != Constant_Util.WASTE_CATEGORY
                && ql.SBQQ__ProductFamily__c != Constant_Util.WASTE_STREAM) {

                // Compare asset with quote line
                AssetComparisonResult comparisonResult = assetComparisonService.compareAssetWithQuoteLine(
                    asset,
                    ql,
                    parentQL
                );

                // Check project code match
                Boolean projectMatches = assetComparisonService.validateProjectCodeMatch(
                    asset,
                    ql.SBQQ__Quote__r.Project__c,
                    ql.SBQQ__Quote__r.Project_Services_Request__c
                );

                if (comparisonResult.requiresUpdate() || !projectMatches) {
                    // Apply baseline updates
                    baselineUpdateService.applyBaselineUpdate(
                        ql,
                        comparisonResult,
                        asset,
                        ow.serviceDate,
                        ow.serviceEndDate
                    );

                    // Track pickup lines (SDT-32782)
                    if (ql.SBQQ__ProductName__c == Constant_Util.PR_PICKUP) {
                        pickupMap.put(ql.SBQQ__RequiredBy__c, ql);
                    }

                    quoteLinesForUpdate.add(ql);
                    wrapper.isAssetChanged = true;
                }

                // Track extra pickup lines (SDT-32782)
                if (ql.SBQQ__ProductName__c == Constant_Util.PR_EXTRA_PICKUP) {
                    extraPickupMap.put(ql.SBQQ__RequiredBy__c, ql);
                }
            } else if (asset == null
                       && ql.SBQQ__ProductFamily__c != Constant_Util.WASTE_CATEGORY
                       && ql.SBQQ__ProductFamily__c != Constant_Util.WASTE_STREAM) {
                // No asset - new service line
                ql.SBQQ__StartDate__c = ow.serviceDate;
                ql.SBQQ__EndDate__c = dateManager.calculateEndDate(
                    ql.SBQQ__ProductName__c,
                    ow.serviceDate,
                    ow.serviceEndDate,
                    null
                );
                QuoteLineServices.setDefaultValuesForQuoteLines(ql, ql.SBQQ__Quote__r.Name);
                quoteLinesForUpdate.add(ql);
                wrapper.isAssetChanged = true;
            }
        }

        // Handle extra pickup line updates (SDT-32782)
        handleExtraPickupLines(quoteLinesForUpdate, pickupMap, extraPickupMap);

        return quoteLinesForUpdate;
    }

    /**
     * @description Process quote lines for new service case
     * @param quoteLines List of quote lines
     * @param ow Order wrapper
     * @param wrapper Summary wrapper
     * @return List of quote lines to update
     */
    private List<SBQQ__QuoteLine__c> processQuoteLinesForNewService(
        List<SBQQ__QuoteLine__c> quoteLines,
        QuoteProcurementController.OrderWrapper ow,
        QuoteProcurementController.QuoteSummaryWrapper wrapper
    ) {
        List<SBQQ__QuoteLine__c> quoteLinesForUpdate = new List<SBQQ__QuoteLine__c>();

        for (SBQQ__QuoteLine__c ql : quoteLines) {
            ql.SBQQ__StartDate__c = ow.serviceDate;
            ql.SBQQ__EndDate__c = dateManager.calculateEndDate(
                ql.SBQQ__ProductName__c,
                ow.serviceDate,
                ow.serviceEndDate,
                null
            );
            quoteLinesForUpdate.add(ql);
        }

        return quoteLinesForUpdate;
    }

    /**
     * @description Handle extra pickup line start date updates
     * @param quoteLinesForUpdate List of quote lines being updated
     * @param pickupMap Map of pickup lines by bundle ID
     * @param extraPickupMap Map of extra pickup lines by bundle ID
     */
    private void handleExtraPickupLines(
        List<SBQQ__QuoteLine__c> quoteLinesForUpdate,
        Map<Id, SBQQ__QuoteLine__c> pickupMap,
        Map<Id, SBQQ__QuoteLine__c> extraPickupMap
    ) {
        if (pickupMap.isEmpty() || extraPickupMap.isEmpty()) {
            return;
        }

        // Get extra pickup lines that need start date updates
        List<SBQQ__QuoteLine__c> extraPickupForUpdate = baselineUpdateService.getExtraPickupLineForStartDateUpdate(
            pickupMap,
            extraPickupMap,
            true
        );

        if (extraPickupForUpdate.isEmpty()) {
            return;
        }

        // Build map of extra pickup lines
        Map<Id, SBQQ__QuoteLine__c> extraPickupUpdateMap = new Map<Id, SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c extraPickup : extraPickupForUpdate) {
            extraPickupUpdateMap.put(extraPickup.Id, extraPickup);
        }

        // Update start dates if not already in update list
        Boolean addedToList = false;
        for (SBQQ__QuoteLine__c currentQL : quoteLinesForUpdate) {
            if (extraPickupUpdateMap.containsKey(currentQL.Id)) {
                for (Id bundleId : extraPickupMap.keySet()) {
                    if (pickupMap.containsKey(bundleId)) {
                        addedToList = true;
                        Date pickupStartDate = pickupMap.get(bundleId).SBQQ__StartDate__c;
                        currentQL.SBQQ__StartDate__c = pickupStartDate;
                    }
                }
            }
        }

        // Add to update list if not already added
        if (!addedToList) {
            quoteLinesForUpdate.addAll(extraPickupForUpdate);
        }
    }

    /**
     * @description Handle haul and removal quote lines
     * @param parentQLId Parent quote line ID
     * @param serviceEndDate Service end date
     */
    private void handleHaulRemovalLines(Id parentQLId, Date serviceEndDate) {
        if (serviceEndDate != null) {
            String dateStr = serviceEndDate.format();
            QuoteProcurementController.validateHaulRemovalqLine(parentQLId, dateStr);
        } else {
            QuoteProcurementController.deleteHaulRemovalqLine(parentQLId);
        }
    }

    /**
     * @description Create quote orders for delivery
     * @param collection Quote line collection
     * @param ow Order wrapper
     * @param placementInstructions Placement instructions
     * @param caseRecordType Case record type
     * @return Result message
     */
    private String createQuoteOrders(
        QuoteLineCollectorService.QuoteLineCollection collection,
        QuoteProcurementController.OrderWrapper ow,
        String placementInstructions,
        String caseRecordType
    ) {
        SBQQ__QuoteLine__c parentQL = collection.parentQuoteLines[0];

        // Check if commercial product with no delivery lines
        if (collection.deliveryQuoteLines.isEmpty()) {
            if (commercialProductHandler.isCommercialProduct(parentQL)) {
                return commercialProductHandler.handleCommercialProductDelivery(
                    parentQL.Id,
                    ow,
                    caseRecordType
                );
            }
            return 'N/A';
        }

        // Create delivery quote orders
        try {
            List<Quote_Order__c> quoteOrders = orderFactory.createDeliveryOrders(
                collection.deliveryQuoteLines,
                parentQL.Quote_Orders__r,
                ow,
                placementInstructions
            );

            // Upsert quote orders
            orderFactory.upsertOrders(quoteOrders);

            // Create removal orders if needed
            String removalResult = createRemovalOrders(
                ow,
                parentQL,
                placementInstructions
            );

            // Handle commercial products (SDT-30092)
            if (commercialProductHandler.isCommercialProduct(parentQL)
                && caseRecordType != Constant_Util.New_Service_Case) {
                commercialProductHandler.handleCommercialProductDelivery(
                    parentQL.Id,
                    ow,
                    caseRecordType
                );
            }

            return removalResult;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error creating quote orders: ' + ex.getMessage());
            return ex.getMessage();
        }
    }

    /**
     * @description Create removal quote orders
     * @param ow Order wrapper
     * @param parentQL Parent quote line
     * @param placementInstructions Placement instructions
     * @return Result message
     */
    private String createRemovalOrders(
        QuoteProcurementController.OrderWrapper ow,
        SBQQ__QuoteLine__c parentQL,
        String placementInstructions
    ) {
        // Query removal/haul quote lines
        List<SBQQ__QuoteLine__c> removalHaulQuoteLines = [
            SELECT Id, Occurrence_Type__c, SBQQ__ProductName__c,
                  Location_Position_Name__r.Container_Position__c,
                  Location_Position_Name__c, SBQQ__EndDate__c, Duration__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = :ow.parentQuoteLine
            AND (SBQQ__ProductName__c = 'Haul' OR SBQQ__ProductName__c = 'Removal')
        ];

        if (removalHaulQuoteLines.isEmpty() || removalHaulQuoteLines[0].SBQQ__EndDate__c == null) {
            return 'SUCCESS';
        }

        // Create removal order
        try {
            Quote_Order__c removalOrder = orderFactory.createRemovalOrder(
                ow,
                removalHaulQuoteLines[0],
                parentQL.Quote_Orders__r
            );

            orderFactory.upsertOrders(new List<Quote_Order__c>{ removalOrder });
            return 'SUCCESS';

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error creating removal order: ' + ex.getMessage());
            return ex.getMessage();
        }
    }

    // ========================================================================
    // Phase 10.3: Quote Line Helper Methods
    // ========================================================================

    /**
     * @description Validate and create/update Removal quote line for TEMP duration services
     * @param parentQLine Parent quote line
     * @param endDate End date string
     * @return Result message ('SUCCESS' or error message)
     */
    public String validateRemoval(SBQQ__QuoteLine__c parentQLine, String endDate) {
        String result = 'SUCCESS';
        try {
            SBQQ__QuoteLine__c removalQLine = getQLine(parentQLine.Id, 'Removal');

            if (removalQLine == null || removalQLine.Id == null) {
                // Create new removal quote line
                removalQLine = new SBQQ__QuoteLine__c();
                removalQLine = assignParentQLineFields(parentQLine);
                removalQLine.SBQQ__Product__c = getProductId('Removal', parentQLine.SBQQ__Product__c);
                removalQLine.SBQQ__Quantity__c = 1;

                if (removalQLine.SBQQ__Product__c != null) {
                    SBQQ__ProductOption__c removalProductOption = getProductOptionId(
                        parentQLine.SBQQ__Product__c,
                        removalQLine.SBQQ__Product__c
                    );

                    if (removalProductOption != null && removalProductOption.Id != null) {
                        removalQLine.SBQQ__ProductOption__c = removalProductOption.Id;
                        removalQLine.Occurrence_Type__c = removalProductOption.Occurrence_Type__c;
                        removalQLine.PriceUOM__c = removalProductOption.PriceUOM__c;
                        removalQLine.Cost_Unit_of_Measure__c = removalProductOption.Cost_Unit_of_Measure__c;
                        removalQLine.CostModelType__c = removalProductOption.CostModelType__c;
                        removalQLine = clearScheduleValues(removalQLine);
                    }
                }

                if (!String.isEmpty(endDate)) {
                    Date removalEndDate = Date.parse(endDate);
                    RemovalQuoteLineHandler.setDatesForRemovalQL(removalQLine, removalEndDate);
                }

                removalQLine.SBQQ__Number__c = getMaxQuoteLineNumber(parentQLine.SBQQ__Quote__c);

                if (parentQLine.SBQQ__Quote__r.SBQQ__Type__c == Constant_Util.QUOTE) {
                    RemovalQuoteLineHandler.checkIfBundleQLHasEnddateBeforeInsert(removalQLine);
                }

                insert removalQLine;
            } else {
                // Update existing removal quote line
                SBQQ__QuoteLine__c updatedRemovalQLine = assignParentQLineFields(parentQLine);
                updatedRemovalQLine.Id = removalQLine.Id;

                if (!String.isEmpty(endDate)) {
                    Date removalDate = Date.parse(endDate);
                    RemovalQuoteLineHandler.setDatesForRemovalQL(updatedRemovalQLine, removalDate);
                }

                updatedRemovalQLine.Occurrence_Type__c = removalQLine.Occurrence_Type__c;
                updatedRemovalQLine = clearScheduleValues(updatedRemovalQLine);
                update updatedRemovalQLine;
            }
        } catch (Exception ex) {
            result = ex.getMessage();
        }
        return result;
    }

    /**
     * @description Validate and create/update Haul quote line for TEMP duration Rolloff products
     * @param parentQLine Parent quote line
     * @param endDate End date string
     * @return Result message ('SUCCESS' or error message)
     */
    public String validateHaul(SBQQ__QuoteLine__c parentQLine, String endDate) {
        String result = 'SUCCESS';
        try {
            SBQQ__QuoteLine__c haulQLine = getQLine(parentQLine.Id, 'Haul');

            if (haulQLine == null || haulQLine.Id == null) {
                // Create new haul quote line
                haulQLine = new SBQQ__QuoteLine__c();
                haulQLine = assignParentQLineFields(parentQLine);
                haulQLine.SBQQ__Product__c = getProductId('Haul', parentQLine.SBQQ__Product__c);
                haulQLine.SBQQ__Quantity__c = 1;

                if (haulQLine.SBQQ__Product__c != null) {
                    SBQQ__ProductOption__c haulProductOption = getProductOptionId(
                        parentQLine.SBQQ__Product__c,
                        haulQLine.SBQQ__Product__c
                    );

                    if (haulProductOption != null && haulProductOption.Id != null) {
                        haulQLine.SBQQ__ProductOption__c = haulProductOption.Id;
                        haulQLine.Occurrence_Type__c = haulProductOption.Occurrence_Type__c;
                        haulQLine.PriceUOM__c = haulProductOption.PriceUOM__c;
                        haulQLine.Cost_Unit_of_Measure__c = haulProductOption.Cost_Unit_of_Measure__c;
                        haulQLine.CostModelType__c = haulProductOption.CostModelType__c;
                        haulQLine = clearScheduleValues(haulQLine);
                    }
                }

                if (!String.isEmpty(endDate)) {
                    Date haulEndDate = Date.parse(endDate);
                    RemovalQuoteLineHandler.setDatesForRemovalQL(haulQLine, haulEndDate);
                }

                haulQLine.SBQQ__Number__c = getMaxQuoteLineNumber(parentQLine.SBQQ__Quote__c);
                insert haulQLine;
            } else {
                // Update existing haul quote line
                SBQQ__QuoteLine__c updatedHaulQLine = assignParentQLineFields(parentQLine);
                updatedHaulQLine.Id = haulQLine.Id;

                if (!String.isEmpty(endDate)) {
                    Date haulDate = Date.parse(endDate);
                    RemovalQuoteLineHandler.setDatesForRemovalQL(updatedHaulQLine, haulDate);
                }

                updatedHaulQLine.Occurrence_Type__c = haulQLine.Occurrence_Type__c;
                updatedHaulQLine = clearScheduleValues(updatedHaulQLine);
                update updatedHaulQLine;
            }
        } catch (Exception ex) {
            result = ex.getMessage();
        }
        return result;
    }

    /**
     * @description Copy parent quote line fields to new child quote line
     * @param parentQLine Parent quote line
     * @return Child quote line with inherited fields
     */
    public SBQQ__QuoteLine__c assignParentQLineFields(SBQQ__QuoteLine__c parentQLine) {
        SBQQ__QuoteLine__c childQLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = parentQLine.SBQQ__Quote__c,
            SBQQ__RequiredBy__c = parentQLine.Id,
            Account__c = parentQLine.Account__c,
            SBQQ__StartDate__c = parentQLine.SBQQ__StartDate__c,
            SBQQ__EndDate__c = parentQLine.SBQQ__EndDate__c,
            Exception_Type__c = parentQLine.Exception_Type__c,
            Exception_Comments__c = parentQLine.Exception_Comments__c,
            Exception_Reason__c = parentQLine.Exception_Reason__c,
            Equipment_Size__c = parentQLine.Equipment_Size__c,
            Occurrence_Type__c = parentQLine.Occurrence_Type__c,
            Schedule_Frequency__c = parentQLine.Schedule_Frequency__c,
            Frequency_Interval__c = parentQLine.Frequency_Interval__c,
            Day_of_Month__c = parentQLine.Day_of_Month__c,
            Service_Days__c = parentQLine.Service_Days__c,
            Duration__c = parentQLine.Duration__c,
            Month_Relative_Interval__c = parentQLine.Month_Relative_Interval__c,
            Month_Relative__c = parentQLine.Month_Relative__c
        );
        return childQLine;
    }

    /**
     * @description Clear schedule-related fields for On-Call products
     * @param qLine Quote line
     * @return Quote line with cleared schedule values
     */
    private SBQQ__QuoteLine__c clearScheduleValues(SBQQ__QuoteLine__c qLine) {
        qLine.Schedule_Frequency__c = null;
        qLine.Frequency_Interval__c = null;
        qLine.Day_of_Month__c = null;
        qLine.Service_Days__c = null;
        qLine.Month_Relative_Interval__c = null;
        qLine.Month_Relative__c = null;
        return qLine;
    }

    /**
     * @description Query child quote line by product name
     * @param qLineId Parent quote line ID
     * @param prdName Product name
     * @return Child quote line or null
     */
    public SBQQ__QuoteLine__c getQLine(String qLineId, String prdName) {
        List<SBQQ__QuoteLine__c> qLineList = [
            SELECT Id, SBQQ__Quote__c, SBQQ__RequiredBy__c, Account__c,
                   SBQQ__StartDate__c, SBQQ__EndDate__c, Exception_Effective_Date__c,
                   Exceptions_Effective_Date__c, Exception_Type__c, Exception_Comments__c,
                   Exception_Reason__c, Equipment_Size__c, Occurrence_Type__c,
                   Schedule_Frequency__c, Frequency_Interval__c, Day_of_Month__c,
                   Service_Days__c, Duration__c, Month_Relative_Interval__c, Month_Relative__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = :qLineId
            AND SBQQ__ProductName__c = :prdName
        ];

        if (qLineList.size() > 0) {
            return qLineList[0];
        }
        return null;
    }

    /**
     * @description Query parent quote line by ID
     * @param parentQLineId Parent quote line ID
     * @return Parent quote line or null
     */
    public SBQQ__QuoteLine__c getParentQline(String parentQLineId) {
        List<SBQQ__QuoteLine__c> pQLineList = [
            SELECT Id, SBQQ__Quote__c, Account__c, SBQQ__StartDate__c,
                   SBQQ__EndDate__c, Exception_Effective_Date__c, Exceptions_Effective_Date__c,
                   Exception_Type__c, Exception_Comments__c, Exception_Reason__c,
                   Equipment_Size__c, SBQQ__Quantity__c, Occurrence_Type__c, Schedule_Frequency__c,
                   Frequency_Interval__c, Day_of_Month__c, Service_Days__c, SBQQ__Product__c,
                   SBQQ__ProductOption__c, Duration__c, SBQQ__ProductFamily__c,
                   SBQQ__Product__r.ProductCode, Month_Relative_Interval__c, Month_Relative__c,
                   SBQQ__Quote__r.SBQQ__Type__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :parentQLineId
        ];

        if (pQLineList.size() > 0) {
            return pQLineList[0];
        }
        return null;
    }

    /**
     * @description Get product ID by name from product options
     * @param productName Product name (e.g., 'Removal', 'Haul')
     * @param parentQuotelineProductId Parent quote line product ID
     * @return Product ID or null
     */
    public Id getProductId(String productName, String parentQuotelineProductId) {
        List<SBQQ__ProductOption__c> pOptionList = [
            SELECT SBQQ__OptionalSKU__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__ConfiguredSKU__c = :parentQuotelineProductId
            AND SBQQ__OptionalSKU__r.Name = :productName
        ];

        if (pOptionList.size() == 0) {
            return null;
        }
        return pOptionList[0].SBQQ__OptionalSKU__c;
    }

    /**
     * @description Get product option record for parent-child product relationship
     * @param parentQLineProductId Parent quote line product ID
     * @param childProductId Child product ID
     * @return Product option record or empty record
     */
    public SBQQ__ProductOption__c getProductOptionId(String parentQLineProductId, String childProductId) {
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();

        List<SBQQ__ProductOption__c> pOptionList = [
            SELECT Id, SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c,
                   Occurrence_Type__c, Cost_Unit_of_Measure__c, CostModelType__c, PriceUOM__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__ConfiguredSKU__c = :parentQLineProductId
            AND SBQQ__OptionalSKU__c = :childProductId
        ];

        if (pOptionList.size() > 0) {
            productOption = pOptionList[0];
        }
        return productOption;
    }

    /**
     * @description Get next available quote line number for a quote
     * @param quoteId Quote ID
     * @return Next quote line number (max + 1)
     */
    public Decimal getMaxQuoteLineNumber(String quoteId) {
        List<SBQQ__QuoteLine__c> maxQL = [
            SELECT SBQQ__Number__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            ORDER BY SBQQ__Number__c DESC
            LIMIT 1
        ];

        Decimal quoteLineNumber = (maxQL.size() > 0) ? maxQL[0].SBQQ__Number__c + 1 : 1;
        return quoteLineNumber;
    }
}
