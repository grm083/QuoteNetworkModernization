/**
 * @description Service for managing Work Order operations
 * Provides interface for delivery, removal, and haul order creation
 * Note: This initial implementation provides a service layer wrapper
 * Full refactoring of the 500+ line createDelivery() method is planned for future phases
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class WorkOrderService {

    /**
     * @description Create delivery order
     * Replaces: QuoteProcurementController.createDelivery() - Initial wrapper implementation
     * @param request Work order request
     * @return WorkOrderResult
     */
    public WorkOrderResult createDeliveryOrder(WorkOrderRequest request) {
        if (request == null || !request.isValid()) {
            return WorkOrderResult.createError('Invalid work order request');
        }

        try {
            // Delegate to existing controller implementation
            // TODO: Phase 3B - Refactor the massive 500+ line createDelivery() method
            QuoteProcurementController.OrderWrapper ow = buildOrderWrapper(request);
            QuoteProcurementController.QuoteSummaryWrapper summary =
                QuoteProcurementController.createDelivery(ow, request.orderType, request.placementInstructions);

            // Convert to WorkOrderResult
            WorkOrderResult result = new WorkOrderResult();
            result.success = true;
            result.isAssetChanged = summary.isAssetChanged;

            return result;
        } catch (Exception ex) {
            return WorkOrderResult.createError(ex.getMessage());
        }
    }

    /**
     * @description Create removal order
     * @param request Work order request
     * @return WorkOrderResult
     */
    public WorkOrderResult createRemovalOrder(WorkOrderRequest request) {
        if (request == null || !request.isValid()) {
            return WorkOrderResult.createError('Invalid work order request');
        }

        try {
            QuoteProcurementController.OrderWrapper ow = buildOrderWrapper(request);
            QuoteProcurementController.QuoteSummaryWrapper summary =
                QuoteProcurementController.createDelivery(ow, Constant_Util.ServiceType_Removal, request.placementInstructions);

            WorkOrderResult result = new WorkOrderResult();
            result.success = true;
            result.isAssetChanged = summary.isAssetChanged;

            return result;
        } catch (Exception ex) {
            return WorkOrderResult.createError(ex.getMessage());
        }
    }

    /**
     * @description Create haul away order
     * @param request Work order request
     * @return WorkOrderResult
     */
    public WorkOrderResult createHaulAwayOrder(WorkOrderRequest request) {
        if (request == null || !request.isValid()) {
            return WorkOrderResult.createError('Invalid work order request');
        }

        try {
            QuoteProcurementController.OrderWrapper ow = buildOrderWrapper(request);
            QuoteProcurementController.QuoteSummaryWrapper summary =
                QuoteProcurementController.createDelivery(ow, Constant_Util.Haul_Away_Service, request.placementInstructions);

            WorkOrderResult result = new WorkOrderResult();
            result.success = true;
            result.isAssetChanged = summary.isAssetChanged;

            return result;
        } catch (Exception ex) {
            return WorkOrderResult.createError(ex.getMessage());
        }
    }

    /**
     * @description Get quote orders for quote line
     * @param quoteLineId Quote line ID
     * @return List of quote orders
     */
    public List<Quote_Order__c> getOrdersForQuoteLine(Id quoteLineId) {
        if (quoteLineId == null) {
            return new List<Quote_Order__c>();
        }

        return [
            SELECT Id, Name, Service_Type__c, Quote_Line__c, Work_Order_Date__c,
                   PlacementInstruction__c, Vendor_Service_Number__c
            FROM Quote_Order__c
            WHERE Quote_Line__c = :quoteLineId
            ORDER BY CreatedDate DESC
        ];
    }

    /**
     * @description Delete quote orders
     * Replaces: QuoteProcurementController.deleteQuoteOrders()
     * @param quoteOrders List of quote orders to delete
     * @return SUCCESS or error message
     */
    public String deleteOrders(List<Quote_Order__c> quoteOrders) {
        if (quoteOrders == null || quoteOrders.isEmpty()) {
            return 'SUCCESS';
        }

        try {
            delete quoteOrders;
            return 'SUCCESS';
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error deleting quote orders: ' + ex.getMessage());
            return ex.getMessage();
        }
    }

    /**
     * @description Validate delivery request
     * @param request Work order request
     * @return ValidationResult
     */
    public ValidationResult validateDeliveryRequest(WorkOrderRequest request) {
        ValidationResult result = new ValidationResult();

        if (request == null) {
            result.addError('Request cannot be null');
            return result;
        }

        if (request.quoteId == null) {
            result.addError('Quote ID is required');
        }

        if (request.parentQuoteLineId == null) {
            result.addError('Parent quote line ID is required');
        }

        if (request.serviceDate == null) {
            result.addError('Service date is required');
        }

        if (String.isBlank(request.orderType)) {
            result.addError('Order type is required');
        }

        return result;
    }

    /**
     * @description Helper: Build OrderWrapper from WorkOrderRequest
     * @param request Work order request
     * @return OrderWrapper
     */
    private QuoteProcurementController.OrderWrapper buildOrderWrapper(WorkOrderRequest request) {
        QuoteProcurementController.OrderWrapper ow = new QuoteProcurementController.OrderWrapper();
        ow.parentQuoteLine = request.parentQuoteLineId;
        ow.quoteId = request.quoteId;
        ow.serviceDate = request.serviceDate;
        ow.serviceEndDate = request.serviceEndDate;
        ow.vendorServiceId = request.vendorServiceId;
        return ow;
    }

    /**
     * @description Create quote order record
     * @param quoteLineId Quote line ID
     * @param orderType Order type
     * @param serviceDate Service date
     * @param vendorServiceId Vendor service ID
     * @param placementInstructions Placement instructions
     * @return Created quote order
     */
    public Quote_Order__c createQuoteOrder(
        Id quoteLineId,
        String orderType,
        Date serviceDate,
        String vendorServiceId,
        String placementInstructions
    ) {
        Quote_Order__c quoteOrder = new Quote_Order__c();
        quoteOrder.Quote_Line__c = quoteLineId;
        quoteOrder.Service_Type__c = orderType;
        quoteOrder.Work_Order_Date__c = serviceDate;
        quoteOrder.Vendor_Service_Number__c = vendorServiceId;
        quoteOrder.PlacementInstruction__c = placementInstructions;

        try {
            insert quoteOrder;
            return quoteOrder;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error creating quote order: ' + ex.getMessage());
            throw ex;
        }
    }

    // ==================================================================================
    // FUTURE REFACTORING NOTES (Phase 3B)
    // ==================================================================================
    // The createDelivery() method in QuoteProcurementController is 500+ lines and handles:
    // 1. Quote line retrieval with complex field sets
    // 2. Asset comparison and baseline updates
    // 3. Commercial product delivery/removal logic
    // 4. Haul away service handling
    // 5. Extra pickup management
    // 6. Date validations and updates
    // 7. Service action determination
    // 8. Project code handling
    // 9. Quote order creation
    //
    // Future refactoring should break this into:
    // - AssetComparisonService: Handle asset vs quote line comparison
    // - BaselineUpdateService: Manage baseline field updates
    // - CommercialProductHandler: Handle commercial-specific logic
    // - ServiceDateManager: Manage date calculations and validations
    // - QuoteOrderFactory: Create quote orders with proper structure
    //
    // This would require:
    // - Extensive unit testing of each extracted service
    // - Integration tests for the full flow
    // - Careful migration with feature flags
    // - Performance testing with bulk data
    // ==================================================================================
}
