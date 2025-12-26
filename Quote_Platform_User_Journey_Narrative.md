# Quote Platform User Journey: A Comprehensive Narrative for UX Design

## Document Purpose

This narrative describes the complete user journey through the Waste Management Quote Platform, a complex Salesforce-based system for creating, configuring, and pricing service quotes for commercial and industrial waste management services. This document is designed to support Figma design work by providing deep context about user workflows, decision points, data flows, and opportunities for UX improvement.

---

## Executive Summary: The Platform's Purpose

The Quote Platform serves as the critical bridge between customer service requests and executable service orders. Users navigate through a multi-state workflow to transform a customer's waste management need—whether for a 20-yard dumpster rental, compactor service, recycling program, or specialized waste disposal—into a fully configured, priced, and approved quote that can be converted into service orders dispatched to field operations.

The platform manages extraordinary complexity: timezone-aware service level agreements, multi-vendor pricing comparisons, entitlement-based pricing tiers, equipment availability constraints, regulatory compliance requirements, and intricate service configurations. Yet this complexity must be navigated by users who need to respond to customers quickly, often while on phone calls, making speed and clarity paramount.

---

## User Personas

### Primary Persona: The Customer Service Representative (CSR)

**Who They Are:**
Customer Service Representatives are the primary users of this platform. They work in call centers or regional offices, taking inbound calls from existing and prospective customers who need waste management services. They are measured on call handle time, quote accuracy, and conversion rates. Many are relatively new to waste management industry terminology and rely heavily on system guidance.

**Their Goals:**
- Respond to customer requests quickly (target: complete quote in under 10 minutes)
- Configure services accurately to avoid service failures and customer dissatisfaction
- Find the best pricing available given the customer's entitlements and contract terms
- Ensure all regulatory and operational requirements are captured
- Create quotes that field operations can actually fulfill

**Their Pain Points:**
- Need to understand complex pricing models while customer is on the phone
- Must remember which fields are required for different service types
- Face anxiety about selecting wrong equipment sizes or service configurations
- Struggle to explain price differences between similar services to customers
- Often unclear why system is showing errors or blocking progression
- Need to switch between multiple screens to gather information

### Secondary Persona: The Sales Account Manager

**Who They Are:**
Account Managers work with larger commercial and industrial accounts, creating complex multi-service quotes for facilities like manufacturing plants, retail chains, or construction sites. They typically work on quotes over multiple sessions, coordinating with pricing specialists, operations managers, and sometimes customer procurement teams.

**Their Goals:**
- Create comprehensive service proposals that address all customer needs
- Leverage corporate entitlements and contract terms to provide competitive pricing
- Customize services to meet specific operational requirements (schedules, locations, regulatory compliance)
- Save and reuse common service configurations for multi-location customers
- Present professional, detailed quotes that support complex sales cycles

**Their Pain Points:**
- Need to configure multiple similar services efficiently (same service, different locations)
- Must track which configurations have been priced and approved
- Require flexibility to override standard configurations for special situations
- Need to explain complex pricing to customers who are comparing multiple vendors
- Want to save successful configurations as templates for future quotes

### Tertiary Persona: The Operations Coordinator

**Who They Are:**
Operations Coordinators review and approve quotes that have operational complexity or exceptions. They ensure that quoted services can actually be delivered given fleet availability, driver schedules, disposal facility access, and regulatory requirements.

**Their Goals:**
- Quickly review quotes flagged for operational approval
- Identify potential service delivery issues before quote approval
- Provide feedback to CSRs about why certain configurations won't work
- Track quotes requiring special handling (manual dispatch, COD, prepayment required)

**Their Pain Points:**
- Need visibility into why a quote was flagged for review
- Want to provide inline feedback without rejecting entire quote
- Require context about customer history and service patterns
- Need to communicate operational constraints clearly to sales teams

---

## The Business Context: When and Why Quotes Are Created

### Scenario 1: New Service Request (Most Common)

A customer calls requesting waste management service. They might say: "I need a dumpster for a construction project" or "We're opening a new restaurant location and need weekly trash pickup." The CSR must quickly determine:

- **What type of service?** (Roll-off, front-load, compactor, recycling, specialty waste)
- **What equipment is needed?** (Container type, size, features like lockable lids)
- **What material is being disposed?** (General waste, construction debris, food waste, recyclables, hazardous materials)
- **Where is the service?** (Customer location, which affects pricing, SLA, and equipment availability)
- **When is it needed?** (Service start date, which triggers SLA calculations and availability checks)
- **How long is service needed?** (Duration affects pricing model and container ownership)
- **What's the service schedule?** (One-time pickup, weekly service, on-call, seasonal)

Each answer constrains subsequent choices. For example, if the customer needs hazardous waste disposal, only certain container types are valid, only licensed disposal facilities can be used, and additional regulatory documentation is required.

### Scenario 2: Service Amendment

An existing quote needs modification. Perhaps pricing changed, the customer requested additional services, or operational review identified issues requiring reconfiguration. The user must understand what was previously configured, what's changing, and how changes affect pricing and service delivery. The system must track what was originally quoted versus amended values, particularly important for contract compliance and audit trails.

### Scenario 3: Service Correction

A quote was created incorrectly—wrong equipment size, wrong location, wrong pricing tier. The user must create a corrected quote while understanding why the original was wrong to avoid repeating the mistake. The system should ideally help users learn from corrections by highlighting what changed and why.

### Scenario 4: Quote-Only Requests

Some customers need quotes for budgeting or procurement processes without immediate service intent. These quotes follow similar configuration paths but have different approval workflows and don't trigger operational scheduling. Users need clear indication that these are quote-only to avoid accidental service dispatches.

### Scenario 5: Multi-Service Proposals

Large accounts need multiple services configured as a single proposal. For example, a shopping mall might need front-load service for 15 tenant spaces, compactor service for the food court, recycling service for the entire property, and specialty service for the maintenance shop. The user must efficiently configure similar services with variations, maintain consistency across service lines, and present unified pricing.

---

## The Quote Creation Journey: A Step-by-Step Narrative

### Entry Point: From Case to Quote

The journey begins before the Quote Platform opens. A customer inquiry creates a **Case** in the system—a customer service record capturing the initial request. From this Case, an **Opportunity** is created, representing the sales potential. Only from an Opportunity can a Quote be initiated.

**Current Experience:**
The user navigates through Salesforce standard interfaces to create Case → Opportunity → Quote. This involves multiple clicks, screen transitions, and data entry across different interfaces. By the time the Quote Platform opens, the user has already invested 2-3 minutes and may have lost conversation context with the customer.

