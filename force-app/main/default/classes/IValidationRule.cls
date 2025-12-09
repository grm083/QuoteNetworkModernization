/**
 * @description Interface for validation rules implementing Strategy Pattern
 * All validation rules must implement this interface to be used by the validation service
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public interface IValidationRule {

    /**
     * @description Execute the validation rule
     * @param quoteLine Quote line to validate
     * @param context Validation context with quote/case information
     * @return ValidationResult indicating success or failure with error messages
     */
    ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context);

    /**
     * @description Get the name of this validation rule for logging/debugging
     * @return Rule name
     */
    String getRuleName();

    /**
     * @description Check if this rule applies to the current validation context
     * Allows rules to be conditionally applied based on stage, quote type, etc.
     * @param context Validation context
     * @return True if rule should be executed, false to skip
     */
    Boolean appliesTo(ValidationContext context);
}
