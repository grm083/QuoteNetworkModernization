/**
 * @description Service for Special Handling detection and management
 * Automatically flags quotes for special handling based on configured criteria
 * @author Quote Network Modernization Team
 * @date 2025-12-13
 * @story Phase 10.5: SLA & Special Handling - SDT-30089
 */
public class SpecialHandlingService {

    // Constants for special handling reasons
    private static final String SPECIAL_HANDLING_AUTOMATIC_REASON = 'Automatically flagged by system';
    private static final String SPECIAL_HANDLING_BACKDATED_REASON = 'Back-dated service requested';

    /**
     * @description Update quote with special handling flags based on criteria
     * Checks for backdated service and special handling scenarios
     * @param quoteId Quote ID
     * @story SDT-30089
     */
    public void updateSpecialHandling(Id quoteId) {
        // Query quote lines for special handling criteria
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, Quote_SLA_Date__c, Certificate_of_Destruction__c, Certificate_of_Disposal__c,
                   Gate_Code__c, Service_Start_Time__c, Service_End_Time__c, Restriction_Details__c,
                   SBQQ__Quote__r.Special_Handling__c, SBQQ__Quote__r.Special_Handling_Reason__c,
                   SBQQ__Quote__r.Special_Handling_Reason_Details__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            AND SBQQ__RequiredBy__c = null
        ];

        if (quoteLines == null || quoteLines.isEmpty()) {
            return;
        }

        SBQQ__Quote__c quoteObj = new SBQQ__Quote__c();
        Boolean shouldUpdate = false;

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            // Check for backdated service (SLA date before today)
            if (isBackdatedService(quoteLine)) {
                quoteObj.Special_Handling__c = true;
                quoteObj.Special_Handling_Reason__c = SPECIAL_HANDLING_BACKDATED_REASON;
                quoteObj.Special_Handling_Reason_Details__c = ''; // SDT-31144
                shouldUpdate = true;
                break;
            }
            // Check for special handling scenarios
            else if (hasSpecialHandlingScenarios(quoteLine)) {
                quoteObj.Special_Handling__c = true;
                quoteObj.Special_Handling_Reason__c = SPECIAL_HANDLING_AUTOMATIC_REASON;
                quoteObj.Special_Handling_Reason_Details__c = ''; // SDT-31144
                shouldUpdate = true;
                break;
            }
            // Clear automatic special handling if criteria no longer met
            else {
                if (isAutomaticSpecialHandling(quoteLine)) {
                    quoteObj.Special_Handling__c = false;
                    quoteObj.Special_Handling_Reason__c = null;
                    quoteObj.Special_Handling_Reason_Details__c = ''; // SDT-31144
                    shouldUpdate = true;
                }
            }
        }

        // Update quote if changes detected
        if (shouldUpdate && quoteObj != null) {
            quoteObj.Id = quoteId;
            update quoteObj;
        }
    }

    /**
     * @description Check if service is backdated (SLA date before today)
     * @param quoteLine Quote line with SLA date
     * @return True if backdated service detected
     */
    public Boolean isBackdatedService(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.Quote_SLA_Date__c != null && quoteLine.Quote_SLA_Date__c < System.today();
    }

    /**
     * @description Check if quote line has special handling scenarios
     * Scenarios include: Certificate requirements, gate codes, service time windows, restrictions
     * @param quoteLine Quote line to check
     * @return True if special handling scenarios detected
     */
    public Boolean hasSpecialHandlingScenarios(SBQQ__QuoteLine__c quoteLine) {
        // Must have future/current SLA date (not backdated)
        if (quoteLine.Quote_SLA_Date__c == null || quoteLine.Quote_SLA_Date__c < System.today()) {
            return false;
        }

        // Check for special handling criteria
        return quoteLine.Certificate_of_Destruction__c
            || quoteLine.Certificate_of_Disposal__c
            || !String.isBlank(quoteLine.Gate_Code__c)
            || quoteLine.Service_Start_Time__c != null
            || quoteLine.Service_End_Time__c != null
            || !String.isBlank(quoteLine.Restriction_Details__c);
    }

    /**
     * @description Check if quote has automatic special handling flag
     * (vs manual special handling set by user)
     * @param quoteLine Quote line with quote relationship
     * @return True if automatic special handling
     */
    private Boolean isAutomaticSpecialHandling(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__Quote__r.Special_Handling_Reason__c == SPECIAL_HANDLING_BACKDATED_REASON
            || quoteLine.SBQQ__Quote__r.Special_Handling_Reason__c == SPECIAL_HANDLING_AUTOMATIC_REASON;
    }

    /**
     * @description Identify all special handling scenarios for a quote line
     * @param quoteLine Quote line to analyze
     * @return List of scenario descriptions
     */
    public List<String> identifySpecialHandlingScenarios(SBQQ__QuoteLine__c quoteLine) {
        List<String> scenarios = new List<String>();

        if (isBackdatedService(quoteLine)) {
            scenarios.add('Back-dated service (SLA date before today)');
        }

        if (quoteLine.Certificate_of_Destruction__c) {
            scenarios.add('Certificate of Destruction required');
        }

        if (quoteLine.Certificate_of_Disposal__c) {
            scenarios.add('Certificate of Disposal required');
        }

        if (!String.isBlank(quoteLine.Gate_Code__c)) {
            scenarios.add('Gate code specified: ' + quoteLine.Gate_Code__c);
        }

        if (quoteLine.Service_Start_Time__c != null || quoteLine.Service_End_Time__c != null) {
            String timeWindow = 'Service time window: ';
            if (quoteLine.Service_Start_Time__c != null) {
                timeWindow += quoteLine.Service_Start_Time__c;
            }
            if (quoteLine.Service_End_Time__c != null) {
                timeWindow += ' - ' + quoteLine.Service_End_Time__c;
            }
            scenarios.add(timeWindow);
        }

        if (!String.isBlank(quoteLine.Restriction_Details__c)) {
            scenarios.add('Restriction details: ' + quoteLine.Restriction_Details__c);
        }

        return scenarios;
    }

    /**
     * @description Flag quote for special handling with specific reason
     * @param quoteId Quote ID
     * @param reason Special handling reason
     * @param details Optional reason details
     */
    public void flagForSpecialHandling(Id quoteId, String reason, String details) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Id = quoteId,
            Special_Handling__c = true,
            Special_Handling_Reason__c = reason,
            Special_Handling_Reason_Details__c = details != null ? details : ''
        );
        update quote;
    }

    /**
     * @description Clear special handling flag from quote
     * @param quoteId Quote ID
     */
    public void clearSpecialHandling(Id quoteId) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Id = quoteId,
            Special_Handling__c = false,
            Special_Handling_Reason__c = null,
            Special_Handling_Reason_Details__c = ''
        );
        update quote;
    }

    /**
     * @description Validate special handling fields
     * @param quote Quote with special handling fields
     * @return Validation result
     */
    public ValidationResult validateSpecialHandling(SBQQ__Quote__c quote) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;

        if (quote.Special_Handling__c && String.isEmpty(quote.Special_Handling_Reason__c)) {
            result.isValid = false;
            result.errorMessage = 'Special Handling Reason is required when Special Handling is enabled';
        }

        return result;
    }

    /**
     * @description Validation result wrapper class
     */
    public class ValidationResult {
        public Boolean isValid;
        public String errorMessage;
        public List<String> warnings;

        public ValidationResult() {
            this.isValid = false;
            this.warnings = new List<String>();
        }
    }
}
