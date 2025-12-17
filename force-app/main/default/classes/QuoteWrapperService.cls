/**
 * @description Service for building quote wrapper objects for UI consumption
 * Extracts wrapper building logic from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 6
 */
public class QuoteWrapperService {

    private static AssetAvailabilityService availabilityService = new AssetAvailabilityService();

    /**
     * @description Build products wrapper for quote display
     * Replaces QuoteProcurementController.buildWrapper() line 340
     * @param quoteId Quote ID
     * @return ProductsWrapper with all quote line data
     */
    public QuoteProcurementController.ProductsWrapper buildQuoteProductsWrapper(Id quoteId) {
        QuoteProcurementController.ProductsWrapper wrapper =
            new QuoteProcurementController.ProductsWrapper();

        if (quoteId == null) {
            return wrapper;
        }

        try {
            // Initialize wrapper with defaults
            wrapper.disableMAS = true;
            wrapper.disableCost = true;
            wrapper.disablePrice = true;
            wrapper.singleQuoteId = quoteId;

            // Get quote and company categories
            List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Account__r.Parent.AccountNumber
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if (quotes.isEmpty()) {
                return wrapper;
            }

            Map<String, String> companyCategoriesMap = null;
            if (quotes[0].SBQQ__Account__r.Parent != null) {
                companyCategoriesMap = AcornCompanyDetails.getAcornCCMap(
                    quotes[0].SBQQ__Account__r.Parent.AccountNumber
                );
            }

            // Get header quote lines
            List<SBQQ__QuoteLine__c> headerRecords = getQuoteProducts(quoteId);

            if (headerRecords == null || headerRecords.isEmpty()) {
                return wrapper;
            }

            // Get bundle status map
            Map<Id, Boolean> bundleStatusMap = PricingRequestSTPProcess.getQuoteProductDetail(quoteId);

            // Build header wrappers
            List<QuoteProcurementController.HeaderWrapper> configuredProducts =
                new List<QuoteProcurementController.HeaderWrapper>();

            for (SBQQ__QuoteLine__c header : headerRecords) {
                QuoteProcurementController.HeaderWrapper headerWrapper =
                    buildHeaderWrapper(header, companyCategoriesMap, bundleStatusMap);
                configuredProducts.add(headerWrapper);
            }

            wrapper.configuredProducts = configuredProducts;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error building quote products wrapper: ' + ex.getMessage());
            UTIL_LoggingService.logHandledException(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.ERROR_APPLICATION,
                LoggingLevel.ERROR
            );
        }

        return wrapper;
    }

