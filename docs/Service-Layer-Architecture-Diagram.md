# Service Layer Architecture Diagram
**Quote Network Modernization Project**

---

## Current Architecture (Monolithic)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Lightning Web Components                      │
│              (QuoteProcurement, QuoteOrders, etc.)              │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 │ @AuraEnabled calls
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│          QuoteProcurementController (5,511 lines)                │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ • 90+ public methods                                     │   │
│  │ • Data retrieval, transformation, validation             │   │
│  │ • Vendor management, MAS integration                     │   │
│  │ • Product configuration, Work orders                     │   │
│  │ • Position management, Financial operations              │   │
│  │ • SLA management, Asset availability                     │   │
│  │ • Quote lifecycle, Approval workflows                    │   │
│  │ • Direct SOQL/DML operations                            │   │
│  │ • Tightly coupled external integrations                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────┬───────────────────────────────────┬───────────────┘
              │                                   │
              │ Direct calls                      │ Direct calls
              ▼                                   ▼
┌──────────────────────────┐      ┌──────────────────────────────┐
│  External Integrations   │      │      Helper Classes          │
│  • AAV API              │      │  • QuoteLineServices         │
│  • Acorn System         │      │  • QuoteFavoritesController  │
│  • MAS                  │      │  • AssetQuoteProcurement...  │
│  • STP Pricing          │      │  • ProductServices           │
└──────────────────────────┘      └──────────────────────────────┘

❌ Problems:
   • Single Responsibility Violation: One class, 12+ responsibilities
   • High coupling: Direct dependencies on concrete implementations
   • Poor testability: Cannot mock integrations
   • Low reusability: Logic tied to Lightning component context
   • Hard to maintain: Changes affect entire class
```

---

## Proposed Architecture (Service Layer)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Lightning Web Components                      │
│          (QuoteProcurement, QuoteOrders, ConfigProducts)        │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 │ @AuraEnabled calls
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│         QuoteProcurementController (<500 lines)                  │
│                  Thin Orchestration Layer                        │
│                                                                  │
│  • Delegates to services                                        │
│  • Handles @AuraEnabled requirements                            │
│  • Minimal business logic                                       │
│  • Exception translation                                        │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 │ Service calls
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SERVICE LAYER                             │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │ QuoteLineDataService   │  │ VendorManagementService    │    │
│  │                        │  │                            │    │
│  │ • buildWrapper()       │  │ • searchVendors()          │    │
│  │ • transformToDTO()     │  │ • assignVendor()           │    │
│  │ • getQuoteLines()      │  │ • validateVendor()         │    │
│  └────────────────────────┘  └────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │QuoteLineValidation     │  │ MASIntegrationService      │    │
│  │Service                 │  │                            │    │
│  │                        │  │ • getMASDetails()          │    │
│  │ • validate()           │  │ • updateMASDetails()       │    │
│  │ • validateDraftStage() │  │ • bypassPriceReview()      │    │
│  │ • validateCostStage()  │  │ • validateMASReqs()        │    │
│  │ • validatePriceStage() │  │                            │    │
│  └────────────────────────┘  └────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │ WorkOrderService       │  │ ProductConfiguration       │    │
│  │                        │  │ Service                    │    │
│  │ • createDelivery()     │  │                            │    │
│  │ • createRemoval()      │  │ • getAccessories()         │    │
│  │ • createHaul()         │  │ • addProductOption()       │    │
│  │ • validateDelivery()   │  │ • updateConfigAttr()       │    │
│  └────────────────────────┘  └────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │ PositionManagement     │  │ QuoteLineFactory           │    │
│  │ Service                │  │ Service                    │    │
│  │                        │  │                            │    │
│  │ • getPositions()       │  │ • createQuoteLineBundle()  │    │
│  │ • createPosition()     │  │ • createFromFavorite()     │    │
│  │ • assignPosition()     │  │ • createDeliveryLine()     │    │
│  └────────────────────────┘  └────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │ AssetAvailability      │  │ PricingService             │    │
│  │ Service                │  │                            │    │
│  │                        │  │ • updateFinancials()       │    │
│  │ • getAvailability()    │  │ • validateNTE()            │    │
│  │ • getAvailMessage()    │  │ • updateCost()             │    │
│  │ • hasPermission()      │  │ • updatePrice()            │    │
│  └────────────────────────┘  └────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │ CompanyCategoryService │  │ QuoteManagementService     │    │
│  │                        │  │                            │    │
│  │ • getCategories()      │  │ • updateStatus()           │    │
│  │ • updateCategory()     │  │ • updateQuoteOnly()        │    │
│  └────────────────────────┘  │ • approveQuoteLine()       │    │
│                               └────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Uses
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      INTEGRATION LAYER                           │
│                                                                  │
│  ┌────────────────────┐  ┌────────────────────┐                │
│  │ AAVIntegration     │  │ AcornIntegration   │                │
│  │ (Wrapper)          │  │ (Wrapper)          │                │
│  └────────────────────┘  └────────────────────┘                │
│                                                                  │
│  ┌────────────────────┐  ┌────────────────────┐                │
│  │ MASIntegration     │  │ STPPricing         │                │
│  │ (Wrapper)          │  │ Integration        │                │
│  └────────────────────┘  └────────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DATA ACCESS LAYER                            │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ QuoteLineSelector│  │ VendorSelector   │  │ AssetSelector│  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ QuoteSelector    │  │ PositionSelector │  │ MASSelector  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘

✅ Benefits:
   ✓ Single Responsibility: Each service has one clear purpose
   ✓ Low coupling: Services depend on interfaces
   ✓ High testability: All layers can be mocked
   ✓ High reusability: Services usable in any context
   ✓ Easy to maintain: Changes isolated to single service
   ✓ Clear dependencies: Architecture is explicit
```