**Design Opportunity:**
The entry flow should be streamlined for common scenarios. If a customer calls saying "I need a dumpster," the ideal experience would allow the CSR to click "New Service Quote" and have Case/Opportunity/Quote created in the background with sensible defaults, allowing them to jump directly into product selection. The system already knows the customer (from phone number lookup or account search), the account's location and entitlements, and the current date/time—all of which should auto-populate rather than require manual entry.

---

### State 1: Product Selection (The Favorites Experience)

The Quote Platform opens to the **Product Selection** state, displaying the QuoteFavorites component. This is the user's first meaningful interaction with quote configuration.

#### What the User Sees

The interface presents two primary paths:

**Path A: Select from Favorites**
A list of saved service configurations appears—these are pre-built "packages" combining container type, equipment size, waste material, and common configuration attributes. For example:
- "20 YD Roll-Off - Construction Debris - 7 Days"
- "8 YD Front Load - General Waste - 2x/Week Service"
- "40 YD Compactor - Cardboard - Customer Owned"

Each favorite shows the container type, material type, equipment size, and quantity. The user can click a favorite to instantly add it to the quote as a configured quote line.

**Path B: Configure from Scratch**
Alternatively, the user can search for products, browsing or searching through hundreds of equipment types. When a product is selected, the interface expands to show:
- **Equipment Size Selector**: A dropdown showing valid sizes for this equipment (e.g., 10 YD, 20 YD, 30 YD, 40 YD)
- **Waste Stream Selector**: A categorized list of materials (General Waste → MSW, Commercial Waste, Industrial Waste; Construction → Wood, Concrete, Mixed C&D; Recyclables → Cardboard, Commingled, etc.)
- **Quantity**: How many containers

#### What's Happening Behind the Scenes

The system is performing complex filtering based on:
- **Product Family**: Only showing equipment types compatible with the customer's account type
- **Configuration Attributes**: Reading SBQQ__ConfigurationAttribute__c records to determine which equipment sizes are valid (the SDT-21768 fix ensures exact picklist matching rather than pattern matching)
- **Waste Stream Relationships**: Querying two-stage product option hierarchy (categories → materials) to build the waste stream selector
- **Account Context**: Considering the customer's location, contract terms, and service history to potentially pre-select or recommend options

#### The User's Mental Model vs. System Reality

**What Users Think:** "I'm selecting a product."

**What's Actually Happening:** The system is creating a **parent quote line** (SBQQ__QuoteLine__c) with SBQQ__ProductOption__c = null, which will serve as the container for a complex bundle of related quote lines. This parent line will have:
- Product reference (the container type)
- Equipment size (from configuration attribute)
- Material reference (as a child quote line in the bundle)
- Quantity
- Various configuration fields that will be populated in later states

The distinction between "selecting a product" and "creating a quote line bundle" is invisible to users but critical to the system's data model. This abstraction works well when it works, but becomes confusing when users encounter errors like "This quote line is missing required product options" because they don't understand the bundle concept.

#### Decision Point: Favorites vs. Custom Configuration

**When Favorites Work Well:**
- Repeat customers ordering standard services
- Common service configurations that rarely change
- Users who are still learning the product catalog

**When Favorites Fall Short:**
- First-time customer with unique requirements
- Specialty waste requiring specific disposal methods
- Services requiring non-standard configurations
- New equipment types not yet in favorites library

**Current Pain Point:**
The system doesn't intelligently recommend favorites based on customer history or current request context. A customer calling for "the same service as last time" still requires the user to remember which favorite matches their previous order, or to abandon favorites and manually search.

**Design Opportunity:**
Show "Recent for this Customer" as a third option alongside Favorites and Search. Use the Case description and customer history to recommend relevant favorites with confidence scoring: "Based on this customer's history and request for 'construction debris,' we recommend: 20 YD Roll-Off - Construction Debris (used 14 times previously)."

#### Adding the Product to the Quote

When the user clicks "Add to Quote" (whether from favorite or custom configuration), several things happen:

1. **Quote Line Creation**: A parent quote line is inserted into the database
2. **SLA Calculation Trigger**: The system immediately begins calculating when service can begin (more on this later)
3. **Validation Begins**: The quote line is checked for required fields, valid configurations, and business rule compliance
4. **Material Bundle Creation**: If a waste stream was selected, a child quote line is created for the material product
5. **Tab Creation**: The QuoteCreationWrapper creates a new tab for this product in the interface

The user sees a new tab appear with the product name (e.g., "20 YD Roll-Off") and the interface transitions to show this product in the configured products table.

#### Multi-Product Quotes

For users creating multi-service proposals, the Product Selection state remains accessible via vertical navigation. They can click back to "Product Selection" and add additional products. Each product gets its own tab, allowing the user to configure multiple services in parallel.

**Current Experience:**
Users must fully configure each product before adding the next, or risk losing context about which tab represents which service. With 5+ products in a quote, tab management becomes cognitively demanding.

**Design Opportunity:**
Allow users to "quick add" multiple products in a batch ("Add 3x 8YD Front Load for different locations") and then configure them individually. Provide better tab labels that include location or other distinguishing information beyond product name.

---

### State 2: Overview (Understanding What Was Created)

After adding a product, the interface can transition to the **Overview** state via the vertical navigation. This is where users see the **QuoteProducts** component—a complex table showing all configured quote lines.

#### What the User Sees

A data-dense table with columns for:
- **Expand/Collapse**: Chevron icon to show/hide child quote lines (accessories, materials, etc.)
- **Product Alerts**: A cluster of icons indicating various conditions
- **Quantity**: Editable quantity field
- **Equipment Type**: The product name
- **Equipment Size**: The configured size
- **Material**: The waste stream for this service
- **Duration**: Service duration (days, weeks, months)
- **Schedule**: Service frequency (daily, weekly, on-call, etc.)
- **Start Date**: When service begins
- **End Date**: When service ends
- **Customer Approval**: Whether customer has approved this line
- **Line Details**: Button to expand full configuration modal

Each quote line also displays action buttons:
- **Edit Product**: Opens detailed configuration modal
- **Add/Modify Position**: Sets GPS coordinates for service location
- **Supplemental Instructions**: Adds driver instructions, access codes, etc.
- **Get Price**: Triggers vendor pricing request
- **Financial Details**: Shows cost/price breakdown
- **Create/View Orders**: Links to operational order creation
- **Approve Quote-Only**: For quote-only lines, marks as approved

#### What the User Is Trying to Accomplish

At this stage, the user is performing **verification and contextualization**. They're asking themselves:
- "Did the system create what I intended?"
- "Are all the required services included?"
- "What's missing that needs to be added?"
- "What looks wrong that needs to be corrected?"

