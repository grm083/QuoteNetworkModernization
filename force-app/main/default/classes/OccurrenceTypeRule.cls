/**
 * @description Validates occurrence type and frequency interval
 * Replaces logic from QuoteProcurementController.validateOccurence() lines 1079-1094
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class OccurrenceTypeRule implements IValidationRule {

    /**
     * @description Validate occurrence type rules
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        if (quoteLine.Occurrence_Type__c == 'SOC' || quoteLine.Occurrence_Type__c == 'SCH') {
            // Scheduled/SOC services need frequency interval for certain frequency types
            if (quoteLine.Schedule_Frequency__c == 'D'
                || quoteLine.Schedule_Frequency__c == 'M'
                || quoteLine.Schedule_Frequency__c == 'Y'
                || quoteLine.Schedule_Frequency__c == 'W') {

                if (String.isBlank(quoteLine.Frequency_Interval__c)) {
                    result.addError('Scheduled/SOC service missing frequency interval');
                }
            }
        } else if (quoteLine.Occurrence_Type__c == 'OC') {
            // On-call services should not have schedule frequency or interval
            if (String.isNotBlank(quoteLine.Schedule_Frequency__c)
                || String.isNotBlank(quoteLine.Frequency_Interval__c)) {
                result.addError('On-call Service should not contain a Service Frequency or Frequency interval');
            }
        }

        return result;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'OccurrenceTypeRule';
    }

    /**
     * @description Check if rule applies to context
     * Applies from Cost Configured stage onwards
     * @param context Validation context
     * @return True if applies
     */
    public Boolean appliesTo(ValidationContext context) {
        return context.getCurrentStage() == ValidationContext.Stage.COST_CONFIGURED
            || context.getCurrentStage() == ValidationContext.Stage.PRICE_CONFIGURED;
    }
}