    /**
     * @description Build header wrapper for a single quote line
     * @param header Quote line record
     * @param companyCategoriesMap Company categories map
     * @param bundleStatusMap Bundle status map
     * @return HeaderWrapper
     */
    private QuoteProcurementController.HeaderWrapper buildHeaderWrapper(
        SBQQ__QuoteLine__c header,
        Map<String, String> companyCategoriesMap,
        Map<Id, Boolean> bundleStatusMap
    ) {
        QuoteProcurementController.HeaderWrapper wrapper =
            new QuoteProcurementController.HeaderWrapper();

        // Basic quote line information
        wrapper.parentId = header.Id;
        wrapper.quoteLineName = header.Name;
        wrapper.quoteLineNumber = header.SBQQ__Number__c;
        wrapper.productId = header.SBQQ__Product__c;
        wrapper.equipmentType = header.SBQQ__ProductName__c;
        wrapper.equipmentTypeCode = header.SBQQ__ProductCode__c;
        wrapper.equipmentSize = header.Equipment_Size__c;
        wrapper.duration = header.Duration__c;
        wrapper.quantity = header.SBQQ__Quantity__c;
        wrapper.quantityEditable = header.SBQQ__Product__r.SBQQ__QuantityEditable__c;
        wrapper.productFamily = header.SBQQ__ProductFamily__c;

        // Quote information
        wrapper.quoteID = header.SBQQ__Quote__c;
        wrapper.quoteIdNav = '/' + header.SBQQ__Quote__c;
        wrapper.quoteName = header.SBQQ__Quote__r.Name;
        wrapper.quoteStatus = header.SBQQ__Quote__r.SBQQ__Status__c;
        wrapper.quoteOnly = header.SBQQ__Quote__r.Quote_Only__c;
        wrapper.quoteType = header.SBQQ__Quote__r.SBQQ__Type__c;
        wrapper.quoteOnlyCopyOf = header.Quote_Only_Copy_of__c;

        // Case information
        wrapper.caseType = header.SBQQ__Quote__r.Case_Type__c;
        if (header.SBQQ__Quote__r.SBQQ__Opportunity2__r != null
            && header.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r != null) {
            wrapper.caseRecordType = header.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.Name;

            // Haul away service check
            Id caseId = header.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c;
            wrapper.isHaulAway = HaulAwayService.getIsHaulAwayService(caseId);
        }

        // Account and location
        wrapper.locationId = header.Account__c;
        wrapper.primaryContact = header.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name;
        wrapper.contactID = header.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Id;

        // Company categories
        wrapper.companyCategories = companyCategoriesMap;
        wrapper.companyCategory = header.CompanyCategoryCode__c;
        wrapper.companyCategoryName = header.CompanyCategoryName__c;

        // Dates and SLA
        wrapper.startDate = header.SBQQ__StartDate__c;
        wrapper.endDate = header.SBQQ__EndDate__c;
        DateTime slaDateTime = QuoteFavoritesController.determineSLA(header.Id);
        if (slaDateTime != null) {
            wrapper.originalSLAstartDate = slaDateTime.date();
        }
        wrapper.slaOverrideReason = header.SLA_Override_Reason__c;
        wrapper.slaOverrideComment = header.SLA_Override_Comment__c;

        // Vendor information
        populateVendorInformation(wrapper, header);

        // Service details
        wrapper.sCode = header.sCode__c;
        wrapper.monthlyScheduleDetails = QuoteLineServices.generateMonthlyScheduleDetails(header);
        wrapper.lineFrequency = header.Service_Schedule__c;
        wrapper.occurrenceType = header.Occurrence_Type__c;
        wrapper.wasteDescription = header.Description_of_Waste__c;
        wrapper.selectedMaterialGrade = header.MaterialGrade__c;
        wrapper.customerApproval = header.CustomerApproval__c;

        // Asset availability overrides
        wrapper.deliveryOverrideReason = header.AAV_Delivery_Override_Reason__c;
        wrapper.deliveryOverrideComment = header.AAV_Delivery_Override_Comment__c;
        wrapper.serviceOverrideReason = header.AAV_Service_Override_Reason__c;
        wrapper.serviceOverrideComment = header.AAV_Service_Day_Override_Comment__c;

        // Bundle and procurement status
        wrapper.bundleProcuredStatus = header.BundleProcuredStatus__c;
        wrapper.nteWarnning = false;
        wrapper.nteWarnningMessage = '';

        // COD flags
        wrapper.isCOD = (header.Certificate_of_Destruction__c == true
                        || header.Certificate_of_Disposal__c == true);

        // MAS wrapper
        wrapper.MAS = buildMASWrapper(header);

        // Work orders
        wrapper.workOrders = buildWorkOrderWrappers(header.Id);

        // Detail lines and error messages
        DetailBuildResult detailResult = buildDetailWrappers(header.Id);
        wrapper.details = detailResult.details;
        if (detailResult.hasErrors) {
            wrapper.lineError = true;
        }

        // Procurement error message
        wrapper.procurementErrorMessage = buildProcurementErrorMessage(
            header,
            bundleStatusMap,
            detailResult.costCompareMessage
        );

        return wrapper;
    }

