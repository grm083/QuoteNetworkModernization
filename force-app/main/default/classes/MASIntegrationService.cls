/**
 * @description Service for MAS (Mainframe Asset System) integration and management
 * Extracts MAS-related logic from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 4
 */
public class MASIntegrationService {

    /**
     * @description MAS response wrapper for write operations
     */
    public class MASResponseWrapper {
        public Boolean isSuccess { get; set; }
        public String errorMessage { get; set; }

        public MASResponseWrapper() {
            this.isSuccess = false;
            this.errorMessage = '';
        }
    }

    /**
     * @description Write MAS details to quote lines
     * Replaces QuoteProcurementController.writeMASDetails() lines 691-751
     * @param parentId Parent quote line ID
     * @param masData MAS wrapper with details
     * @return Response wrapper with success status
     * @story SDT-25787, SDT-29392
     */
    public MASResponseWrapper writeMASDetails(Id parentId, QuoteProcurementController.MASWrapper masData) {
        MASResponseWrapper response = new MASResponseWrapper();

        if (parentId == null || masData == null) {
            response.errorMessage = 'Invalid input: parentId and masData are required';
            return response;
        }

        try {
            // Query quote lines to update
            List<SBQQ__QuoteLine__c> quoteHeaders = [SELECT Id, MASLibrary__c, MASCompany__c, MASAccount__c,
                                                           MASCustomerUniqueId__c, MASServiceLine__c, MASBox__c,
                                                           BypassPriceReview__c, BypassMASServiceChange__c,
                                                           SetupComment__c, DoNotCreateMASTicket__c,
                                                           DoNotCreateTaskGridTickets__c, VCRCode__c
                                                     FROM SBQQ__QuoteLine__c
                                                     WHERE Id = :parentId
                                                     OR SBQQ__RequiredBy__c = :parentId
                                                     OR SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :parentId];

            // Update MAS fields
            for (SBQQ__QuoteLine__c quoteHeader : quoteHeaders) {
                applyMASFieldUpdates(quoteHeader, masData);
            }

            // Check field-level security
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, quoteHeaders);

            if (decision.getRemovedFields().size() > 0) {
                response.errorMessage = 'You do not have access to MAS fields';
                response.isSuccess = false;
                return response;
            }

            // Update records
            update decision.getRecords();
            response.isSuccess = true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error writing MAS details: ' + e.getMessage());
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }

