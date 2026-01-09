# Lightning Web Components Architecture Strategy
## Quote Platform UX Redesign

---

## Executive Summary

This document outlines a comprehensive strategy for rebuilding the Quote Platform using modern Lightning Web Components (LWC) architecture. The design implements the UX improvements identified in the User Journey Narrative while maintaining full compatibility with the existing Salesforce data model and refactored service layer (Phases 10-13).

### Key Principles

1. **Component-Based Architecture**: Small, focused components with single responsibilities
2. **State Management**: Centralized state management using Lightning Message Service (LMS) and custom events
3. **Progressive Disclosure**: Show complexity only when needed
4. **Real-time Validation**: Validate as users type, show errors inline with resolution paths
5. **Responsive Design**: Mobile-first design that scales to desktop
6. **Accessibility**: WCAG 2.1 AA compliant throughout
7. **Performance**: Lazy loading, caching, and optimistic UI updates

---

## Component Hierarchy Overview

```
quoteFlowContainer (Parent Container)
├── quoteFlowHeader (Top-level navigation and progress)
├── quoteFlowSidebar (Contextual help and summary)
└── quoteFlowMain (Main content area)
    ├── quickQuoteWizard (Guided flow for standard quotes)
    │   ├── productSelectorCard
    │   ├── serviceDetailsCard
    │   ├── pricingPreviewCard
    │   └── quoteSubmitCard
    │
    ├── advancedQuoteBuilder (Power user interface)
    │   ├── productSelectionPanel
    │   │   ├── smartFavoritesList
    │   │   ├── productSearchBar
    │   │   └── productCatalogGrid
    │   │
    │   ├── quoteProductsTable (Enhanced configured products table)
    │   │   ├── productLineRow (Reusable row component)
    │   │   │   ├── productAlertIcons
    │   │   │   ├── inlineEditor
    │   │   │   └── actionButtonGroup
    │   │   └── productLineExpander (Child lines)
    │   │
    │   ├── configurationPanel
    │   │   ├── locationConfigCard
    │   │   ├── scheduleConfigCard
    │   │   ├── equipmentConfigCard
    │   │   └── accessorySelector
    │   │
    │   ├── validationSummary
    │   │   ├── validationItem (Individual validation issue)
    │   │   └── quickFixModal
    │   │
    │   └── pricingComparison
    │       ├── vendorPricingCard (Per vendor)
    │       ├── pricingBreakdown
    │       └── marginCalculator
    │
    └── sharedComponents (Reusable across flows)
        ├── slaCalculatorDisplay
        ├── entitlementBadge
        ├── addressLookup
        ├── wasteStreamSelector
        ├── equipmentSizeSelector
        ├── scheduleBuilder
        ├── approvalTracker
        └── changeHistoryPanel
```

---

## Core Components: Detailed Specifications

### 1. quoteFlowContainer (Root Component)

**Purpose**: Main container managing overall quote creation flow and state

**Responsibilities**:
- Route between Quick Quote Wizard vs. Advanced Builder based on user preference
- Manage global quote state (quote ID, account context, user permissions)
- Coordinate Lightning Message Service for cross-component communication
- Handle session persistence and autosave

**Data Inputs**:
- `@api recordId` - Case/Opportunity/Quote ID
- `@api flowMode` - 'new' | 'edit' | 'amend' | 'correct'
- `@api userProfile` - User role and permissions

**State Management**:
```javascript
@track quoteState = {
  quoteId: null,
  accountId: null,
  opportunityId: null,
  caseId: null,
  quoteLines: [],
  validationStatus: {},
  pricingStatus: {},
  approvalStatus: {},
  isDirty: false,
  lastSaved: null
}
```

**Wire Adapters**:
- `@wire(getQuoteData, { quoteId: '$quoteId' })` - Full quote with lines
- `@wire(getAccountContext, { accountId: '$accountId' })` - Account, entitlements, location, timezone
- `@wire(getUserPermissions)` - User's editing permissions and approval authority