    /**
     * @description Populate vendor information on header wrapper
     * @param wrapper Header wrapper to populate
     * @param header Quote line with vendor data
     */
    private void populateVendorInformation(
        QuoteProcurementController.HeaderWrapper wrapper,
        SBQQ__QuoteLine__c header
    ) {
        wrapper.vendorId = header.Vendor__c;
        wrapper.vendorName = header.Vendor__r.Name;
        wrapper.vendorNumber = header.Vendor__r.AccountNumber;
        wrapper.vendorBU = header.Vendor__r.Vendor_Business_Unit__c;
        wrapper.vendorFacilityCode = header.Vendor__r.FacilityCode__c;
        wrapper.parentVendorId = header.Vendor__r.Parent_Vendor_Id__c;

        // Vendor flags
        wrapper.vendorManualDispatch = (header.Vendor__r.Contact_Manually_Vendor__c == true) ? 'Yes' : 'No';
        wrapper.vendorPrepayment = (header.Vendor__r.Prepayment_Required__c == 'Yes') ? 'Yes' : 'No';
    }

    /**
     * @description Build MAS wrapper from quote line
     * @param header Quote line record
     * @return MASWrapper
     */
    private QuoteProcurementController.MASWrapper buildMASWrapper(SBQQ__QuoteLine__c header) {
        QuoteProcurementController.MASWrapper masWrapper = new QuoteProcurementController.MASWrapper();

        masWrapper.MASLibrary = header.MASLibrary__c;
        masWrapper.MASCompany = header.MASCompany__c;
        masWrapper.MASAccount = header.MASAccount__c;
        masWrapper.MASUniqueId = header.MASCustomerUniqueId__c;
        masWrapper.MASServiceLine = header.MASServiceLine__c;
        masWrapper.MASBox = header.MASBox__c;
        masWrapper.MASComment = header.SetupComment__c;
        masWrapper.MASBypassPrice = header.BypassPriceReview__c;
        masWrapper.MASDoNotCreate = header.DoNotCreateMASTicket__c;
        masWrapper.DoNotCreateTaskGridTickets = header.DoNotCreateTaskGridTickets__c;
        masWrapper.VCRCode = header.VCRCode__c;

        return masWrapper;
    }

    /**
     * @description Build work order wrappers for quote line
     * @param quoteLineId Quote line ID
     * @return List of WOWrapper
     */
    private List<QuoteProcurementController.WOWrapper> buildWorkOrderWrappers(Id quoteLineId) {
        List<QuoteProcurementController.WOWrapper> workOrders =
            new List<QuoteProcurementController.WOWrapper>();

        List<Quote_Order__c> quoteOrders = QuoteProcurementController.getOrders(quoteLineId);

        for (Quote_Order__c qo : quoteOrders) {
            QuoteProcurementController.WOWrapper woWrapper = new QuoteProcurementController.WOWrapper();
            woWrapper.serviceDate = qo.Service_Date__c;
            woWrapper.serviceType = qo.Service_Type__c;
            woWrapper.instructions = qo.Acorn_Instructions__c;
            workOrders.add(woWrapper);
        }

        return workOrders;
    }

