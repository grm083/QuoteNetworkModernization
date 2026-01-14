# User Requirements Analysis: Service Tier Integration

## Executive Summary

This document analyzes 7 user-requested functionalities and maps them to the Quote Network Modernization service tier architecture. Each requirement is evaluated for:
- Appropriate service tier placement
- Existing code patterns to leverage
- Implementation recommendations
- Testing considerations

---

## Service Tier Architecture Overview

The Quote Network Modernization project established a 4-layer service architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION LAYER                       │
│  (DeliveryOrchestrationService, QuoteLineOperationsService)  │
├─────────────────────────────────────────────────────────────┤
│                      SERVICE LAYER                           │
│  (QuoteLineValidationService, SLAManagementService,         │
│   SpecialHandlingService, VendorManagementService)          │
├─────────────────────────────────────────────────────────────┤
│                    INTEGRATION LAYER                         │
│  (QuoteDataMapperService, AssetAvailabilityService)         │
├─────────────────────────────────────────────────────────────┤
│                    DATA ACCESS LAYER                         │
│  (Selectors, Domain Classes, Trigger Handlers)              │
└─────────────────────────────────────────────────────────────┘
```

---

## Requirement 1: Asset End Date Restriction Removal

### Description
Remove restriction preventing `AssetQuoteProcurementController` from running when a user selects an Asset where `End_Date__c != null`. Quote lines created should have:
- `SBQQ__StartDate__c` = `Asset.End_Date__c + 1 day`
- `SBQQ__EndDate__c` = `null`

### Current State Analysis
The `AssetQuoteProcurementController` currently blocks asset selection when `End_Date__c` is populated. This is a business rule that needs modification.

### Recommended Service Tier: **Integration Layer**

#### Target Service: `AssetAvailabilityService`
This service already handles asset availability and eligibility checks. The end date restriction logic should be:
1. Removed from `AssetQuoteProcurementController` validation
2. Added to `AssetAvailabilityService` as configurable behavior

#### Implementation Approach

```apex
// AssetAvailabilityService.cls - New Method
public class AssetAvailabilityService {

