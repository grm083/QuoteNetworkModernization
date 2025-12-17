# Phase 10: QuoteProcurementController Refactoring Plan

## Executive Summary

**Current State**: 5,753 lines, 98 methods, massive complexity
**Target State**: ~2,500 lines, full service delegation, clean controller
**Expected Reduction**: 50-60% (3,000+ lines to services)
**Timeline**: 5 focused phases

---

## Current State Analysis

### Critical Metrics
- **Total Lines**: 5,753
- **Total Methods**: 98 (58 @AuraEnabled, 83 public static)
- **Longest Method**: `buildWrapper` (251 lines)
- **Highest Complexity**: `createDelivery` (60+ conditionals)
- **Code Duplication**: 27+ vendor status checks, 10+ MAS validation patterns
- **Service Integration**: 8 services partially used (20-30% coverage)

### Top 10 Longest Methods (Refactoring Targets)
1. **buildWrapper** - 251 lines (Data transformation)
2. **createQuoteLines** - 202 lines (Quote line creation)
3. **addQuoteAndQuoteine** - 138 lines (Quote/line addition)
4. **addCommentForSLAOverride** - 81 lines (SLA handling)
5. **validateRemoval** - 81 lines (Removal validation)
6. **buildQuoteWrapper** - 74 lines (Quote wrapping)
7. **vTStage** - 69 lines (Stage T validation)
8. **vSStage** - 65 lines (Stage S validation)
9. **createDelivery** - 60+ conditionals (Delivery orchestration)
10. **HandleSizeChange** - 29+ conditionals (Size change handling)

---

## Phase 10 Roadmap

### **Phase 10.1: Data Mapping & Transformation** (Week 1)
**Goal**: Extract all data wrapper/mapper logic to dedicated service

**Create: QuoteDataMapperService**
- `buildQuoteWrapper()` - 74 lines → service method
- `buildWrapper()` - 251 lines → service method
- `buildQuoteLineWrapper()` - Extract from various methods
- `buildProductWrapper()` - Extract from getQuoteProducts
- `mapQuoteLineToWrapper()` - Consolidate 6 similar patterns

**Methods to Refactor**: 6 methods, ~400 lines
**Expected Result**: Controller → 5,350 lines

---

### **Phase 10.2: Validation Consolidation** (Week 2)
**Goal**: Consolidate all validation logic into expanded service

**Expand: QuoteLineValidationService**

**New Methods to Add**:
```apex
// Stage Validations
validateStageF(quoteLine, quote) → ValidationResult  // vFStage
validateStageS(quoteLine, quote) → ValidationResult  // vSStage
validateStageT(quoteLine, quote) → ValidationResult  // vTStage
validateStageQ(quoteLine, quote) → ValidationResult  // vQStage
validateAllStages(quoteLine, quote) → ValidationResult

// Vendor Validations (consolidate 27+ duplicate checks)
validateVendorStatus(vendor) → Boolean
validateVendorRequired(quoteLine) → ValidationResult
validateVendorForProduct(quoteLine, vendor) → ValidationResult

// MAS Validations (consolidate 10+ patterns)
validateMASLibrary(quoteLine) → ValidationResult
validateMASCompanyCode(quoteLine) → ValidationResult
validateMASUniqueId(quoteLine) → ValidationResult
validateAllMASFields(quoteLine) → ValidationResult

// Cost/Price Validations
validateCostAndPrice(quoteLine) → ValidationResult
validatePricingMethod(quoteLine) → ValidationResult
validateCostModel(quoteLine) → ValidationResult

// Product Validations
validateWMFeeProduct(quoteLine) → ValidationResult
validateManagementFee(quoteLine) → ValidationResult
validateProductConfiguration(quoteLine) → ValidationResult
```

**Methods to Refactor**: 14 methods, ~500 lines
**Expected Result**: Controller → 4,850 lines

---

### **Phase 10.3: Delivery Orchestration Expansion** (Week 3)
**Goal**: Complete delivery orchestration service implementation

**Expand: DeliveryOrchestrationService**

