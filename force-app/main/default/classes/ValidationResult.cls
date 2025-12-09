/**
 * @description Encapsulates the result of a validation operation
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class ValidationResult {

    private Boolean isValid;
    private List<String> errorMessages;
    private List<String> warningMessages;
    private Map<String, Object> metadata;

    /**
     * @description Constructor for successful validation
     */
    public ValidationResult() {
        this(true, new List<String>(), new List<String>());
    }

    /**
     * @description Constructor with validation status and messages
     * @param isValid Whether validation passed
     * @param errors List of error messages
     * @param warnings List of warning messages
     */
    public ValidationResult(Boolean isValid, List<String> errors, List<String> warnings) {
        this.isValid = isValid;
        this.errorMessages = errors != null ? errors : new List<String>();
        this.warningMessages = warnings != null ? warnings : new List<String>();
        this.metadata = new Map<String, Object>();
    }

    /**
     * @description Add an error message (fluent API)
     * @param message Error message to add
     * @return This ValidationResult for chaining
     */
    public ValidationResult addError(String message) {
        if (String.isNotBlank(message)) {
            this.errorMessages.add(message);
            this.isValid = false;
        }
        return this;
    }

    /**
     * @description Add a warning message (fluent API)
     * @param message Warning message to add
     * @return This ValidationResult for chaining
     */
    public ValidationResult addWarning(String message) {
        if (String.isNotBlank(message)) {
            this.warningMessages.add(message);
        }
        return this;
    }

    /**
     * @description Add metadata (fluent API)
     * @param key Metadata key
     * @param value Metadata value
     * @return This ValidationResult for chaining
     */
    public ValidationResult addMetadata(String key, Object value) {
        if (String.isNotBlank(key)) {
            this.metadata.put(key, value);
        }
        return this;
    }

    /**
     * @description Check if validation passed
     * @return True if valid, false otherwise
     */
    public Boolean isValid() {
        return this.isValid;
    }

    /**
     * @description Check if there are any errors
     * @return True if errors exist
     */
    public Boolean hasErrors() {
        return !this.errorMessages.isEmpty();
    }

    /**
     * @description Check if there are any warnings
     * @return True if warnings exist
     */
    public Boolean hasWarnings() {
        return !this.warningMessages.isEmpty();
    }

    /**
     * @description Get all error messages concatenated
     * @return Single string with all errors separated by newlines
     */
    public String getErrorMessage() {
        return String.join(this.errorMessages, '\n');
    }

    /**
     * @description Get list of error messages
     * @return List of error messages
     */
    public List<String> getErrorMessages() {
        return this.errorMessages;
    }

    /**
     * @description Get list of warning messages
     * @return List of warning messages
     */
    public List<String> getWarningMessages() {
        return this.warningMessages;
    }

    /**
     * @description Get metadata by key
     * @param key Metadata key
     * @return Metadata value
     */
    public Object getMetadata(String key) {
        return this.metadata.get(key);
    }

    /**
     * @description Get all metadata
     * @return Map of all metadata
     */
    public Map<String, Object> getAllMetadata() {
        return this.metadata;
    }

    /**
     * @description Combines multiple validation results into one
     * @param results List of validation results to combine
     * @return Combined ValidationResult
     */
    public static ValidationResult combine(List<ValidationResult> results) {
        if (results == null || results.isEmpty()) {
            return new ValidationResult();
        }

        ValidationResult combined = new ValidationResult();

        for (ValidationResult result : results) {
            if (result == null) {
                continue;
            }

            if (result.hasErrors()) {
                combined.isValid = false;
                combined.errorMessages.addAll(result.getErrorMessages());
            }

            if (result.hasWarnings()) {
                combined.warningMessages.addAll(result.getWarningMessages());
            }

            // Combine metadata
            for (String key : result.getAllMetadata().keySet()) {
                combined.metadata.put(key, result.getMetadata(key));
            }
        }

        return combined;
    }

    /**
     * @description Create a failed validation result with error message
     * @param errorMessage Error message
     * @return ValidationResult with error
     */
    public static ValidationResult createError(String errorMessage) {
        ValidationResult result = new ValidationResult();
        result.addError(errorMessage);
        return result;
    }

    /**
     * @description Create a successful validation result
     * @return ValidationResult with success
     */
    public static ValidationResult createSuccess() {
        return new ValidationResult();
    }

    /**
     * @description Create a validation result with warning
     * @param warningMessage Warning message
     * @return ValidationResult with warning
     */
    public static ValidationResult createWarning(String warningMessage) {
        ValidationResult result = new ValidationResult();
        result.addWarning(warningMessage);
        return result;
    }
}