    /**
     * Calculates quote line dates based on asset end date
     * @param asset The source asset
     * @return Map containing StartDate and EndDate values
     */
    public static Map<String, Date> calculateQuoteLineDatesFromAsset(Asset asset) {
        Map<String, Date> dateMap = new Map<String, Date>();

        if (asset.End_Date__c != null) {
            // Requirement 1: Start date = End_Date__c + 1 day
            dateMap.put('StartDate', asset.End_Date__c.addDays(1));
            dateMap.put('EndDate', null);
        } else {
            // Existing behavior for assets without end date
            dateMap.put('StartDate', Date.today());
            dateMap.put('EndDate', null);
        }

        return dateMap;
    }
}
```

#### Files to Modify
| File | Change Required |
|------|-----------------|
| `AssetQuoteProcurementController.cls` | Remove `End_Date__c != null` restriction check |
| `AssetAvailabilityService.cls` | Add `calculateQuoteLineDatesFromAsset()` method |
| `QuoteLineOperationsService.cls` | Call new date calculation method during quote line creation |

#### Feature Flag
```apex
public static final String USE_ASSET_END_DATE_HANDLING = 'USE_ASSET_END_DATE_HANDLING';
```

---

## Requirement 2: Future Start Date Asset Modification

### Description
Allow modification of assets where `Asset.Start_Date__c > Today`. Quote lines should have:
- `SBQQ__StartDate__c` = `Asset.Start_Date__c + 1 day`
- `SBQQ__EndDate__c` = `Asset.End_Date__c` (may be null)

### Current State Analysis
The system currently restricts modification of assets with future start dates. This is related to Requirement 1 but handles a different scenario.

### Recommended Service Tier: **Integration Layer**

#### Target Service: `AssetAvailabilityService`
Extend the same service with future-dated asset handling.

#### Implementation Approach

```apex
// AssetAvailabilityService.cls - Extended Method
public static Map<String, Date> calculateQuoteLineDatesFromAsset(Asset asset) {
    Map<String, Date> dateMap = new Map<String, Date>();

    // Requirement 2: Future start date assets
    if (asset.Start_Date__c != null && asset.Start_Date__c > Date.today()) {
        dateMap.put('StartDate', asset.Start_Date__c.addDays(1));
        dateMap.put('EndDate', asset.End_Date__c); // May be null
    }
    // Requirement 1: Assets with end date
    else if (asset.End_Date__c != null) {
        dateMap.put('StartDate', asset.End_Date__c.addDays(1));
        dateMap.put('EndDate', null);
    }
    // Default behavior
    else {
        dateMap.put('StartDate', Date.today());
        dateMap.put('EndDate', null);
    }

    return dateMap;
}
```

#### Files to Modify
| File | Change Required |
|------|-----------------|
| `AssetQuoteProcurementController.cls` | Remove `Start_Date__c > Today` restriction |
| `AssetAvailabilityService.cls` | Extend date calculation to handle future start dates |

#### Feature Flag
```apex
public static final String USE_FUTURE_START_DATE_HANDLING = 'USE_FUTURE_START_DATE_HANDLING';
```

---

## Requirement 3: Checkbox Field Cascade to Child Quote Lines

### Description
When `DoNotCreateTaskGridTicket__c` OR `BypassPriceReview__c` is populated on a parent quote line (`SBQQ__RequiredBy__c == null`), cascade the value to all children where `SBQQ__RequiredBy__c = parent.Id`.

### Current State Analysis
Based on grep searches, there is no existing cascade logic for these specific checkbox fields. However, the parent-child relationship pattern is well-established in the codebase through `SBQQ__RequiredBy__c`.

### Recommended Service Tier: **Service Layer**

#### Target Service: NEW `QuoteLineFieldCascadeService`
Create a dedicated service for field cascade operations. This follows the Single Responsibility Principle and allows for future cascade requirements.

#### Implementation Approach

```apex
/**
 * QuoteLineFieldCascadeService.cls
 * Handles field value cascading from parent to child quote lines
 */
public class QuoteLineFieldCascadeService {

    // Fields that should cascade from parent to children
    private static final Set<String> CASCADE_FIELDS = new Set<String>{
        'DoNotCreateTaskGridTicket__c',
        'BypassPriceReview__c'
    };

    /**
     * Cascades specified field values from parent quote lines to children
     * @param parentQuoteLines List of parent quote lines (SBQQ__RequiredBy__c == null)
     * @param allQuoteLines All quote lines in the transaction for child lookup
     */
    public static void cascadeFieldsToChildren(
        List<SBQQ__QuoteLine__c> parentQuoteLines,
        Map<Id, SBQQ__QuoteLine__c> allQuoteLinesById
    ) {
        if (!FeatureFlags.isEnabled('USE_FIELD_CASCADE_SERVICE')) {
            return;
        }

        List<SBQQ__QuoteLine__c> childrenToUpdate = new List<SBQQ__QuoteLine__c>();

        for (SBQQ__QuoteLine__c parent : parentQuoteLines) {
            // Only process if parent has checkbox values
            if (parent.DoNotCreateTaskGridTicket__c == true ||
                parent.BypassPriceReview__c == true) {

                // Find all children
                List<SBQQ__QuoteLine__c> children = getChildQuoteLines(
                    parent.Id,
                    allQuoteLinesById
                );

                for (SBQQ__QuoteLine__c child : children) {
                    Boolean needsUpdate = false;

                    if (parent.DoNotCreateTaskGridTicket__c == true &&
                        child.DoNotCreateTaskGridTicket__c != true) {
                        child.DoNotCreateTaskGridTicket__c = true;
                        needsUpdate = true;
                    }

                    if (parent.BypassPriceReview__c == true &&
                        child.BypassPriceReview__c != true) {
                        child.BypassPriceReview__c = true;
                        needsUpdate = true;
                    }

                    if (needsUpdate) {
                        childrenToUpdate.add(child);
                    }
                }
            }
        }

        if (!childrenToUpdate.isEmpty()) {
            update childrenToUpdate;
        }
    }