**Component Template**:
```html
<template>
  <lightning-card class="quote-flow-container">
    <!-- Header with progress -->
    <c-quote-flow-header
      quote-id={quoteId}
      flow-mode={flowMode}
      current-step={currentStep}
      onnavigation={handleNavigation}
    ></c-quote-flow-header>

    <!-- Main content area -->
    <div class="quote-flow-body">
      <!-- Sidebar (collapsible on mobile) -->
      <c-quote-flow-sidebar
        quote-summary={quoteSummary}
        validation-status={validationStatus}
        help-context={currentHelpContext}
      ></c-quote-flow-sidebar>

      <!-- Main panel - Conditional rendering -->
      <div class="quote-flow-main">
        <template if:true={isQuickQuoteMode}>
          <c-quick-quote-wizard
            quote-state={quoteState}
            onwizardcomplete={handleWizardComplete}
          ></c-quick-quote-wizard>
        </template>

        <template if:true={isAdvancedMode}>
          <c-advanced-quote-builder
            quote-state={quoteState}
            onquoteupdated={handleQuoteUpdated}
          ></c-advanced-quote-builder>
        </template>
      </div>
    </div>

    <!-- Footer with actions -->
    <div slot="footer" class="quote-flow-footer">
      <lightning-button label="Save Draft" onclick={handleSaveDraft}></lightning-button>
      <lightning-button variant="brand" label="Get Pricing" onclick={handleGetPricing}></lightning-button>
    </div>
  </lightning-card>

  <!-- Toasts and modals -->
  <template if:true={showAutosaveNotification}>
    <c-autosave-toast last-saved={lastSaved}></c-autosave-toast>
  </template>
</template>
```

---

### 2. quickQuoteWizard (Guided Flow for CSRs)

**Purpose**: Step-by-step wizard for creating standard quotes quickly (target: <5 minutes)

**Steps**:
1. **Product Selection** - Favorites + Recent for Customer + Search
2. **Service Details** - Location, Start Date, Schedule (critical three)
3. **Pricing Preview** - Auto-calculate and show preliminary pricing
4. **Submit** - Final validation and quote creation

**Key Features**:
- **Smart Defaults**: Pre-fill from account context and customer history
- **Progressive Disclosure**: Only show fields relevant to selected product type
- **Inline Help**: Contextual guidance at each step
- **Progress Indicator**: Clear visual showing 4-step progress
- **Keyboard Navigation**: Support Tab, Enter to advance through wizard

**Product Selection Step Template**:
```html
<template>
  <div class="wizard-step">
    <h2 class="slds-text-heading_medium">Select Service</h2>

    <!-- Recommendations based on context -->
    <template if:true={hasRecommendations}>
      <c-recommendation-banner
        recommendations={recommendations}
        onselect={handleRecommendationSelect}
      ></c-recommendation-banner>
    </template>

    <!-- Tabbed interface: Favorites | Recent | Search -->
    <lightning-tabset active-tab-value={activeTab}>

      <lightning-tab label="Favorites" value="favorites">
        <c-smart-favorites-list
          account-id={accountId}
          customer-history={customerHistory}
          onselect={handleFavoriteSelect}
        ></c-smart-favorites-list>
      </lightning-tab>

      <lightning-tab label="Recent for This Customer" value="recent">
        <c-customer-history-list
          account-id={accountId}
          onselect={handleHistorySelect}
        ></c-customer-history-list>
      </lightning-tab>

      <lightning-tab label="Search Catalog" value="search">
        <c-product-search-bar
          onsearch={handleProductSearch}
        ></c-product-search-bar>
        <c-product-catalog-grid
          products={searchResults}
          onselect={handleProductSelect}
        ></c-product-catalog-grid>
      </lightning-tab>
    </lightning-tabset>

    <!-- Selected product preview -->
    <template if:true={selectedProduct}>
      <c-product-preview-card
        product={selectedProduct}
        onmodify={handleModifySelection}
      ></c-product-preview-card>
    </template>

    <!-- Navigation -->
    <div class="wizard-navigation">
      <lightning-button label="Back" onclick={handleBack}></lightning-button>
      <lightning-button
        variant="brand"
        label="Next: Service Details"
        onclick={handleNext}
        disabled={!selectedProduct}
      ></lightning-button>
    </div>
  </div>
</template>
```

---

### 3. smartFavoritesList (Intelligent Favorites)

**Purpose**: Display favorites with AI-powered recommendations based on context

**Data Sources**:
- SBQQ__FavoriteProduct__c records
- Customer quote history
- Current Case description (NLP analysis for keywords)
- Seasonal patterns (e.g., construction season preferences)

