/**
 * @description Service for validating quote lines using strategy pattern
 * Replaces validation logic from QuoteProcurementController (vFStage, vSStage, vTStage, validateOccurence, etc.)
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class QuoteLineValidationService {

    private Map<ValidationContext.Stage, List<IValidationRule>> rulesByStage;

    /**
     * @description Constructor - initializes validation rules
     */
    public QuoteLineValidationService() {
        initializeValidationRules();
    }

    /**
     * @description Validate a quote line based on its current context
     * @param quoteLine Quote line to validate (must include Quote__r relationship)
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        if (quoteLine == null) {
            return ValidationResult.createError('Quote line cannot be null');
        }

        if (context == null) {
            return ValidationResult.createError('Validation context cannot be null');
        }

        List<ValidationResult> results = new List<ValidationResult>();

        // Get rules for current stage
        List<IValidationRule> rules = getRulesForStage(context.getCurrentStage());

        // Execute each applicable rule
        for (IValidationRule rule : rules) {
            try {
                if (rule.appliesTo(context)) {
                    ValidationResult ruleResult = rule.validate(quoteLine, context);
                    if (ruleResult != null) {
                        results.add(ruleResult);
                    }
                }
            } catch (Exception ex) {
                // Log exception and continue with other rules
                System.debug(LoggingLevel.ERROR, 'Exception in validation rule ' + rule.getRuleName() + ': ' + ex.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + ex.getStackTraceString());

                // Add error to results instead of failing entire validation
                results.add(ValidationResult.createError('Validation rule ' + rule.getRuleName() + ' failed: ' + ex.getMessage()));
            }
        }

        // Combine all validation results
        return ValidationResult.combine(results);
    }

    /**
     * @description Validate by specific stage (convenience method)
     * @param quoteLine Quote line to validate
     * @param stage Specific stage to validate against
     * @return ValidationResult
     */
    public ValidationResult validateByStage(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationContext context = new ValidationContext(quoteLine).withStage(stage);
        return validate(quoteLine, context);
    }

    /**
     * @description Batch validate multiple quote lines
     * @param quoteLines List of quote lines to validate
     * @return Map of quote line ID to validation result
     */
    public Map<Id, ValidationResult> validateBatch(List<SBQQ__QuoteLine__c> quoteLines) {
        Map<Id, ValidationResult> resultMap = new Map<Id, ValidationResult>();

        if (quoteLines == null || quoteLines.isEmpty()) {
            return resultMap;
        }

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            try {
                ValidationContext context = new ValidationContext(quoteLine);
                ValidationResult result = validate(quoteLine, context);
                resultMap.put(quoteLine.Id, result);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Exception validating quote line ' + quoteLine.Id + ': ' + ex.getMessage());
                resultMap.put(quoteLine.Id, ValidationResult.createError('Validation failed: ' + ex.getMessage()));
            }
        }

        return resultMap;
    }

    /**
     * @description Initialize validation rules by stage
     * This method maps rules to stages, implementing the cascading validation logic:
     * - Draft stage: Basic rules
     * - Product Configured: Draft + Vendor rules
     * - Cost Configured: Product Configured + Cost rules
     * - Price Configured: Cost Configured + Price rules
     */
    private void initializeValidationRules() {
        rulesByStage = new Map<ValidationContext.Stage, List<IValidationRule>>();

        // Draft stage rules - Basic validation
        List<IValidationRule> draftRules = new List<IValidationRule>{
            new ScheduleFrequencyRule(),
            new VendorActiveStatusRule()
        };
        rulesByStage.put(ValidationContext.Stage.DRAFT, draftRules);

        // Product Configured stage: Draft + Vendor and MAS rules
        List<IValidationRule> productConfiguredRules = new List<IValidationRule>();
        productConfiguredRules.addAll(draftRules);
        productConfiguredRules.addAll(new List<IValidationRule>{
            new VendorRequiredRule(),
            new MASLibraryRequiredRule(),
            new VendorCommitDateRule(),
            new VCRCodeRequiredRule()
        });
        rulesByStage.put(ValidationContext.Stage.PRODUCT_CONFIGURED, productConfiguredRules);

        // Cost Configured stage: Product Configured + Cost rules
        List<IValidationRule> costConfiguredRules = new List<IValidationRule>();
        costConfiguredRules.addAll(productConfiguredRules);
        costConfiguredRules.addAll(new List<IValidationRule>{
            new OccurrenceTypeRule(),
            new CostUOMRequiredRule(),
            new RemovalSwapoutSizeRule()
        });
        rulesByStage.put(ValidationContext.Stage.COST_CONFIGURED, costConfiguredRules);

        // Price Configured stage: Cost Configured + Price rules
        List<IValidationRule> priceConfiguredRules = new List<IValidationRule>();
        priceConfiguredRules.addAll(costConfiguredRules);
        priceConfiguredRules.addAll(new List<IValidationRule>{
            new MASUniqueIdRequiredRule(),
            new PricingMethodRequiredRule(),
            new PriceUOMRequiredRule(),
            new ListPriceRequiredRule(),
            new ManagementFeePriceRule(),
            new SteppedPriceRule()
        });
        rulesByStage.put(ValidationContext.Stage.PRICE_CONFIGURED, priceConfiguredRules);
    }

    /**
     * @description Get validation rules for a specific stage
     * @param stage Validation stage
     * @return List of validation rules for the stage
     */
    private List<IValidationRule> getRulesForStage(ValidationContext.Stage stage) {
        List<IValidationRule> rules = rulesByStage.get(stage);
        return rules != null ? rules : new List<IValidationRule>();
    }

    /**
     * @description Check if a quote line is valid for a specific stage
     * Convenience method that returns boolean instead of full ValidationResult
     * @param quoteLine Quote line to validate
     * @param stage Validation stage
     * @return True if valid, false otherwise
     */
    public Boolean isValid(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationResult result = validateByStage(quoteLine, stage);
        return result.isValid();
    }

    /**
     * @description Get error message for a quote line at a specific stage
     * Convenience method for getting just the error message
     * @param quoteLine Quote line to validate
     * @param stage Validation stage
     * @return Error message or empty string if valid
     */
    public String getErrorMessage(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationResult result = validateByStage(quoteLine, stage);
        return result.hasErrors() ? result.getErrorMessage() : '';
    }

    // ========================================================================
    // PHASE 10.2: CONSOLIDATED STAGE VALIDATION METHODS
    // These methods replace vFStage, vSStage, vTStage from QuoteProcurementController
    // Consolidates 27+ duplicate vendor checks, 10+ MAS validation patterns
    // ========================================================================

    /**
     * @description Validate Stage F (Draft) - Basic scheduling and vendor status
     * Replaces: QuoteProcurementController.vFStage()
     * @param qLine Quote line to validate (must include SBQQ__Quote__r relationship)
     * @return Error message or empty string if valid
     */
    public String validateStageF(SBQQ__QuoteLine__c qLine) {
        String errMsg = '';

        // Schedule frequency validation
        if (qLine.Occurrence_Type__c == 'SOC' || qLine.Occurrence_Type__c == 'SCH') {
            if (String.isBlank(qLine.Schedule_Frequency__c)) {
                errMsg = 'Scheduled service missing a service frequency (weekly, monthly, etc.)';
            } else if (qLine.Schedule_Frequency__c == 'W' && String.isBlank(qLine.Service_Days__c)) {
                errMsg = 'Weekly scheduled service missing day(s) of the week';
            }
        }

        // Vendor status validation (consolidated pattern)
        if (String.isBlank(errMsg)) {
            errMsg = validateVendorStatus(qLine);
        }

        return errMsg;
    }

    /**
     * @description Validate Stage S (Product Configured) - Vendor, MAS, and Cost validations
     * Replaces: QuoteProcurementController.vSStage()
     * @param qLine Quote line to validate (must include all vendor and MAS relationships)
     * @return Error message or empty string if valid
     */
    public String validateStageS(SBQQ__QuoteLine__c qLine) {
        String errMsg = '';

        // Check if quote line changed for non-new service (SDT-32124)
        if (!QuoteLineServices.isQuoteLineChangedforNonNs(qLine)) {
            return errMsg;
        }

        // Vendor required validation
        if (qLine.Vendor__c == null) {
            return QuoteProcurementController.strVendorMissing;
        }

        // Vendor status validation
        errMsg = validateVendorStatus(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // MAS fields validation for WM vendors
        errMsg = validateMASFields(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // Vendor commit date validation
        errMsg = validateVendorCommitDate(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // VCR Code validation for WM vendors
        errMsg = validateVCRCode(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // Cost model validation
        if (String.isBlank(errMsg)) {
            errMsg = validateCostModel(qLine);
        }

        // Removal/Swapout size validation (SDT-32753)
        if (String.isBlank(errMsg) &&
            qLine.SBQQ__RequiredBy__r.SBQQ__ProductFamily__c == Constant_Util.COMMERCIAL &&
            qLine.SBQQ__Quote__r.SBQQ__Status__c == 'Product Configured' &&
            (qLine.SBQQ__Product__r.Name == Constant_Util.REMOVAL ||
             qLine.SBQQ__Product__r.Name == Constant_Util.SWAPOUT_PRODUCT) &&
            qLine.SBQQ__Quote__r.Case_record_Type__c != Constant_Util.New_Service_Case) {
            errMsg = validateRemovalSwapoutSize(qLine);
        }

        return errMsg;
    }

    /**
     * @description Validate Stage T (Cost/Price Configured) - MAS, Pricing, and Price validations
     * Replaces: QuoteProcurementController.vTStage()
     * @param qLine Quote line to validate (must include all relationships)
     * @return Error message or empty string if valid
     */
    public String validateStageT(SBQQ__QuoteLine__c qLine) {
        String errMsg = '';

        // Vendor status validation
        errMsg = validateVendorStatus(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // Vendor commit date validation
        errMsg = validateVendorCommitDate(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // MAS Unique ID validation for WM vendors (non-Quote types)
        String vendorId = qLine.Vendor__r.Parent_Vendor_ID__c;
        if ((vendorId == Constant_Util.WM_US_VENDOR || vendorId == Constant_Util.WM_CANADA_VENDOR) &&
            qLine.SBQQ__Quote__r.SBQQ__Type__c != 'Quote' &&
            qLine.MASCustomerUniqueId__c == null) {
            return QuoteProcurementController.strMassIdMissing;
        }

        // VCR Code validation for WM vendors
        errMsg = validateVCRCode(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // Pricing method validation
        errMsg = validatePricingMethod(qLine);
        if (String.isNotBlank(errMsg)) {
            return errMsg;
        }

        // Price fields validation
        errMsg = validatePriceFields(qLine);

        return errMsg;
    }

    // ========================================================================
    // CONSOLIDATED HELPER VALIDATION METHODS
    // Reusable validation logic to eliminate duplication
    // ========================================================================

    /**
     * @description Validate vendor status (consolidates 27+ duplicate checks)
     * @param qLine Quote line with vendor relationship
     * @return Error message or empty string if valid
     */
    public String validateVendorStatus(SBQQ__QuoteLine__c qLine) {
        if (qLine.Vendor__c == null) {
            return '';
        }

        // Check if vendor status validation applies
        Boolean shouldValidateVendor = (
            qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' ||
            qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Exception' ||
            qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Correction' ||
            (qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote' && qLine.SBQQ__Quote__r.STP__c == false) ||
            (qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote' && qLine.SBQQ__Quote__r.STP__c == true)
        );

        if (shouldValidateVendor && qLine.Vendor__r.Status__c == 'Inactive') {
            return QuoteProcurementController.strVendorInactive;
        }

        return '';
    }

    /**
     * @description Validate MAS fields for WM vendors (consolidates 10+ patterns)
     * @param qLine Quote line with vendor and MAS relationships
     * @return Error message or empty string if valid
     */
    public String validateMASFields(SBQQ__QuoteLine__c qLine) {
        String vendorId = qLine.Vendor__r.Parent_Vendor_ID__c;

        // MAS Library/Company validation for WM vendors
        if (vendorId == Constant_Util.WM_US_VENDOR || vendorId == Constant_Util.WM_CANADA_VENDOR) {
            if (String.isBlank(qLine.MASLibrary__c) || String.isBlank(qLine.MASCompany__c)) {
                return QuoteProcurementController.strMASLibraryOrCode;
            }

            // Setup comment validation (SDT-33303)
            if (String.isBlank(qLine.SetupComment__c) && qLine.DoNotCreateTaskGridTickets__c == false) {
                return QuoteProcurementController.strSetupComment;
            }
        }

        return '';
    }

    /**
     * @description Validate VCR Code for WM vendors
     * @param qLine Quote line with vendor relationship
     * @return Error message or empty string if valid
     */
    public String validateVCRCode(SBQQ__QuoteLine__c qLine) {
        String vendorId = qLine.Vendor__r.Parent_Vendor_ID__c;

        if ((vendorId == Constant_Util.WM_US_VENDOR || vendorId == Constant_Util.WM_CANADA_VENDOR) &&
            qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote' &&
            String.isBlank(qLine.VCRCode__c)) {
            return QuoteProcurementController.strVCRCodeMissing;
        }

        return '';
    }

    /**
     * @description Validate vendor commit date vs end date
     * @param qLine Quote line with date fields
     * @return Error message or empty string if valid
     */
    public String validateVendorCommitDate(SBQQ__QuoteLine__c qLine) {
        Date vendorCommitDate = qLine.Vendor_Commit_Date__c;
        Date endDate = qLine.SBQQ__EndDate__c;

        if (vendorCommitDate != null && endDate != null && vendorCommitDate > endDate &&
            (qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' || qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote')) {
            return 'End Dates must be greater than the vendor commit date';
        }

        return '';
    }

    /**
     * @description Validate cost model type and related fields
     * @param qLine Quote line with cost fields
     * @return Error message or empty string if valid
     */
    public String validateCostModel(SBQQ__QuoteLine__c qLine) {
        String vendorName = qLine.Vendor__r.Name;
        String vendorId = qLine.Vendor__r.Parent_Vendor_ID__c;

        // Cost UOM and Model Type required
        if (String.isBlank(qLine.Cost_Unit_of_Measure__c) || String.isBlank(qLine.CostModelType__c)) {
            return QuoteProcurementController.strCostUOMType;
        }

        // Stepped cost validation (SDT-41532)
        if (qLine.CostModelType__c == 'STP') {
            if (qLine.CostPrice1__c == null || qLine.CostPrice2__c == null) {
                return QuoteProcurementController.strCostModelTypeSTP;
            }
        }
        // Rebate cost validation
        else if (qLine.CostModelType__c == 'REB') {
            if (qLine.SBQQ__UnitCost__c != 0) {
                return QuoteProcurementController.strCostModelTypeRebate;
            }
        }
        // Standard cost validation
        else {
            if (qLine.SBQQ__UnitCost__c == null) {
                return QuoteProcurementController.strCostMissing;
            }

            // Management Fee validation
            if (qLine.SBQQ__ProductName__c == 'Management Fee') {
                if (qLine.SBQQ__UnitCost__c != 0 || !vendorName.startsWithIgnoreCase('WM Fee')) {
                    return QuoteProcurementController.strManagementFee;
                }
            }
            // WM Fee unit cost validation (SDT-48564)
            else if ((qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' || qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote') &&
                     !qLine.SBQQ__Quote__r.STP__c &&
                     vendorName != null &&
                     vendorName.startsWithIgnoreCase('WM Fee') &&
                     qLine.SBQQ__UnitCost__c != 0) {
                return QuoteProcurementController.strWMFeeUnitCost;
            }
            // Occurrence validation
            else {
                return validateOccurrence(qLine);
            }
        }

        return '';
    }

    /**
     * @description Validate pricing method field
     * @param qLine Quote line with pricing fields
     * @return Error message or empty string if valid
     */
    public String validatePricingMethod(SBQQ__QuoteLine__c qLine) {
        if (!qLine.SBQQ__Quote__r.STP__c &&
            (qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' || qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote') &&
            String.isBlank(qLine.SBQQ__PricingMethod__c)) {
            return QuoteProcurementController.strPricingMethodMissing;
        }

        return '';
    }

    /**
     * @description Validate price fields (UOM, List Price, WM Fee, Management Fee, Stepped)
     * @param qLine Quote line with price fields
     * @return Error message or empty string if valid
     */
    public String validatePriceFields(SBQQ__QuoteLine__c qLine) {
        String vendorName = qLine.Vendor__r.Name;

        // WM Fee list price validation
        if (vendorName != null && vendorName.startsWithIgnoreCase('WM Fee') && qLine.SBQQ__ListPrice__c == 0) {
            return QuoteProcurementController.strWMFeeList;
        }

        // Unit list price validation
        if ((qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' || qLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote') &&
            !qLine.SBQQ__Quote__r.STP__c &&
            qLine.SBQQ__ListPrice__c == null &&
            qLine.PricingUnitMethod__c != 'STP') {
            return QuoteProcurementController.strPriceMissing;
        }

        // Price UOM validation
        if (String.isBlank(qLine.PriceUOM__c)) {
            return 'Missing price unit of measure';
        }

        // Management Fee price validation
        if (qLine.SBQQ__ProductName__c == 'Management Fee' &&
            (qLine.SBQQ__ListPrice__c == null || qLine.SBQQ__ListPrice__c <= 0)) {
            return 'Price of Management Fee product option must be greater than $0.00';
        }

        // Stepped price validation (SDT-41532)
        if (qLine.SBQQ__PricingMethod__c == 'STP') {
            if (qLine.PricePrice1__c == null || qLine.PricePrice2__c == null) {
                return QuoteProcurementController.strPricingUnitMethodSTP;
            }
        }

        return '';
    }

    /**
     * @description Validate occurrence type and frequency fields
     * @param qLine Quote line with occurrence fields
     * @return Error message or empty string if valid
     */
    public String validateOccurrence(SBQQ__QuoteLine__c qLine) {
        if (qLine.Occurrence_Type__c == 'SOC' || qLine.Occurrence_Type__c == 'SCH') {
            // Frequency interval validation (SDT-48522)
            if ((qLine.Schedule_Frequency__c == 'D' || qLine.Schedule_Frequency__c == 'M' ||
                 qLine.Schedule_Frequency__c == 'Y' || qLine.Schedule_Frequency__c == 'W') &&
                String.isBlank(qLine.Frequency_Interval__c)) {
                return 'Scheduled/SOC service missing frequency interval';
            }
        } else if (qLine.Occurrence_Type__c == 'OC') {
            // On-call should not have frequency
            if (String.isNotBlank(qLine.Schedule_Frequency__c) || String.isNotBlank(qLine.Frequency_Interval__c)) {
                return 'On-call Service should not contain a Service Frequency or Frequency interval';
            }
        }

        return '';
    }

    /**
     * @description Validate removal/swapout size matches asset size (SDT-32753)
     * @param qLine Quote line with size and asset relationships
     * @return Error message or empty string if valid
     */
    public String validateRemovalSwapoutSize(SBQQ__QuoteLine__c qLine) {
        // Only validate if parent is commercial family
        if (qLine.SBQQ__RequiredBy__c == null ||
            qLine.SBQQ__RequiredBy__r.SBQQ__ProductFamily__c != Constant_Util.COMMERCIAL) {
            return '';
        }

        // Get equipment size picklist entries
        List<Schema.PicklistEntry> equipmentSizeEntries =
            Schema.SObjectType.SBQQ__QuoteLine__c.fields.Equipment_Size__c.getPicklistValues();

        String convertedAssetSize = AssetQuoteProcurementController.getPicklistEntryByLabel(
            equipmentSizeEntries,
            qLine.SBQQ__RequiredBy__r.AssetId__r.Equipment_Size__c
        );

        // Check if size changed for bundle
        if (qLine.SBQQ__RequiredBy__r.Equipment_Size__c != convertedAssetSize &&
            qLine.Equipment_Size__c != convertedAssetSize) {
            return 'Please ensure your Swapout and Removal have the correct sizes';
        }

        return '';
    }
}
