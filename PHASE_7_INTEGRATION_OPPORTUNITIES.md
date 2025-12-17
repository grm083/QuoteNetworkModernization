# Phase 7: Service Integration Opportunities

## Executive Summary

This document identifies opportunities to integrate business logic from **QuoteTriggerHelper** (1,141 lines), **QuoteLineTriggerHelper** (1,636 lines), and **QuoteFavoritesController** (1,112 lines) into the modernized service tier architecture established in Phases 1-6.

**Total Lines Under Review**: 3,889 lines
**Modernization Potential**: ~2,500-3,000 lines could be extracted into services

---

## File Analysis

### 1. QuoteTriggerHelper (1,141 lines)

**Current Responsibilities**:
- Genesys integration and task creation
- Quote status change handling
- Type of Change field tracking
- VCR code updates
- Amendment quote approval workflows
- Integration orchestration (STP, pricing)
- Frequency calculations
- Haul away task creation
- Chargeability case creation

**Key Methods** (40+ methods):
- `isEligibleForGenesys()` - Genesys eligibility checking
- `createGenesysForQuote()` - Genesys record creation
- `changeInStatus()` - Quote status change handler
- `updateTypeOfChangeFieldOnQuoteLines()` - Type of change tracking
- `compareAndUpdateTypeOfChangeFieldOnQuoteLine()` - Asset comparison logic
- `integrationRequired()` - Integration workflow orchestration
- `stpPricingOnlyIntegration()` - STP pricing integration
- `filterQuoteAndUpdateQuoteLinesWithVCR()` - VCR code management
- `calculateFrequencyChange()` - Frequency delta calculation
- `createTaskonHaulAwayQuote()` - Haul away task automation
- `verifyAmendmentQuoteApprovalBySalesTeam()` - Amendment approvals

### 2. QuoteLineTriggerHelper (1,636 lines)

**Current Responsibilities**:
- Extra pickup quote line management
- Vendor validation
- MAS details propagation to quote lines
- Material type updates
- Duration and account management
- Quote date calculations
- Cost/price validation
- Schedule field calculations
- Classification tracking
- Company category updates
- Asset size comparison

**Key Methods** (50+ methods):
- `addExtraPickupQuoteLine()` - Extra pickup automation
- `removeExtraPickupQuoteLine()` - Extra pickup cleanup
- `validateVendorSelection()` - Vendor validation rules
- `updateMASDetailsToQuoteLines()` - MAS propagation (DUPLICATE with Phase 5)
- `updateDurationAndAccountOnQuoteLine()` - Duration management
- `updateQuotedate()` - Quote date synchronization
- `validateQLCostPrice()` - Cost/price validation
- `calculateScheduleField()` - Schedule calculations
- `assignInitialClassificationChanges()` - Classification tracking
- `CompareQlsizewithAssetsize()` - Asset comparison
- `updateCCOnCase()` - Company category propagation

### 3. QuoteFavoritesController (1,112 lines)

**Current Responsibilities**:
- Product search and retrieval
- Waste stream management
- Equipment size lookups
- Favorites CRUD operations
- **SLA calculation engine** (CRITICAL - 500+ lines)
- Quote line creation from favorites

**Key Methods** (15+ @AuraEnabled methods):
- `getProducts()` - Product retrieval
- `searchProducts()` - Product search
- `getWasteStreams()` - Waste stream options
- `getSizes()` - Equipment sizes (USED by Phase 6)
- `getFavorites()` - Favorites retrieval
- `addQuoteFavorite()` - Create quote line from favorite
- `determineSLA()` - **Main SLA calculation (318-877)**
- `calculateEntitlementSLA()` - Entitlement-based SLA
- `calculateISSLA()` - Industry Standard SLA
- `getRelatedEntitleMent()` - Entitlement lookup

---

## Integration Opportunities by Service Domain

### 🔴 HIGH PRIORITY - Phase 7A

#### 1. **SLA Calculation Service**
**Target**: Extract from QuoteFavoritesController
**Lines**: ~560 lines
**Complexity**: HIGH
**Business Impact**: CRITICAL

**Methods to Extract**:
- `determineSLA()` - Main SLA orchestration (lines 318-877)
- `calculateEntitlementSLA()` - Entitlement calculations
- `calculateEntitlementSLA_LocTimezone()` - Timezone-aware calculations
- `calculateISSLA()` - Industry standard calculations
- `calculateISSLA_LocTimezone()` - Timezone industry standards
- `getRelatedEntitleMent()` - Entitlement lookups
- `getBusinessIdByTimeZone()` - Business hours lookup
- `getBusinessHoursInAccountTimeZone()` - Timezone conversions
- `getSLASwitch()` - Feature flag checking