    private static List<SBQQ__QuoteLine__c> getChildQuoteLines(
        Id parentId,
        Map<Id, SBQQ__QuoteLine__c> allQuoteLinesById
    ) {
        List<SBQQ__QuoteLine__c> children = new List<SBQQ__QuoteLine__c>();

        for (SBQQ__QuoteLine__c ql : allQuoteLinesById.values()) {
            if (ql.SBQQ__RequiredBy__c == parentId) {
                children.add(ql);
            }
        }

        return children;
    }
}
```

#### Integration Point
The cascade service should be called from `QuoteLineTriggerHandler` after update operations:

```apex
// QuoteLineTriggerHandler.cls - afterUpdate method
if (FeatureFlags.isEnabled('USE_FIELD_CASCADE_SERVICE')) {
    List<SBQQ__QuoteLine__c> parentsWithChanges = new List<SBQQ__QuoteLine__c>();

    for (SBQQ__QuoteLine__c ql : Trigger.new) {
        SBQQ__QuoteLine__c oldQl = Trigger.oldMap.get(ql.Id);

        // Check if this is a parent and checkbox fields changed
        if (ql.SBQQ__RequiredBy__c == null && (
            ql.DoNotCreateTaskGridTicket__c != oldQl.DoNotCreateTaskGridTicket__c ||
            ql.BypassPriceReview__c != oldQl.BypassPriceReview__c
        )) {
            parentsWithChanges.add(ql);
        }
    }

    if (!parentsWithChanges.isEmpty()) {
        QuoteLineFieldCascadeService.cascadeFieldsToChildren(
            parentsWithChanges,
            getAllQuoteLinesForQuotes(parentsWithChanges)
        );
    }
}
```

#### Files to Create/Modify
| File | Change Required |
|------|-----------------|
| `QuoteLineFieldCascadeService.cls` | **NEW** - Create cascade service |
| `QuoteLineFieldCascadeServiceTest.cls` | **NEW** - Unit tests |
| `QuoteLineTriggerHandler.cls` | Add call to cascade service in afterUpdate |

#### Feature Flag
```apex
public static final String USE_FIELD_CASCADE_SERVICE = 'USE_FIELD_CASCADE_SERVICE';
```

---

## Requirement 4: Extra Pickup Pricing Reset on Equipment Size Change

### Description
When `Equipment_Size__c` changes on parent, find child with `SBQQ__ProductName__c = 'Extra Pickup'` and set:
- `SBQQ__UnitCost__c` = `null`
- `SBQQ__ListPrice__c` = `null`

This triggers the API to re-price based on new equipment size.

### Current State Analysis
Existing code in `QuoteLineTriggerHelper.cls` handles Extra Pickup logic:

```apex
// QuoteLineTriggerHelper.cls - Lines 8-9
private static final string EXTRA_PICKUP_PRODUCT = 'Extra Pickup';
private static final string PICKUP_PRODUCT = 'Pickup';
```

Methods exist for `removeExtraPickupQuoteLine()` and `addExtraPickupQuoteLine()`. The pricing reset logic can be added to this existing pattern.

### Recommended Service Tier: **Service Layer**

#### Target Service: Extend existing `QuoteLineTriggerHelper` or create `ExtraPickupPricingService`

Given the existing Extra Pickup handling in `QuoteLineTriggerHelper`, we have two options:

**Option A: Extend QuoteLineTriggerHelper** (Recommended for consistency)
```apex
// QuoteLineTriggerHelper.cls - New Method
public static void resetExtraPickupPricingOnSizeChange(
    List<SBQQ__QuoteLine__c> parentQuoteLines,
    Map<Id, SBQQ__QuoteLine__c> oldMap
) {
    Set<Id> parentIdsWithSizeChange = new Set<Id>();

    // Identify parents with equipment size changes
    for (SBQQ__QuoteLine__c parent : parentQuoteLines) {
        if (parent.SBQQ__RequiredBy__c == null) {
            SBQQ__QuoteLine__c oldParent = oldMap.get(parent.Id);
            if (parent.Equipment_Size__c != oldParent.Equipment_Size__c) {
                parentIdsWithSizeChange.add(parent.Id);
            }
        }
    }

    if (parentIdsWithSizeChange.isEmpty()) {
        return;
    }

    // Find and update Extra Pickup children
    List<SBQQ__QuoteLine__c> extraPickupsToUpdate = [
        SELECT Id, SBQQ__UnitCost__c, SBQQ__ListPrice__c
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__RequiredBy__c IN :parentIdsWithSizeChange
        AND SBQQ__ProductName__c = :EXTRA_PICKUP_PRODUCT
    ];

    for (SBQQ__QuoteLine__c extraPickup : extraPickupsToUpdate) {
        extraPickup.SBQQ__UnitCost__c = null;
        extraPickup.SBQQ__ListPrice__c = null;
    }

    if (!extraPickupsToUpdate.isEmpty()) {
        update extraPickupsToUpdate;
    }
}
```

**Option B: Create ExtraPickupPricingService** (Better for service isolation)
```apex
/**
 * ExtraPickupPricingService.cls
 * Handles pricing logic for Extra Pickup quote lines
 */