---

## Service Communication Patterns

### Pattern 1: Controller → Service (Simple)
```
Controller                  Service
    │                          │
    │  1. Call method          │
    ├─────────────────────────>│
    │                          │
    │                     2. Execute logic
    │                          │
    │  3. Return result        │
    │<─────────────────────────┤
    │                          │
```

### Pattern 2: Service → Service (Composition)
```
QuoteLineValidation         VendorManagement         MASIntegration
Service                     Service                  Service
    │                          │                          │
    │  1. validate()           │                          │
    │                          │                          │
    │  2. validateVendor()     │                          │
    ├─────────────────────────>│                          │
    │                          │  3. getMASDetails()      │
    │                          ├─────────────────────────>│
    │                          │                          │
    │                          │  4. Return MAS data      │
    │                          │<─────────────────────────┤
    │  5. Return vendor valid  │                          │
    │<─────────────────────────┤                          │
    │                          │                          │
    │  6. Return validation    │                          │
    │     result               │                          │
```

### Pattern 3: Service → Selector (Data Access)
```
Service                     Selector                Database
    │                          │                        │
    │  1. getQuoteLines()      │                        │
    ├─────────────────────────>│                        │
    │                          │  2. SOQL Query         │
    │                          ├───────────────────────>│
    │                          │                        │
    │                          │  3. Return records     │
    │                          │<───────────────────────┤
    │  4. Return DTOs          │                        │
    │<─────────────────────────┤                        │
    │                          │                        │
```

---

## Dependency Injection Example

### Without DI (Current State - Tightly Coupled)
```apex
public class QuoteProcurementController {
    @AuraEnabled
    public static Boolean updateVendor(Id quoteLineId, Id vendorId) {
        // Tightly coupled to concrete implementation
        List<SBQQ__QuoteLine__c> lines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Id = :quoteLineId];
        lines[0].Vendor__c = vendorId;
        update lines;
        return true;
    }
}

// ❌ Cannot test without database
// ❌ Cannot substitute different implementation
// ❌ Hard to mock
```

### With DI (Proposed State - Loosely Coupled)
```apex
public class VendorManagementService {
    @TestVisible
    private IQuoteLineSelector quoteLineSelector;

    public VendorManagementService() {
        this(new QuoteLineSelector());
    }

    @TestVisible
    private VendorManagementService(IQuoteLineSelector selector) {
        this.quoteLineSelector = selector;
    }

    public Boolean assignVendorToQuoteLine(Id quoteLineId, Id vendorId) {
        List<SBQQ__QuoteLine__c> lines = quoteLineSelector.getQuoteLinesById(new Set<Id>{quoteLineId});
        lines[0].Vendor__c = vendorId;
        update lines;
        return true;
    }
}

// ✅ Can inject mock selector for testing
// ✅ Can substitute different implementations
// ✅ Testable without database
```

---

## Example: Validation Service Architecture

```
                    ┌──────────────────────────┐
                    │  QuoteLineValidation     │
                    │  Service                 │
                    │                          │
                    │  + validate()            │
                    └─────────┬────────────────┘
                              │
                              │ delegates to
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌────────────────┐   ┌────────────────┐
│ DraftStage    │   │ CostStage      │   │ PriceStage     │
│ Validator     │   │ Validator      │   │ Validator      │
│               │   │                │   │                │
│ + validate()  │   │ + validate()   │   │ + validate()   │
└───────────────┘   └────────────────┘   └────────────────┘

Each validator contains specific validation rules:

DraftStage:
• Schedule frequency validation
• Service days validation
• Vendor active status

CostStage (includes DraftStage):
• All DraftStage validations
• Vendor required
• MAS library/company required (WM)
• Setup comment required (WM)
• Cost UOM required
• Cost model type validation
• Rebate/Stepped cost rules

PriceStage (includes CostStage):
• All CostStage validations
• MAS unique ID required
• VCR code required
• Pricing method required
• Price UOM required
• List price validation
• Stepped price rules

Strategy Pattern:
┌────────────────────────────────┐
│  IValidationRule (interface)   │
│  + validate()                  │
└────────────────┬───────────────┘
                 │
                 │ implemented by
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│Vendor   │ │Schedule │ │MAS      │
│Rule     │ │Rule     │ │Rule     │
└─────────┘ └─────────┘ └─────────┘
```

