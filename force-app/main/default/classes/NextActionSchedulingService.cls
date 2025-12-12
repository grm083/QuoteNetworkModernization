/**
 * @description Service for calculating next action dates using business hours
 * Consolidates 8 InvocableBusinessHours calls from Quote_Status_Change_Flow
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Service Layer
 */
public with sharing class NextActionSchedulingService {

    private QuoteActionFrameworkRepository actionFrameworkRepo;
    private BusinessHours defaultBusinessHours;

    public NextActionSchedulingService() {
        this.actionFrameworkRepo = new QuoteActionFrameworkRepository();
        loadBusinessHours();
    }

    /**
     * @description Load default business hours
     */
    private void loadBusinessHours() {
        try {
            List<BusinessHours> bhList = [
                SELECT Id, Name
                FROM BusinessHours
                WHERE Name = :Constant_Util.BUSINESSNAME
                LIMIT 1
            ];

            if (!bhList.isEmpty()) {
                this.defaultBusinessHours = bhList[0];
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'NextActionSchedulingService', 'loadBusinessHours');
        }
    }

    /**
     * @description Calculate next action date/time considering business hours
     * Replaces InvocableBusinessHours.calculateBusinessTime()
     * @param delayMinutes Delay in minutes from now
     * @param quoteStartDate Quote start date
     * @param quoteStatus Quote status
     * @return DateTime next action date
     */
    public DateTime calculateNextActionDate(
        Decimal delayMinutes,
        Date quoteStartDate,
        String quoteStatus
    ) {
        if (defaultBusinessHours == null) {
            // Fallback: just add minutes to current time
            return DateTime.now().addMinutes(delayMinutes != null ? delayMinutes.intValue() : 0);
        }

        try {
            // Special handling for quotes >45 days out in Product Configured status
            // (matches InvocableBusinessHours logic)
            if (quoteStartDate != null &&
                Date.today().daysBetween(quoteStartDate) > 45 &&
                Constant_Util.QUOTE_PRODUCT_CONFIGURED.equalsIgnoreCase(quoteStatus)) {

                Date targetDate = quoteStartDate.addDays(-45);
                return BusinessHours.nextStartDate(defaultBusinessHours.Id, targetDate);
            }

            // Standard case: add delay to current time
            Long delayMilliseconds = (delayMinutes != null ? delayMinutes : 0) * 60000;
            return BusinessHours.add(defaultBusinessHours.Id, DateTime.now(), delayMilliseconds);

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'NextActionSchedulingService', 'calculateNextActionDate');
            // Fallback
            return DateTime.now().addMinutes(delayMinutes != null ? delayMinutes.intValue() : 0);
        }
    }

    /**
     * @description Calculate customer action delay
     * Replaces flow's "Calculate_Customer_Action_0" step
     * @param quote Quote record
     * @param framework Action framework with customer delay
     * @return DateTime next action due date
     */
    public DateTime calculateCustomerActionDelay(
        SBQQ__Quote__c quote,
        Quote_Action_Framework__mdt framework
    ) {
        if (framework == null || framework.Customer_Delay__c == null) {
            return null;
        }

        return calculateNextActionDate(
            framework.Customer_Delay__c,
            quote.SBQQ__StartDate__c,
            quote.SBQQ__Status__c
        );
    }

    /**
     * @description Calculate vendor action delay
     * Determines vendor type and applies appropriate delay
     * @param quote Quote record
     * @param vendorCode Vendor code (WM, RSG, TPH)
     * @param framework Action framework with vendor delays
     * @return DateTime next action date
     */
    public DateTime calculateVendorActionDelay(
        SBQQ__Quote__c quote,
        String vendorCode,
        Quote_Action_Framework__mdt framework
    ) {
        if (framework == null) {
            return null;
        }

        // Get appropriate delay based on vendor
        Decimal delayMinutes = getVendorDelayMinutes(vendorCode, framework);

        if (delayMinutes == null) {
            return null;
        }

        return calculateNextActionDate(
            delayMinutes,
            quote.SBQQ__StartDate__c,
            quote.SBQQ__Status__c
        );
    }

    /**
     * @description Get delay minutes for specific vendor
     * @param vendorCode Vendor code
     * @param framework Action framework
     * @return Decimal delay in minutes
     */
    private Decimal getVendorDelayMinutes(
        String vendorCode,
        Quote_Action_Framework__mdt framework
    ) {
        if (String.isBlank(vendorCode)) {
            return framework.Default_Delay__c;
        }

        String vendorCodeUpper = vendorCode.toUpperCase();

        if (vendorCodeUpper.contains('WM')) {
            return framework.WM_Delay__c;
        } else if (vendorCodeUpper.contains('RSG') || vendorCodeUpper.contains('REPUBLIC')) {
            return framework.RSG_Delay__c;
        } else if (vendorCodeUpper.contains('TPH')) {
            return framework.TPH_Delay__c;
        }

        return framework.Default_Delay__c;
    }

    /**
     * @description Calculate customer action offset
     * Replaces flow's "Calc_Customer_Offset" step
     * Used for Next_Action_Start_Date__c
     * @param quote Quote record
     * @param delayMinutes Delay in minutes
     * @return DateTime next action start date
     */
    public DateTime calculateCustomerActionOffset(
        SBQQ__Quote__c quote,
        Decimal delayMinutes
    ) {
        return calculateNextActionDate(
            delayMinutes,
            quote.SBQQ__StartDate__c,
            quote.SBQQ__Status__c
        );
    }

    /**
     * @description Result wrapper for scheduling calculations
     */
    public class SchedulingResult {
        public DateTime nextActionStartDate;
        public DateTime nextActionDueDate;
        public Boolean isVendorDelay = false;
        public Boolean isCustomerDelay = false;
        public String delayType; // 'WM', 'RSG', 'TPH', 'Customer'
        public Decimal delayMinutes;
        public Boolean success = true;
        public String errorMessage;

        public SchedulingResult() {
            this.success = true;
        }
    }

    /**
     * @description Calculate complete scheduling for quote
     * Determines if vendor or customer delay applies and calculates both dates
     * @param quote Quote record
     * @param vendorCode Vendor code from quote lines
     * @return SchedulingResult wrapper
     */
    public SchedulingResult calculateCompleteScheduling(
        SBQQ__Quote__c quote,
        String vendorCode
    ) {
        SchedulingResult result = new SchedulingResult();

        try {
            if (quote == null) {
                result.success = false;
                result.errorMessage = 'Quote is null';
                return result;
            }

            // Get action framework for quote status
            Quote_Action_Framework__mdt framework =
                actionFrameworkRepo.getFrameworkByStatus(quote.SBQQ__Status__c);

            if (framework == null) {
                result.success = false;
                result.errorMessage = 'No action framework found for status: ' + quote.SBQQ__Status__c;
                return result;
            }

            // Determine if vendor or customer delay applies
            Boolean hasVendorDelay = String.isNotBlank(vendorCode) &&
                                     (framework.WM_Delay__c != null ||
                                      framework.RSG_Delay__c != null ||
                                      framework.TPH_Delay__c != null);

            if (hasVendorDelay) {
                // Vendor delay scenario
                result.isVendorDelay = true;
                result.delayType = getVendorType(vendorCode);
                result.delayMinutes = getVendorDelayMinutes(vendorCode, framework);

                result.nextActionStartDate = calculateVendorActionDelay(quote, vendorCode, framework);
                result.nextActionDueDate = calculateVendorActionDelay(quote, vendorCode, framework);

            } else if (framework.Customer_Delay__c != null) {
                // Customer delay scenario
                result.isCustomerDelay = true;
                result.delayType = 'Customer';
                result.delayMinutes = framework.Customer_Delay__c;

                result.nextActionStartDate = calculateCustomerActionOffset(quote, framework.Customer_Delay__c);
                result.nextActionDueDate = calculateCustomerActionDelay(quote, framework);
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'NextActionSchedulingService', 'calculateCompleteScheduling');
            result.success = false;
            result.errorMessage = ex.getMessage();
        }

        return result;
    }

    /**
     * @description Get vendor type from vendor code
     * @param vendorCode Vendor code
     * @return String vendor type (WM, RSG, TPH, Other)
     */
    private String getVendorType(String vendorCode) {
        if (String.isBlank(vendorCode)) {
            return 'Other';
        }

        String vendorCodeUpper = vendorCode.toUpperCase();

        if (vendorCodeUpper.contains('WM')) {
            return 'WM';
        } else if (vendorCodeUpper.contains('RSG') || vendorCodeUpper.contains('REPUBLIC')) {
            return 'RSG';
        } else if (vendorCodeUpper.contains('TPH')) {
            return 'TPH';
        }

        return 'Other';
    }

    /**
     * @description Calculate next start date for action (simplified)
     * For immediate actions without delay
     * @return DateTime current time or next business start
     */
    public DateTime calculateImmediateActionStart() {
        if (defaultBusinessHours == null) {
            return DateTime.now();
        }

        try {
            return BusinessHours.nextStartDate(defaultBusinessHours.Id, Date.today());
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'NextActionSchedulingService', 'calculateImmediateActionStart');
            return DateTime.now();
        }
    }
}