**Wire Adapters**:
```javascript
@wire(getFavoritesWithRecommendations, {
  productId: '$currentProductFilter',
  accountId: '$accountId',
  caseDescription: '$caseDescription'
})
favoritesData;
```

**Apex Method** (calls Phase 13 FavoritesService):
```apex
@AuraEnabled(cacheable=true)
public static List<FavoriteRecommendationWrapper> getFavoritesWithRecommendations(
  Id productId,
  Id accountId,
  String caseDescription
) {
  // Get base favorites from FavoritesService
  FavoritesService favService = new FavoritesService();
  List<FavoritesService.FavoriteWrapper> baseFavorites = favService.getFavorites(productId);

  // Enhance with recommendation scoring
  List<FavoriteRecommendationWrapper> recommendations = new List<FavoriteRecommendationWrapper>();

  for (FavoritesService.FavoriteWrapper fav : baseFavorites) {
    FavoriteRecommendationWrapper rec = new FavoriteRecommendationWrapper();
    rec.favorite = fav;
    rec.confidenceScore = calculateRecommendationScore(fav, accountId, caseDescription);
    rec.reasonText = generateReasonText(fav, accountId);
    recommendations.add(rec);
  }

  // Sort by confidence score
  recommendations.sort();
  return recommendations;
}
```

**Component Template**:
```html
<template>
  <div class="favorites-list">
    <template if:true={hasRecommendations}>
      <div class="recommendation-header">
        <lightning-icon icon-name="utility:sparkles" size="small"></lightning-icon>
        <span>Recommended based on customer history and request</span>
      </div>
    </template>

    <template for:each={favorites} for:item="favorite">
      <div key={favorite.favoriteId} class="favorite-card">
        <!-- Confidence badge for high-scoring recommendations -->
        <template if:true={favorite.isHighConfidence}>
          <lightning-badge label={favorite.confidenceText} class="confidence-badge"></lightning-badge>
        </template>

        <div class="favorite-content">
          <h3 class="favorite-title">{favorite.containerType}</h3>

          <div class="favorite-details">
            <lightning-layout multiple-rows>
              <lightning-layout-item size="6">
                <div class="detail-item">
                  <lightning-icon icon-name="utility:product" size="x-small"></lightning-icon>
                  <span>Size: {favorite.equipmentSize}</span>
                </div>
              </lightning-layout-item>

              <lightning-layout-item size="6">
                <div class="detail-item">
                  <lightning-icon icon-name="utility:recycle_bin" size="x-small"></lightning-icon>
                  <span>Material: {favorite.materialType}</span>
                </div>
              </lightning-layout-item>

              <lightning-layout-item size="6">
                <div class="detail-item">
                  <lightning-icon icon-name="utility:number_input" size="x-small"></lightning-icon>
                  <span>Qty: {favorite.quantity}</span>
                </div>
              </lightning-layout-item>

              <lightning-layout-item size="6">
                <div class="detail-item">
                  <lightning-icon icon-name="utility:user" size="x-small"></lightning-icon>
                  <span>{favorite.ownership}</span>
                </div>
              </lightning-layout-item>
            </lightning-layout>
          </div>

          <!-- Recommendation reason -->
          <template if:true={favorite.reasonText}>
            <div class="recommendation-reason">
              <lightning-icon icon-name="utility:info" size="xx-small"></lightning-icon>
              <span class="reason-text">{favorite.reasonText}</span>
            </div>
          </template>
        </div>

        <div class="favorite-actions">
          <lightning-button
            label="Select"
            variant="brand"
            data-favorite-id={favorite.favoriteId}
            onclick={handleSelectFavorite}
          ></lightning-button>
          <lightning-button-icon
            icon-name="utility:preview"
            alternative-text="Preview"
            title="Preview Configuration"
            onclick={handlePreview}
          ></lightning-button-icon>
        </div>
      </div>
    </template>

    <!-- Empty state -->
    <template if:false={hasFavorites}>
      <div class="empty-state">
        <lightning-icon icon-name="custom:custom78" size="large"></lightning-icon>
        <p>No favorites available. Search the catalog or create a custom configuration.</p>
      </div>
    </template>
  </div>
</template>
```

---

### 4. slaCalculatorDisplay (Transparent SLA)

**Purpose**: Show SLA calculation transparently with explanation and alternatives