**Why This Matters**:
- SLA calculation is core business logic used across the platform
- Currently embedded in UI controller (should be in service layer)
- Complex timezone handling needs to be reusable
- Already referenced by Phase 6 QuoteWrapperService
- Enables better testing and consistency

**Proposed Service**: `SLACalculationService`

**Integration with Existing Services**:
- Used by: QuoteWrapperService (Phase 6)
- Integrates with: HaulAwayService (checks haul away status)
- Could leverage: UIDataService for picklist values

---

#### 2. **Type of Change Tracking Service**
**Target**: Extract from QuoteTriggerHelper
**Lines**: ~220 lines
**Complexity**: MEDIUM
**Business Impact**: HIGH

**Methods to Extract**:
- `updateTypeOfChangeFieldOnQuoteLines()` - Change tracking trigger
- `compareAndUpdateTypeOfChangeFieldOnQuoteLine()` - Asset comparison (lines 546-683)
- `calculateFrequencyChange()` - Frequency delta calculation
- `calculateQuoteLineFrequency()` - Quote line frequency calc
- `calculateAssetFrequency()` - Asset frequency calc

**Why This Matters**:
- Critical for amendment quote processing
- Compares quote lines vs assets across 10+ dimensions
- Business logic should not be in trigger helper
- Enables reuse for asset change detection

**Proposed Service**: `ChangeTrackingService`

**Integration with Existing Services**:
- Could use: AssetComparisonService (Phase 3C) - **MERGE OPPORTUNITY**
- Related to: QuoteLineValidationService (Phase 1)

---

#### 3. **VCR Code Management Service**
**Target**: Extract from QuoteTriggerHelper
**Lines**: ~50 lines (+ VCRCodeController integration)
**Complexity**: LOW
**Business Impact**: MEDIUM

**Methods to Extract**:
- `filterQuoteAndUpdateQuoteLinesWithVCR()` - VCR triggering logic

**Why This Matters**:
- VCR code calculation should be service-based
- Currently triggers on quote approval
- Needs better orchestration

**Proposed Service**: Enhance existing `VCRCodeController` or create `VCRCodeService`

---

### 🟡 MEDIUM PRIORITY - Phase 7B

#### 4. **MAS Integration Service Enhancement**
**Target**: Extract from QuoteLineTriggerHelper
**Lines**: ~115 lines
**Complexity**: MEDIUM
**Business Impact**: MEDIUM

**Methods to Extract**:
- `updateMASDetailsToQuoteLines()` - MAS propagation (lines 378-492)

**Why This Matters**:
- **DUPLICATE LOGIC**: This replicates DataAggregationService.getUniqueMASDetails() from Phase 5
- Should be consolidated into MASIntegrationService (Phase 4)
- Same facility→business unit fallback logic
- Same line of business determination

**Proposed Action**:
- **DO NOT create new service**
- **REFACTOR** QuoteLineTriggerHelper to use existing MASIntegrationService + DataAggregationService
- **CONSOLIDATE** MAS propagation logic into MASIntegrationService

**Integration Opportunities**:
- Use: DataAggregationService.getUniqueMASDetails() (Phase 5)
- Use: MASIntegrationService.writeMASDetails() (Phase 4)
- Eliminate: Duplicate facility/business unit lookup logic

---

#### 5. **Extra Pickup Management Service**
**Target**: Extract from QuoteLineTriggerHelper
**Lines**: ~150 lines
**Complexity**: LOW
**Business Impact**: LOW

**Methods to Extract**:
- `addExtraPickupQuoteLine()` - Auto-add extra pickup
- `removeExtraPickupQuoteLine()` - Cleanup extra pickup

**Why This Matters**:
- Product-specific business logic
- Could be generalized for product add-ons
- Trigger helper is not the right place

**Proposed Service**: `ProductAddOnService` or enhance `ProductConfigurationService`

---

#### 6. **Schedule Calculation Service**
**Target**: Extract from QuoteLineTriggerHelper
**Lines**: ~100 lines
**Complexity**: MEDIUM
**Business Impact**: MEDIUM

**Methods to Extract**:
- `calculateScheduleField()` - Schedule string generation (lines 1123-1222)

**Why This Matters**:
- Complex string formatting logic
- Reusable across UI and integrations
- Should be testable independently

**Proposed Service**: `ScheduleFormattingService`

---

#### 7. **Genesys Integration Service**
**Target**: Extract from QuoteTriggerHelper
**Lines**: ~240 lines
**Complexity**: MEDIUM
**Business Impact**: MEDIUM

**Methods to Extract**:
- `isEligibleForGenesys()` - Eligibility checking
- `createGenesysForQuote()` - Genesys record creation
- `updateGenesysRequired()` - Genesys flag management
- `updateQuoteFlag()` - Quote flag updates