This is a critical pause point between initial configuration and detailed customization. Users need to build a mental model of the quote structure before diving into specifics.

#### The Alert Icon Problem

The table can display up to six different alert icons per quote line:

1. **COD Indicator** (utility:page, error): Cash on delivery requested
2. **Line Error Indicator** (utility:warning): Validation errors on this line
3. **Prepayment Required** (utility:moneybag, error): Vendor requires deposit
4. **Manual Dispatch** (utility:dialing): Requires manual scheduling, not automated
5. **Procurement Errors** (utility:alert): Issues with vendor procurement
6. **NTE Warning** (utility:alert): Not-to-exceed amount concerns

**Current Experience:**
Icons appear in a cluster without clear hierarchy or explanation. Users must hover over each icon to read tooltip text explaining the condition. With multiple quote lines, each having multiple icons, the table becomes a sea of red/orange indicators requiring investigation.

A line might show: 🔶📄💰📞⚠️

The user must decode: "This line has a procurement error, is COD, requires prepayment, needs manual dispatch, and has an NTE warning." But the critical question—"Can this quote proceed or is it blocked?"—isn't immediately clear.

**Design Opportunity:**
Implement visual hierarchy for alerts:
- **Blockers** (quote cannot proceed): Large, red, left-most position, with "Fix Required" label
- **Warnings** (quote can proceed but may have issues): Medium, orange, with "Review Recommended" label
- **Information** (for awareness only): Small, blue, with "FYI" label

Group related alerts and provide one-click resolution paths. For example, if a line shows "Prepayment Required," provide an inline "Configure Prepayment" button rather than making the user hunt through menus.

#### The Expand/Collapse Complexity

Quote lines can have child lines (materials, accessories, keys for padlocks, etc.). The expand arrow reveals these children, which inherit some but not all properties from the parent.

**User Confusion:**
It's not always clear which properties are inherited vs. independent. If a user changes the parent's start date, will children update automatically? (Answer: Yes, in most cases, but not always—it depends on the relationship type and configuration rules.)

The visual hierarchy (indentation, styling) is subtle. Users sometimes edit child lines thinking they're editing the parent, or vice versa.

**Design Opportunity:**
Use stronger visual distinction between parent and child lines. Consider a nested table or card-based layout that makes the hierarchy obvious. Provide clear feedback when editing: "Changing parent start date will update 3 child lines" with option to review before applying.

---

### State 3: Order Configuration (The Details Matter)

Via vertical navigation, users move to the **Service** state, which displays the **QuoteOrderDetails** component. This is where the quote transforms from a product list into a service specification.

#### What Happens in Order Configuration

This state is about specifying **operational details**—the information field operations needs to actually deliver the service:

**Location Specifics:**
- **Service Address**: Street address where equipment will be placed (may differ from billing address)
- **GPS Coordinates**: Precise lat/long for driver navigation and geofencing
- **Access Instructions**: "Gate code 1234, go to rear dock, avoid front entrance during business hours"
- **Placement Instructions**: "Place dumpster in marked zone, 10 feet from building, leave clear path to door"
- **Site Contact**: On-site person to call if issues arise, may differ from account contact

**Service Timing:**
- **Start Date**: When service begins (auto-calculated from SLA but editable)
- **End Date**: When service ends or final pickup occurs
- **Service Schedule**: Specific days/times for recurring service
- **Schedule Frequency**: How often service occurs (daily, weekly, bi-weekly, monthly, seasonal, on-call)
- **Frequency Interval**: If weekly, which day? If monthly, which week and day?

**Equipment Configuration:**
- **Ownership**: Company-owned vs. customer-owned equipment (affects pricing and responsibilities)
- **Equipment Style**: Apartment-style, slant-top, tall, split-container, cathedral, etc. (based on equipment type—SDT-22447 filters invalid combinations)
- **Equipment Features**: Lockable lid, wheels, drain plugs, specific colors, branding

**Service Attributes:**
- **Occurrence Type**: Recurring vs. one-time vs. on-call
- **Duration**: Service contract duration (affects pricing and container allocation)
- **Trigger Type**: What triggers service (time-based, volume-based, on-call)
- **Special Handling**: Hazmat certification, COD, prepayment, manual dispatch flags

**Financial Attributes:**
- **Cost Model**: Per-haul, per-day, per-month, per-ton, tiered pricing
- **Price UOM**: Unit of measure for pricing
- **Cost UOM**: Unit of measure for cost (may differ from price)
- **NTE Amount**: Not-to-exceed amount for variable pricing

#### The Cognitive Load Problem

The Order Configuration state can present 30+ fields depending on product type and service configuration. Many fields have complex interdependencies:

- If "Occurrence Type" = "Recurring", then "Schedule Frequency" becomes required
- If "Ownership" = "Customer Owned", then "Equipment Features" may be locked
- If "Duration" > 30 days, then pricing model may shift from per-day to per-month
- If "Material" = (hazardous waste type), then "Regulatory Certifications" section appears

**Current Experience:**
All fields are presented in a long form. Required vs. optional isn't always visually distinct. Users often scroll past important fields or spend time on optional fields while missing required ones. Error messages appear at top of form, requiring scrolling to find the problematic field.

**Design Opportunity:**
Implement **progressive disclosure** and **smart defaults**:

1. **Start with Critical Three**: Location, Start Date, Schedule. These three fields drive most downstream calculations.
2. **Reveal Contextual Fields**: Only show "Schedule Frequency" if service is recurring. Only show "Equipment Features" if they're configurable for this equipment type.
3. **Pre-fill from Context**: If the account has a default service address on file, auto-populate it. If this is a repeat customer, suggest their previous schedule.
4. **Validation as You Go**: Validate fields inline with helpful messages: "Start date must be at least 3 business days out due to SLA requirements. Earliest available: March 15."
5. **Section Completion Indicators**: Show progress: "Required Details: 3/5 complete" with checklist showing what's missing.

#### The Hidden SLA Calculation

Behind the scenes, one of the most complex processes in the system is running: **Service Level Agreement calculation**.

When the user selects a start date or location, the system:

1. **Queries Entitlements**: Runs the 6-level priority matching logic to find relevant entitlement (Phase 11b code):
   - Priority 1: Project Code + Location match
   - Priority 2: Project Code + Parent Account match
   - Priority 3: Duration + Container + Location match
   - Priority 4: Duration + Location match
   - Priority 5: Duration + Container + Account match
   - Priority 6: Duration + Account match

2. **Determines SLA Calculation Method**: Entitlement-based or industry standard

