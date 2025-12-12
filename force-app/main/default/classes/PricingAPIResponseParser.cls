/**
 * @description Service for parsing and validating pricing API responses
 * Enhances existing PricingReportingFieldsMetadata with additional validation
 * Part of Phase 8 - STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 * @note Centralizes pricing response parsing and validation logic
 */
public with sharing class PricingAPIResponseParser {

    /**
     * @description Parse result with validation status
     */
    public class ParseResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public PricingReportingFieldsMetadata response { get; set; }
        @AuraEnabled public Boolean hasErrors { get; set; }
        @AuraEnabled public List<String> errorMessages { get; set; }
        @AuraEnabled public String parseErrorMessage { get; set; }

        public ParseResult() {
            this.success = false;
            this.hasErrors = false;
            this.errorMessages = new List<String>();
        }
    }

    /**
     * @description Parse pricing API response JSON
     * @param responseJson JSON response string
     * @return Parse result with validation
     */
    public ParseResult parsePricingResponse(String responseJson) {
        ParseResult result = new ParseResult();

        if (String.isBlank(responseJson)) {
            result.parseErrorMessage = 'Response JSON is blank';
            return result;
        }

        try {
            // Parse using existing metadata class
            PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);
            result.response = response;
            result.success = true;

            // Check for API errors
            if (response.isError()) {
                result.hasErrors = true;
                result.errorMessages = extractErrorMessages(response);
            }

        } catch (System.JSONException ex) {
            UTIL_LoggingService.logException(ex, 'PricingAPIResponseParser', 'parsePricingResponse');
            result.success = false;
            result.parseErrorMessage = 'JSON parse error: ' + ex.getMessage();
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingAPIResponseParser', 'parsePricingResponse');
            result.success = false;
            result.parseErrorMessage = 'Unexpected error: ' + ex.getMessage();
        }

        return result;
    }

    /**
     * @description Extract error messages from problem object
     * @param response Parsed pricing response
     * @return List of error messages
     */
    public List<String> extractErrorMessages(PricingReportingFieldsMetadata response) {
        List<String> messages = new List<String>();

        if (response == null || response.problem == null || response.problem.errors == null) {
            return messages;
        }

        for (PricingReportingFieldsMetadata.Errors error : response.problem.errors) {
            if (String.isNotBlank(error.message)) {
                messages.add(error.message);
            }
        }

        return messages;
    }

    /**
     * @description Validate response has required data
     * @param response Parsed pricing response
     * @return True if response has data section
     */
    public Boolean hasValidData(PricingReportingFieldsMetadata response) {
        return response != null && response.data != null;
    }

    /**
     * @description Validate response has rolloff pricing data
     * @param response Parsed pricing response
     * @return True if response has rolloff data
     */
    public Boolean hasRolloffData(PricingReportingFieldsMetadata response) {
        return hasValidData(response) && response.data.rollOff != null;
    }

    /**
     * @description Validate response has commercial pricing data
     * @param response Parsed pricing response
     * @return True if response has commercial data
     */
    public Boolean hasCommercialData(PricingReportingFieldsMetadata response) {
        return hasValidData(response) && response.data.commercial != null;
    }

    /**
     * @description Validate response has service charges
     * @param response Parsed pricing response
     * @return True if response has service charges
     */
    public Boolean hasServiceCharges(PricingReportingFieldsMetadata response) {
        return hasValidData(response) &&
               response.data.serviceCharges != null &&
               !response.data.serviceCharges.isEmpty();
    }

    /**
     * @description Get vendor code from response
     * @param response Parsed pricing response
     * @return Vendor code or null
     */
    public String getVendorCode(PricingReportingFieldsMetadata response) {
        if (!hasValidData(response)) {
            return null;
        }
        return response.data.supplierCode;
    }

    /**
     * @description Get cost source from response
     * @param response Parsed pricing response
     * @return Cost source or null
     */
    public String getCostSource(PricingReportingFieldsMetadata response) {
        if (!hasValidData(response)) {
            return null;
        }
        return response.data.costSource;
    }

    /**
     * @description Get currency code from response
     * @param response Parsed pricing response
     * @return Currency code or null
     */
    public String getCurrencyCode(PricingReportingFieldsMetadata response) {
        if (!hasValidData(response)) {
            return null;
        }
        return response.data.currencyCode;
    }

    /**
     * @description Check if response is cost only
     * @param response Parsed pricing response
     * @return True if cost only
     */
    public Boolean isCostOnlyResponse(PricingReportingFieldsMetadata response) {
        if (!hasValidData(response)) {
            return false;
        }
        return response.data.isCostOnly == true;
    }

    /**
     * @description Get haul cost from rolloff response
     * @param response Parsed pricing response
     * @return Haul cost or null
     */
    public Decimal getHaulCost(PricingReportingFieldsMetadata response) {
        if (!hasRolloffData(response)) {
            return null;
        }
        return response.data.rollOff.haulCost;
    }

    /**
     * @description Get haul price from rolloff response
     * @param response Parsed pricing response
     * @return Haul price or null
     */
    public Decimal getHaulPrice(PricingReportingFieldsMetadata response) {
        if (!hasRolloffData(response)) {
            return null;
        }
        return response.data.rollOff.haulPrice;
    }

    /**
     * @description Get disposal cost from rolloff response
     * @param response Parsed pricing response
     * @return Disposal cost or null
     */
    public Decimal getDisposalCost(PricingReportingFieldsMetadata response) {
        if (!hasRolloffData(response)) {
            return null;
        }
        return response.data.rollOff.disposalCost;
    }

    /**
     * @description Get disposal price from rolloff response
     * @param response Parsed pricing response
     * @return Disposal price or null
     */
    public Decimal getDisposalPrice(PricingReportingFieldsMetadata response) {
        if (!hasRolloffData(response)) {
            return null;
        }
        return response.data.rollOff.disposalPrice;
    }

    /**
     * @description Get pickup cost from commercial response
     * @param response Parsed pricing response
     * @return Pickup cost or null
     */
    public Decimal getPickupCost(PricingReportingFieldsMetadata response) {
        if (!hasCommercialData(response)) {
            return null;
        }
        return response.data.commercial.cost;
    }

    /**
     * @description Get pickup price from commercial response
     * @param response Parsed pricing response
     * @return Pickup price or null
     */
    public Decimal getPickupPrice(PricingReportingFieldsMetadata response) {
        if (!hasCommercialData(response)) {
            return null;
        }
        return response.data.commercial.price;
    }

    /**
     * @description Find service charge by code
     * @param response Parsed pricing response
     * @param serviceChargeCode Service charge code to find
     * @return Service charge or null
     */
    public PricingReportingFieldsMetadata.ServiceCharges findServiceChargeByCode(
        PricingReportingFieldsMetadata response,
        String serviceChargeCode
    ) {
        if (!hasServiceCharges(response) || String.isBlank(serviceChargeCode)) {
            return null;
        }

        for (PricingReportingFieldsMetadata.ServiceCharges charge : response.data.serviceCharges) {
            if (charge.code == serviceChargeCode) {
                return charge;
            }
        }

        return null;
    }

    /**
     * @description Find service charges by action name
     * @param response Parsed pricing response
     * @param actionName Action name (Allow, Adjust, Exclude, etc.)
     * @return List of matching service charges
     */
    public List<PricingReportingFieldsMetadata.ServiceCharges> findServiceChargesByAction(
        PricingReportingFieldsMetadata response,
        String actionName
    ) {
        List<PricingReportingFieldsMetadata.ServiceCharges> matches = new List<PricingReportingFieldsMetadata.ServiceCharges>();

        if (!hasServiceCharges(response)) {
            return matches;
        }

        for (PricingReportingFieldsMetadata.ServiceCharges charge : response.data.serviceCharges) {
            if (charge.actionName == actionName) {
                matches.add(charge);
            }
        }

        return matches;
    }

    /**
     * @description Get all service charge codes from response
     * @param response Parsed pricing response
     * @return Set of service charge codes
     */
    public Set<String> getServiceChargeCodes(PricingReportingFieldsMetadata response) {
        Set<String> codes = new Set<String>();

        if (!hasServiceCharges(response)) {
            return codes;
        }

        for (PricingReportingFieldsMetadata.ServiceCharges charge : response.data.serviceCharges) {
            if (String.isNotBlank(charge.code)) {
                codes.add(charge.code);
            }
        }

        return codes;
    }

    /**
     * @description Validate response has required pricing data
     * @param response Parsed pricing response
     * @param lineOfBusiness Line of business (Rolloff, Commercial, etc.)
     * @return True if has required pricing data
     */
    public Boolean hasRequiredPricingData(
        PricingReportingFieldsMetadata response,
        String lineOfBusiness
    ) {
        if (!hasValidData(response)) {
            return false;
        }

        if (lineOfBusiness == 'Rolloff') {
            return hasRolloffData(response) &&
                   (response.data.rollOff.haulCost != null || response.data.rollOff.haulPrice != null ||
                    response.data.rollOff.disposalCost != null || response.data.rollOff.disposalPrice != null);
        }
        else if (lineOfBusiness == 'Commercial') {
            return hasCommercialData(response) &&
                   (response.data.commercial.cost != null || response.data.commercial.price != null);
        }

        return false;
    }

    /**
     * @description Build error summary from response
     * @param response Parsed pricing response
     * @return Error summary string
     */
    public String buildErrorSummary(PricingReportingFieldsMetadata response) {
        if (response == null || !response.isError()) {
            return null;
        }

        List<String> errorMessages = extractErrorMessages(response);
        if (errorMessages.isEmpty()) {
            return 'Unknown pricing error';
        }

        return String.join(errorMessages, '; ');
    }

    /**
     * @description Parse multiple pricing responses
     * @param responseJsonList List of JSON response strings
     * @return List of parse results
     */
    public List<ParseResult> parseBulkPricingResponses(List<String> responseJsonList) {
        List<ParseResult> results = new List<ParseResult>();

        if (responseJsonList == null || responseJsonList.isEmpty()) {
            return results;
        }

        for (String responseJson : responseJsonList) {
            ParseResult result = parsePricingResponse(responseJson);
            results.add(result);
        }

        return results;
    }

    /**
     * @description Get step disposal pricing (for tiered disposal)
     * @param response Parsed pricing response
     * @return List of step disposal tiers or empty list
     */
    public List<PricingReportingFieldsMetadata.StepDisposal> getStepDisposals(
        PricingReportingFieldsMetadata response
    ) {
        if (!hasRolloffData(response) || response.data.rollOff.stepDisposals == null) {
            return new List<PricingReportingFieldsMetadata.StepDisposal>();
        }
        return response.data.rollOff.stepDisposals;
    }

    /**
     * @description Check if response has tiered disposal pricing
     * @param response Parsed pricing response
     * @return True if has step disposal pricing
     */
    public Boolean hasStepDisposalPricing(PricingReportingFieldsMetadata response) {
        List<PricingReportingFieldsMetadata.StepDisposal> steps = getStepDisposals(response);
        return !steps.isEmpty();
    }
}
