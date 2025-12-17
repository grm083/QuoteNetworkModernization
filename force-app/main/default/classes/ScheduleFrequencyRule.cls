/**
 * @description Validates schedule frequency for scheduled/SOC services
 * Replaces logic from QuoteProcurementController.vFStage() lines 925-933
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class ScheduleFrequencyRule implements IValidationRule {

    /**
     * @description Validate schedule frequency and service days
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Check if this is a scheduled or SOC service
        if (quoteLine.Occurrence_Type__c == 'SOC' || quoteLine.Occurrence_Type__c == 'SCH') {

            // Frequency is required for scheduled/SOC services
            if (String.isBlank(quoteLine.Schedule_Frequency__c)) {
                result.addError('Scheduled service missing a service frequency (weekly, monthly, etc.)');
                return result;
            }

            // Weekly frequency requires service days
            if (quoteLine.Schedule_Frequency__c == 'W' && String.isBlank(quoteLine.Service_Days__c)) {
                result.addError('Weekly scheduled service missing day(s) of the week');
            }
        }

        return result;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'ScheduleFrequencyRule';
    }

    /**
     * @description Check if rule applies to context
     * This rule applies to all stages
     * @param context Validation context
     * @return True (always applies)
     */
    public Boolean appliesTo(ValidationContext context) {
        return true; // Applies to all stages
    }
}