**Why This Matters**:
- External system integration should be service-based
- Enable better error handling and retry logic
- Testability for integration scenarios

**Proposed Service**: `GenesysIntegrationService`

---

### 🟢 LOW PRIORITY - Phase 7C

#### 8. **Favorites Management Service**
**Target**: Extract from QuoteFavoritesController
**Lines**: ~200 lines
**Complexity**: LOW
**Business Impact**: LOW

**Methods to Extract**:
- `getFavorites()` - Favorites retrieval
- `addQuoteFavorite()` - Create from favorite
- `createNonFavoriteLine()` - Create non-favorite line

**Why This Matters**:
- UI-specific logic in controller is acceptable
- Lower priority than core business logic
- Could wait for LWC migration

**Proposed Action**: Consider for future LWC migration

---

#### 9. **Quote Date Synchronization Service**
**Target**: Extract from QuoteLineTriggerHelper
**Lines**: ~80 lines
**Complexity**: LOW
**Business Impact**: LOW

**Methods to Extract**:
- `updateQuotedate()` - Quote date updates (lines 628-833)

**Why This Matters**:
- Date synchronization logic
- Could be part of validation service

**Proposed Service**: Enhance `QuoteLineValidationService` or create `QuoteDateService`

---

## Recommended Phase 7 Implementation Plan

### **Phase 7A: Critical Business Logic Extraction** (HIGH PRIORITY)

**Deliverables**:
1. ✅ **SLACalculationService**
   - Extract 560 lines from QuoteFavoritesController
   - Consolidate all SLA calculation logic
   - Support entitlement and industry standard calculations
   - Timezone-aware calculations
   - Comprehensive test coverage

2. ✅ **ChangeTrackingService**
   - Extract 220 lines from QuoteTriggerHelper
   - Asset vs quote line comparison
   - Type of change determination
   - Frequency delta calculations
   - Merge with AssetComparisonService (Phase 3C)

3. ✅ **MAS Consolidation**
   - Refactor QuoteLineTriggerHelper.updateMASDetailsToQuoteLines()
   - Use DataAggregationService.getUniqueMASDetails() (Phase 5)
   - Use MASIntegrationService.writeMASDetails() (Phase 4)
   - Eliminate 115 lines of duplicate logic

**Estimated Impact**:
- Lines Extracted/Consolidated: ~900 lines
- Services Created: 2 new + 1 consolidated
- Integration Points: 5+ existing services

---

### **Phase 7B: Integration & Product Logic** (MEDIUM PRIORITY)

**Deliverables**:
1. ✅ **GenesysIntegrationService**
   - Extract 240 lines from QuoteTriggerHelper
   - Centralize Genesys integration

2. ✅ **VCR Code Service Enhancement**
   - Extract VCR triggering logic
   - Better orchestration

3. ✅ **ProductAddOnService**
   - Extract extra pickup logic
   - Generalize for product add-ons

4. ✅ **ScheduleFormattingService**
   - Extract schedule calculation
   - Reusable formatting

**Estimated Impact**:
- Lines Extracted: ~500 lines
- Services Created/Enhanced: 4

---

### **Phase 7C: UI & Support Services** (LOW PRIORITY)

**Deliverables**:
1. Consider during LWC migration
2. Lower business impact
3. Can wait for natural refactoring opportunities

---

## Integration Map: How New Services Connect

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 7 SERVICE INTEGRATION                  │
└─────────────────────────────────────────────────────────────────┘

NEW SERVICES (Phase 7A):
┌──────────────────────────┐
│ SLACalculationService    │──┐
└──────────────────────────┘  │
         ↓ uses                │
┌──────────────────────────┐  │
│ HaulAwayService (P3B)    │  │
└──────────────────────────┘  │
                              │ used by
                              ↓
┌──────────────────────────┐  ┌──────────────────────────┐
│ QuoteWrapperService (P6) │←─│ QuoteTriggerHelper       │
└──────────────────────────┘  │ QuoteLineTriggerHelper   │
                              │ QuoteFavoritesController │
┌──────────────────────────┐  └──────────────────────────┘
│ ChangeTrackingService    │──┐
└──────────────────────────┘  │
         ↓ merges with         │
┌──────────────────────────┐  │
│ AssetComparisonService   │  │
│ (Phase 3C)               │  │
└──────────────────────────┘  │

MAS CONSOLIDATION:
┌──────────────────────────┐  │
│ MASIntegrationService    │←─┤
│ (Phase 4)                │  │
└──────────────────────────┘  │
         ↑ uses                │
