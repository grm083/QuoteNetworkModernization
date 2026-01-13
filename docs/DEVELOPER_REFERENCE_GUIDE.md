# Quote Network Modernization - Developer Reference Guide

## Document Information
| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | January 2026 |
| **Project** | Quote Framework Service Layer Refactoring |
| **Audience** | Salesforce Developers, Technical Leads, Architects |

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Feature Flags](#2-feature-flags)
3. [Service Layer Reference](#3-service-layer-reference)
4. [Functional Area Code Mapping](#4-functional-area-code-mapping)
5. [Testing Reference](#5-testing-reference)
6. [Common Development Tasks](#6-common-development-tasks)
7. [Troubleshooting Guide](#7-troubleshooting-guide)

---

## 1. Architecture Overview

### 1.1 Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│                  (LWC / Aura / Visualforce)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CONTROLLER LAYER                               │
│  QuoteProcurementController.cls (~4,218 lines)                  │
│  QuoteFavoritesController.cls                                   │
│  • @AuraEnabled method wrappers                                 │
│  • Service delegation via feature flags                          │
│  • Request/Response transformation                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                                │
│              52 Specialized Service Classes                      │
├─────────────────────────────────────────────────────────────────┤
│  Core Services          │  Integration Services                 │
│  ─────────────────────  │  ──────────────────────────────────   │
│  QuoteLineValidation    │  VendorManagementService              │
│  DeliveryOrchestration  │  MASIntegrationService                │
│  QuoteLineOperations    │  AssetAvailabilityService             │
│  QuoteDataMapper        │  HaulAwayService                      │
│  SLAManagement          │  EntitlementMatchingService           │
│  SpecialHandling        │  AcornIntegrationService              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA ACCESS LAYER                             │
│              SOQL / DML / External APIs                          │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Key Files Location

| Component | Path |
|-----------|------|
| Main Controller | `force-app/main/default/classes/QuoteProcurementController.cls` |
| Favorites Controller | `force-app/main/default/classes/QuoteFavoritesController.cls` |
| Service Classes | `force-app/main/default/classes/*Service.cls` |
| Test Classes | `force-app/main/default/classes/*Test.cls` |
| Trigger Handlers | `force-app/main/default/classes/*Handler.cls` |

---

## 2. Feature Flags

### 2.1 Feature Flag Definitions

All feature flags are defined in `QuoteProcurementController.cls` (lines 17-57):

```apex
// Location: QuoteProcurementController.cls:17-57

// Phase 10.1-10.4 Services (Stable - No Fallback)
@TestVisible private static Boolean USE_VALIDATION_SERVICE = true;      // Line 18
@TestVisible private static Boolean USE_POSITION_SERVICE = true;        // Line 22
@TestVisible private static Boolean USE_PRODUCT_CONFIG_SERVICE = true;  // Line 25
@TestVisible private static Boolean USE_WORK_ORDER_SERVICE = true;      // Line 28
@TestVisible private static Boolean USE_DELIVERY_ORCHESTRATION_SERVICE = true; // Line 32
@TestVisible private static Boolean USE_VENDOR_SERVICE = true;          // Line 36
@TestVisible private static Boolean USE_MAS_SERVICE = true;             // Line 39
@TestVisible private static Boolean USE_AVAILABILITY_SERVICE = true;    // Line 42
@TestVisible private static Boolean USE_DATA_MAPPER_SERVICE = true;     // Line 46
@TestVisible private static Boolean USE_QUOTE_LINE_OPERATIONS_SERVICE = true; // Line 50

// Phase 10.5 Services (Safety Net - Fallback Retained)
@TestVisible private static Boolean USE_SLA_MANAGEMENT_SERVICE = true;  // Line 54
@TestVisible private static Boolean USE_SPECIAL_HANDLING_SERVICE = true; // Line 57
```

### 2.2 Service Instances

Service instances are defined in `QuoteProcurementController.cls` (lines 59-99):

```apex
// Location: QuoteProcurementController.cls:59-99

@TestVisible private static QuoteLineValidationService validationService = new QuoteLineValidationService();
@TestVisible private static PositionManagementService positionService = new PositionManagementService();
@TestVisible private static ProductConfigurationService productConfigService = new ProductConfigurationService();
@TestVisible private static WorkOrderService workOrderService = new WorkOrderService();
@TestVisible private static DeliveryOrchestrationService deliveryOrchestrationService = new DeliveryOrchestrationService();
@TestVisible private static VendorManagementService vendorService = new VendorManagementService();
@TestVisible private static MASIntegrationService masService = new MASIntegrationService();
@TestVisible private static AssetAvailabilityService availabilityService = new AssetAvailabilityService();
@TestVisible private static QuoteDataMapperService dataMapperService = new QuoteDataMapperService();
@TestVisible private static QuoteLineOperationsService quoteLineOperationsService = new QuoteLineOperationsService();
@TestVisible private static SLAManagementService slaManagementService = new SLAManagementService();
@TestVisible private static SpecialHandlingService specialHandlingService = new SpecialHandlingService();
```

### 2.3 Emergency Rollback

To disable a service in production, set the corresponding flag to `false`:

```apex
// Emergency disable example
private static Boolean USE_VALIDATION_SERVICE = false;  // Disables validation service
```

---

## 3. Service Layer Reference

### 3.1 QuoteLineValidationService

**File:** `force-app/main/default/classes/QuoteLineValidationService.cls`

**Purpose:** Multi-stage validation with strategy pattern. Consolidates 27+ duplicate vendor checks, 10+ MAS validation patterns.

| Method | Line | Description |
|--------|------|-------------|
| `validate(quoteLine, context)` | 25 | Main validation entry point |
| `validateByStage(quoteLine, stage)` | 68 | Validate by specific stage |
| `validateBatch(quoteLines)` | 78 | Batch validate multiple lines |
| `isValid(quoteLine, stage)` | 169 | Boolean convenience method |
| `getErrorMessage(quoteLine, stage)` | 181 | Get error message string |
| `validateStageF(qLine)` | 198 | Draft stage validation |
| `validateStageS(qLine)` | 224 | Product Configured validation |
| `validateStageT(qLine)` | 285 | Cost/Price Configured validation |
| `validateVendorStatus(qLine)` | 336 | Consolidated vendor status check |
| `validateMASFields(qLine)` | 362 | MAS fields validation |
| `validateVCRCode(qLine)` | 385 | VCR code validation |
| `validateVendorCommitDate(qLine)` | 402 | Vendor commit date logic |
| `validateCostModel(qLine)` | 419 | Cost model validation |
| `validatePricingMethod(qLine)` | 474 | Pricing method validation |
| `validatePriceFields(qLine)` | 489 | Price fields validation |
| `validateOccurrence(qLine)` | 531 | Occurrence type validation |
| `validateRemovalSwapoutSize(qLine)` | 554 | Removal/swapout size (SDT-32753) |

**Validation Stages (lines 107-150):**
- `DRAFT`: Basic scheduling and vendor status
- `PRODUCT_CONFIGURED`: Draft + Vendor/MAS requirements
- `COST_CONFIGURED`: Product Configured + Cost rules
- `PRICE_CONFIGURED`: Cost Configured + Price rules

**Validation Rules (lines 111-149):**
| Rule Class | Purpose |
|------------|---------|
| `ScheduleFrequencyRule` | Scheduled service requires frequency |
| `VendorActiveStatusRule` | Vendor must be active |
| `VendorRequiredRule` | Vendor assignment required |
| `MASLibraryRequiredRule` | WM vendors require MAS library |
| `VendorCommitDateRule` | Commit date before end date |
| `VCRCodeRequiredRule` | VCR code for WM vendors |
| `OccurrenceTypeRule` | One-time vs scheduled |
| `CostUOMRequiredRule` | Cost UOM required |
| `RemovalSwapoutSizeRule` | Size validation (SDT-32753) |
| `MASUniqueIdRequiredRule` | MAS unique ID |
| `PricingMethodRequiredRule` | Pricing method |
| `PriceUOMRequiredRule` | Price UOM |
| `ListPriceRequiredRule` | List price |
| `ManagementFeePriceRule` | WM management fee |
| `SteppedPriceRule` | Stepped pricing (SDT-41532) |

**Test File:** `QuoteLineValidationServiceTest.cls`

---

### 3.2 DeliveryOrchestrationService

**File:** `force-app/main/default/classes/DeliveryOrchestrationService.cls`

**Purpose:** Orchestrates complex 533-line delivery creation workflow. Coordinates Phase 3 services.

| Method | Line | Description |
|--------|------|-------------|
| `executeDeliveryCreation(ow, orderType, placementInstructions)` | 37 | Main orchestration workflow |
| `processQuoteLinesWithAssetComparison(collection, assetProductMap, ow, wrapper)` | 120 | Process with asset comparison |
| `processQuoteLinesForNewService(quoteLines, ow, wrapper)` | 217 | New service processing |
| `handleExtraPickupLines(quoteLinesForUpdate, pickupMap, extraPickupMap)` | 244 | Extra pickup handling (SDT-32782) |
| `handleHaulRemovalLines(parentQLId, serviceEndDate)` | 295 | Haul/removal processing |
| `createQuoteOrders(collection, ow, placementInstructions, caseRecordType)` | 312 | Quote order creation |
| `createRemovalOrders(ow, parentQL, placementInstructions)` | 376 | Removal order creation |
| `validateRemoval(parentQLine, endDate)` | 422 | Validate/create removal line |
| `validateHaul(parentQLine, endDate)` | 488 | Validate/create haul line |
| `assignParentQLineFields(parentQLine)` | 548 | Copy parent fields to child |
| `getQLine(qLineId, prdName)` | 592 | Query child quote line |
| `getParentQline(parentQLineId)` | 616 | Query parent quote line |
| `getProductId(productName, parentQuotelineProductId)` | 642 | Get product ID from options |
| `getProductOptionId(parentQLineProductId, childProductId)` | 662 | Get product option record |
| `getMaxQuoteLineNumber(quoteId)` | 684 | Get next line number |

**Service Dependencies (lines 11-16):**
```apex
private QuoteLineCollectorService collectorService;
private AssetComparisonService assetComparisonService;
private BaselineUpdateService baselineUpdateService;
private ServiceDateManager dateManager;
private QuoteOrderFactory orderFactory;
private CommercialProductHandler commercialProductHandler;
```

**Test File:** `DeliveryOrchestrationServiceTest.cls`

---

### 3.3 QuoteLineOperationsService

**File:** `force-app/main/default/classes/QuoteLineOperationsService.cls`

**Purpose:** CRUD operations for quote lines with product configuration.

| Method | Line | Description |
|--------|------|-------------|
| `createQuoteLines(quoteId, productId, wasteStream, equipmentSize)` | 22 | Create parent + child quote lines |
| `addQuoteAndQuoteLine(favoriteId, caseId, quoteID, quoteScreen)` | 219 | Convert favorite to quote lines |
| `getQuoteProducts(quoteId)` | 371 | Get quote header records |
| `getQuoteLineMASDetails(quoteLineId)` | 407 | Get MAS details for line |
| `getQuoteDetails(quoteLineId)` | 426 | Get child quote lines |
| `getMaterialOption(wasteStream)` | 469 | Get material product option |
| `getCategoryOption(materialParentSKU, productId)` | 487 | Get category product option |
| `getMaxQuoteLineNumber(quoteId)` | 505 | Get next available line number |

**Key Integration Points:**
- `SBQQConfigurationRuleService` - CPQ configuration rules (line 56)
- `QuoteLineServices` - Parent quote line creation (line 37)
- `HaulAwayService` - Haul Away vendor assignment (SDT-44574, lines 142-153)

**Test File:** `QuoteLineOperationsServiceTest.cls` (if exists) or included in `QuoteProcurementControllerTest.cls`

---

### 3.4 QuoteDataMapperService

**File:** `force-app/main/default/classes/QuoteDataMapperService.cls`

**Purpose:** Data transformation from SObjects to UI wrapper classes.

| Method | Line | Description |
|--------|------|-------------|
| `buildQuoteWrapper(quoteId)` | 23 | Simple wrapper for specific UI |
| `buildWrapper(quoteId)` | 56 | Full wrapper with cost, price, MAS |
| `mapToSimpleHeaderWrapper(header, parentQuote)` | 152 | Simple header mapping |
| `mapToHeaderWrapper(header, companyCategoriesMap)` | 206 | Full header mapping |
| `mapToMASWrapper(header)` | 310 | MAS data mapping |
| `mapToDetailWrapper(detail)` | 331 | Detail line mapping |
| `mapToWorkOrderWrappers(quoteOrders)` | 377 | Work order mapping |
| `queryQuoteForSimpleWrapper(quoteId)` | 394 | Query for simple wrapper |
| `queryQuoteLinesForSimpleWrapper(quoteId)` | 413 | Query lines for simple wrapper |
| `queryDetailsForMaterialType(headerRecordId)` | 430 | Query material type |
| `queryQuoteForCompanyCategories(quoteId)` | 443 | Query for company categories |

**Service Dependencies (line 11):**
```apex
private AssetAvailabilityService availabilityService;
```

**Test File:** `QuoteDataMapperServiceTest.cls`

---

### 3.5 VendorManagementService

**File:** `force-app/main/default/classes/VendorManagementService.cls`

**Purpose:** Vendor search, assignment, and validation. Consolidates 27+ duplicate vendor checks.

| Method | Line | Description |
|--------|------|-------------|
| `searchVendors(searchString)` | 17 | SOSL search for vendors (SDT-45005) |
| `filterParentVendors(vendorList)` | 50 | Filter parent vendors |
| `updateVendorDetails(parentId, vendorId, sCode)` | 91 | Update vendor on quote lines |
| `isVendorActive(vendorId)` | 127 | Check if vendor is active |
| `isWMVendor(vendorId)` | 151 | Check if WM vendor |
| `getVendorBusinessUnit(vendorId)` | 180 | Get vendor business unit |
| `getVendorFacilityCode(vendorId)` | 205 | Get facility code (SDT-29645) |
| `getVendorParentVendorId(vendorId)` | 229 | Get parent vendor ID |
| `getVendorDetails(vendorId)` | 253 | Get full vendor details |

**Test File:** `VendorManagementServiceTest.cls` (if exists) or `Phase4ServicesTest.cls`

---

### 3.6 SLAManagementService

**File:** `force-app/main/default/classes/SLAManagementService.cls`

**Purpose:** SLA override comments, validation, and date calculations.

| Method | Line | Description |
|--------|------|-------------|
| `addCommentForSLAOverrideFromIntake(caseId)` | 19 | Intake screen wrapper |
| `addCommentForSLAOverrideFromFlow(caseId, slaComment, slaReason)` | 29 | Flow integration for MIF |
| `addCommentForSLAOverride(caseId, slaComment, slaReason)` | 40 | Create SLA override comment (SDT-25005) |
| `validateSLAOverride(quoteLine)` | 139 | Validate SLA override fields |
| `calculateSLADate(quoteLineId)` | 158 | Calculate SLA date |
| `isBackdatedService(quoteLine)` | 172 | Detect backdated service |
| `determineSLAForAlternateProducts(parentQuoteLineId, equipmentSizes)` | 187 | SLA for alternate products (SDT-29961) |
| `determineSLA(parentQuoteLineId)` | 284 | Determine SLA datetime |
| `calculateEntitlementSLA(e, bh)` | 429 | Calculate from entitlement |
| `calculateEntitlementSLA_LocTimezone(e, bh, locTimeZone)` | 481 | With location timezone |
| `calculateISSLA(indStand, bh)` | 592 | Industry standard SLA |
| `calculateISSLA_LocTimezone(indStand, bh, parentQL, locTimeZone)` | 627 | Industry standard with timezone |
| `getSLASwitch()` | 746 | Get SLA logic switch |

**Inner Classes:**
- `currentDateTime` (lines 805-830) - Date/time utilities
- `ValidationResult` (lines 835-844) - Validation result wrapper

**Test File:** `SLAManagementServiceTest.cls` (if exists) or integrated tests

---

### 3.7 SpecialHandlingService

**File:** `force-app/main/default/classes/SpecialHandlingService.cls`

**Purpose:** Auto-detect special handling scenarios (SDT-30089).

| Method | Line | Description |
|--------|------|-------------|
| `updateSpecialHandling(quoteId)` | 20 | Update quote with special handling flags |
| `isBackdatedService(quoteLine)` | 79 | Check if SLA date before today |
| `hasSpecialHandlingScenarios(quoteLine)` | 89 | Check for special handling criteria |
| `isAutomaticSpecialHandling(quoteLine)` | 110 | Check if auto-flagged |
| `identifySpecialHandlingScenarios(quoteLine)` | 120 | Get scenario descriptions |
| `flagForSpecialHandling(quoteId, reason, details)` | 163 | Manually flag for special handling |
| `clearSpecialHandling(quoteId)` | 177 | Clear special handling flag |
| `validateSpecialHandling(quote)` | 192 | Validate special handling fields |

**Detection Criteria (lines 96-101):**
- `Certificate_of_Destruction__c` - Certificate required
- `Certificate_of_Disposal__c` - Certificate required
- `Gate_Code__c` - Gate code specified
- `Service_Start_Time__c` / `Service_End_Time__c` - Time window
- `Restriction_Details__c` - Restriction specified

**Test File:** `SpecialHandlingServiceTest.cls` (if exists) or integrated tests

---

### 3.8 FavoritesService

**File:** `force-app/main/default/classes/FavoritesService.cls`

**Purpose:** Favorites management and quote line conversion.

| Method | Line | Description |
|--------|------|-------------|
| `getFavorites(productId)` | 17 | Get favorites for product |
| `addQuoteFavorite(favoriteId, quoteId)` | 74 | Add favorite to quote |
| `createNonFavoriteLine(quoteId, productId, wasteStream, equipmentSize)` | 114 | Create non-favorite line |

**Inner Class:**
- `FavoriteWrapper` (lines 128-136) - Favorite product data wrapper

**Test File:** `FavoritesServiceTest.cls` (if exists) or `FavoritesManagementServiceTest.cls`

---

### 3.9 Additional Services

| Service | File | Key Methods |
|---------|------|-------------|
| **QuoteLineCollectorService** | `QuoteLineCollectorService.cls` | `collectQuoteLines()`, `getCaseRecordType()`, `getAssetProductMap()` |
| **AssetComparisonService** | `AssetComparisonService.cls` | `compareAssetWithQuoteLine()`, `validateProjectCodeMatch()` |
| **BaselineUpdateService** | `BaselineUpdateService.cls` | `applyBaselineUpdate()`, `getExtraPickupLineForStartDateUpdate()` |
| **ServiceDateManager** | `ServiceDateManager.cls` | `calculateEndDate()` |
| **QuoteOrderFactory** | `QuoteOrderFactory.cls` | `createDeliveryOrders()`, `createRemovalOrder()`, `upsertOrders()` |
| **CommercialProductHandler** | `CommercialProductHandler.cls` | `isCommercialProduct()`, `handleCommercialProductDelivery()` |
| **HaulAwayService** | `HaulAwayService.cls` | `getIsHaulAwayService()`, `getHaulAwayVendor()`, `getHaulAwayVendorByLocation()` |
| **AssetAvailabilityService** | `AssetAvailabilityService.cls` | `getAvailabilityBellIconMessage()`, `updateAAVOverrideFields()` |
| **MASIntegrationService** | `MASIntegrationService.cls` | MAS system integration methods |
| **EntitlementMatchingService** | `EntitlementMatchingService.cls` | `getRelatedEntitlement()` - 6-level priority logic |
| **ProductConfigurationService** | `ProductConfigurationService.cls` | `getAccessories()`, `getPadlockKeys()` |
| **PositionManagementService** | `PositionManagementService.cls` | Account position CRUD |
| **WorkOrderService** | `WorkOrderService.cls` | Work order creation interface |

---

## 4. Functional Area Code Mapping

### 4.1 Quote Creation & Management

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Create Quote | Click "New Quote" | `createQuote()` | - | QuoteProcurementController |
| Build Quote Wrapper | Load quote screen | `buildQuoteWrapper()` | QuoteDataMapperService | QuoteDataMapperService.cls:23 |
| Build Full Wrapper | Load procurement UI | `buildWrapper()` | QuoteDataMapperService | QuoteDataMapperService.cls:56 |

### 4.2 Quote Line Configuration

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Add Quote Line | Click "Add Product" | `createQuoteLines()` | QuoteLineOperationsService | QuoteLineOperationsService.cls:22 |
| Get Quote Products | View quote lines | `getQuoteProducts()` | QuoteLineOperationsService | QuoteLineOperationsService.cls:371 |
| Get Quote Details | Expand quote line | `getQuoteDetails()` | QuoteLineOperationsService | QuoteLineOperationsService.cls:426 |
| Add from Favorite | Select favorite | `addQuoteAndQuoteLine()` | QuoteLineOperationsService | QuoteLineOperationsService.cls:219 |

### 4.3 Vendor Selection & Management

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Search Vendors | Type in vendor search | `searchVendors()` | VendorManagementService | VendorManagementService.cls:17 |
| Assign Vendor | Select vendor | `updateVendorDetails()` | VendorManagementService | VendorManagementService.cls:91 |
| Validate Vendor | Save quote line | `isVendorActive()` | VendorManagementService | VendorManagementService.cls:127 |
| Check WM Vendor | Validate MAS | `isWMVendor()` | VendorManagementService | VendorManagementService.cls:151 |

### 4.4 Validation

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Draft Validation | Save draft | `vFStage()` → `validateStageF()` | QuoteLineValidationService | QuoteLineValidationService.cls:198 |
| Product Validation | Configure product | `vSStage()` → `validateStageS()` | QuoteLineValidationService | QuoteLineValidationService.cls:224 |
| Cost/Price Validation | Configure pricing | `vTStage()` → `validateStageT()` | QuoteLineValidationService | QuoteLineValidationService.cls:285 |
| Batch Validation | Submit quote | `validateBatch()` | QuoteLineValidationService | QuoteLineValidationService.cls:78 |
| Vendor Status | Any save | `validateVendorStatus()` | QuoteLineValidationService | QuoteLineValidationService.cls:336 |
| MAS Fields | WM vendor | `validateMASFields()` | QuoteLineValidationService | QuoteLineValidationService.cls:362 |

### 4.5 Delivery & Order Creation

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Create Delivery | Click "Create Delivery" | `createDelivery()` | DeliveryOrchestrationService | DeliveryOrchestrationService.cls:37 |
| Asset Comparison | Existing service | `processQuoteLinesWithAssetComparison()` | DeliveryOrchestrationService | DeliveryOrchestrationService.cls:120 |
| Create Quote Orders | Delivery workflow | `createQuoteOrders()` | DeliveryOrchestrationService | DeliveryOrchestrationService.cls:312 |
| Handle Haul/Removal | Haul/removal lines | `handleHaulRemovalLines()` | DeliveryOrchestrationService | DeliveryOrchestrationService.cls:295 |
| Validate Removal | TEMP duration | `validateRemoval()` | DeliveryOrchestrationService | DeliveryOrchestrationService.cls:422 |
| Validate Haul | Rolloff TEMP | `validateHaul()` | DeliveryOrchestrationService | DeliveryOrchestrationService.cls:488 |

### 4.6 SLA Management

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Calculate SLA | Add product | `determineSLA()` | SLAManagementService | SLAManagementService.cls:284 |
| SLA Override Comment | Override SLA | `addCommentForSLAOverride()` | SLAManagementService | SLAManagementService.cls:40 |
| Backdated Detection | Save quote | `isBackdatedService()` | SLAManagementService | SLAManagementService.cls:172 |
| Entitlement SLA | Has entitlement | `calculateEntitlementSLA()` | SLAManagementService | SLAManagementService.cls:429 |
| Industry Standard SLA | No entitlement | `calculateISSLA()` | SLAManagementService | SLAManagementService.cls:592 |

### 4.7 Special Handling

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Update Special Handling | Save quote | `updateSpecialHandling()` | SpecialHandlingService | SpecialHandlingService.cls:20 |
| Check Backdated | Validate SLA | `isBackdatedService()` | SpecialHandlingService | SpecialHandlingService.cls:79 |
| Check Scenarios | Save quote | `hasSpecialHandlingScenarios()` | SpecialHandlingService | SpecialHandlingService.cls:89 |
| Identify Scenarios | View details | `identifySpecialHandlingScenarios()` | SpecialHandlingService | SpecialHandlingService.cls:120 |
| Flag Quote | Manual flag | `flagForSpecialHandling()` | SpecialHandlingService | SpecialHandlingService.cls:163 |
| Clear Flag | Remove criteria | `clearSpecialHandling()` | SpecialHandlingService | SpecialHandlingService.cls:177 |

### 4.8 Favorites Management

| Function | UI Action | Controller Method | Service | File:Line |
|----------|-----------|-------------------|---------|-----------|
| Get Favorites | View favorites | `getFavorites()` | FavoritesService | FavoritesService.cls:17 |
| Add to Quote | Select favorite | `addQuoteFavorite()` | FavoritesService | FavoritesService.cls:74 |
| Create Non-Favorite | New product | `createNonFavoriteLine()` | FavoritesService | FavoritesService.cls:114 |

---

## 5. Testing Reference

### 5.1 Test Class Mapping

| Service | Test Class |
|---------|------------|
| QuoteLineValidationService | `QuoteLineValidationServiceTest.cls` |
| DeliveryOrchestrationService | `DeliveryOrchestrationServiceTest.cls` |
| QuoteDataMapperService | `QuoteDataMapperServiceTest.cls` |
| VendorManagementService | `Phase4ServicesTest.cls` |
| SLAManagementService | Integrated in `QuoteFavoritesControllerTest.cls` |
| SpecialHandlingService | Integrated tests |
| FavoritesService | `FavoritesManagementServiceTest.cls` |
| Phase 3 Services | `Phase3ServicesTest.cls`, `Phase3BServicesTest.cls`, `Phase3CServicesTest.cls` |
| Phase 4 Services | `Phase4ServicesTest.cls` |

### 5.2 Test Data Factory

**Primary Factory:** `QuoteTestDataFactory.cls` (if exists) or use existing test setup patterns.

```apex
// Common test data setup pattern
@TestSetup
static void setupTestData() {
    // Create account
    Account customerAccount = new Account(Name = 'Test Customer');
    insert customerAccount;

    // Create vendor
    Account vendorAccount = new Account(
        Name = 'Test Vendor',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(),
        Status__c = 'Active'
    );
    insert vendorAccount;

    // Create case
    Case testCase = new Case(
        AccountId = customerAccount.Id,
        Subject = 'Test Case'
    );
    insert testCase;

    // Create quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
        SBQQ__Account__c = customerAccount.Id
    );
    insert testQuote;
}
```

### 5.3 Feature Flag Testing

To test with feature flags disabled:

```apex
@isTest
static void testWithFeatureFlagDisabled() {
    // Disable feature flag for testing
    QuoteProcurementController.USE_VALIDATION_SERVICE = false;

    // Test fallback behavior
    // ...

    // Re-enable
    QuoteProcurementController.USE_VALIDATION_SERVICE = true;
}
```

---

## 6. Common Development Tasks

### 6.1 Adding a New Validation Rule

1. Create a new rule class implementing `IValidationRule`:

```apex
// File: NewValidationRule.cls
public class NewValidationRule implements IValidationRule {
    public Boolean appliesTo(ValidationContext context) {
        return context.getCurrentStage() == ValidationContext.Stage.PRICE_CONFIGURED;
    }

    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        if (/* validation condition */) {
            return ValidationResult.createError('Error message');
        }
        return null;
    }

    public String getRuleName() {
        return 'NewValidationRule';
    }
}
```

2. Register the rule in `QuoteLineValidationService.initializeValidationRules()`:

```apex
// QuoteLineValidationService.cls, around line 141
priceConfiguredRules.add(new NewValidationRule());
```

### 6.2 Adding a New Service

1. Create the service class:

```apex
// File: NewFeatureService.cls
public class NewFeatureService {
    public void doSomething() {
        // Implementation
    }
}
```

2. Add feature flag in `QuoteProcurementController.cls`:

```apex
@TestVisible
private static Boolean USE_NEW_FEATURE_SERVICE = true;

@TestVisible
private static NewFeatureService newFeatureService = new NewFeatureService();
```

3. Use delegation pattern in controller:

```apex
@AuraEnabled
public static void someMethod() {
    if (USE_NEW_FEATURE_SERVICE) {
        newFeatureService.doSomething();
        return;
    }
    // Fallback implementation
}
```

### 6.3 Modifying Delivery Workflow

The delivery workflow is in `DeliveryOrchestrationService.executeDeliveryCreation()` (line 37):

1. **Step 1:** Collect quote lines via `QuoteLineCollectorService`
2. **Step 2:** Get case record type
3. **Step 3:** Process based on case type (new vs existing service)
4. **Step 4:** Update quote lines
5. **Step 5:** Handle haul/removal lines
6. **Step 6:** Create quote orders

To add a new step, insert logic in the appropriate location within `executeDeliveryCreation()`.

---

## 7. Troubleshooting Guide

### 7.1 Common Issues

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| Validation not running | Feature flag disabled | Check `USE_VALIDATION_SERVICE` |
| Vendor search returns no results | Parent vendor filtering | Check `filterParentVendors()` logic |
| SLA date incorrect | Timezone handling | Check `calculateISSLA_LocTimezone()` |
| Special handling not flagging | Detection criteria | Review `hasSpecialHandlingScenarios()` |
| Delivery creation fails | Missing dependencies | Check `QuoteLineCollectorService` query |

### 7.2 Debug Logging

All services include debug logging. To enable detailed logging:

```apex
System.debug(LoggingLevel.DEBUG, 'Detailed message');
System.debug(LoggingLevel.ERROR, 'Error message');
```

Key debug points:
- `QuoteLineValidationService.validate()` - Validation flow
- `DeliveryOrchestrationService.executeDeliveryCreation()` - Delivery workflow
- `VendorManagementService.searchVendors()` - Vendor search
- `SLAManagementService.determineSLA()` - SLA calculation

### 7.3 Error Handling

Services use `UTIL_LoggingService` for error logging:

```apex
// Example from SLAManagementService.cls:122
UTIL_LoggingService.logHandledExceptionWithClass(
    ex,
    UserInfo.getOrganizationId(),
    UTIL_ErrorConstants.CONFIRM_CONFIGURATION_ACTION,
    System.LoggingLevel.ERROR,
    'SLAManagementService',
    'addCommentForSLAOverride',
    null
);
```

### 7.4 Rollback Procedures

**Emergency Disable Single Service:**
```apex
// QuoteProcurementController.cls
private static Boolean USE_VALIDATION_SERVICE = false;
```

**Emergency Disable All Services:**
```apex
// Set all feature flags to false
private static Boolean USE_VALIDATION_SERVICE = false;
private static Boolean USE_DELIVERY_ORCHESTRATION_SERVICE = false;
// ... etc
```

---

## Appendix A: File Index

| File | Purpose | Lines |
|------|---------|-------|
| `QuoteProcurementController.cls` | Main controller | ~4,218 |
| `QuoteLineValidationService.cls` | Validation logic | ~580 |
| `DeliveryOrchestrationService.cls` | Delivery workflow | ~700 |
| `QuoteLineOperationsService.cls` | Quote line CRUD | ~520 |
| `QuoteDataMapperService.cls` | Data transformation | ~450 |
| `VendorManagementService.cls` | Vendor operations | ~275 |
| `SLAManagementService.cls` | SLA management | ~845 |
| `SpecialHandlingService.cls` | Special handling | ~220 |
| `FavoritesService.cls` | Favorites management | ~140 |
| `AssetAvailabilityService.cls` | Asset availability | ~150 |
| `HaulAwayService.cls` | Haul away integration | Variable |
| `MASIntegrationService.cls` | MAS integration | ~335 |

---

## Appendix B: SDT Story Reference

| SDT Story | Feature | Service | Method |
|-----------|---------|---------|--------|
| SDT-45005 | Filter parent vendors | VendorManagementService | `filterParentVendors()` |
| SDT-29645 | Vendor facility codes | VendorManagementService | `getVendorFacilityCode()` |
| SDT-32753 | Removal/swapout size | QuoteLineValidationService | `validateRemovalSwapoutSize()` |
| SDT-41532 | Stepped pricing | QuoteLineValidationService | `SteppedPriceRule` |
| SDT-30089 | Special handling auto-detect | SpecialHandlingService | `updateSpecialHandling()` |
| SDT-31144 | Special handling details | SpecialHandlingService | `flagForSpecialHandling()` |
| SDT-25005 | SLA override comments | SLAManagementService | `addCommentForSLAOverride()` |
| SDT-48501 | Comment record creation | SLAManagementService | `addCommentForSLAOverride()` |
| SDT-44574 | Haul Away integration | HaulAwayService | `getHaulAwayVendor()` |
| SDT-32782 | Extra pickup handling | DeliveryOrchestrationService | `handleExtraPickupLines()` |
| SDT-41184 | Recursive trigger prevention | DeliveryOrchestrationService | `RecurrsiveTriggerHandler` |
| SDT-30092 | Commercial product delivery | CommercialProductHandler | `handleCommercialProductDelivery()` |
| SDT-29961 | SLA for alternate products | SLAManagementService | `determineSLAForAlternateProducts()` |
| SDT-39637 | Location timezone SLA | SLAManagementService | `calculateISSLA_LocTimezone()` |
| SDT-45007 | Entitlement timezone | SLAManagementService | `calculateEntitlementSLA_LocTimezone()` |

---

## Appendix C: Contact & Support

For questions about this codebase:
1. Review this documentation first
2. Check test classes for usage examples
3. Review inline code comments
4. Consult the Architecture Decision Records (if available)