public class ExtraPickupPricingService {

    private static final String EXTRA_PICKUP_PRODUCT = 'Extra Pickup';

    /**
     * Resets pricing on Extra Pickup lines when parent equipment size changes
     * This triggers re-pricing through the pricing API
     */
    public static void resetPricingOnEquipmentSizeChange(
        Set<Id> parentIdsWithSizeChange
    ) {
        if (!FeatureFlags.isEnabled('USE_EXTRA_PICKUP_PRICING_SERVICE')) {
            return;
        }

        if (parentIdsWithSizeChange.isEmpty()) {
            return;
        }

        List<SBQQ__QuoteLine__c> extraPickupsToUpdate = [
            SELECT Id, SBQQ__UnitCost__c, SBQQ__ListPrice__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c IN :parentIdsWithSizeChange
            AND SBQQ__ProductName__c = :EXTRA_PICKUP_PRODUCT
        ];

        for (SBQQ__QuoteLine__c ep : extraPickupsToUpdate) {
            ep.SBQQ__UnitCost__c = null;
            ep.SBQQ__ListPrice__c = null;
        }

        if (!extraPickupsToUpdate.isEmpty()) {
            update extraPickupsToUpdate;
        }
    }
}
```

#### Files to Create/Modify
| File | Change Required |
|------|-----------------|
| `QuoteLineTriggerHelper.cls` | Add `resetExtraPickupPricingOnSizeChange()` method |
| `QuoteLineTriggerHandler.cls` | Call new method in afterUpdate |

#### Feature Flag
```apex
public static final String USE_EXTRA_PICKUP_PRICING_RESET = 'USE_EXTRA_PICKUP_PRICING_RESET';
```

---

## Requirement 5: Currency Based on Account Shipping Country

### Description
Set `CurrencyIsoCode` based on `SBQQ__Quote__c.SBQQ__Account__c.ShippingCountry`:
- Canada → CAD
- Otherwise → USD

This should override the user default currency.

### Current State Analysis
Currency handling currently appears to use user default. This needs to be changed at the quote line creation level.

### Recommended Service Tier: **Integration Layer**

#### Target Service: `QuoteDataMapperService`
The data mapper service already handles field mapping during quote line creation. Currency logic fits naturally here.

#### Implementation Approach

```apex
// QuoteDataMapperService.cls - New Method
public class QuoteDataMapperService {

    private static final Map<String, String> COUNTRY_TO_CURRENCY = new Map<String, String>{
        'Canada' => 'CAD',
        'CA' => 'CAD'
        // All other countries default to USD
    };

    private static final String DEFAULT_CURRENCY = 'USD';

    /**
     * Determines the appropriate currency based on account shipping country
     * @param accountShippingCountry The shipping country from the quote's account
     * @return The CurrencyIsoCode to use (CAD or USD)
     */
    public static String determineCurrencyFromAccount(String accountShippingCountry) {
        if (String.isBlank(accountShippingCountry)) {
            return DEFAULT_CURRENCY;
        }

        String currency = COUNTRY_TO_CURRENCY.get(accountShippingCountry);
        return String.isNotBlank(currency) ? currency : DEFAULT_CURRENCY;
    }