**Data Integration**:
- Calls Phase 11a SLAManagementService.determineSLA()
- Calls Phase 11b EntitlementMatchingService.getRelatedEntitlement()
- Shows business hours calculation from SLAManagementService

**Component Template**:
```html
<template>
  <div class="sla-calculator">
    <!-- Calculated SLA Date Display -->
    <div class="sla-result">
      <lightning-icon icon-name="utility:date_time" size="small"></lightning-icon>
      <div class="sla-date">
        <label>Earliest Service Date</label>
        <div class="date-value">{formattedSlaDate}</div>
      </div>

      <!-- Why this date? Expandable explanation -->
      <lightning-button-icon
        icon-name="utility:info"
        alternative-text="Why this date?"
        title="Show calculation details"
        onclick={toggleCalculationDetails}
        class="info-button"
      ></lightning-button-icon>
    </div>

    <!-- Expandable calculation details -->
    <template if:true={showCalculationDetails}>
      <div class="calculation-details">
        <h4>How We Calculated This Date</h4>

        <div class="calculation-step">
          <lightning-icon icon-name="utility:date_input" size="xx-small"></lightning-icon>
          <span>Today: {currentDate} at {currentTime}</span>
        </div>

        <template if:true={hasEntitlement}>
          <div class="calculation-step">
            <lightning-icon icon-name="utility:contract" size="xx-small"></lightning-icon>
            <span>Your contract guarantees: {entitlementGuarantee}</span>
          </div>

          <div class="calculation-step">
            <lightning-icon icon-name="utility:world" size="xx-small"></lightning-icon>
            <span>Service location timezone: {locationTimezone}</span>
          </div>

          <div class="calculation-step">
            <lightning-icon icon-name="utility:clock" size="xx-small"></lightning-icon>
            <span>Business hours: {businessHoursRange}</span>
          </div>

          <div class="calculation-step">
            <lightning-icon icon-name="utility:add" size="xx-small"></lightning-icon>
            <span>Adding {slaBusinessDays} business days</span>
          </div>
        </template>

        <template if:false={hasEntitlement}>
          <div class="calculation-step">
            <lightning-icon icon-name="utility:standard_objects" size="xx-small"></lightning-icon>
            <span>Using industry standard: {industryStandardSla}</span>
          </div>
        </template>

        <div class="calculation-result">
          <lightning-icon icon-name="utility:success" size="xx-small"></lightning-icon>
          <span><strong>Result: {formattedSlaDate}</strong></span>
        </div>

        <!-- Alternative options -->
        <template if:true={hasAlternatives}>
          <div class="alternatives-section">
            <h5>Need sooner?</h5>
            <template for:each={alternatives} for:item="alt">
              <div key={alt.id} class="alternative-option">
                <lightning-input
                  type="radio"
                  label={alt.label}
                  value={alt.value}
                  onchange={handleAlternativeSelect}
                ></lightning-input>
                <span class="alternative-details">{alt.details}</span>
              </div>
            </template>
          </div>
        </template>
      </div>
    </template>

    <!-- Override option for authorized users -->
    <template if:true={canOverrideSla}>
      <div class="override-section">
        <lightning-input
          type="checkbox"
          label="Override calculated SLA"
          checked={isOverridden}
          onchange={handleOverrideToggle}
        ></lightning-input>

        <template if:true={isOverridden}>
          <lightning-input
            type="date"
            label="Custom Service Date"
            value={overrideDate}
            min={minimumDate}
            onchange={handleOverrideDateChange}
          ></lightning-input>

          <lightning-textarea
            label="Override Reason (required)"
            value={overrideReason}
            required
            onchange={handleReasonChange}
          ></lightning-textarea>
        </template>
      </div>
    </template>
  </div>
</template>
```

