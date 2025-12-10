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
}