    /**
     * Sets currency on quote lines based on account shipping country
     * @param quoteLines Quote lines to set currency on
     * @param quoteToAccountMap Map of Quote Id to Account record
     */
    public static void setCurrencyFromAccountCountry(
        List<SBQQ__QuoteLine__c> quoteLines,
        Map<Id, Account> quoteToAccountMap
    ) {
        if (!FeatureFlags.isEnabled('USE_ACCOUNT_BASED_CURRENCY')) {
            return;
        }

        for (SBQQ__QuoteLine__c ql : quoteLines) {
            Account acct = quoteToAccountMap.get(ql.SBQQ__Quote__c);
            if (acct != null) {
                ql.CurrencyIsoCode = determineCurrencyFromAccount(acct.ShippingCountry);
            }
        }
    }
}
```

#### Integration Point
Call during quote line creation in `QuoteLineOperationsService`:

```apex
// QuoteLineOperationsService.cls
public static void createQuoteLines(List<SBQQ__QuoteLine__c> newQuoteLines) {
    // ... existing logic ...

    // Set currency based on account country
    if (FeatureFlags.isEnabled('USE_ACCOUNT_BASED_CURRENCY')) {
        Map<Id, Account> quoteToAccountMap = getAccountsForQuotes(quoteIds);
        QuoteDataMapperService.setCurrencyFromAccountCountry(newQuoteLines, quoteToAccountMap);
    }

    // ... continue with insert ...
}
```

#### Files to Modify
| File | Change Required |
|------|-----------------|
| `QuoteDataMapperService.cls` | Add currency determination methods |
| `QuoteLineOperationsService.cls` | Call currency mapping during creation |
| `QuoteLineTriggerHandler.cls` | Ensure currency is set on beforeInsert |

#### Feature Flag
```apex
public static final String USE_ACCOUNT_BASED_CURRENCY = 'USE_ACCOUNT_BASED_CURRENCY';
```

---

## Requirement 6: Removal Quote Line Equipment Size (Old Size from Asset)

### Description
When `Equipment_Size__c` changes, set Removal Quote Line `Equipment_Size__c` to the OLD size from Asset (`SBQQ__QuoteLine__c.AssetId__c.Equipment_Size__c`), converting from label format (e.g., "40 Yards") to code format (e.g., "YRDS-40").

### Current State Analysis
The codebase has existing equipment size conversion utilities:

**QuoteLineServices.cls** - Contains `changeInSize()` method with conversion logic:
```apex
// Lines showing conversion pattern
if(assetVolume.Contains('Yards')) { assetVolumefinal = 'YRDS'; }
else if(assetVolume.Contains('Gallons')) { assetVolumefinal = 'GALS'; }
```

**AssetQuoteProcurementController.cls** - Contains picklist conversion utilities:
- `getPicklistEntryByLabel()`
- `getPicklistEntryByAPIName()`

### Recommended Service Tier: **Service Layer**

#### Target Service: Extend `QuoteLineServices` or create `EquipmentSizeConversionService`

Given the existing conversion logic in `QuoteLineServices.cls`, we should:
1. Extract conversion logic into a dedicated utility
2. Use it for Removal Quote Line processing

#### Implementation Approach

```apex
/**
 * EquipmentSizeConversionService.cls
 * Centralized service for equipment size format conversions
 */
public class EquipmentSizeConversionService {

    // Label to code mappings for volume units
    private static final Map<String, String> VOLUME_LABEL_TO_CODE = new Map<String, String>{
        'Yards' => 'YRDS',
        'Gallons' => 'GALS',
        'Cubic Yards' => 'CYDS',
        'Cubic Meters' => 'CMTR'
    };