**Controller Logic**:
```javascript
import { LightningElement, api, wire, track } from 'lwc';
import determineSLA from '@salesforce/apex/QuoteFavoritesController.determineSLA';
import getRelatedEntitlement from '@salesforce/apex/QuoteFavoritesController.getRelatedEntitleMent';

export default class SlaCalculatorDisplay extends LightningElement {
  @api quoteLineId;
  @api quoteId;
  @api accountTimezone;

  @track showCalculationDetails = false;
  @track slaDate;
  @track entitlement;
  @track calculationBreakdown;

  // Wire to get SLA calculation
  @wire(determineSLA, { parentQuoteLineId: '$quoteLineId' })
  wiredSla({ error, data }) {
    if (data) {
      this.slaDate = data;
      this.fetchCalculationDetails();
    }
  }

  // Wire to get entitlement
  @wire(getRelatedEntitlement, {
    quoteId: '$quoteId',
    parentqLineId: '$quoteLineId'
  })
  wiredEntitlement({ error, data }) {
    if (data) {
      this.entitlement = data;
      this.buildEntitlementExplanation();
    }
  }

  toggleCalculationDetails() {
    this.showCalculationDetails = !this.showCalculationDetails;
  }

  buildEntitlementExplanation() {
    // Build human-readable explanation of entitlement match
    if (this.entitlement) {
      const category = this.entitlement.Service_Guarantee_Category__c;
      const value = this.entitlement.Service_Guarantee_Category_Value__c;

      if (category === 'Days') {
        this.entitlementGuarantee = `${value} business day${value > 1 ? 's' : ''}`;
      } else if (category === 'Hours') {
        this.entitlementGuarantee = `${value} hour${value > 1 ? 's' : ''}`;
      }
    }
  }

  // Additional methods...
}
```

---

### 5. validationSummary (Inline Validation with Quick Fixes)

**Purpose**: Show validation errors with contextual resolution paths

**Component Template**:
```html
<template>
  <div class="validation-summary">
    <!-- Overall status -->
    <div class={validationStatusClass}>
      <lightning-icon icon-name={validationIcon} size="small"></lightning-icon>
      <div class="status-text">
        <h3>{validationStatusTitle}</h3>
        <p>{validationStatusMessage}</p>
      </div>
    </div>

    <!-- Progress bar -->
    <template if:true={showProgress}>
      <div class="validation-progress">
        <lightning-progress-bar
          value={validationScore}
          variant={progressVariant}
        ></lightning-progress-bar>
        <span class="progress-label">{progressLabel}</span>
      </div>
    </template>

    <!-- Categorized issues -->
    <template if:true={hasIssues}>
      <lightning-accordion allow-multiple-sections-open active-section-name={activeSections}>

        <!-- Blockers (must fix) -->
        <template if:true={hasBlockers}>
          <lightning-accordion-section name="blockers" label={blockersLabel}>
            <div class="issue-category blockers">
              <template for:each={blockers} for:item="issue">
                <c-validation-item
                  key={issue.id}
                  issue={issue}
                  severity="blocker"
                  onquickfix={handleQuickFix}
                  onnavigate={handleNavigateToField}
                ></c-validation-item>
              </template>
            </div>
          </lightning-accordion-section>
        </template>

        <!-- Warnings (should fix) -->
        <template if:true={hasWarnings}>
          <lightning-accordion-section name="warnings" label={warningsLabel}>
            <div class="issue-category warnings">
              <template for:each={warnings} for:item="issue">
                <c-validation-item
                  key={issue.id}
                  issue={issue}
                  severity="warning"
                  onquickfix={handleQuickFix}
                  onnavigate={handleNavigateToField}
                ></c-validation-item>
              </template>
            </div>
          </lightning-accordion-section>
        </template>

        <!-- Information (FYI) -->
        <template if:true={hasInfo}>
          <lightning-accordion-section name="info" label={infoLabel}>
            <div class="issue-category info">
              <template for:each={infoItems} for:item="issue">
                <c-validation-item
                  key={issue.id}
                  issue={issue}
                  severity="info"
                ></c-validation-item>
              </template>
            </div>
          </lightning-accordion-section>
        </template>
      </lightning-accordion>
    </template>

    <!-- All clear state -->
    <template if:false={hasIssues}>
      <div class="all-clear">
        <lightning-icon icon-name="utility:success" size="medium" variant="success"></lightning-icon>
        <h3>Quote is ready for pricing!</h3>
        <p>All validation checks passed. Click "Get Pricing" to continue.</p>
      </div>
    </template>
  </div>
</template>
```

---

### 6. validationItem (Individual Issue with Quick Fix)

**Purpose**: Display single validation issue with inline resolution