**Critical Methods to Extract** (HIGH COMPLEXITY):
```apex
// Delivery Creation (60+ conditionals!)
createDelivery(request) → DeliveryResult

// Change Handlers (29-40 conditionals each)
handleSizeChange(quoteLine, oldSize, newSize) → ChangeResult
handleQuantityChange(quoteLine, oldQty, newQty) → ChangeResult
handleSizeAndQuantityChange(quoteLine, changes) → ChangeResult

// Removal Orchestration
validateRemoval(quoteLine) → ValidationResult  // 81 lines
processRemoval(quoteLine) → RemovalResult
```

**Supporting Services**:
```apex
// DeliveryValidationService (NEW)
validateDeliveryRequest(request) → ValidationResult
validateVendorCommitment(quoteLine) → ValidationResult
validateBackdatedService(quoteLine) → ValidationResult

// RemovalOrchestrationService (NEW)
orchestrateRemoval(quoteLine) → RemovalResult
validateRemovalEligibility(quoteLine) → ValidationResult
processAssetRemoval(quoteLine, asset) → Result
```

**Methods to Refactor**: 6 methods, ~400 lines (but HIGH complexity)
**Expected Result**: Controller → 4,450 lines

---

### **Phase 10.4: Quote Line Operations** (Week 4)
**Goal**: Extract all quote line CRUD operations to service

**Create: QuoteLineOperationsService**

**Methods to Extract**:
```apex
// Creation Operations
createQuoteLines(products, quoteId) → CreateResult  // 202 lines!
addQuoteAndQuoteLine(request) → AddResult  // 138 lines
cloneQuoteLine(quoteLineId) → CloneResult

// Update Operations
updateQuoteLine(quoteLine) → UpdateResult
updateQuoteLines(quoteLines) → BulkUpdateResult
updateQuoteLineStatus(quoteLineId, status) → Result

// Deletion Operations
deleteQuoteLine(quoteLineId) → DeleteResult
deleteQuoteLines(quoteLineIds) → BulkDeleteResult

// Bulk Operations
getQuoteProducts(quoteId) → List<Product>
getQuoteLinesForQuote(quoteId) → List<QuoteLine>
refreshQuoteLineData(quoteLineIds) → RefreshResult

// Orchestration
orchestrateQuoteLineCreation(request) → OrchestrationResult
```

**Methods to Refactor**: 12 methods, ~600 lines
**Expected Result**: Controller → 3,850 lines

---

### **Phase 10.5: SLA & Special Handling** (Week 5)
**Goal**: Extract SLA and special handling logic

**Create: SLAManagementService**
```apex
// SLA Operations
addCommentForSLAOverride(quoteLine, comment) → Result  // 81 lines
validateSLAOverride(quoteLine) → ValidationResult
calculateSLADates(quoteLine) → SLADates

// Comment Management
addSetupComment(quoteLine, comment) → Result
validateComment(comment) → ValidationResult
```

**Create: SpecialHandlingService**
```apex
// Special Handling
identifySpecialHandlingScenarios(quoteLine) → List<Scenario>
flagForSpecialHandling(quoteLine, reason) → Result
validateSpecialHandling(quoteLine) → ValidationResult

// Backdated Service Handling
detectBackdatedService(quoteLine) → Boolean
processBackdatedService(quoteLine) → Result
```

**Methods to Refactor**: 10 methods, ~300 lines
**Expected Result**: Controller → 3,550 lines

---

### **Phase 10.6: Remaining Refactoring** (Week 6)
**Goal**: Complete remaining service extractions

**Expand: VendorManagementService**
- Complete vendor validation integration
- Remove 27+ duplicate vendor status checks
- Consolidate vendor-related operations

**Expand: MASIntegrationService**
- Complete MAS validation integration
- Consolidate 10+ duplicate MAS patterns
- Add MAS data refresh operations

**Expand: ProductConfigurationService**
- Complete product config operations
- Add product validation
- Handle product relationships

**Methods to Refactor**: 15+ methods, ~400 lines
**Expected Result**: Controller → 3,150 lines

---

## Service Architecture - Phase 10