    /**
     * Converts equipment size from label format to code format
     * Example: "40 Yards" → "YRDS-40"
     *
     * @param labelFormat The equipment size in label format (e.g., "40 Yards")
     * @return The equipment size in code format (e.g., "YRDS-40")
     */
    public static String convertLabelToCode(String labelFormat) {
        if (String.isBlank(labelFormat) || labelFormat == 'Unknown') {
            return null;
        }

        try {
            // Parse "40 Yards" → size=40, unit=Yards
            String sizeValue = labelFormat.substringBefore(' ').trim();
            String unitLabel = labelFormat.substringAfter(' ').trim();

            // Convert unit label to code
            String unitCode = null;
            for (String label : VOLUME_LABEL_TO_CODE.keySet()) {
                if (unitLabel.containsIgnoreCase(label)) {
                    unitCode = VOLUME_LABEL_TO_CODE.get(label);
                    break;
                }
            }

            if (unitCode == null) {
                return null;
            }

            // Format as "YRDS-40"
            return unitCode + '-' + sizeValue;

        } catch (Exception e) {
            System.debug('Error converting equipment size: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Converts equipment size from code format to label format
     * Example: "YRDS-40" → "40 Yards"
     */
    public static String convertCodeToLabel(String codeFormat) {
        // Reverse mapping implementation
        // ...
    }
}
```

#### Removal Quote Line Integration

```apex
/**
 * RemovalQuoteLineService.cls
 * Handles creation and updates of Removal Quote Lines
 */
public class RemovalQuoteLineService {

    /**
     * Sets the equipment size on removal quote lines using the original asset size
     * @param removalQuoteLines The removal quote lines to update
     * @param assetMap Map of Asset Id to Asset record with original Equipment_Size__c
     */
    public static void setEquipmentSizeFromAsset(
        List<SBQQ__QuoteLine__c> removalQuoteLines,
        Map<Id, Asset> assetMap
    ) {
        if (!FeatureFlags.isEnabled('USE_REMOVAL_EQUIPMENT_SIZE_SERVICE')) {
            return;
        }

        for (SBQQ__QuoteLine__c removalLine : removalQuoteLines) {
            Id assetId = removalLine.AssetId__c;

            if (assetId != null && assetMap.containsKey(assetId)) {
                Asset originalAsset = assetMap.get(assetId);
                String assetSizeLabel = originalAsset.Equipment_Size__c;

                // Convert from label format to code format
                String sizeCode = EquipmentSizeConversionService.convertLabelToCode(assetSizeLabel);

                if (sizeCode != null) {
                    removalLine.Equipment_Size__c = sizeCode;
                }
            }
        }
    }
}
```

#### Files to Create/Modify
| File | Change Required |
|------|-----------------|
| `EquipmentSizeConversionService.cls` | **NEW** - Centralized conversion utility |
| `EquipmentSizeConversionServiceTest.cls` | **NEW** - Unit tests for conversions |
| `RemovalQuoteLineService.cls` | **NEW or EXTEND** - Removal line handling |
| `QuoteLineServices.cls` | Refactor to use new conversion service |
| `QuoteLineTriggerHandler.cls` | Call removal size service on equipment change |

#### Feature Flag
```apex
public static final String USE_REMOVAL_EQUIPMENT_SIZE_SERVICE = 'USE_REMOVAL_EQUIPMENT_SIZE_SERVICE';
```

---

## Requirement 7: Amendment Quote End Date Handling

### Description
When `SBQQ__Quote__c.SBQQ__Type__c == 'Amendment'` and adding quote lines to bundles:
- Set `SBQQ__EndDate__c` = `SBQQ__StartDate__c` (1 day service)
- Instead of current behavior: `SBQQ__StartDate__c + 7`

### Current State Analysis
The "+ 7 days" logic exists somewhere in the quote line creation flow. This needs to be modified for Amendment quote types.

### Recommended Service Tier: **Service Layer**

#### Target Service: Extend `QuoteLineOperationsService` or `SLAManagementService`

The SLA Management Service handles duration-related logic, making it a good candidate.

#### Implementation Approach

```apex
// SLAManagementService.cls - New or Extended Method
public class SLAManagementService {

    /**
     * Calculates the end date for a quote line based on quote type
     * Amendment quotes get 1-day service, regular quotes get 7-day default
     *
     * @param quoteLine The quote line to calculate end date for
     * @param quoteType The SBQQ__Type__c of the parent quote
     * @return The calculated end date
     */
    public static Date calculateEndDate(
        SBQQ__QuoteLine__c quoteLine,
        String quoteType
    ) {
        if (!FeatureFlags.isEnabled('USE_AMENDMENT_END_DATE_HANDLING')) {
            // Fall back to existing behavior
            return quoteLine.SBQQ__StartDate__c != null
                ? quoteLine.SBQQ__StartDate__c.addDays(7)
                : null;
        }

        // Requirement 7: Amendment quotes get 1-day service
        if (quoteType == 'Amendment') {
            return quoteLine.SBQQ__StartDate__c; // Same day = 1 day service
        }

        // Default: 7-day service for non-amendment quotes
        return quoteLine.SBQQ__StartDate__c != null
            ? quoteLine.SBQQ__StartDate__c.addDays(7)
            : null;
    }

    /**
     * Sets end dates on quote lines being added to bundles
     * @param quoteLines Quote lines being added
     * @param quoteMap Map of Quote Id to Quote record
     */
    public static void setEndDatesForBundleAdditions(
        List<SBQQ__QuoteLine__c> quoteLines,
        Map<Id, SBQQ__Quote__c> quoteMap
    ) {
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            // Only process lines being added to bundles (have RequiredBy)
            if (ql.SBQQ__RequiredBy__c != null && ql.SBQQ__StartDate__c != null) {
                SBQQ__Quote__c quote = quoteMap.get(ql.SBQQ__Quote__c);

                if (quote != null) {
                    ql.SBQQ__EndDate__c = calculateEndDate(ql, quote.SBQQ__Type__c);
                }
            }
        }
    }
}
```

#### Integration Point
Call during quote line creation:

```apex
// QuoteLineOperationsService.cls or QuoteLineTriggerHandler.cls
if (FeatureFlags.isEnabled('USE_AMENDMENT_END_DATE_HANDLING')) {
    Map<Id, SBQQ__Quote__c> quoteMap = getQuotesWithType(quoteIds);
    SLAManagementService.setEndDatesForBundleAdditions(newQuoteLines, quoteMap);
}
```

#### Files to Modify
| File | Change Required |
|------|-----------------|
| `SLAManagementService.cls` | Add `calculateEndDate()` and `setEndDatesForBundleAdditions()` methods |
| `QuoteLineOperationsService.cls` | Call SLA service during bundle additions |
| `QuoteLineTriggerHandler.cls` | Ensure end date logic runs on beforeInsert |

#### Feature Flag
```apex
public static final String USE_AMENDMENT_END_DATE_HANDLING = 'USE_AMENDMENT_END_DATE_HANDLING';
```

---

## Implementation Summary

### New Services to Create

| Service | Layer | Requirements Covered |
|---------|-------|---------------------|
| `QuoteLineFieldCascadeService` | Service | #3 (Checkbox Cascade) |
| `EquipmentSizeConversionService` | Service | #6 (Removal Size) |
| `RemovalQuoteLineService` | Service | #6 (Removal Size) |
| `ExtraPickupPricingService` (Optional) | Service | #4 (Extra Pickup Reset) |

### Existing Services to Extend

| Service | Layer | Requirements Covered |
|---------|-------|---------------------|
| `AssetAvailabilityService` | Integration | #1 (End Date), #2 (Future Start) |
| `QuoteDataMapperService` | Integration | #5 (Currency) |
| `SLAManagementService` | Service | #7 (Amendment End Date) |
| `QuoteLineTriggerHelper` | Data Access | #4 (Extra Pickup Reset) |

### Feature Flags Summary

| Feature Flag | Requirement |
|-------------|-------------|
| `USE_ASSET_END_DATE_HANDLING` | #1 |
| `USE_FUTURE_START_DATE_HANDLING` | #2 |
| `USE_FIELD_CASCADE_SERVICE` | #3 |
| `USE_EXTRA_PICKUP_PRICING_RESET` | #4 |
| `USE_ACCOUNT_BASED_CURRENCY` | #5 |
| `USE_REMOVAL_EQUIPMENT_SIZE_SERVICE` | #6 |
| `USE_AMENDMENT_END_DATE_HANDLING` | #7 |

---

## Testing Strategy

Each requirement should have dedicated test coverage:

### Unit Tests
- Test each service method in isolation
- Test edge cases (null values, empty collections, invalid formats)
- Test feature flag enable/disable behavior

### Integration Tests
- Test trigger handler integration with services
- Test end-to-end quote line creation flows
- Test parent-child cascade operations

### Test Data Patterns
```apex
@isTest
private class QuoteLineFieldCascadeServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test account, opportunity, quote
        // Create parent quote line
        // Create child quote lines with SBQQ__RequiredBy__c
    }