**Component Template**:
```html
<template>
  <div class={issueCardClass}>
    <!-- Issue severity indicator -->
    <div class="issue-indicator">
      <lightning-icon icon-name={severityIcon} size="small" variant={severityVariant}></lightning-icon>
    </div>

    <!-- Issue content -->
    <div class="issue-content">
      <div class="issue-header">
        <h4 class="issue-title">{issue.title}</h4>
        <lightning-badge label={issue.quoteLineReference}></lightning-badge>
      </div>

      <p class="issue-description">{issue.description}</p>

      <!-- Suggested fix -->
      <template if:true={issue.hasSuggestedFix}>
        <div class="suggested-fix">
          <lightning-icon icon-name="utility:info" size="xx-small"></lightning-icon>
          <span>{issue.suggestedFix}</span>
        </div>
      </template>
    </div>

    <!-- Actions -->
    <div class="issue-actions">
      <template if:true={issue.hasQuickFix}>
        <lightning-button
          label="Fix Now"
          variant="brand"
          onclick={handleQuickFix}
          icon-name="utility:settings"
        ></lightning-button>
      </template>

      <template if:false={issue.hasQuickFix}>
        <lightning-button
          label="Go to Field"
          variant="neutral"
          onclick={handleNavigate}
          icon-name="utility:forward"
        ></lightning-button>
      </template>

      <lightning-button-icon
        icon-name="utility:info"
        alternative-text="More Info"
        title="Learn more about this requirement"
        onclick={handleShowMoreInfo}
      ></lightning-button-icon>
    </div>
  </div>

  <!-- Quick fix modal -->
  <template if:true={showQuickFixModal}>
    <section role="dialog" class="slds-modal slds-fade-in-open">
      <div class="slds-modal__container">
        <header class="slds-modal__header">
          <h2 class="slds-text-heading_medium">Quick Fix: {issue.title}</h2>
        </header>

        <div class="slds-modal__content">
          <!-- Dynamic quick fix content based on issue type -->
          <template if:true={isRequiredFieldIssue}>
            <c-inline-field-editor
              field-name={issue.fieldName}
              field-label={issue.fieldLabel}
              current-value={issue.currentValue}
              record-id={issue.recordId}
              onvaluechange={handleFieldValueChange}
            ></c-inline-field-editor>
          </template>

          <template if:true={isEquipmentAvailabilityIssue}>
            <c-equipment-alternatives-selector
              current-size={issue.currentSize}
              available-sizes={issue.availableSizes}
              onselect={handleAlternativeSelect}
            ></c-equipment-alternatives-selector>
          </template>

          <!-- Add more quick fix templates for different issue types -->
        </div>

        <footer class="slds-modal__footer">
          <lightning-button label="Cancel" onclick={handleCloseModal}></lightning-button>
          <lightning-button
            label="Apply Fix"
            variant="brand"
            onclick={handleApplyFix}
            disabled={!canApplyFix}
          ></lightning-button>
        </footer>
      </div>
    </section>
    <div class="slds-backdrop slds-backdrop_open"></div>
  </template>
</template>
```

---

## State Management Strategy

### Lightning Message Service Channels

**quoteStateChannel.messageChannel-meta.xml**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningMessageChannel xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Quote state updates across components</description>
    <isExposed>true</isExposed>
    <lightningMessageFields>
        <fieldName>quoteId</fieldName>
        <description>Quote record ID</description>
    </lightningMessageFields>
    <lightningMessageFields>
        <fieldName>action</fieldName>
        <description>State change action: lineAdded, lineUpdated, lineDeleted, validated, priced</description>
    </lightningMessageFields>
    <lightningMessageFields>
        <fieldName>payload</fieldName>
        <description>Action-specific data</description>
    </lightningMessageFields>
    <masterLabel>Quote State Channel</masterLabel>
</LightningMessageChannel>
```

**Usage Example**:
```javascript
import { LightningElement, wire } from 'lwc';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import QUOTE_STATE_CHANNEL from '@salesforce/messageChannel/quoteStateChannel__c';

