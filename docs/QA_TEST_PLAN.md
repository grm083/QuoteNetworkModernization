# Quote Network Modernization - QA Test Plan

## Document Information
| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | January 2026 |
| **Project** | Quote Framework Service Layer Refactoring |
| **Scope** | Regression Testing for 52 Extracted Services |

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Test Strategy](#2-test-strategy)
3. [Test Environment Requirements](#3-test-environment-requirements)
4. [Service-Level Test Cases](#4-service-level-test-cases)
5. [Integration Test Scenarios](#5-integration-test-scenarios)
6. [Feature Flag Testing](#6-feature-flag-testing)
7. [Performance Testing](#7-performance-testing)
8. [Regression Test Suite](#8-regression-test-suite)
9. [Risk-Based Testing Priority](#9-risk-based-testing-priority)
10. [Test Data Requirements](#10-test-data-requirements)

---

## 1. Executive Summary

### 1.1 Purpose
This QA Test Plan provides comprehensive testing coverage for the Quote Network Modernization project, which refactored the monolithic `QuoteProcurementController` (5,753 lines) into 52+ specialized service classes following SOLID principles.

### 1.2 Scope of Changes
| Metric | Value |
|--------|-------|
| Original Controller Size | 5,753 lines |
| New Controller Size | 4,218 lines |
| Services Created | 52 classes |
| Total New Code | ~15,793 lines |
| Feature Flags | 12 |
| Test Classes | 324 |

### 1.3 Critical Services Under Test
| Service | Risk Level | Priority |
|---------|------------|----------|
| QuoteLineValidationService | HIGH | P0 |
| DeliveryOrchestrationService | HIGH | P0 |
| QuoteLineOperationsService | HIGH | P0 |
| QuoteDataMapperService | MEDIUM | P1 |
| VendorManagementService | MEDIUM | P1 |
| SLAManagementService | MEDIUM | P1 |
| SpecialHandlingService | MEDIUM | P1 |
| ProductConfigurationService | MEDIUM | P2 |
| AssetAvailabilityService | LOW | P2 |
| FavoritesService | LOW | P2 |

---

## 2. Test Strategy

### 2.1 Test Pyramid Approach
```
        ┌─────────────────┐
        │     E2E Tests   │  5% - Full user journeys
        │   (Manual/Auto) │
        └────────┬────────┘
                 │
           ┌─────┴─────┐
           │Integration│  15% - Service interactions
           │   Tests   │
           └─────┬─────┘
                 │
        ┌────────┴────────┐
        │   Unit Tests    │  80% - Individual methods
        │  (Apex Tests)   │
        └─────────────────┘
```

### 2.2 Test Types

| Test Type | Coverage Target | Automation |
|-----------|-----------------|------------|
| Unit Tests | 95%+ per service | Apex Test Classes |
| Integration Tests | Key workflows | Apex Test Classes |
| API Tests | All @AuraEnabled methods | Apex + Postman |
| Regression Tests | All critical paths | Automated Suite |
| Performance Tests | Response times < 3s | Apex Limits Tests |
| Smoke Tests | Core functionality | Daily Automated |

### 2.3 Entry/Exit Criteria

**Entry Criteria:**
- All feature flags deployed to test environment
- Test data created per specifications
- All service classes deployed successfully
- No blocking deployment errors

**Exit Criteria:**
- 95%+ code coverage achieved
- All P0/P1 test cases passed
- No critical/high severity defects open
- Performance benchmarks met
- Feature flag toggle tests passed

---

## 3. Test Environment Requirements

### 3.1 Salesforce Org Configuration
| Component | Requirement |
|-----------|-------------|
| Org Type | Full Sandbox / Partial Copy |
| Apex Test Coverage | 95%+ target |
| Custom Objects | Quote, Quote Line, Case, Work Order, Asset, Account |
| Custom Metadata | Comment_Log_Detail__mdt, SLA configuration |
| Custom Settings | Feature flag overrides |
| Integration Users | MAS, Acorn, Genesys test users |

### 3.2 Required Test Data
| Object | Minimum Records | Key Variations |
|--------|-----------------|----------------|
| Accounts | 50+ | Customer, Vendor, Active, Inactive |
| Cases | 100+ | New Service, Existing Service, Commercial |
| Quotes | 200+ | Draft, Product Configured, Cost Configured, Price Configured |
| Quote Lines | 500+ | Parent, Child, Haul, Removal, Delivery |
| Assets | 100+ | Various equipment sizes, waste streams |
| Products | 50+ | Container, Compactor, Roll-Off, Haul Away |
| Entitlements | 20+ | Various SLA levels |

### 3.3 Feature Flag Configuration for Testing
```apex
// Test environment should have all flags enabled
USE_DATA_MAPPER_SERVICE = true;
USE_VALIDATION_SERVICE = true;
USE_DELIVERY_ORCHESTRATION_SERVICE = true;
USE_QUOTE_LINE_OPERATIONS_SERVICE = true;
USE_SLA_MANAGEMENT_SERVICE = true;
USE_SPECIAL_HANDLING_SERVICE = true;
USE_VENDOR_SERVICE = true;
USE_MAS_SERVICE = true;
USE_AVAILABILITY_SERVICE = true;
USE_PRODUCT_CONFIG_SERVICE = true;
USE_POSITION_SERVICE = true;
USE_WORK_ORDER_SERVICE = true;
```

---

## 4. Service-Level Test Cases

### 4.1 QuoteLineValidationService Tests

#### 4.1.1 Schedule Frequency Validation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VAL-001 | Validate scheduled service with missing frequency | Validation error returned | P0 |
| VAL-002 | Validate weekly service with missing service days | Validation error returned | P0 |
| VAL-003 | Validate one-time service (no frequency required) | Validation passes | P0 |
| VAL-004 | Validate scheduled service with all required fields | Validation passes | P0 |
| VAL-005 | Validate monthly frequency with day of month | Validation passes | P1 |
| VAL-006 | Validate bi-weekly with alternating weeks | Validation passes | P1 |

#### 4.1.2 Vendor Validation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VAL-010 | Validate quote line with no vendor assigned | Validation error | P0 |
| VAL-011 | Validate quote line with inactive vendor | Validation error | P0 |
| VAL-012 | Validate quote line with active vendor | Validation passes | P0 |
| VAL-013 | Validate parent vendor (should filter) | Validation error (SDT-45005) | P1 |
| VAL-014 | Validate WM vendor without MAS library | Validation error | P0 |
| VAL-015 | Validate WM vendor with MAS library | Validation passes | P0 |

#### 4.1.3 Cost/Price Validation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VAL-020 | Cost UOM missing at COST_CONFIGURED stage | Validation error | P0 |
| VAL-021 | Price UOM missing at PRICE_CONFIGURED stage | Validation error | P0 |
| VAL-022 | List price missing at PRICE_CONFIGURED stage | Validation error | P0 |
| VAL-023 | WM management fee pricing validation | Validation per business rules | P1 |
| VAL-024 | Stepped pricing configuration | Validation per business rules | P1 |
| VAL-025 | Pricing method missing | Validation error | P0 |

#### 4.1.4 Stage-Based Validation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VAL-030 | DRAFT stage validation (basic checks only) | Only schedule/vendor validated | P0 |
| VAL-031 | PRODUCT_CONFIGURED stage validation | DRAFT + MAS requirements | P0 |
| VAL-032 | COST_CONFIGURED stage validation | All previous + cost rules | P0 |
| VAL-033 | PRICE_CONFIGURED stage validation | All rules validated | P0 |
| VAL-034 | Batch validation with 50+ quote lines | All lines validated | P1 |
| VAL-035 | Validation result combination | Errors aggregated correctly | P1 |

#### 4.1.5 MAS Validation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VAL-040 | MAS unique ID missing | Validation error | P0 |
| VAL-041 | MAS library required for WM vendor | Validation error if missing | P0 |
| VAL-042 | MAS company code validation | Validation per business rules | P1 |
| VAL-043 | Non-WM vendor (MAS not required) | Validation passes | P1 |

#### 4.1.6 Special Validations
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VAL-050 | VCR code required validation | Validation error if missing | P1 |
| VAL-051 | Vendor commit date logic | Validation per business rules | P1 |
| VAL-052 | Removal/swap-out size validation | Equipment sizes match | P1 |
| VAL-053 | Occurrence type validation | One-time vs scheduled | P1 |

---

### 4.2 DeliveryOrchestrationService Tests

#### 4.2.1 Delivery Creation Workflow
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| DEL-001 | Execute delivery creation for new service | Quote orders created | P0 |
| DEL-002 | Execute delivery creation for existing service | Asset comparison performed | P0 |
| DEL-003 | Execute delivery creation with haul lines | Haul quote lines processed | P0 |
| DEL-004 | Execute delivery creation with removal lines | Removal quote lines processed | P0 |
| DEL-005 | Execute delivery with commercial product | Commercial handler invoked | P1 |
| DEL-006 | Verify recursive trigger prevention (SDT-41184) | No duplicate processing | P0 |

#### 4.2.2 Asset Comparison
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| DEL-010 | Compare asset to quote line - no changes | No updates triggered | P1 |
| DEL-011 | Compare asset to quote line - field changes | Changes detected and logged | P1 |
| DEL-012 | Compare asset with field set mapping | All fields compared | P1 |
| DEL-013 | Asset not found for existing service | Error handled gracefully | P1 |

#### 4.2.3 Quote Order Creation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| DEL-020 | Create quote order for delivery | Order type = Delivery | P0 |
| DEL-021 | Create quote order for pickup | Order type = Pickup | P0 |
| DEL-022 | Create quote order for swap | Order type = Swap | P0 |
| DEL-023 | Calculate service end date | Date calculated correctly | P1 |
| DEL-024 | Assign max quote line number | Next number assigned | P1 |
| DEL-025 | Parent quote line field assignment | Fields propagated | P1 |

---

### 4.3 QuoteLineOperationsService Tests

#### 4.3.1 Quote Line Creation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| QOP-001 | Create quote lines with product/waste stream | Parent + child lines created | P0 |
| QOP-002 | Create quote lines with equipment size | Size properly assigned | P0 |
| QOP-003 | Create quote lines with category option | Category resolved | P1 |
| QOP-004 | Create quote lines with material option | Material resolved | P1 |
| QOP-005 | Haul Away product integration (SDT-44574) | Vendor assignment correct | P0 |
| QOP-006 | CPQ configuration rules processed | Rules applied | P1 |

#### 4.3.2 Quote Line Queries
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| QOP-010 | Get quote products for quote ID | Parent lines returned | P0 |
| QOP-011 | Get quote line MAS details | MAS fields returned | P1 |
| QOP-012 | Get quote details (child lines) | Child lines with details | P1 |
| QOP-013 | Get max quote line number | Next available number | P1 |

#### 4.3.3 Favorite Conversion
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| QOP-020 | Add quote from favorite | Quote created from template | P0 |
| QOP-021 | Add quote line from favorite | Quote line created | P0 |
| QOP-022 | Convert favorite to non-favorite line | Conversion successful | P1 |

---

### 4.4 QuoteDataMapperService Tests

#### 4.4.1 Wrapper Building
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| MAP-001 | Build complete products wrapper | All fields mapped | P0 |
| MAP-002 | Build simple quote wrapper | Simplified view returned | P1 |
| MAP-003 | Map header wrapper from quote line | Header fields correct | P1 |
| MAP-004 | Map detail wrapper from quote line | Detail fields correct | P1 |
| MAP-005 | Map work order wrappers | Work orders included | P1 |

#### 4.4.2 Data Transformation
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| MAP-010 | Material type mapping | Correct material type | P1 |
| MAP-011 | Availability message integration | Bell icon message correct | P1 |
| MAP-012 | Cost compare message handling | Compare message included | P1 |
| MAP-013 | Null handling in wrapper building | No null pointer exceptions | P0 |

---

### 4.5 VendorManagementService Tests

#### 4.5.1 Vendor Search
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VND-001 | Search vendors by name | Matching vendors returned | P0 |
| VND-002 | Search vendors - empty result | Empty list returned | P1 |
| VND-003 | Filter parent vendors (SDT-45005) | Parents excluded | P0 |
| VND-004 | Search with special characters | Results or empty | P1 |

#### 4.5.2 Vendor Operations
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| VND-010 | Update vendor details on quote line | Parent + child updated | P0 |
| VND-011 | Validate active vendor status | Status verified | P0 |
| VND-012 | Validate inactive vendor status | Error returned | P0 |
| VND-013 | Get vendor details by ID | Vendor record returned | P1 |
| VND-014 | Get all active vendors | Active vendors list | P1 |

---

### 4.6 SLAManagementService Tests

#### 4.6.1 SLA Override Comments
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| SLA-001 | Add comment for SLA override | Comment__c created | P0 |
| SLA-002 | Add comment with metadata template | Template fields used | P1 |
| SLA-003 | Add comment from intake screen | Comment created | P1 |
| SLA-004 | Add comment from Flow (MIF) | Comment created | P1 |
| SLA-005 | Verify RecordType assignment | Correct RecordType | P1 |

#### 4.6.2 SLA Calculations
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| SLA-010 | Calculate SLA date from entitlement | Date calculated | P1 |
| SLA-011 | Detect backdated service | Backdated flag set | P0 |
| SLA-012 | Validate SLA override fields | Validation passed | P1 |
| SLA-013 | Handle missing entitlement | Graceful handling | P1 |

---

### 4.7 SpecialHandlingService Tests

#### 4.7.1 Auto-Detection
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| SPH-001 | Detect backdated service (SLA < today) | Special handling flagged | P0 |
| SPH-002 | Detect certificate requirements | Special handling flagged | P0 |
| SPH-003 | Detect gate code requirement | Special handling flagged | P1 |
| SPH-004 | Detect time window restriction | Special handling flagged | P1 |
| SPH-005 | Detect restriction details | Special handling flagged | P1 |
| SPH-006 | No special handling scenarios | Flag not set | P0 |

#### 4.7.2 Special Handling Updates
| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| SPH-010 | Update special handling on quote | Quote.Special_Handling__c = true | P0 |
| SPH-011 | Set special handling reason | Reason populated | P1 |
| SPH-012 | Clear special handling when criteria removed | Flag cleared | P0 |
| SPH-013 | Identify all scenarios | Descriptions returned | P1 |

---

### 4.8 ProductConfigurationService Tests

| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| PCS-001 | Get accessories for product | Accessories list returned | P1 |
| PCS-002 | Get padlock keys for product | Keys list returned | P1 |
| PCS-003 | Get configuration attributes | Attributes returned | P1 |
| PCS-004 | SDT-22447 exclusions applied | Exclusions honored | P1 |

---

### 4.9 AssetAvailabilityService Tests

| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| AAV-001 | Get availability bell icon message | Message formatted | P1 |
| AAV-002 | Update AAV override fields | Fields updated | P1 |
| AAV-003 | Handle null availability data | No errors | P1 |

---

### 4.10 FavoritesService Tests

| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| FAV-001 | Get favorites for user | Favorites list returned | P1 |
| FAV-002 | Add quote favorite | Favorite created | P1 |
| FAV-003 | Create non-favorite line | Line created | P1 |
| FAV-004 | Remove favorite | Favorite deleted | P1 |

---

### 4.11 EntitlementMatchingService Tests

| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| ENT-001 | Match entitlement - priority level 1 | Correct entitlement | P1 |
| ENT-002 | Match entitlement - priority level 6 | Fallback entitlement | P1 |
| ENT-003 | Get related entitlement by quote line | Entitlement returned | P1 |
| ENT-004 | No matching entitlement | Null returned gracefully | P1 |

---

### 4.12 HaulAwayService Tests

| Test ID | Test Case | Expected Result | Priority |
|---------|-----------|-----------------|----------|
| HAL-001 | Vendor mapping for Haul Away (SDT-44574) | Vendor assigned | P0 |
| HAL-002 | Location-based vendor selection | Correct vendor | P1 |
| HAL-003 | Task creation for Haul Away | Task created | P1 |
| HAL-004 | Handle missing vendor mapping | Error handled | P1 |

---

## 5. Integration Test Scenarios

### 5.1 End-to-End Quote Creation Flow

| Test ID | Scenario | Steps | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| INT-001 | New Service Quote Creation | 1. Create Case 2. Add Quote 3. Add Quote Lines 4. Configure Product 5. Configure Cost 6. Configure Price 7. Create Delivery | Quote Order created, Work Order generated | P0 |
| INT-002 | Existing Service Modification | 1. Open existing case 2. Modify quote line 3. Validate changes 4. Create delivery | Asset comparison performed, changes applied | P0 |
| INT-003 | Haul Away Integration | 1. Create quote 2. Add Haul Away product 3. Vendor auto-assignment 4. Create delivery | Haul vendor assigned, order created | P0 |

### 5.2 Service Interaction Tests

| Test ID | Services Tested | Scenario | Expected Result | Priority |
|---------|-----------------|----------|-----------------|----------|
| INT-010 | Validation + DataMapper | Validate quote and build wrapper | Both services work in sequence | P0 |
| INT-011 | Operations + Delivery | Create lines then deliver | Quote lines to orders flow | P0 |
| INT-012 | Vendor + Validation | Search vendor then validate | Vendor validated after selection | P0 |
| INT-013 | SLA + SpecialHandling | SLA override with backdated | Both flags set correctly | P1 |
| INT-014 | Favorites + Operations | Convert favorite to quote | Favorite becomes quote line | P1 |

### 5.3 Multi-Service Orchestration

| Test ID | Scenario | Services Involved | Expected Result | Priority |
|---------|----------|-------------------|-----------------|----------|
| INT-020 | Full delivery workflow | DeliveryOrchestration, QuoteLineCollector, AssetComparison, ServiceDateManager, QuoteOrderFactory | Complete workflow success | P0 |
| INT-021 | Product configuration flow | ProductConfig, QuoteLineOps, Validation | Configuration persisted | P1 |
| INT-022 | SLA with entitlement | EntitlementMatching, SLAManagement | SLA calculated from entitlement | P1 |

---

## 6. Feature Flag Testing

### 6.1 Flag Enable/Disable Tests

| Test ID | Feature Flag | Test Scenario | Expected Result | Priority |
|---------|--------------|---------------|-----------------|----------|
| FF-001 | USE_DATA_MAPPER_SERVICE | Disable flag | Fallback behavior (if exists) | P1 |
| FF-002 | USE_VALIDATION_SERVICE | Disable flag | Fallback validation | P1 |
| FF-003 | USE_DELIVERY_ORCHESTRATION_SERVICE | Disable flag | Original createDelivery() | P1 |
| FF-004 | USE_QUOTE_LINE_OPERATIONS_SERVICE | Disable flag | Original operations | P1 |
| FF-005 | USE_SLA_MANAGEMENT_SERVICE | Disable flag | Fallback SLA logic | P0 |
| FF-006 | USE_SPECIAL_HANDLING_SERVICE | Disable flag | Fallback special handling | P0 |
| FF-007 | USE_VENDOR_SERVICE | Disable flag | Original vendor logic | P1 |
| FF-008 | USE_MAS_SERVICE | Disable flag | Original MAS logic | P1 |
| FF-009 | USE_AVAILABILITY_SERVICE | Disable flag | Original availability | P1 |
| FF-010 | USE_PRODUCT_CONFIG_SERVICE | Disable flag | Original config | P1 |
| FF-011 | USE_POSITION_SERVICE | Disable flag | Original position | P2 |
| FF-012 | USE_WORK_ORDER_SERVICE | Disable flag | Original work order | P1 |

### 6.2 Rollback Scenarios

| Test ID | Scenario | Steps | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| FF-020 | Emergency all-disable | Set all flags to false | System uses all fallbacks | P0 |
| FF-021 | Selective disable | Disable one service only | Other services unaffected | P0 |
| FF-022 | Service exception fallback | Force exception in service | Fallback triggered (Phase 10.5) | P0 |
| FF-023 | Gradual rollout (10%) | Enable for 10% of users | 10% use service, 90% fallback | P2 |

---

## 7. Performance Testing

### 7.1 Response Time Benchmarks

| Test ID | Operation | Target Time | Max Time | Priority |
|---------|-----------|-------------|----------|----------|
| PERF-001 | buildWrapper() - 10 lines | < 1s | 2s | P0 |
| PERF-002 | buildWrapper() - 50 lines | < 2s | 3s | P0 |
| PERF-003 | buildWrapper() - 100 lines | < 3s | 5s | P1 |
| PERF-004 | validate() - single line | < 200ms | 500ms | P0 |
| PERF-005 | validateBatch() - 50 lines | < 1s | 2s | P0 |
| PERF-006 | executeDeliveryCreation() | < 2s | 4s | P0 |
| PERF-007 | searchVendors() - SOSL | < 500ms | 1s | P1 |
| PERF-008 | createQuoteLines() | < 1s | 2s | P0 |

### 7.2 Governor Limit Tests

| Test ID | Limit Type | Test Scenario | Expected | Priority |
|---------|------------|---------------|----------|----------|
| PERF-010 | SOQL Queries | 100 quote lines | < 80 queries | P0 |
| PERF-011 | DML Operations | Bulk delivery creation | < 100 DML | P0 |
| PERF-012 | CPU Time | Complex wrapper build | < 8000ms | P0 |
| PERF-013 | Heap Size | Large quote processing | < 10MB | P1 |
| PERF-014 | Callout Limits | MAS integration | < 50 callouts | P1 |

### 7.3 Bulk Operation Tests

| Test ID | Operation | Volume | Expected | Priority |
|---------|-----------|--------|----------|----------|
| PERF-020 | Batch validation | 200 lines | Success, < 5s | P0 |
| PERF-021 | Mass delivery creation | 50 orders | Success, < 30s | P1 |
| PERF-022 | Bulk wrapper building | 100 quotes | Success, < 60s | P1 |

---

## 8. Regression Test Suite

### 8.1 Daily Smoke Tests (10-15 minutes)

| Test ID | Area | Test Cases | Pass Criteria |
|---------|------|------------|---------------|
| SMOKE-001 | Quote Creation | Create basic quote with 3 lines | Quote saved |
| SMOKE-002 | Validation | Validate quote at each stage | No errors |
| SMOKE-003 | Vendor Selection | Search and assign vendor | Vendor assigned |
| SMOKE-004 | Delivery | Create simple delivery | Order created |
| SMOKE-005 | Data Mapping | Build products wrapper | Wrapper returned |

### 8.2 Weekly Regression (2-4 hours)

| Suite | Test Count | Coverage |
|-------|------------|----------|
| Validation Suite | 56 tests | All validation rules |
| Delivery Suite | 25 tests | All delivery scenarios |
| Operations Suite | 30 tests | All CRUD operations |
| Integration Suite | 20 tests | Key integrations |
| Feature Flag Suite | 12 tests | All flags |

### 8.3 Release Regression (8-12 hours)

| Suite | Test Count | Coverage |
|-------|------------|----------|
| Full Unit Tests | 324 classes | All services |
| Integration Tests | 50+ scenarios | All workflows |
| Performance Tests | 20 tests | All benchmarks |
| E2E Tests | 10 scenarios | User journeys |

### 8.4 Automated Test Execution

```bash
# Daily smoke tests
sfdx force:apex:test:run --testlevel RunSpecifiedTests \
  --tests QuoteSmokeSuite

# Weekly regression
sfdx force:apex:test:run --testlevel RunLocalTests \
  --codecoverage

# Release regression
sfdx force:apex:test:run --testlevel RunAllTestsInOrg \
  --codecoverage --resultformat json
```

---

## 9. Risk-Based Testing Priority

### 9.1 Risk Assessment Matrix

| Service | Business Impact | Change Frequency | Complexity | Risk Score |
|---------|-----------------|------------------|------------|------------|
| QuoteLineValidationService | HIGH | HIGH | HIGH | **CRITICAL** |
| DeliveryOrchestrationService | HIGH | MEDIUM | HIGH | **CRITICAL** |
| QuoteLineOperationsService | HIGH | MEDIUM | MEDIUM | **HIGH** |
| VendorManagementService | MEDIUM | LOW | MEDIUM | **MEDIUM** |
| SLAManagementService | MEDIUM | LOW | MEDIUM | **MEDIUM** |
| SpecialHandlingService | LOW | LOW | LOW | **LOW** |

### 9.2 Testing Priority by Risk

**P0 (Critical) - Must Pass for Release:**
- All validation rule tests
- Delivery creation end-to-end
- Quote line CRUD operations
- Feature flag toggle tests
- Performance benchmarks

**P1 (High) - Required for Release:**
- Vendor operations
- SLA management
- Data mapping
- Integration scenarios

**P2 (Medium) - Should Pass:**
- Product configuration
- Asset availability
- Favorites management
- Edge cases

**P3 (Low) - Nice to Have:**
- Cosmetic issues
- Minor edge cases
- Documentation validation

---

## 10. Test Data Requirements

### 10.1 Data Factory Classes

```apex
// Primary test data factory
@isTest
public class QuoteTestDataFactory {
    public static Account createCustomerAccount();
    public static Account createVendorAccount(Boolean isActive);
    public static Case createServiceCase(Id accountId);
    public static SBQQ__Quote__c createQuote(Id caseId);
    public static SBQQ__QuoteLine__c createQuoteLine(Id quoteId, String type);
    public static Product2 createProduct(String productType);
    public static Asset createAsset(Id accountId, String equipmentSize);
    public static Entitlement createEntitlement(Id accountId, Integer slaHours);
}
```

### 10.2 Required Test Data Scenarios

| Scenario | Data Requirements |
|----------|-------------------|
| New Service | Customer account, Case, empty Quote |
| Existing Service | Customer, Case, Quote, Asset, Quote Lines |
| Vendor Assignment | Active vendor, Inactive vendor, Parent vendor |
| MAS Integration | WM vendor with MAS library |
| Haul Away | Haul Away product, vendor mapping |
| SLA Override | Entitlement, SLA metadata |
| Special Handling | Various special handling triggers |
| Commercial | Commercial product, commercial customer |

### 10.3 Data Isolation Requirements

- Each test class should create its own test data
- Use @TestSetup for shared data within a class
- Never rely on org data for tests
- Clean up any persisted test data

---

## Appendix A: Test Case Template

```markdown
### Test Case: [TEST-ID]

**Title:** [Brief description]

**Preconditions:**
- [Required setup]

**Test Steps:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
- [Expected outcome]

**Actual Result:**
- [To be filled during execution]

**Status:** [ ] Pass [ ] Fail [ ] Blocked

**Notes:**
- [Any observations]
```

---

## Appendix B: Defect Severity Classification

| Severity | Definition | Example |
|----------|------------|---------|
| Critical | System unusable, data loss | Delivery creation fails completely |
| High | Major feature broken | Validation bypassed |
| Medium | Feature works with workaround | Minor data mapping issue |
| Low | Cosmetic or minor issue | Formatting problem |

---

## Appendix C: Test Execution Checklist

- [ ] Test environment prepared
- [ ] Test data created
- [ ] Feature flags configured
- [ ] Test cases reviewed
- [ ] Smoke tests passed
- [ ] Unit tests executed
- [ ] Integration tests executed
- [ ] Performance tests executed
- [ ] Results documented
- [ ] Defects logged
- [ ] Coverage report generated
