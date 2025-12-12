/**
 * @description Service for mapping Quote and QuoteLine data to wrapper objects
 * Extracts data transformation logic from QuoteProcurementController (Phase 10.1)
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 10.1 - Data Mapping & Transformation
 */
public with sharing class QuoteDataMapperService {

    // Service instances for delegation
    private AssetAvailabilityService availabilityService;

    public QuoteDataMapperService() {
        this.availabilityService = new AssetAvailabilityService();
    }

    /**
     * @description Build simple quote wrapper for specific UI contexts
     * Extracted from QuoteProcurementController.buildQuoteWrapper()
     * @param quoteId The quote ID to build wrapper for
     * @return ProductsWrapper containing configured products
     */
    public QuoteProcurementController.ProductsWrapper buildQuoteWrapper(String quoteId) {
        SBQQ__Quote__c parentQuote = queryQuoteForSimpleWrapper(quoteId);
        QuoteProcurementController.ProductsWrapper pw = new QuoteProcurementController.ProductsWrapper();

        List<SBQQ__QuoteLine__c> headerRecords = queryQuoteLinesForSimpleWrapper(quoteId);
        List<QuoteProcurementController.HeaderWrapper> confProducts = new List<QuoteProcurementController.HeaderWrapper>();

        for (SBQQ__QuoteLine__c header : headerRecords) {
            QuoteProcurementController.HeaderWrapper prod = mapToSimpleHeaderWrapper(header, parentQuote);

            // Query and map material type from detail records
            List<SBQQ__QuoteLine__c> detailRecords = queryDetailsForMaterialType(header.Id);
            for (SBQQ__QuoteLine__c detail : detailRecords) {
                if (detail.SBQQ__ProductFamily__c == 'Waste Stream') {
                    prod.materialType = detail.SBQQ__ProductName__c;
                    prod.materialTypeCode = detail.SBQQ__ProductCode__c;
                    break;
                }
            }

            confProducts.add(prod);
        }

        pw.configuredProducts = confProducts;
        return pw;
    }

    /**
     * @description Build comprehensive wrapper for procurement UI
     * Extracted from QuoteProcurementController.buildWrapper()
     * @param quoteId The quote ID to build wrapper for
     * @return ProductsWrapper with full details including cost, price, MAS, work orders
     */
    public QuoteProcurementController.ProductsWrapper buildWrapper(String quoteId) {
        SBQQ__Quote__c parentQuote = queryQuoteForCompanyCategories(quoteId);
        Map<String, String> companyCategoriesMap = AcornCompanyDetails.getAcornCCMap(
            parentQuote.SBQQ__Account__r.Parent.AccountNumber
        );

        // Initialize wrapper with default flags
        QuoteProcurementController.ProductsWrapper pw = new QuoteProcurementController.ProductsWrapper();
        pw.disableMAS = true;
        pw.disableCost = true;
        pw.disablePrice = true;

        // Query header records
        List<SBQQ__QuoteLine__c> headerRecords = QuoteProcurementController.getQuoteProducts(quoteId);
        Map<Id, Boolean> bundleStatusMap = PricingRequestSTPProcess.getQuoteProductDetail(quoteId);

        if (headerRecords == null || headerRecords.size() == 0) {
            pw.singleQuoteId = quoteId;
            return pw;
        }

        List<QuoteProcurementController.HeaderWrapper> confProducts = new List<QuoteProcurementController.HeaderWrapper>();

        for (SBQQ__QuoteLine__c header : headerRecords) {
            QuoteProcurementController.HeaderWrapper prod = mapToHeaderWrapper(header, companyCategoriesMap);

            // Map work orders
            List<Quote_Order__c> quoteOrders = QuoteProcurementController.getOrders(header.Id);
            prod.workOrders = mapToWorkOrderWrappers(quoteOrders);

            // Map detail records
            String costCompareMessage = '';
            List<SBQQ__QuoteLine__c> detailRecords = QuoteProcurementController.getQuoteDetails(header.Id);
            List<QuoteProcurementController.DetailWrapper> prodDetails = new List<QuoteProcurementController.DetailWrapper>();

            for (SBQQ__QuoteLine__c detail : detailRecords) {
                // Handle material type
                if (detail.SBQQ__ProductFamily__c == 'Waste Stream') {
                    prod.materialType = detail.SBQQ__ProductName__c;
                    prod.materialTypeCode = detail.SBQQ__ProductCode__c;
                    continue;
                }

                QuoteProcurementController.DetailWrapper detailInstance = mapToDetailWrapper(detail);

                // Capture cost compare message for hauling
                if (detail.SBQQ__ProductCode__c == 'H') {
                    costCompareMessage = detail.Cost_Compare_Message__c;
                }

                prodDetails.add(detailInstance);
            }

            prod.details = prodDetails;

            // Map procurement error messages
            prod.procurementErrorMessage = bundleStatusMap.get(header.Id) == true ?
                '' : header.ProcurementErrorMessage__c;

            // Append cost compare message
            if (!String.isEmpty(costCompareMessage)) {
                if (prod.procurementErrorMessage == Constant_Util.QLI_PROCURMENT_SUCCESS) {
                    prod.procurementErrorMessage = costCompareMessage;
                } else {
                    prod.procurementErrorMessage += '\n' + costCompareMessage;
                }
            }

            // Add availability messages via service
            if (header.Availability_Flag__c != null) {
                try {
                    prod.procurementErrorMessage = availabilityService.getAvailabilityBellIconMessage(
                        header,
                        prod.procurementErrorMessage
                    );
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR,
                        'Error in AssetAvailabilityService.getAvailabilityBellIconMessage: ' + ex.getMessage());
                    // Fallback to utility class
                    prod.procurementErrorMessage = AAV_AvailabilityUtility.getAvailabilityBellIconMessage(
                        header,
                        prod.procurementErrorMessage
                    );
                }
            }

            confProducts.add(prod);
        }

        pw.configuredProducts = confProducts;
        return pw;
    }

    /**
     * @description Map QuoteLine to simple HeaderWrapper
     */
    private QuoteProcurementController.HeaderWrapper mapToSimpleHeaderWrapper(
        SBQQ__QuoteLine__c header,
        SBQQ__Quote__c parentQuote
    ) {
        QuoteProcurementController.HeaderWrapper prod = new QuoteProcurementController.HeaderWrapper();

        // Case and Quote information
        prod.caseType = parentQuote.Case_Type__c;
        prod.caseSubType = parentQuote.Case_Sub_Type__c;
        prod.caseReason = parentQuote.Case_Reason__c;
        prod.caseOrigin = parentQuote.SBQQ__Opportunity2__r.Case__r.Origin;
        prod.caseRecordType = parentQuote.SBQQ__Opportunity2__r.Case__r.Recordtype.Name;
        prod.quoteName = header.SBQQ__Quote__r.Name;
        prod.quoteStatus = parentQuote.SBQQ__Status__c;
        prod.quoteID = header.SBQQ__Quote__c;

        // Product information
        prod.productId = header.SBQQ__Product__c;
        prod.productFamily = header.SBQQ__ProductFamily__c;
        prod.equipmentType = header.SBQQ__ProductName__c;
        prod.equipmentTypeCode = header.SBQQ__ProductCode__c;
        prod.equipmentSize = header.Equipment_Size__c;
        prod.selectedMaterialGrade = header.MaterialGrade__c;
        prod.quantity = header.SBQQ__Quantity__c;
        prod.duration = header.Duration__c;

        // Dates and contact
        prod.startDate = header.SBQQ__StartDate__c;
        prod.endDate = header.SBQQ__EndDate__c;
        prod.primaryContact = parentQuote.SBQQ__PrimaryContact__r.Name;
        prod.contactID = parentQuote.SBQQ__PrimaryContact__c;

        // Location and account information
        prod.occurrenceType = header.Occurrence_Type__c;
        prod.clientId = parentQuote.SBQQ__Account__r.ParentId;
        prod.locationId = parentQuote.SBQQ__Account__c;
        prod.locationDivision = parentQuote.SBQQ__Account__r.Division__c;
        prod.locationGeography = parentQuote.SBQQ__Account__r.Geography__c;
        prod.locationType = parentQuote.SBQQ__Account__r.Location_Type__c;
        prod.locationBrand = parentQuote.SBQQ__Account__r.Brand__c;
        prod.projectCodeId = parentQuote.Project__c;

        // Asset and vendor
        prod.assetId = header.AssetId__c;
        prod.companyCategoryName = header.CompanyCategoryName__c;
        prod.vendorName = header.Vendor__r.Name;
        prod.parentVendorId = header.Vendor__r.Parent_Vendor_Id__c;

        return prod;
    }

    /**
     * @description Map QuoteLine to comprehensive HeaderWrapper
     */
    private QuoteProcurementController.HeaderWrapper mapToHeaderWrapper(
        SBQQ__QuoteLine__c header,
        Map<String, String> companyCategoriesMap
    ) {
        QuoteProcurementController.HeaderWrapper prod = new QuoteProcurementController.HeaderWrapper();

        // Quote and case information
        prod.quoteOnlyCopyOf = header.Quote_Only_Copy_of__c;
        prod.caseType = header.SBQQ__Quote__r.Case_Type__c;
        prod.caseRecordType = header.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Recordtype.Name;
        prod.quoteName = header.SBQQ__Quote__r.Name;
        prod.quoteStatus = header.SBQQ__Quote__r.SBQQ__Status__c;
        prod.quoteIdNav = '/' + header.SBQQ__Quote__c;
        prod.quoteID = header.SBQQ__Quote__c;
        prod.quoteOnly = header.SBQQ__Quote__r.Quote_Only__c;
        prod.quoteType = header.SBQQ__Quote__r.SBQQ__Type__c;

        // Quote line identification
        prod.parentId = header.Id;
        prod.quoteLineName = header.Name;
        prod.quoteLineNumber = header.SBQQ__Number__c;

        // Product information
        prod.productId = header.SBQQ__Product__c;
        prod.productFamily = header.SBQQ__ProductFamily__c;
        prod.equipmentType = header.SBQQ__ProductName__c;
        prod.equipmentTypeCode = header.SBQQ__ProductCode__c;
        prod.equipmentSize = header.Equipment_Size__c;
        prod.selectedMaterialGrade = header.MaterialGrade__c;
        prod.duration = header.Duration__c;

        // Scheduling and quantity
        prod.occurrenceType = header.Occurrence_Type__c;
        prod.Quantity = header.SBQQ__Quantity__c;
        prod.quantityEditable = header.SBQQ__Product__r.SBQQ__QuantityEditable__c;
        prod.lineFrequency = header.Service_Schedule__c;
        prod.monthlyScheduleDetails = QuoteLineServices.generateMonthlyScheduleDetails(header);

        // Dates and SLA
        prod.startDate = header.SBQQ__StartDate__c;
        prod.endDate = header.SBQQ__EndDate__c;
        DateTime SLADateTime = QuoteFavoritesController.determineSLA(header.Id);
        if (SLADateTime != null) {
            prod.originalSLAstartDate = SLADateTime.date();
        }
        prod.slaOverrideReason = header.SLA_Override_Reason__c;
        prod.slaOverrideComment = header.SLA_Override_Comment__c;

        // Location and account
        prod.locationId = header.Account__c;
        prod.companyCategories = companyCategoriesMap;
        prod.companyCategory = header.CompanyCategoryCode__c;
        prod.companyCategoryName = header.CompanyCategoryName__c;

        // Vendor information
        prod.vendorId = header.Vendor__c;
        prod.vendorName = header.Vendor__r.Name;
        prod.vendorNumber = header.Vendor__r.AccountNumber;
        prod.vendorBU = header.Vendor__r.Vendor_Business_Unit__c;
        prod.vendorFacilityCode = header.Vendor__r.FacilityCode__c;
        prod.parentVendorId = header.Vendor__r.Parent_Vendor_Id__c;
        prod.sCode = header.sCode__c;

        // Vendor flags
        prod.vendorManualDispatch = (header.Vendor__r.Contact_Manually_Vendor__c == true) ? 'Yes' : 'No';
        prod.vendorPrepayment = (header.Vendor__r.Prepayment_Required__c == 'Yes' &&
                                  header.Vendor__r.Prepayment_Required__c != null) ? 'Yes' : 'No';

        // Contact
        prod.primaryContact = header.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name;
        prod.contactID = header.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Id;

        // Status and flags
        prod.bundleProcuredStatus = header.BundleProcuredStatus__c;
        prod.customerApproval = header.CustomerApproval__c;
        prod.nteWarnning = false;
        prod.nteWarnningMessage = '';

        // Certificate of Destruction/Disposal
        prod.isCOD = (header.Certificate_of_Destruction__c == true ||
                      header.Certificate_of_Disposal__c == true);

        // Override reasons and comments
        prod.deliveryOverrideReason = header.AAV_Delivery_Override_Reason__c;
        prod.deliveryOverrideComment = header.AAV_Delivery_Override_Comment__c;
        prod.serviceOverrideReason = header.AAV_Service_Override_Reason__c;
        prod.serviceOverrideComment = header.AAV_Service_Day_Override_Comment__c;

        // Waste description
        prod.wasteDescription = header.Description_of_Waste__c;

        // Haul Away check
        Id caseId = header.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c;
        prod.isHaulAway = HaulAwayService.getIsHaulAwayService(caseId);

        // Map MAS wrapper
        prod.MAS = mapToMASWrapper(header);

        return prod;
    }

    /**
     * @description Map QuoteLine to MASWrapper
     */
    private QuoteProcurementController.MASWrapper mapToMASWrapper(SBQQ__QuoteLine__c header) {
        QuoteProcurementController.MASWrapper prodMAS = new QuoteProcurementController.MASWrapper();

        prodMAS.MASLibrary = header.MASLibrary__c;
        prodMAS.MASCompany = header.MASCompany__c;
        prodMAS.MASAccount = header.MASAccount__c;
        prodMAS.MASUniqueId = header.MASCustomerUniqueId__c;
        prodMAS.MASServiceLine = header.MASServiceLine__c;
        prodMAS.MASBox = header.MASBox__c;
        prodMAS.MASComment = header.SetupComment__c;
        prodMAS.MASBypassPrice = header.BypassPriceReview__c;
        prodMAS.MASDoNotCreate = header.DoNotCreateMASTicket__c;
        prodMAS.DoNotCreateTaskGridTickets = header.DoNotCreateTaskGridTickets__c;
        prodMAS.VCRCode = header.VCRCode__c;

        return prodMAS;
    }

    /**
     * @description Map QuoteLine detail to DetailWrapper
     */
    private QuoteProcurementController.DetailWrapper mapToDetailWrapper(SBQQ__QuoteLine__c detail) {
        QuoteProcurementController.DetailWrapper detailInstance = new QuoteProcurementController.DetailWrapper();

        // Identification
        detailInstance.quoteLineName = detail.Name;
        detailInstance.componentId = detail.Id;
        detailInstance.componentType = detail.SBQQ__ProductName__c;

        // Quantity and scheduling
        detailInstance.componentQuantity = Integer.valueOf(detail.SBQQ__Quantity__c);
        detailInstance.componentStartDate = detail.SBQQ__StartDate__c;
        detailInstance.componentEndDate = detail.SBQQ__EndDate__c;
        detailInstance.occurrenceType = detail.Occurrence_Type__c;
        detailInstance.scheduleFrequency = detail.Schedule_Frequency__c;
        detailInstance.frequencyInterval = detail.Frequency_Interval__c;
        detailInstance.serviceDays = detail.Service_Days__c;

        // Error handling
        if (String.isBlank(detail.ErrorComments__c)) {
            detailInstance.iconName = 'utility:check';
            detailInstance.errorMessage = 'All validations passed';
        } else {
            detailInstance.iconName = 'utility:warning';
            detailInstance.errorMessage = detail.ErrorComments__c;
        }

        // Cost details
        detailInstance.vendorCost = detail.SBQQ__UnitCost__c;
        detailInstance.costCurrencyCode = detail.SBQQ__UnitCost__c != null ?
            detail.CurrencyIsoCode : Constant_Util.EMPTY_STRING;
        detailInstance.costUOM = detail.Cost_Unit_of_Measure__c;
        detailInstance.costMin = detail.CostMinQuantity__c;

        // Price details
        detailInstance.customerPrice = detail.SBQQ__ListPrice__c;
        detailInstance.priceCurrencyCode = detail.SBQQ__ListPrice__c != null ?
            detail.CurrencyIsoCode : Constant_Util.EMPTY_STRING;
        detailInstance.priceUOM = detail.PriceUOM__c;
        detailInstance.priceMin = detail.PriceMinQuantity__c;

        return detailInstance;
    }

    /**
     * @description Map Quote_Order__c to WOWrapper list
     */
    private List<QuoteProcurementController.WOWrapper> mapToWorkOrderWrappers(List<Quote_Order__c> quoteOrders) {
        List<QuoteProcurementController.WOWrapper> workOrders = new List<QuoteProcurementController.WOWrapper>();

        for (Quote_Order__c qo : quoteOrders) {
            QuoteProcurementController.WOWrapper woInstance = new QuoteProcurementController.WOWrapper();
            woInstance.serviceDate = qo.Service_Date__c;
            woInstance.serviceType = qo.Service_Type__c;
            woInstance.instructions = qo.Acorn_Instructions__c;
            workOrders.add(woInstance);
        }

        return workOrders;
    }

    /**
     * @description Query quote for simple wrapper (buildQuoteWrapper)
     */
    private SBQQ__Quote__c queryQuoteForSimpleWrapper(String quoteId) {
        return [
            SELECT Id, SBQQ__Account__r.Parent.AccountNumber,
                   SBQQ__Account__r.ParentId, Project__c, SBQQ__Account__c,
                   SBQQ__Account__r.Division__c, SBQQ__Account__r.Geography__c,
                   SBQQ__Account__r.Location_Type__c, SBQQ__Account__r.Brand__c,
                   Case_Sub_Type__c, Case_Reason__c, Case_Type__c,
                   SBQQ__Opportunity2__r.Case__r.Origin,
                   SBQQ__Opportunity2__r.Case__r.Recordtype.Name,
                   toLabel(SBQQ__Status__c),
                   SBQQ__PrimaryContact__r.Name, SBQQ__PrimaryContact__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
        ];
    }

    /**
     * @description Query quote lines for simple wrapper
     */
    private List<SBQQ__QuoteLine__c> queryQuoteLinesForSimpleWrapper(String quoteId) {
        return [
            SELECT SBQQ__Quote__r.Case_Type__c, SBQQ__Quote__r.Name, SBQQ__Quote__c,
                   MaterialGrade__c, SBQQ__ProductName__c, toLabel(Duration__c),
                   Vendor__r.Name, Vendor__r.Parent_Vendor_Id__c,
                   toLabel(Equipment_Size__c), SBQQ__StartDate__c, SBQQ__EndDate__c,
                   Occurrence_Type__c, SBQQ__Quantity__c,
                   AssetId__c, CompanyCategoryName__c, SBQQ__Product__c,
                   SBQQ__ProductFamily__c, SBQQ__ProductCode__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId AND SBQQ__RequiredBy__c = null
        ];
    }

    /**
     * @description Query details for material type (simple wrapper)
     */
    private List<SBQQ__QuoteLine__c> queryDetailsForMaterialType(Id headerRecordId) {
        return [
            SELECT SBQQ__ProductName__c, SBQQ__ProductCode__c, SBQQ__ProductFamily__c
            FROM SBQQ__QuoteLine__c
            WHERE (SBQQ__RequiredBy__c = :headerRecordId OR
                   SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :headerRecordId)
            AND SBQQ__ProductFamily__c != 'Waste Category'
        ];
    }

    /**
     * @description Query quote for company categories (buildWrapper)
     */
    private SBQQ__Quote__c queryQuoteForCompanyCategories(String quoteId) {
        return [
            SELECT Id, SBQQ__Account__r.Parent.AccountNumber
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
        ];
    }
}