export default class ProductLineRow extends LightningElement {
  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    this.subscribeToQuoteChanges();
  }

  subscribeToQuoteChanges() {
    this.subscription = subscribe(
      this.messageContext,
      QUOTE_STATE_CHANNEL,
      (message) => this.handleQuoteStateChange(message)
    );
  }

  handleLineUpdate(event) {
    const message = {
      quoteId: this.quoteId,
      action: 'lineUpdated',
      payload: {
        lineId: this.lineId,
        updatedFields: event.detail.fields
      }
    };

    publish(this.messageContext, QUOTE_STATE_CHANNEL, message);
  }
}
```

---

## Data Integration Points

### Apex Controllers Mapping

Each LWC connects to refactored Apex services (Phases 10-13):

| Component | Apex Controller | Service Layer |
|-----------|----------------|---------------|
| smartFavoritesList | QuoteFavoritesController | FavoritesService |
| productCatalogGrid | QuoteFavoritesController | ProductConfigurationService |
| slaCalculatorDisplay | QuoteFavoritesController | SLAManagementService, EntitlementMatchingService |
| equipmentSizeSelector | QuoteFavoritesController | ProductConfigurationService.getSizes() |
| wasteStreamSelector | QuoteFavoritesController | ProductConfigurationService.getWasteStreams() |
| pricingComparison | QuoteProcurementController | (External pricing APIs) |
| validationSummary | QuoteProcurementController | ValidationService |
| quoteProductsTable | QuoteProcurementController | QuoteDataMapperService.buildWrapper() |

### Wire Adapters vs. Imperative Calls

**Use @wire for**:
- Read-only data that caches well (product catalog, favorites)
- Data that refreshes automatically (quote line status)
- Reactive data (changes trigger UI updates)

**Use imperative calls for**:
- Data mutations (create, update, delete)
- Actions requiring user confirmation
- Error handling with user feedback

---

## Performance Optimization

### 1. Lazy Loading Strategy

Load components progressively:
- **Initial Load**: Header, sidebar, first step of wizard only
- **On Demand**: Load Advanced Builder only when user clicks "Advanced Mode"
- **Progressive**: Load validation panel only when validation runs
- **Conditional**: Load pricing comparison only after pricing succeeds

### 2. Caching Strategy

```javascript
// Cache product catalog for session
import { LightningElement, wire } from 'lwc';
import getProducts from '@salesforce/apex/QuoteFavoritesController.getProducts';

export default class ProductCatalogGrid extends LightningElement {
  @wire(getProducts, {}) // Empty params = cache for session
  wiredProducts;

  // Refresh cache manually when needed
  refreshCatalog() {
    return refreshApex(this.wiredProducts);
  }
}
```

### 3. Optimistic UI Updates

Update UI immediately, sync with server in background:
```javascript
handleQuantityChange(event) {
  // Update UI immediately
  this.quoteLine.quantity = event.target.value;

  // Save to server (optimistic)
  updateQuoteLine({
    lineId: this.lineId,
    quantity: event.target.value
  })
  .then(() => {
    // Success - already reflected in UI
    this.showToast('Saved', 'Quantity updated', 'success');
  })
  .catch(error => {
    // Rollback UI on error
    this.quoteLine.quantity = this.originalQuantity;
    this.showToast('Error', error.body.message, 'error');
  });
}
```

---

## Responsive Design Strategy

### Breakpoints

```css
/* Mobile first */
.quote-flow-container {
  display: flex;
  flex-direction: column;
}

/* Tablet: 768px */
@media (min-width: 768px) {
  .quote-flow-container {
    flex-direction: row;
  }

  .quote-flow-sidebar {
    width: 300px;
  }
}

/* Desktop: 1024px */
@media (min-width: 1024px) {
  .quote-flow-main {
    max-width: 1200px;
  }
}

/* Large desktop: 1440px */
@media (min-width: 1440px) {
  .quote-products-table {
    /* Show all columns */
  }
}
```

### Mobile Considerations

- **Vertical Navigation**: Collapse to hamburger menu on mobile
- **Tables**: Switch to card layout on mobile (product lines become stacked cards)
- **Modals**: Full-screen on mobile, centered on desktop
- **Forms**: Single column on mobile, multi-column on desktop

---

## Accessibility Strategy

### ARIA Labels and Roles

```html
<div role="region" aria-label="Quote Configuration">
  <h2 id="config-heading">Service Configuration</h2>

  <div role="form" aria-labelledby="config-heading">
    <lightning-input
      label="Service Address"
      aria-required="true"
      aria-describedby="address-help"
    ></lightning-input>

    <div id="address-help" class="slds-form-element__help">
      Address where equipment will be placed
    </div>
  </div>