    /**
     * @description Build detail wrappers for quote line components
     * @param parentQuoteLineId Parent quote line ID
     * @return DetailBuildResult
     */
    private DetailBuildResult buildDetailWrappers(Id parentQuoteLineId) {
        DetailBuildResult result = new DetailBuildResult();
        result.details = new List<QuoteProcurementController.DetailWrapper>();
        result.hasErrors = false;
        result.costCompareMessage = '';

        List<SBQQ__QuoteLine__c> detailRecords = QuoteProcurementController.getQuoteDetails(parentQuoteLineId);

        for (SBQQ__QuoteLine__c detail : detailRecords) {
            // Skip waste stream items (handled separately in material type)
            if (detail.SBQQ__ProductFamily__c == 'Waste Stream') {
                continue;
            }

            QuoteProcurementController.DetailWrapper detailWrapper =
                new QuoteProcurementController.DetailWrapper();

            detailWrapper.quoteLineName = detail.Name;
            detailWrapper.componentId = detail.Id;
            detailWrapper.componentType = detail.SBQQ__ProductName__c;
            detailWrapper.componentQuantity = Integer.valueOf(detail.SBQQ__Quantity__c);
            detailWrapper.componentStartDate = detail.SBQQ__StartDate__c;
            detailWrapper.componentEndDate = detail.SBQQ__EndDate__c;
            detailWrapper.occurrenceType = detail.Occurrence_Type__c;
            detailWrapper.scheduleFrequency = detail.Schedule_Frequency__c;
            detailWrapper.frequencyInterval = detail.Frequency_Interval__c;
            detailWrapper.serviceDays = detail.Service_Days__c;
            detailWrapper.errorMessage = detail.ErrorComments__c;

            // Set icon based on error status
            if (String.isBlank(detail.ErrorComments__c)) {
                detailWrapper.iconName = 'utility:check';
                detailWrapper.errorMessage = 'All validations passed';
            } else {
                detailWrapper.iconName = 'utility:warning';
                result.hasErrors = true;
            }

            // Cost details
            detailWrapper.vendorCost = detail.SBQQ__UnitCost__c;
            detailWrapper.costCurrencyCode = detail.SBQQ__UnitCost__c != null
                ? detail.CurrencyIsoCode
                : Constant_Util.EMPTY_STRING;
            detailWrapper.costUOM = detail.Cost_Unit_of_Measure__c;
            detailWrapper.costMin = detail.CostMinQuantity__c;

            // Price details
            detailWrapper.customerPrice = detail.SBQQ__ListPrice__c;
            detailWrapper.priceCurrencyCode = detail.SBQQ__ListPrice__c != null
                ? detail.CurrencyIsoCode
                : Constant_Util.EMPTY_STRING;
            detailWrapper.priceUOM = detail.PriceUOM__c;
            detailWrapper.priceMin = detail.PriceMinQuantity__c;

            // Capture cost compare message from haul line (product code 'H')
            if (detail.SBQQ__ProductCode__c == 'H' && String.isNotBlank(detail.Cost_Compare_Message__c)) {
                result.costCompareMessage = detail.Cost_Compare_Message__c;
            }

            result.details.add(detailWrapper);
        }

        return result;
    }

    /**
     * @description Build procurement error message
     * @param header Quote line header
     * @param bundleStatusMap Bundle status map
     * @param costCompareMessage Cost compare message
     * @return Error message string
     */
    private String buildProcurementErrorMessage(
        SBQQ__QuoteLine__c header,
        Map<Id, Boolean> bundleStatusMap,
        String costCompareMessage
    ) {
        String errorMessage = '';

        // Base procurement error
        Boolean bundleSuccess = bundleStatusMap != null && bundleStatusMap.get(header.Id) == true;
        errorMessage = bundleSuccess ? '' : header.ProcurementErrorMessage__c;

        // Append cost compare message if present
        if (String.isNotBlank(costCompareMessage)) {
            if (errorMessage == Constant_Util.QLI_PROCURMENT_SUCCESS) {
                errorMessage = costCompareMessage;
            } else if (String.isNotBlank(errorMessage)) {
                errorMessage += '\n' + costCompareMessage;
            } else {
                errorMessage = costCompareMessage;
            }
        }

        // Add availability message if applicable
        if (header.Availability_Flag__c != null) {
            try {
                errorMessage = availabilityService.getAvailabilityBellIconMessage(header, errorMessage);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error getting availability message: ' + ex.getMessage());
                // Fallback to utility class
                errorMessage = AAV_AvailabilityUtility.getAvailabilityBellIconMessage(header, errorMessage);
            }
        }

        return errorMessage;
    }

    /**
     * @description Get quote products (parent quote lines)
     * @param quoteId Quote ID
     * @return List of parent quote lines
     */
    private List<SBQQ__QuoteLine__c> getQuoteProducts(Id quoteId) {
        return QuoteProcurementController.getQuoteProducts(quoteId);
    }

    /**
     * @description Detail build result wrapper
     */
    private class DetailBuildResult {
        public List<QuoteProcurementController.DetailWrapper> details { get; set; }
        public Boolean hasErrors { get; set; }
        public String costCompareMessage { get; set; }

        public DetailBuildResult() {
            this.details = new List<QuoteProcurementController.DetailWrapper>();
            this.hasErrors = false;
            this.costCompareMessage = '';
        }
    }
}