3. **Calculates Business Hours**: Gets business hours for the customer's timezone (Phase 11a code):
   - Queries timezone from account location
   - Finds matching business hours record ("WM SBS - America/Los_Angeles")
   - Handles timezone offset calculations

4. **Applies Service Guarantee Category**: If entitlement found:
   - "Hours": Adds specified hours to current time
   - "Days": Adds business days considering before/after rules and specific time thresholds
   - Adjusts for 9:00 AM, 10:00 AM, 13:00, 14:00, 15:00, 23:59 boundaries (SDT-24917, SDT-45007, SDT-47963)

5. **Checks for Haul-Away Exception**: If service type is haul-away (SDT-41473, SDT-42045), returns current time immediately

6. **Sets Start Date**: Auto-populates the calculated SLA date as the earliest available service date

**What the User Experiences:**
The Start Date field shows a date. If they try to select an earlier date, they might see an error: "Service cannot begin before March 15 due to SLA requirements."

But *why* March 15? Is it based on:
- Equipment availability?
- Entitlement terms?
- Driver scheduling?
- Vendor lead time?
- Business hours rules?

The user has no visibility into this calculation. They can't explain to a customer why service can't start sooner. They can't override it (even if the customer is willing to pay premium for expedited service).

**Design Opportunity:**
Make SLA calculations **transparent and actionable**:

1. **Explain the Date**: "Earliest service date: March 15 (based on your contract's 3-business-day service guarantee for this location)"
2. **Show the Calculation**: Provide an expandable "Why this date?" that shows: "Today: March 10, 2PM → Add 3 business days (your entitlement) → March 15, 9AM (service time)"
3. **Offer Alternatives**: "Need sooner? Expedited service available March 12 for $50 premium" or "Check equipment availability for earlier date"
4. **Allow Informed Overrides**: For authorized users, allow override with reason code and customer acknowledgment

---

### State 4: Accessory Selection

Within the Order Configuration flow (or sometimes as a modal from the QuoteProducts table), users can add **accessories and product options**.

#### What Are Accessories?

Accessories are add-on products that attach to the primary service:
- **Locks and Keys**: Padlocks for securing containers, with keys
- **Wheels**: Mobility accessories for containers
- **Drain Plugs**: For liquid waste management
- **Liners**: Disposable liners for certain container types
- **Signage**: Recycling instructions, hazmat warnings, customer branding
- **Additional Services**: Extra pickups beyond schedule, container cleaning, tipping fees

Each accessory has its own configuration:
- **Quantity**: Often defaulted but editable (e.g., padlock quantity editable = false, keys quantity editable = true)
- **Occurrence Type**: One-time, recurring, or per-service
- **Pricing**: Separate unit price, may be per-item, per-service, or monthly

#### The Padlock-Key Relationship

A specific complexity: If a user adds a padlock accessory, the system must also add a key accessory (SDT-23055, SDT-31752, SDT-31973). The key is a child of the padlock, which is itself a child of the parent container line.

This creates a three-level hierarchy:
```
Parent: 20 YD Roll-Off
  └─ Child: Padlock (accessory)
       └─ Grandchild: Keys (accessory of accessory)
```