    @isTest
    static void testCascadeDoNotCreateTaskGridTicket() {
        // Given: Parent with DoNotCreateTaskGridTicket__c = true
        // When: Cascade service is called
        // Then: All children have DoNotCreateTaskGridTicket__c = true
    }

    @isTest
    static void testCascadeBypassPriceReview() {
        // Given: Parent with BypassPriceReview__c = true
        // When: Cascade service is called
        // Then: All children have BypassPriceReview__c = true
    }

    @isTest
    static void testNoCascadeWhenFeatureFlagDisabled() {
        // Given: Feature flag disabled
        // When: Parent checkbox changed
        // Then: Children unchanged
    }
}
```

---

## Rollout Recommendation

### Phase 1: Foundation (Week 1-2)
1. Create `EquipmentSizeConversionService` - centralized utility
2. Extend `AssetAvailabilityService` with date calculations
3. Add all feature flags (disabled by default)

### Phase 2: Non-Pricing Changes (Week 3-4)
1. Implement Requirement #1 (Asset End Date)
2. Implement Requirement #2 (Future Start Date)
3. Implement Requirement #3 (Checkbox Cascade)

### Phase 3: Pricing & Complex Logic (Week 5-6)
1. Implement Requirement #4 (Extra Pickup Pricing Reset)
2. Implement Requirement #5 (Account Currency)
3. Implement Requirement #6 (Removal Equipment Size)

### Phase 4: Amendment Handling (Week 7)
1. Implement Requirement #7 (Amendment End Date)

### Phase 5: Validation & Rollout
1. Enable feature flags in sandbox
2. User acceptance testing
3. Gradual production rollout per feature flag

---

## Appendix: Code Pattern References

### Existing Extra Pickup Pattern (QuoteLineTriggerHelper.cls)
```apex
private static final string EXTRA_PICKUP_PRODUCT = 'Extra Pickup';
private static final string PICKUP_PRODUCT = 'Pickup';