</div>
```

### Keyboard Navigation

- **Tab Order**: Logical flow through form fields
- **Escape Key**: Close modals and dropdowns
- **Enter Key**: Submit forms, advance wizard steps
- **Arrow Keys**: Navigate through lists and tables
- **Shortcuts**: Ctrl+S to save, Ctrl+P to price, etc.

### Screen Reader Support

- Dynamic content changes announced via aria-live regions
- Form validation errors announced immediately
- Loading states announced ("Loading pricing...")
- Success/error toasts readable by screen readers

---

## Testing Strategy

### Unit Tests (Jest)

Each component has comprehensive tests:
```javascript
// slaCalculatorDisplay.test.js
import { createElement } from 'lwc';
import SlaCalculatorDisplay from 'c/slaCalculatorDisplay';
import determineSLA from '@salesforce/apex/QuoteFavoritesController.determineSLA';

jest.mock('@salesforce/apex/QuoteFavoritesController.determineSLA');

describe('c-sla-calculator-display', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('displays calculated SLA date', async () => {
    const mockSlaDate = '2025-03-15T09:00:00.000Z';
    determineSLA.mockResolvedValue(mockSlaDate);

    const element = createElement('c-sla-calculator-display', {
      is: SlaCalculatorDisplay
    });
    element.quoteLineId = 'a0X5000000xxxxx';
    document.body.appendChild(element);

    await Promise.resolve(); // Wait for wire

    const dateDisplay = element.shadowRoot.querySelector('.date-value');
    expect(dateDisplay.textContent).toBe('March 15, 2025 at 9:00 AM');
  });

  it('shows calculation details when info button clicked', async () => {
    const element = createElement('c-sla-calculator-display', {
      is: SlaCalculatorDisplay
    });
    document.body.appendChild(element);

    const infoButton = element.shadowRoot.querySelector('.info-button');
    infoButton.click();

    await Promise.resolve();

    const details = element.shadowRoot.querySelector('.calculation-details');
    expect(details).toBeTruthy();
  });
});
```

### Integration Tests

Test component interactions via LMS:
```javascript
it('publishes line update when quantity changed', async () => {
  const publishSpy = jest.fn();
  publish.mockImplementation(publishSpy);

  const element = createElement('c-product-line-row', {
    is: ProductLineRow
  });
  document.body.appendChild(element);

  const quantityInput = element.shadowRoot.querySelector('lightning-input[data-field="quantity"]');
  quantityInput.value = 5;
  quantityInput.dispatchEvent(new CustomEvent('change'));

  await Promise.resolve();

  expect(publishSpy).toHaveBeenCalledWith(
    expect.anything(),
    QUOTE_STATE_CHANNEL,
    expect.objectContaining({
      action: 'lineUpdated',
      payload: expect.objectContaining({
        updatedFields: expect.objectContaining({ quantity: 5 })
      })
    })
  );
});
```

---

## Next Steps

1. **Review component architecture** with stakeholders
2. **Create visual mockups** (wireframes) for key components
3. **Build prototype** of Quick Quote Wizard (highest priority)
4. **User testing** with CSRs on prototype
5. **Iterate** based on feedback
6. **Build remaining components** in priority order
7. **Integration testing** with full data model
8. **Deployment** in phases (wizard first, then advanced builder)

---

## Appendix: Component File Structure

```
force-app/main/default/lwc/
├── quoteFlowContainer/
│   ├── quoteFlowContainer.html
│   ├── quoteFlowContainer.js
│   ├── quoteFlowContainer.css
│   └── quoteFlowContainer.js-meta.xml
│
├── quickQuoteWizard/
│   ├── quickQuoteWizard.html
│   ├── quickQuoteWizard.js
│   ├── quickQuoteWizard.css
│   └── quickQuoteWizard.js-meta.xml
│
├── smartFavoritesList/
│   ├── smartFavoritesList.html
│   ├── smartFavoritesList.js
│   ├── smartFavoritesList.css
│   └── smartFavoritesList.js-meta.xml
│
├── slaCalculatorDisplay/
│   ├── slaCalculatorDisplay.html
│   ├── slaCalculatorDisplay.js
│   ├── slaCalculatorDisplay.css
│   └── slaCalculatorDisplay.js-meta.xml
│
├── validationSummary/
│   ├── validationSummary.html
│   ├── validationSummary.js
│   ├── validationSummary.css
│   └── validationSummary.js-meta.xml
│
└── [30+ additional components...]
```

Each component follows Lightning Design System patterns and connects to the refactored service layer.