```
QuoteProcurementController (3,150 lines target)
├─ @AuraEnabled Methods (58 thin wrappers)
│
├─ QuoteDataMapperService (NEW)
│  ├─ buildQuoteWrapper()
│  ├─ buildWrapper()
│  └─ mapToWrappers()
│
├─ QuoteLineValidationService (EXPAND)
│  ├─ validateStageF/S/T/Q()
│  ├─ validateVendor() [27 → 1]
│  ├─ validateMAS() [10 → 1]
│  └─ validateCostPrice()
│
├─ DeliveryOrchestrationService (EXPAND)
│  ├─ createDelivery()
│  ├─ handleSizeChange()
│  ├─ handleQuantityChange()
│  └─ validateRemoval()
│
├─ QuoteLineOperationsService (NEW)
│  ├─ createQuoteLines()
│  ├─ addQuoteAndQuoteLine()
│  ├─ updateQuoteLine()
│  └─ orchestrateCreation()
│
├─ SLAManagementService (NEW)
│  ├─ addCommentForSLAOverride()
│  └─ calculateSLADates()
│
├─ SpecialHandlingService (NEW)
│  ├─ identifyScenarios()
│  └─ processBackdatedService()
│
├─ VendorManagementService (EXPAND)
│  └─ Consolidate vendor operations
│
├─ MASIntegrationService (EXPAND)
│  └─ Consolidate MAS operations
│
└─ ProductConfigurationService (EXPAND)
    └─ Complete config operations
```

---

## Implementation Strategy

### Approach: Incremental Service Extraction

**Step-by-Step Process** (repeat for each phase):

1. **Identify Target Methods**
   - Select 5-10 related methods
   - Document current behavior
   - Identify dependencies

2. **Create/Expand Service**
   - Create new service class OR expand existing
   - Extract business logic from controller
   - Add comprehensive error handling
   - Add result wrappers

3. **Create Test Class**
   - Aim for 95%+ coverage
   - Test all scenarios
   - Test error conditions

4. **Update Controller**
   - Replace inline logic with service call
   - Keep @AuraEnabled wrapper thin
   - Maintain backward compatibility

5. **Test & Validate**
   - Run all tests
   - Validate in sandbox
   - Compare results with old logic

6. **Commit & Push**
   - Clear commit message
   - Reference phase number
   - Document changes

---

## Code Reduction Targets

| Phase | Description | Lines Reduced | Controller Size | Status |
|-------|-------------|---------------|-----------------|--------|
| **Current** | Baseline | - | 5,753 | ✅ |
| **10.1** | Data Mapping | 400 | 5,350 | ⏳ |
| **10.2** | Validation | 500 | 4,850 | ⏳ |
| **10.3** | Delivery Orchestration | 400 | 4,450 | ⏳ |
| **10.4** | Quote Line Operations | 600 | 3,850 | ⏳ |
| **10.5** | SLA & Special Handling | 300 | 3,550 | ⏳ |
| **10.6** | Remaining Refactoring | 400 | **3,150** | ⏳ |
| | | | | |
| **Total** | **Overall Reduction** | **2,600 lines (45%)** | **3,150** | **🎯** |

---

## Success Metrics

### Code Quality
- ✅ Controller under 3,500 lines
- ✅ No method over 100 lines
- ✅ No method with >15 conditionals
- ✅ All business logic in services
- ✅ 95%+ test coverage maintained

### Maintainability
- ✅ Clear separation of concerns
- ✅ No duplicate logic
- ✅ Service layer reusable
- ✅ Easy to extend

### Performance
- ✅ No SOQL queries in controller loops
- ✅ Service layer caching
- ✅ Bulk operations optimized

---

## Example: Before & After

### BEFORE (Current State)
```apex
@AuraEnabled
public static string vSStage(SBQQ__QuoteLine__c bundleHeader, Boolean isNewService) {
    // 65 lines of inline validation logic
    // Multiple SOQL queries
    // Complex nested conditionals
    // Duplicate vendor checks
    // No error handling wrappers

    if(bundleHeader.Vendor__c == null){
        return strVendorMissing;
    }

    Account vendor = [SELECT Id, Name, Vendor_Status__c
                      FROM Account WHERE Id = :bundleHeader.Vendor__c LIMIT 1];

    if(vendor.Vendor_Status__c != 'Active'){
        return strVendorInactive;
    }

    // ... 60 more lines of validation logic ...

    return null;
}
```