---

## Data Flow: Create Quote Line Bundle

### Current State (Monolithic)
```
LWC Component
    │
    │ 1. createQuoteLines(quoteId, productId, wasteStream, size)
    ▼
QuoteProcurementController
    │
    │ 2. SOQL: Get Quote
    │ 3. SOQL: Get Product
    │ 4. SOQL: Get Product Options
    │ 5. Create parent quote line
    │ 6. Create child quote lines
    │ 7. Create waste stream lines
    │ 8. Create category lines
    │ 9. Call CPQ rules
    │ 10. Insert all lines
    │ 11. Call SLA determination
    │ 12. Update lines with SLA
    │ 13. Return success
    ▼
LWC Component

❌ All logic in one method (200+ lines)
❌ Cannot reuse in other contexts
❌ Hard to test
❌ Mixed concerns
```

### Proposed State (Service Layer)
```
LWC Component
    │
    │ 1. createQuoteLines(quoteId, productId, wasteStream, size)
    ▼
QuoteProcurementController
    │
    │ 2. Delegate to factory
    ▼
QuoteLineFactoryService
    │
    │ 3. Get quote data (via QuoteLineDataService)
    │ 4. Build request object
    │ 5. Call createQuoteLineBundle()
    ▼
    │
    │ 6. Create parent line
    │ 7. Get product options (via ProductConfigurationService)
    │ 8. Create child lines
    │ 9. Validate bundle (via QuoteLineValidationService)
    │ 10. Execute product rules (via ProductRulesService)
    │ 11. Save bundle
    │ 12. Calculate SLA (via SLAService)
    │ 13. Return bundle result
    ▼
QuoteProcurementController
    │
    │ 14. Return to LWC
    ▼
LWC Component

✅ Each service has single responsibility
✅ Reusable in batch, trigger, API
✅ Fully testable with mocks
✅ Clear separation of concerns
```

---

## Testing Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Test Pyramid                              │
│                                                              │
│                       ┌─────────┐                            │
│                       │   E2E   │                            │
│                       │  Tests  │ (Few)                      │
│                       └────┬────┘                            │
│                            │                                 │
│                  ┌─────────┴─────────┐                       │
│                  │  Integration      │                       │
│                  │  Tests            │ (Some)                │
│                  └────────┬──────────┘                       │
│                           │                                  │
│              ┌────────────┴────────────┐                     │
│              │    Unit Tests            │                    │
│              │    (Service Layer)       │ (Many)             │
│              └──────────────────────────┘                    │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Unit Tests (95% of tests):
• Test each service in isolation
• Mock all dependencies
• Fast execution (<1 second per test)
• No database access
• No callouts

Integration Tests (4% of tests):
• Test service interactions
• Limited mocking
• Use test data factory
• Verify end-to-end flows

E2E Tests (1% of tests):
• Test through controller
• Real database (test context)
• Verify Lightning component integration
• Full scenario testing
```

---

## Deployment Strategy

### Phase 1: Foundation (Week 1-2)
```
┌─────────────────────────┐
│ Existing Controller     │ (No changes yet)
└─────────────────────────┘

┌─────────────────────────┐
│ NEW: Service Base       │ (Deploy infrastructure)
│ • IService interface    │
│ • ServiceException      │
│ • ValidationResult      │
│ • Request/Response DTOs │
└─────────────────────────┘

┌─────────────────────────┐
│ NEW: Validation Service │ (First service deployed)
│ + Tests (95% coverage)  │
└─────────────────────────┘

Risk: LOW - No changes to existing functionality
```

### Phase 2: Integration (Week 3-4)
```
┌─────────────────────────┐
│ Controller              │ (Start delegating to services)
│ • Original methods      │
│   maintained as facade  │
│ • New service calls     │
│   behind feature flag   │
└─────────────────────────┘

┌─────────────────────────┐
│ NEW Services:           │
│ • Vendor Management     │
│ • MAS Integration       │
│ • Asset Availability    │
│ + Tests                 │
└─────────────────────────┘

Risk: MEDIUM - Gradual service adoption with rollback capability
```

### Phase 3: Full Migration (Week 5-10)
```
┌─────────────────────────┐
│ Controller (<500 lines) │ (Thin orchestration layer)
│ • All logic in services │
│ • Original methods      │
│   removed               │
└─────────────────────────┘

┌─────────────────────────┐
│ Complete Service Layer: │
│ • 12 service classes    │
│ • All tests             │
│ • Documentation         │
└─────────────────────────┘

Risk: LOW - Incremental migration reduces risk
```

---

**Document Version:** 1.0
**Date:** 2025-12-09
**Author:** Quote Network Modernization Team