┌──────────────────────────┐  │
│ DataAggregationService   │←─┤
│ (Phase 5)                │  │
└──────────────────────────┘  │
         ↑                     │
         └─────────────────────┘
         replaces duplicate logic in
         QuoteLineTriggerHelper.updateMASDetailsToQuoteLines()
```

---

## Code Duplication Analysis

### 🔴 **Critical Duplication Found**

**Location 1**: `QuoteLineTriggerHelper.updateMASDetailsToQuoteLines()` (lines 378-492)
**Location 2**: `DataAggregationService.getUniqueMASDetails()` (Phase 5)

**Duplicate Logic**:
1. ✅ Facility ID → MAS setup lookup
2. ✅ Business Unit fallback logic
3. ✅ Line of business determination (Commercial/Rolloff/Industrial)
4. ✅ New service case detection
5. ✅ MAS field propagation to quote lines

**Recommendation**: **IMMEDIATE CONSOLIDATION REQUIRED**
- QuoteLineTriggerHelper should call DataAggregationService
- Eliminate 115 lines of duplicate code
- Single source of truth for MAS lookups

---

## Benefits of Phase 7 Implementation

### **Technical Benefits**:
1. ✅ **Reduce Trigger Helper Complexity** - Remove 1,500+ lines from helpers
2. ✅ **Eliminate Code Duplication** - Consolidate MAS logic (115 lines saved)
3. ✅ **Improve Testability** - Service layer enables better unit testing
4. ✅ **Enable Reusability** - SLA calc, change tracking, MAS logic reused
5. ✅ **Better Separation of Concerns** - Business logic out of triggers

### **Business Benefits**:
1. ✅ **Consistent SLA Calculations** - Single source of truth
2. ✅ **Better Change Tracking** - Standardized asset comparison
3. ✅ **Improved MAS Integration** - Consolidated, tested logic
4. ✅ **Faster Development** - Reusable services reduce new code
5. ✅ **Reduced Defects** - Less duplication = fewer bugs

### **Maintainability Benefits**:
1. ✅ **Easier to Modify** - Change in one place
2. ✅ **Better Documentation** - Service methods are self-documenting
3. ✅ **Simpler Debugging** - Isolated service logic
4. ✅ **Cleaner Triggers** - Focus on orchestration, not business logic

---

## Migration Strategy

### **Approach**:
1. **Create Service** - Build new service with extracted logic
2. **Add Comprehensive Tests** - Test all scenarios
3. **Update Trigger Helper** - Replace with service call
4. **Keep Fallback** - Maintain old code temporarily with feature flag
5. **Monitor & Validate** - Run in parallel for one release
6. **Remove Old Code** - Clean up after validation

### **Feature Flag Pattern**:
```apex
// In QuoteTriggerHelper
@TestVisible
private static Boolean USE_SLA_SERVICE = true;

public static DateTime calculateSLA(Id quoteLineId) {
    if (USE_SLA_SERVICE) {
        try {
            return new SLACalculationService().determineSLA(quoteLineId);
        } catch (Exception ex) {
            System.debug('Error in SLACalculationService: ' + ex.getMessage());
            // Fallback to old implementation
        }
    }

    // Original implementation (fallback)
    // ... old code ...
}
```

---

## Estimated LOE

| Phase | Services | Lines Extracted | Complexity | Estimated Days |
|-------|----------|----------------|------------|---------------|
| **7A** | 3 (2 new + consolidation) | ~900 | HIGH | 8-10 days |
| **7B** | 4 | ~500 | MEDIUM | 5-7 days |
| **7C** | TBD | ~200 | LOW | 3-5 days |
| **Total** | 7+ | ~1,600+ | MIXED | **16-22 days** |

---

## Conclusion

The review of QuoteTriggerHelper, QuoteLineTriggerHelper, and QuoteFavoritesController reveals **significant opportunities** for service integration:

✅ **~1,600+ lines** can be extracted into services
✅ **7+ new/enhanced services** identified
✅ **115 lines of duplicate MAS logic** can be eliminated
✅ **Critical SLA calculation logic** (560 lines) should move to service tier
✅ **Asset comparison/change tracking** should be consolidated

**Recommendation**: **Proceed with Phase 7A implementation** focusing on SLACalculationService, ChangeTrackingService, and MAS consolidation. These provide the highest business value and technical improvement.

---

## Next Steps

1. ✅ **Review this document** with stakeholders
2. ✅ **Prioritize Phase 7A** for immediate implementation
3. ✅ **Create Phase 7A implementation plan**
4. ✅ **Begin with SLACalculationService** (highest impact)
5. ✅ **Follow with ChangeTrackingService** and MAS consolidation
6. ✅ **Plan Phase 7B** after 7A completion

---

**Document Created**: 2025-12-11
**Created By**: Quote Network Modernization Team
**Status**: Ready for Review