### AFTER (Phase 10.2 Target)
```apex
@AuraEnabled
public static string vSStage(SBQQ__QuoteLine__c bundleHeader, Boolean isNewService) {
    try {
        // Delegate to validation service
        QuoteLineValidationService validationService = new QuoteLineValidationService();
        QuoteLineValidationService.ValidationResult result =
            validationService.validateStageS(bundleHeader, isNewService);

        return result.isValid ? null : result.errorMessage;

    } catch (Exception ex) {
        UTIL_LoggingService.logException(ex, 'QuoteProcurementController', 'vSStage');
        return 'Validation failed: ' + ex.getMessage();
    }
}
```

**Validation Service Implementation**:
```apex
public class QuoteLineValidationService {

    public ValidationResult validateStageS(SBQQ__QuoteLine__c quoteLine, Boolean isNewService) {
        ValidationResult result = new ValidationResult();

        // Vendor validation (reusable across all stages)
        ValidationResult vendorResult = validateVendorRequired(quoteLine);
        if (!vendorResult.isValid) {
            return vendorResult;
        }

        // MAS validation (reusable)
        ValidationResult masResult = validateMASRequired(quoteLine);
        if (!masResult.isValid) {
            return masResult;
        }

        // Cost validation (reusable)
        ValidationResult costResult = validateCostRequired(quoteLine);
        if (!costResult.isValid) {
            return costResult;
        }

        // Stage S specific validations
        // ... additional logic ...

        result.isValid = true;
        return result;
    }

    // Reusable validation methods used across all stages
    private ValidationResult validateVendorRequired(SBQQ__QuoteLine__c quoteLine) {
        // Consolidated from 27+ duplicate checks
        // Includes caching, error handling, proper logging
    }

    public class ValidationResult {
        public Boolean isValid;
        public String errorMessage;
        public List<String> warnings;
    }
}
```

---

## Risk Mitigation

### Risk 1: Breaking Existing Functionality
**Mitigation**:
- Comprehensive test coverage before refactoring
- Feature flags for gradual rollout
- Parallel execution testing
- Sandbox validation before production

### Risk 2: Performance Degradation
**Mitigation**:
- Performance testing after each phase
- Service layer caching
- SOQL query optimization
- Bulk operation patterns

### Risk 3: LWC/Aura Compatibility
**Mitigation**:
- Maintain @AuraEnabled method signatures
- Keep same return types
- Backward compatibility wrappers
- Thorough UI testing

### Risk 4: Timeline Overruns
**Mitigation**:
- Phased approach (6 weeks → 6 phases)
- Focus on highest-value phases first
- Can stop after any phase
- Incremental value delivery

### Risk 5: Developer Knowledge Transfer
**Mitigation**:
- Comprehensive documentation
- Code comments on service methods
- Service architecture diagrams
- Pair programming during implementation

---

## Dependencies & Prerequisites

### Required Before Starting
- ✅ Phase 8 complete (STP refactoring)
- ✅ Phase 9 complete (Lifecycle services)
- ✅ Existing 8 services available
- ✅ Test framework in place
- ✅ Sandbox environment ready

### Team Requirements
- 1-2 developers (full-time)
- Code reviewer
- QA for validation
- Access to sandbox

---

## Next Steps

### Immediate Actions
1. **Review this plan** with team
2. **Prioritize phases** (all 6 or subset?)
3. **Allocate resources** (developers, QA)
4. **Set timeline** (6 weeks aggressive, 8-10 weeks comfortable)
5. **Create Phase 10.1 task list**

### Start Phase 10.1 (Data Mapping Service)
```
□ Create QuoteDataMapperService.cls
□ Extract buildQuoteWrapper() → service
□ Extract buildWrapper() → service
□ Create comprehensive test class
□ Update controller to use service
□ Test in sandbox
□ Commit & push
```

---

## Questions?

- Which phase should we start with?
- Do you want all 6 phases or prioritize certain ones?
- What's your preferred timeline?
- Any specific concerns about certain methods?

---

**Last Updated**: 2025-12-12
**Version**: 1.0
**Author**: Quote Network Modernization Team