        return response;
    }

    /**
     * @description Apply MAS field updates to a single quote line
     * @param quoteLine Quote line to update
     * @param masData MAS wrapper with details
     */
    private void applyMASFieldUpdates(SBQQ__QuoteLine__c quoteLine, QuoteProcurementController.MASWrapper masData) {
        if (!String.isBlank(masData.MASLibrary)) {
            quoteLine.MASLibrary__c = masData.MASLibrary;
        }

        if (!String.isBlank(masData.MASCompany)) {
            quoteLine.MASCompany__c = masData.MASCompany;
        }

        if (masData.MASAccount != null) {
            quoteLine.MASAccount__c = masData.MASAccount;
        }

        if (masData.MASUniqueId != null) {
            quoteLine.MASCustomerUniqueId__c = masData.MASUniqueId;
        }

        if (masData.MASServiceLine != null) {
            quoteLine.MASServiceLine__c = masData.MASServiceLine;
        }

        if (!String.isBlank(masData.MASBox)) {
            quoteLine.MASBox__c = masData.MASBox;
        }

        if (!String.isBlank(masData.MASComment)) {
            quoteLine.SetupComment__c = masData.MASComment;
        }

        quoteLine.BypassPriceReview__c = masData.MASBypassPrice;
        quoteLine.DoNotCreateMASTicket__c = masData.MASDoNotCreate;

        // SDT-29392
        quoteLine.DoNotCreateTaskGridTickets__c = masData.DoNotCreateTaskGridTickets;

        if (!String.isBlank(masData.VCRCode)) {
            quoteLine.VCRCode__c = masData.VCRCode;
        }
    }

    /**
     * @description Determine bypass price review flag based on contract type, vendor, and MAS library
     * Replaces QuoteProcurementController.bypassPriceReview() lines 764-808
     * @param quoteLineId Quote line ID
     * @param masLibrary MAS library value
     * @return Bypass price review flag
     * @story SDT-31627
     */
    public Boolean bypassPriceReview(Id quoteLineId, String masLibrary) {
        if (quoteLineId == null) {
            return false;
        }

        try {
            // Query quote line with availability data
            List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, SBQQ__RequiredBy__c, BypassPriceReview__c,
                                                            sCode__c, Vendor__r.Parent_Vendor_ID__c,
                                                            SBQQ__Quote__r.Name, Name,
                                                            (SELECT Id, AAV_APIRequestOutput__c
                                                             FROM Asset_Availabilities__r)
                                                      FROM SBQQ__QuoteLine__c
                                                      WHERE Id = :quoteLineId];

            if (quoteLineList.isEmpty()) {
                return false;
            }

            SBQQ__QuoteLine__c quoteLine = quoteLineList[0];

            // Only process parent quote lines
            if (quoteLine.SBQQ__RequiredBy__c != null) {
                return false;
            }

            Boolean byPassReviewFlag = quoteLine.BypassPriceReview__c;

            // Parse availability output for contract type
            for (AAV_Asset_Availability__c availabilityOutput : quoteLine.Asset_Availabilities__r) {
                if (availabilityOutput != null && availabilityOutput.AAV_APIRequestOutput__c != null) {
                    String contractType = parseContractTypeFromAvailability(
                        availabilityOutput.AAV_APIRequestOutput__c,
                        quoteLine
                    );

                    if (contractType != null) {
                        return PricingRequestSTPProcess.getBypassPriceReview(
                            contractType,
                            quoteLine.Vendor__r.Parent_Vendor_ID__c,
                            masLibrary
                        );
                    }
                }
            }

            // Handle franchise service code
            if (quoteLine.sCode__c == 'FRCH') {
                return PricingRequestSTPProcess.getBypassPriceReview(
                    'WM Franchise',
                    quoteLine.Vendor__r.Parent_Vendor_ID__c,
                    masLibrary
                );
            }

            return byPassReviewFlag;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in bypassPriceReview: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Parse contract type from availability API output
     * @param apiOutput AAV API request output JSON
     * @param quoteLine Quote line for error logging
     * @return Contract type or null
     */
    private String parseContractTypeFromAvailability(String apiOutput, SBQQ__QuoteLine__c quoteLine) {
        try {
            AvailabilityAPIJsonDeserialize availabilityData =
                AvailabilityAPIJsonDeserialize.parse(apiOutput);

            if (availabilityData.data != null
                && availabilityData.data.suppliers != null
                && availabilityData.data.suppliers.size() > 0) {

                AvailabilityAPIJsonDeserialize.cls_suppliers supplier =
                    availabilityData.data.suppliers[0];

                if (supplier != null && supplier.contractType != null) {
                    return supplier.contractType;
                }
            }

        } catch (Exception ex) {
            String appName = 'MASIntegrationService By Pass Review Availability parser failed for Quote ' +
                           quoteLine.SBQQ__Quote__r.Name + ' QuoteLine ' + quoteLine.Name;
            STPExceptionUtil.setStepByStepExceptionObj('bypassPriceReview', appName, ex.getMessage());
        }

        return null;
    }

    /**
     * @description Validate MAS details are complete
     * @param masData MAS wrapper to validate
     * @return List of validation error messages
     */
    public List<String> validateMASDetails(QuoteProcurementController.MASWrapper masData) {
        List<String> errors = new List<String>();

        if (masData == null) {
            errors.add('MAS details are required');
            return errors;
        }

        if (String.isBlank(masData.MASLibrary)) {
            errors.add('MAS Library is required');
        }

        if (String.isBlank(masData.MASCompany)) {
            errors.add('MAS Company is required');
        }

        if (masData.MASAccount == null) {
            errors.add('MAS Account is required');
        }

        if (masData.MASUniqueId == null) {
            errors.add('MAS Unique ID is required');
        }

        return errors;
    }

    /**
     * @description Get MAS details from quote line
     * @param quoteLineId Quote line ID
     * @return MAS wrapper with current values or null
     */
    public QuoteProcurementController.MASWrapper getMASDetails(Id quoteLineId) {
        if (quoteLineId == null) {
            return null;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, MASLibrary__c, MASCompany__c, MASAccount__c,
                                                         MASCustomerUniqueId__c, MASServiceLine__c, MASBox__c,
                                                         BypassPriceReview__c, SetupComment__c,
                                                         DoNotCreateMASTicket__c, DoNotCreateTaskGridTickets__c,
                                                         VCRCode__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE Id = :quoteLineId
                                                   LIMIT 1];

            if (quoteLines.isEmpty()) {
                return null;
            }

            SBQQ__QuoteLine__c quoteLine = quoteLines[0];
            QuoteProcurementController.MASWrapper masData = new QuoteProcurementController.MASWrapper();

            masData.MASLibrary = quoteLine.MASLibrary__c;
            masData.MASCompany = quoteLine.MASCompany__c;
            masData.MASAccount = quoteLine.MASAccount__c;
            masData.MASUniqueId = quoteLine.MASCustomerUniqueId__c;
            masData.MASServiceLine = quoteLine.MASServiceLine__c;
            masData.MASBox = quoteLine.MASBox__c;
            masData.MASComment = quoteLine.SetupComment__c;
            masData.MASBypassPrice = quoteLine.BypassPriceReview__c;
            masData.MASDoNotCreate = quoteLine.DoNotCreateMASTicket__c;
            masData.DoNotCreateTaskGridTickets = quoteLine.DoNotCreateTaskGridTickets__c;
            masData.VCRCode = quoteLine.VCRCode__c;

            return masData;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting MAS details: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Check if MAS details should bypass MAS service change
     * @param quoteLineId Quote line ID
     * @return True if should bypass
     */
    public Boolean shouldBypassMASServiceChange(Id quoteLineId) {
        if (quoteLineId == null) {
            return false;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, BypassMASServiceChange__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE Id = :quoteLineId
                                                   LIMIT 1];

            return !quoteLines.isEmpty() && quoteLines[0].BypassMASServiceChange__c;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error checking bypass MAS service change: ' + ex.getMessage());
            return false;
        }
    }
}