public static void removeExtraPickupQuoteLine(List<SBQQ__QuoteLine__c> quoteLineNewList) {
    Set<Id> requiredByIds = new Set<Id>();
    for(SBQQ__QuoteLine__c quoteLine : quoteLineNewList){
        if(quoteLine.SBQQ__RequiredBy__c != null
           && quoteLine.SBQQ__ProductName__c == EXTRA_PICKUP_PRODUCT){
               requiredByIds.add(quoteLine.SBQQ__RequiredBy__c);
        }
    }
    // ... continues with update logic
}
```

### Existing Size Change Detection (QuoteLineServices.cls)
```apex
public static boolean changeInSize(SBQQ__QuoteLine__c quoteLineRecord, Asset asset) {
    if(quoteLineRecord.AssetId__r.Equipment_Size__c != null &&
       quoteLineRecord.AssetId__r.Equipment_Size__c != 'Unknown' &&
       quoteLineRecord.Equipment_Size__c != null) {
        Double assetSize = Double.valueOf(
            quoteLineRecord.AssetId__r.Equipment_Size__c.substringBefore(' ')
        );
        Double quoteLineSize = Double.valueOf(
            quoteLineRecord.Equipment_Size__c.substringAfter('-')
        );
        // Volume conversion logic...
    }
    return changeInSize;
}
```

---

*Document Version: 1.0*
*Created: January 2026*
*Project: Quote Network Modernization - User Requirements Analysis*