**User Implications:**
- If user removes the padlock, keys must also be removed (or orphaned keys cause errors)
- Keys have special pricing rules (often free with padlock, charged separately if ordered standalone)
- Key end date = key start date (they're delivered once, not recurring, even if padlock is recurring)

**Current Experience:**
Users add padlock, see a key line appear automatically, sometimes get confused about why they can't configure the key separately, occasionally try to delete the key (which may succeed or fail depending on system state).

**Design Opportunity:**
Show accessory relationships visually as bundles: "Padlock + 2 Keys" as a single selectable unit with expandable details. Clearly indicate "Included with Padlock" for automatic accessories. Prevent confusion by not allowing separate removal of dependent items—remove the bundle as a unit.

---

### State 5: Summary and Validation

After configuration, users navigate to the **Summary** state (QuoteSummaryConfirmation component). This is the final review before pricing.

#### What the User Sees

A comprehensive summary of the entire quote:
- **Account Information**: Customer name, address, contact
- **Quote Metadata**: Quote number, creation date, valid until date
- **Line Item Summary**: All quote lines with configurations (read-only view)
- **Total Quantity**: Total number of containers/services
- **Validation Status**: Pass/fail indicators for all validation rules
- **Approval Status**: Which lines need additional approval
- **Next Steps**: What needs to happen before pricing can be requested

#### Validation Hell

This is where users discover configuration problems. The system runs comprehensive validation checks:

**Required Field Validation:**
- "Quote line 3 is missing required field: Service Address"
- "Quote line 1 is missing required field: Waste Stream"

**Business Rule Validation:**
- "Hazmat waste requires certified disposal facility (not selected)"
- "Customer credit status requires prepayment for services over $1000"
- "COD not available for recurring services"
- "Selected equipment size not available at this location"

**Inventory Validation:**
- "20 YD containers not currently available in this region (12 in use, 10 capacity)"
- "Requested start date conflicts with existing asset allocation"

**Regulatory Validation:**
- "This waste type requires EPA profile number"
- "Service location requires city permit (not on file)"

**Pricing Validation:**
- "No pricing configured for this product-location combination"
- "Multi-vendor pricing required but only one vendor available"

**Current Experience:**
Errors appear as a list of text messages. Users must mentally map each message back to specific quote lines and fields. Fixing one error and re-validating sometimes reveals new errors (cascading validation). Users describe this as "whack-a-mole validation."

Error messages use technical field names that don't match the UI labels: "Field SBQQ__StartDate__c is required" instead of "Start Date is required."

**Design Opportunity:**
Implement **contextual, actionable validation**:

1. **Inline Validation**: Validate as users configure, showing errors immediately in context
2. **Smart Error Messages**: "Service address is required for operational scheduling. Add address now?" with inline edit capability
3. **Grouped Errors**: "Quote Line 3 has 4 issues" with expandable list and "Fix All" workflow
4. **Progressive Validation**: Run basic validation first (required fields), then business rules, then inventory/pricing. Don't overwhelm with all errors at once.
5. **Suggested Fixes**: "Equipment not available in size 20YD. Available alternatives: 15YD, 30YD. Switch to 30YD?"
6. **Validation Progress**: Show validation score: "Quote is 85% ready for pricing. 3 issues remaining."

#### The Amendment/Correction Context

For amended or corrected quotes, the Summary state must show **what changed**:
- Original values vs. new values
- Reason for change
- Impact on pricing
- Impact on already-scheduled services

**Current Experience:**
Change tracking is minimal. Users must manually compare original quote to amended quote to understand differences. This is particularly problematic when Operations asks "What changed from the original quote?" and the CSR has to reconstruct the history.

**Design Opportunity:**
Provide **diff view** for amendments: side-by-side comparison with highlighted changes, change reason annotations, and pricing impact calculations. For corrections, show "Original (incorrect): 20YD → Corrected: 30YD" with explanation field.

---

### State 6: Pricing (The Moment of Truth)

After validation passes, users navigate to the **Pricing Response** state. This is where the quote becomes a proposal with actual costs and prices.

#### The Pricing Request

When the user clicks "Get Pricing," the system:

1. **Determines Vendor Strategy**: Single vendor vs. multi-vendor pricing
2. **Calls External Pricing APIs**: Sends quote details to vendor systems (STP API, multi-vendor integrations)
3. **Receives Pricing Responses**: Gets back cost, price, availability, lead time
4. **Applies Business Rules**: Margin requirements, approval thresholds, customer-specific pricing
5. **Updates Quote Lines**: Populates cost and price fields on each quote line
6. **Calculates Totals**: Sums up total cost, total price, total margin

**What Users Wait For:**
Pricing can take 5-60 seconds depending on:
- Number of quote lines
- Number of vendors being queried
- External API response times
- Complexity of pricing calculations

**Current Experience:**
Users see a loading spinner. If pricing fails, they get an error: "Pricing request failed. Contact support." No indication of which vendor failed, why it failed, or what to do next.

If pricing succeeds but some lines have $0 price, it's unclear whether that's intentional (free accessory), an error (pricing not configured), or a failure (API timeout for that specific line).

**Design Opportunity:**
Provide **transparent pricing feedback**:

1. **Progress Indicators**: "Requesting pricing from 3 vendors... Vendor A: Complete ($450), Vendor B: In Progress, Vendor C: In Progress"
2. **Partial Results**: Allow users to review successful pricing while waiting for remaining vendors
3. **Error Context**: "Vendor B pricing failed: Product code not recognized in vendor system. This may require manual pricing. Contact pricing team or continue with Vendor A pricing."
4. **Pricing Breakdown**: Show how price was calculated: "Base Rate: $200 + Fuel Surcharge: $25 + Environmental Fee: $15 = Total: $240"
5. **Margin Alerts**: "Warning: Margin on this line is 12%, below company minimum of 15%. Requires manager approval."

#### Multi-Vendor Pricing Comparison

For multi-vendor quotes (SDT-20689), users can receive pricing from multiple waste haulers and choose the best option.

**The User's Decision:**
- **Lowest Cost**: Minimize company cost
- **Best Margin**: Maximize profit
- **Fastest Service**: Prioritize availability and lead time
- **Preferred Vendor**: Use established vendor relationship
- **Customer Preference**: Customer specifies vendor

The interface should present pricing side-by-side with decision-relevant attributes:

| Vendor | Total Price | Total Cost | Margin | Availability | Lead Time | Service Rating |
|--------|-------------|------------|--------|--------------|-----------|----------------|
| Vendor A | $450 | $350 | 22% | In Stock | 2 days | 4.5★ |
| Vendor B | $425 | $360 | 15% | Limited | 5 days | 3.8★ |
| Vendor C | $480 | $340 | 29% | In Stock | 1 day | 4.8★ |

**Current Experience:**
Multi-vendor pricing displays in separate sections with minimal comparison tools. Users must manually calculate margin percentages and compare across vendors. Selection is via radio button with no clear indication of which vendor was chosen or why.

**Design Opportunity:**
Implement **intelligent pricing comparison**:

1. **Recommended Vendor**: Highlight best option based on company priorities (configurable: lowest cost, best margin, fastest delivery)
2. **Comparison Table**: Side-by-side vendor comparison with sortable columns
3. **Trade-off Analysis**: "Vendor B saves $25 but reduces margin by 7% and delays service by 3 days. Accept trade-off?"
4. **Customer Communication**: Generate customer-facing explanation: "We've selected Vendor A because they offer the best combination of price, availability, and service quality for your needs."

#### Price Editing and Overrides

Sometimes pricing needs manual adjustment:
- **Promotional Discounts**: Special offers or contract terms
- **Competitive Match**: Matching competitor pricing
- **Service Recovery**: Reduced pricing for service failures
- **Bundle Discounts**: Multi-service discounts
- **Pricing Errors**: Correcting automated pricing mistakes

**Current Experience:**
Users with appropriate permissions can click into price fields and edit directly. Changes are logged but not always with clear reason codes. Approval workflows may trigger for large discounts but the trigger thresholds aren't visible to users.

**Design Opportunity:**
Implement **guided price adjustments**:

1. **Reason Codes**: Require selection from dropdown: "Promotional Discount," "Competitive Match," "Service Recovery," etc.
2. **Impact Preview**: "Reducing price by 15% will decrease margin from 22% to 7%. This requires director approval."
3. **Approval Routing**: Clearly show approval path: "This adjustment will be routed to: Manager → Director → VP (for discounts >20%)"
4. **Competitive Context**: If selecting "Competitive Match," provide field to enter competitor name and price being matched
5. **Customer Communication**: Auto-generate justification text for customer: "Special promotional pricing available for new customers this month."

---

### State 7: Final Approval and Quote Delivery

After pricing is accepted, the quote enters approval workflows (if required) and delivery to customer.

#### Approval Workflows

Depending on quote characteristics, various approvals may be required:

**Operational Approval:**
- Manual dispatch required
- Equipment not in standard inventory
- Service location has access challenges
- Regulatory requirements need verification

**Financial Approval:**
- Price below cost (negative margin)
- Discount exceeds threshold
- Credit hold on customer account
- Prepayment or deposit required

**Management Approval:**
- Large deal size (e.g., >$10,000)
- Non-standard contract terms
- Services for VIP customers
- Quote-only requests from competitors (market intelligence)

**Current Experience:**
Approvals are handled via Salesforce standard approval processes—email notifications with approve/reject buttons. Approvers have limited context and often request more information via email chains. The CSR can't see where the quote is in the approval queue or take action to expedite.

**Design Opportunity:**
Implement **transparent, collaborative approval**:

1. **Approval Dashboard**: CSR can see "Pending approval from: Operations Manager (requested 2 hours ago, typically responds in 4 hours)"
2. **Contextual Information**: Approvers see full quote context, not just "Approve this quote for $4,500?" but "Customer needs 3x 8YD front-load for new restaurant opening. Pricing is 5% below standard due to multi-location account. Operations flagged for review due to narrow alley access. Similar service successfully delivered at sister location."
3. **Inline Collaboration**: Approver can comment directly on quote: "Approved for operations, but require customer to confirm alley dimensions before first service."
4. **Conditional Approval**: Allow approvers to approve with modifications: "Approved at $4,800 (not $4,500). Below that requires VP approval."

#### Quote Delivery to Customer

Once approved, the quote must be communicated to the customer:

**Delivery Methods:**
- **Email PDF**: Formatted quote document sent to customer email
- **Customer Portal**: Customer logs in to view and approve quote
- **Verbal**: CSR reads pricing over phone, customer approves verbally
- **Integrated Systems**: For large customers, quote data exports to their procurement system

**Current Experience:**
Quote PDFs are auto-generated with all technical details—quote line IDs, product codes, internal field names. Customers receive overwhelming documents that are difficult to understand. CSRs often must call customers to "explain the quote," which defeats the purpose of written documentation.

**Design Opportunity:**
Implement **audience-appropriate quote formats**:

1. **Customer-Facing Summary**: High-level proposal showing "8 Yard Front-Load Container, Weekly Service, General Waste: $180/month" without internal codes
2. **Detailed Specification**: Expandable sections for customers who want full details (equipment specs, service terms, regulatory compliance info)
3. **Interactive Quotes**: Customer can click "Accept Quote," "Request Modification," or "Ask Question" directly from email/portal
4. **Visual Quotes**: Include images of equipment, service area maps, service schedule calendars
5. **Comparison Quotes**: For multi-service quotes, show comparison table: "Standard Service: $180/month, Premium Service: $220/month (includes lock, weekly cleaning, priority scheduling)"

---

## The Data Flow Journey: Behind the Scenes

While users navigate the interface, complex data flows occur across multiple Salesforce objects and external systems.

### Object Relationships

The core data model:

```
Case (Customer Inquiry)
  └─ Opportunity (Sales Potential)
      └─ Quote (SBQQ__Quote__c)
          └─ Quote Lines (SBQQ__QuoteLine__c)
              ├─ Parent Lines (containers, services)
              └─ Child Lines (materials, accessories)
                  └─ Grandchild Lines (keys for padlocks, etc.)
```

**Related Objects:**
- **Product2**: Equipment types, waste materials, accessories
- **SBQQ__ProductOption__c**: Relationships between products (what accessories are valid for which containers)
- **SBQQ__FavoriteProduct__c**: Saved favorite configurations
- **SBQQ__ConfigurationAttribute__c**: Rules for how products can be configured
- **Entitlement**: Service level agreement terms for accounts
- **Account**: Customer information, location, timezone, credit status
- **BusinessHours**: Business hours by timezone for SLA calculations
- **Industry_Standard_SLA__mdt**: Default SLA rules when no entitlement exists
- **Vendor Records**: External vendor systems for pricing and order fulfillment

### Service Extraction Architecture

Through the refactoring work (Phases 10-13), business logic has been extracted into specialized services:

**SLAManagementService** (843 lines):
- Calculates when service can begin based on entitlements and business hours
- Handles timezone-aware calculations
- Manages industry standard vs. entitlement-based SLA rules
- Accounts for haul-away service exceptions

**EntitlementMatchingService** (183 lines):
- Implements 6-level priority matching to find applicable entitlement
- Handles project-based, location-based, duration-based, and account-based matching
- Returns highest-priority entitlement or null if none match

**ProductConfigurationService** (478 lines):
- Manages product catalog queries and searches
- Handles configuration attribute logic (equipment sizes, waste streams)
- Enforces product-specific rules (SDT-21768 equipment style filtering)
- Manages accessories and product option relationships

**FavoritesService** (137 lines):
- Retrieves saved favorite configurations
- Creates quote lines from favorites
- Handles non-favorite (custom) line creation

**QuoteDataMapperService** (built in earlier phases):
- Builds wrapper objects for UI display
- Aggregates data from multiple sources (quote, lines, products, entitlements)
- Handles complex join queries for performance

**ValidationService** (built in earlier phases):
- Runs comprehensive validation rules
- Checks required fields, business rules, inventory, regulatory compliance
- Returns structured error messages

**HaulAwayService** (referenced in code):
- Determines if service is haul-away type
- Overrides SLA calculations for haul-away services

### External Integration Points

**Pricing APIs:**
- **STP (Single Tender Pricing)**: Primary vendor pricing system
- **Multi-Vendor APIs**: Alternative vendor pricing for competitive quotes
- Real-time pricing requests with 5-60 second response times
- Handles timeout, retry, and fallback logic

**Operational Systems:**
- **Order Management**: Creates operational orders from approved quotes
- **Fleet Management**: Checks equipment availability and schedules
- **Dispatch Systems**: Assigns drivers and routes for service delivery
- **Regulatory Databases**: Validates permits, certifications, waste profiles

**Customer Systems:**
- **Customer Portal**: Allows customers to view/approve quotes
- **Procurement Integration**: Exports quote data to customer ERP systems
- **Payment Processing**: Handles prepayment, deposits, COD

### Performance Considerations

The platform must handle:
- **Concurrent Users**: 50-200 CSRs creating quotes simultaneously
- **Complex Queries**: Multi-object joins across 5+ related objects
- **Large Quotes**: Up to 50+ quote lines per quote
- **External API Latency**: 5-60 second pricing API calls
- **Real-time Validation**: Sub-second response for inline validation

**Current Challenges:**
- Deep nesting (parent → child → grandchild quote lines) requires recursive queries
- SLA calculations run synchronously, blocking UI during calculation
- Validation runs full suite on every save, even for minor changes
- Pricing APIs are called synchronously, freezing UI during wait

**Design Opportunity:**
- Implement asynchronous SLA calculation with optimistic UI updates
- Progressive validation (only re-validate changed fields and dependent fields)
- Parallel pricing API calls with progressive result display
- Client-side caching of frequently accessed data (product catalog, favorites)

---

## Alternative Paths and Edge Cases

### Path 1: The Speed Quote (Time-Pressured CSR)

**Context:** Customer calls during lunch rush, needs quick pricing for standard service, CSR is measured on call handle time.

**Ideal Journey:**
1. Click "New Quote" → Auto-creates Case/Opp/Quote from customer phone lookup
2. Customer says "Same as last time" → System shows "Most Recent Service" favorite → Click to add
3. Confirm service address → Auto-populated from account, CSR says "Correct?" → "Yes" → Next
4. Auto-calculates SLA, shows "Service can start Monday" → Customer agrees → Next
5. Click "Get Pricing" → 10 seconds → "$180/month" → CSR quotes → Customer approves
6. Click "Send Quote" → Email sent → Done

**Total Time:** 2-3 minutes

**Current Friction Points:**
- Must manually create Case/Opportunity (adds 1-2 minutes)
- Must search through 20+ favorites to find "same as last time" (adds 30-60 seconds)
- Summary validation errors on minor fields not relevant to customer (adds 1-2 minutes to fix)
- Must wait for pricing API with no ability to proceed during wait (adds perceived time)

### Path 2: The Complex Multi-Service Quote (Account Manager)

**Context:** Account Manager creating proposal for new manufacturing facility needing 8 different services across 3 buildings.

**Ideal Journey:**
1. Create quote → Batch-add 8 services using template: "Manufacturing Facility Template"
2. For each service, specify building location (A, B, C) → System creates location variants
3. Bulk-configure common attributes: Same start date, same ownership, same billing contact
4. Individual-configure unique attributes: Equipment sizes, waste types, schedules vary by building
5. Request multi-vendor pricing → Compare 3 vendors side-by-side → Select best value
6. Generate customer-facing proposal with site map, service schedule calendar, pricing summary
7. Save as new template: "Manufacturing Facility - Customer Name" for future use

**Total Time:** 20-30 minutes for 8-service quote

**Current Friction Points:**
- Must configure each service individually, repeating common fields 8 times
- No visual site map to associate services with buildings
- Can't save partially configured quote to resume later (session timeout risk)
- Multi-vendor comparison requires manual spreadsheet to compare
- Customer-facing proposal requires manual editing of generated PDF

### Path 3: The Amendment After Operational Review (Operations Coordinator)

**Context:** Quote was approved, but Operations flagged issue: requested equipment size not available at location, must change to different size.

**Ideal Journey:**
1. Open original quote → Click "Create Amendment"
2. System shows: "Line 3: 20YD Roll-Off → Change to 30YD (20YD not available)"
3. Change equipment size → System auto-recalculates pricing with new size
4. System shows: "Price changed from $450 to $520 due to size increase. Customer approval required?"
5. Generate amendment communication: "Your quoted service requires equipment size adjustment due to availability. New price: $520 (was $450). Approve to proceed?"
6. Send to customer → Customer approves → Amendment complete → Operations proceeds

**Current Friction Points:**
- Amendments require re-creating entire quote, not just changing specific lines
- No automated communication of what changed and why
- Pricing recalculation requires manual "Get Pricing" again
- No easy way to show customer "original vs. amended" comparison
- Amendment history not clearly tracked

### Path 4: The Quote-Only for Budgeting (No Immediate Service Intent)

**Context:** Procurement manager from large corporation needs waste management budget estimate for next fiscal year, covering 50 locations.

**Ideal Journey:**
1. Create quote → Flag as "Quote-Only - Budgeting"
2. Import 50 locations from spreadsheet
3. Apply standard service template to all locations
4. Adjust for location-specific requirements (different equipment sizes, waste types by facility type)
5. Get pricing → Generate budget summary report showing total annual cost by location, service type, month
6. Export to customer's format (their procurement system template)
7. Set quote expiration for 90 days (budget cycle timing)
8. No operational approvals required (not creating actual orders)

**Current Friction Points:**
- Quote-only quotes go through same approval workflow as service quotes (unnecessary delays)
- No bulk import capability for multi-location quotes
- Budget reporting requires manual export and Excel work
- Quote expiration defaults to 30 days (too short for budget cycles)

### Path 5: The Correction After Error Discovery

**Context:** CSR created quote with wrong waste type (selected General Waste instead of Construction Debris), affecting pricing and regulatory requirements. Customer hasn't seen quote yet.

**Ideal Journey:**
1. CSR realizes error → Click "Correct Quote"
2. System asks: "What needs correction?" → CSR selects "Waste Type"
3. Change waste type from General Waste → Construction Debris
4. System shows impact: "This changes pricing, disposal facility requirements, and regulatory profile. Recalculate pricing?"
5. CSR confirms → System recalculates → New price shown
6. System generates correction note: "Quote corrected before customer delivery. Original waste type: General Waste (incorrect). Corrected waste type: Construction Debris."
7. Quote proceeds to customer with corrected information, correction logged for quality tracking

**Current Friction Points:**
- No clear "Correct Quote" workflow—must manually edit and track changes
- System doesn't automatically identify downstream impacts of changes
- Correction history not clearly separated from normal amendments
- Quality tracking requires manual reporting of correction incidents

---

## Pain Points and Opportunities: A UX Perspective

### Pain Point 1: Cognitive Overload from Technical Exposure

**The Problem:**
Users see technical implementation details that have no meaning to them or their customers:
- Field names: "SBQQ__StartDate__c" instead of "Start Date"
- Product codes: "PROD-8YD-FL-MS" instead of "8 Yard Front-Load"
- Error messages: "Required field missing: SBQQ__RequiredBy__c" instead of "This accessory needs a parent service"
- Object IDs in logs: "Quote Line 0Q05000000XXX created" instead of "20YD Roll-Off added to quote"

**The Opportunity:**
Implement consistent **human-readable labeling** throughout the platform. Technical details should be available for support/debugging but hidden by default. Every field, every error, every message should use language a CSR can speak to a customer.

### Pain Point 2: Invisible Business Logic

**The Problem:**
Critical business logic runs invisibly, creating unexplainable outcomes:
- "Why can't service start until March 15?" → User doesn't know (SLA calculation hidden)
- "Why is this line flagged for approval?" → User doesn't know (approval rule invisible)
- "Why did price change from $450 to $520?" → User doesn't know (pricing formula opaque)
- "Why can't I select 20YD for this product?" → User doesn't know (configuration attribute filtering hidden)

**The Opportunity:**
Make business logic **transparent and educational**:
- Every calculated value should have "Why?" button showing calculation
- Every restriction should explain the rule: "20YD not available for Compactors per product configuration"
- Every price should show breakdown: "Base + Fuel Surcharge + Environmental Fee = Total"
- System becomes teaching tool, helping users learn over time

### Pain Point 3: Error Messages Without Action Paths

**The Problem:**
Validation errors tell users what's wrong but not how to fix it:
- "Service address required" → Where do I add it?
- "Equipment not available" → What are my alternatives?
- "Pricing failed" → What do I do now?
- "Approval required" → Who do I contact?

**The Opportunity:**
Transform errors into **guided resolution workflows**:
- Error: "Service address required" → Action: "Add Address" button → Inline address entry → Auto-validates → Error cleared
- Error: "Equipment not available" → Action: "View Alternatives" → Shows available sizes → "Switch to 30YD?" → One-click change
- Error: "Pricing failed" → Action: "Request Manual Pricing" → Routes to pricing team with context → Or "Continue without pricing" for quote-only

### Pain Point 4: No Proactive Guidance

**The Problem:**
System waits for users to make mistakes rather than preventing them:
- User can select invalid waste type for equipment, then gets error during validation
- User can configure service that exceeds customer's credit limit, discovering problem at approval stage
- User can create quote for customer with active quote already in progress, creating duplicates

**The Opportunity:**
Implement **proactive guidance and prevention**:
- As user types waste type, show only valid options for selected equipment: "For Compactors, you can select: General Waste, Cardboard, Commingled Recycling"
- Before pricing, show credit check: "Note: Customer has $5,000 credit limit with $3,000 used. This quote ($2,500) will exceed limit and require prepayment."
- When creating quote, check for active quotes: "Customer has quote #12345 in progress (created 2 days ago). Continue with new quote or resume existing?"

### Pain Point 5: Lack of Context Preservation

**The Problem:**
Users lose context when navigating between states or returning to quotes:
- What was I working on before I got interrupted?
- Which quote line was I configuring when the phone rang?
- What changes did I make in this session vs. original quote?
- Why did I configure this service this particular way?

**The Opportunity:**
Implement **smart context preservation**:
- Session autosave: "You were last editing Line 3: Equipment Size. Resume?"
- Change tracking: Highlight modified fields: "You changed Duration from 30 to 60 days"
- Note field: "Add note about why you configured it this way" → "Customer specifically requested customer-owned equipment due to past damage issues"
- Smart highlighting: Recently modified lines highlighted in table

### Pain Point 6: No Learning Path

**The Problem:**
New users are overwhelmed. The system doesn't help them learn:
- No guidance on "What do I configure first?"
- No explanation of why certain fields matter
- No feedback on whether their configuration is optimal
- No way to learn from experienced users' configurations

**The Opportunity:**
Implement **progressive learning features**:
- **Guided Mode for New Users**: "Let's configure your first quote. Step 1: Select equipment type. Here's how to choose..." → Contextual help at each step
- **Quality Scoring**: "This quote configuration scores 85/100. To improve: Add service address for better SLA accuracy. Consider lock accessory for high-theft area."
- **Best Practices**: "Experienced users typically configure compactor service with customer-owned equipment for contracts >6 months. Apply this practice?"
- **Learn from History**: "This customer's last 5 quotes all used 8YD front-load with weekly schedule. Use same configuration?"

---

## Recommended UX Improvements: Prioritized

### Priority 1: Critical for MVP Redesign

**1. Progressive Disclosure Form Design**
Replace long form with smart wizard that reveals fields contextually. Start with critical three (product, location, schedule), expand based on selections.

**2. Inline Validation with Resolution Paths**
Validate as users configure, show errors immediately with "Fix Now" actions that resolve inline without navigation.

**3. Transparent SLA Calculations**
Show "Earliest service date: [Date] because [Reason]" with expandable calculation and alternative options.

**4. Contextual Help Throughout**
Every field has "?" icon with explanation, examples, and common mistakes to avoid.

**5. Human-Readable Everything**
Eliminate technical jargon from user-facing messages. Use customer-friendly language throughout.

### Priority 2: High-Value Enhancements

**6. Smart Favorites with Recommendations**
"Based on this customer's history and your request for 'construction debris,' we recommend..."

**7. Batch Operations for Multi-Service Quotes**
Add 5 similar services → Configure common attributes once → Customize individual differences.

**8. Visual Pricing Comparison**
Side-by-side vendor comparison table with sort, filter, and recommendation highlighting.

**9. Change Tracking for Amendments**
Clear diff view showing original vs. amended values with explanations and customer communication templates.

**10. Progress Indicators**
"Quote is 75% complete. Remaining: Get pricing, operations approval" with estimated time.

### Priority 3: Efficiency Optimizations

**11. Templates and Cloning**
Save successful quotes as templates. Clone quotes for similar customers.

**12. Bulk Import for Multi-Location**
Import 50 locations from spreadsheet, apply standard configuration, adjust individually.

**13. Mobile-Optimized Views**
CSRs working from tablets need touch-friendly, simplified views for common operations.

**14. Keyboard Shortcuts**
Power users want Ctrl+S to save, Ctrl+N for new line, Tab to navigate without mouse.

**15. Customizable Dashboards**
Users configure their workspace: "Show me my pending approvals, recent quotes, and high-priority customers."

---

## Conclusion: Designing for the Real User Journey

The Quote Platform is powerful but complex. Users navigate this complexity daily, often under time pressure, always with customers depending on accurate results.

The redesign opportunity is to **make complex simple** without making powerful weak:

- **Hide complexity by default, reveal on demand**: Most quotes are standard. Design for the 80% case, provide power features for the 20%.

- **Guide without constraining**: Help users make good choices, but allow expert overrides when justified.

- **Explain the machine**: When system makes decisions (SLA calculations, validation rules, pricing), explain why in human terms.

- **Learn and adapt**: System should get smarter about each user's patterns, each customer's preferences, each industry's best practices.

- **Fail gracefully**: When things go wrong (API timeout, validation error, approval rejection), provide clear path forward.

The ultimate measure: Can a new CSR create an accurate, priced quote for a standard service in under 5 minutes? Can an experienced Account Manager create a complex 10-service proposal in under 30 minutes? Can Operations approve or flag quotes without email chains?

This narrative provides the foundation. The Figma designs should bring it to life with specific interaction patterns, visual hierarchies, and component designs that serve these real users in their real workflows.

---

## Appendix: Technical User Stories Referenced

Throughout the codebase, user stories (SDT-XXXXX) document specific features and fixes:

- **SDT-21768**: Equipment size exact matching (Toshender Kumar)
- **SDT-22447**: Equipment style filtering by product type
- **SDT-23055, SDT-31752**: Padlock-key relationship handling
- **SDT-24088**: Quote validation enhancements
- **SDT-24402, SDT-24917, SDT-24925, SDT-25065, SDT-25078, SDT-26160**: Entitlement matching priorities
- **SDT-29961**: Alternate products SLA determination
- **SDT-20689**: Multi-vendor pricing support
- **SDT-30072**: Asset availability permission checks
- **SDT-33378**: Quote correction workflows
- **SDT-39637, SDT-45007, SDT-47963, SDT-47970, SDT-47975**: SLA calculation refinements
- **SDT-41473, SDT-42045**: Haul-away service exception handling

These stories represent real user pain points that drove development. The redesign should ensure these fixes remain in place while improving overall experience.
