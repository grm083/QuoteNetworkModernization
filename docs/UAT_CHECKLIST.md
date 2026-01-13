# Quote Network Modernization - UAT Checklist

## Document Information
| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | January 2026 |
| **Project** | Quote Framework Service Layer Refactoring |
| **Audience** | Business Users, UAT Testers, Product Owners |

---

## Table of Contents
1. [Overview](#1-overview)
2. [Pre-UAT Requirements](#2-pre-uat-requirements)
3. [Quote Creation & Management](#3-quote-creation--management)
4. [Quote Line Configuration](#4-quote-line-configuration)
5. [Vendor Selection & Management](#5-vendor-selection--management)
6. [Pricing & Cost Configuration](#6-pricing--cost-configuration)
7. [Delivery & Order Creation](#7-delivery--order-creation)
8. [SLA Management](#8-sla-management)
9. [Special Handling](#9-special-handling)
10. [Favorites Management](#10-favorites-management)
11. [Asset & Equipment Management](#11-asset--equipment-management)
12. [Work Order Integration](#12-work-order-integration)
13. [Commercial Products](#13-commercial-products)
14. [Haul Away Services](#14-haul-away-services)
15. [Error Handling & Validation Messages](#15-error-handling--validation-messages)
16. [Performance & Usability](#16-performance--usability)
17. [Sign-Off Criteria](#17-sign-off-criteria)

---

## 1. Overview

### 1.1 Purpose
This UAT Checklist provides business users with a comprehensive guide to validate the Quote Network Modernization changes through the Salesforce user interface. All testing is performed through standard UI navigation without requiring Apex code execution.

### 1.2 What Changed
The underlying service layer for the Quote Procurement system has been completely refactored. While the **user interface remains the same**, the backend processing has been modernized. Users should verify that:
- All existing functionality works as expected
- No regression in behavior
- Performance is equal to or better than before
- Error messages are clear and actionable

### 1.3 Testing Approach
- Navigate through the UI as you normally would
- Perform standard business operations
- Verify expected outcomes
- Report any deviations from expected behavior

---

## 2. Pre-UAT Requirements

### 2.1 Environment Checklist
| Item | Status |
|------|--------|
| [ ] UAT sandbox refreshed and configured | |
| [ ] User accounts provisioned with correct profiles | |
| [ ] Test data loaded (accounts, cases, products) | |
| [ ] Integration endpoints configured (MAS, Acorn) | |
| [ ] Email notifications enabled for testing | |

### 2.2 User Access Verification
| Role | Required Access | Verified |
|------|-----------------|----------|
| Quote Specialist | Create/Edit Quotes, Quote Lines | [ ] |
| Pricing Analyst | Configure Costs, Set Prices | [ ] |
| Vendor Coordinator | Search/Assign Vendors | [ ] |
| Operations Manager | Create Deliveries, Work Orders | [ ] |
| Customer Service Rep | View Quotes, Add Comments | [ ] |

### 2.3 Test Data Availability
| Data Type | Minimum Qty | Available |
|-----------|-------------|-----------|
| Customer Accounts | 10 | [ ] |
| Active Vendors | 15 | [ ] |
| Products (Container, Compactor, Roll-Off) | 20 | [ ] |
| Open Cases | 25 | [ ] |
| Existing Quotes | 20 | [ ] |
| Assets with Equipment | 15 | [ ] |

---

## 3. Quote Creation & Management

### 3.1 New Quote Creation

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-Q001 | Create new quote from Case | 1. Open a Case record 2. Click "New Quote" button 3. Fill required fields 4. Save | Quote created and linked to Case | [ ] |
| UAT-Q002 | Create quote with customer account | 1. Create new quote 2. Select customer account 3. Verify account details populate | Account information auto-populates | [ ] |
| UAT-Q003 | Clone existing quote | 1. Open existing quote 2. Click "Clone" 3. Verify all fields copied | New quote with copied data | [ ] |
| UAT-Q004 | View quote summary | 1. Open quote 2. Navigate to Summary tab 3. Review all sections | All quote details visible | [ ] |

### 3.2 Quote Status Transitions

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-Q010 | Move quote to Draft | 1. Create new quote 2. Verify status is "Draft" | Status shows Draft | [ ] |
| UAT-Q011 | Progress to Product Configured | 1. Add products to quote 2. Configure products 3. Verify status change | Status updates correctly | [ ] |
| UAT-Q012 | Progress to Cost Configured | 1. Complete product config 2. Add cost information 3. Verify status | Status shows Cost Configured | [ ] |
| UAT-Q013 | Progress to Price Configured | 1. Complete cost config 2. Add pricing 3. Verify status | Status shows Price Configured | [ ] |
| UAT-Q014 | Finalize quote | 1. Complete all configuration 2. Submit quote 3. Verify final status | Quote finalized successfully | [ ] |

### 3.3 Quote Search & Filtering

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-Q020 | Search quotes by number | 1. Go to Quotes tab 2. Search by quote number | Correct quote found | [ ] |
| UAT-Q021 | Filter quotes by status | 1. Apply status filter 2. Verify results | Only matching quotes shown | [ ] |
| UAT-Q022 | Filter quotes by date range | 1. Set date range filter 2. Review results | Quotes within date range | [ ] |
| UAT-Q023 | View my quotes | 1. Apply "My Quotes" filter 2. Verify ownership | Only owned quotes shown | [ ] |

---

## 4. Quote Line Configuration

### 4.1 Adding Quote Lines

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-QL001 | Add single quote line | 1. Open quote 2. Click "Add Product" 3. Select product 4. Save | Quote line added | [ ] |
| UAT-QL002 | Add multiple quote lines | 1. Add first product 2. Add second product 3. Add third product | All lines visible in list | [ ] |
| UAT-QL003 | Add quote line with waste stream | 1. Add product 2. Select waste stream 3. Select material type 4. Save | Waste stream and material saved | [ ] |
| UAT-QL004 | Add quote line with equipment size | 1. Add product 2. Select equipment size 3. Save | Equipment size assigned | [ ] |
| UAT-QL005 | Add child quote lines | 1. Select parent line 2. Add child line 3. Verify hierarchy | Parent-child relationship shown | [ ] |

### 4.2 Editing Quote Lines

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-QL010 | Edit quote line quantity | 1. Open quote line 2. Change quantity 3. Save | Quantity updated | [ ] |
| UAT-QL011 | Edit quote line product | 1. Open quote line 2. Change product 3. Save | Product updated | [ ] |
| UAT-QL012 | Edit schedule frequency | 1. Open quote line 2. Set frequency (Weekly/Monthly) 3. Save | Frequency saved | [ ] |
| UAT-QL013 | Set service days | 1. Open quote line 2. Select service days (Mon, Wed, Fri) 3. Save | Service days saved | [ ] |
| UAT-QL014 | Edit quote line notes | 1. Open quote line 2. Add/edit notes 3. Save | Notes saved and visible | [ ] |

### 4.3 Deleting Quote Lines

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-QL020 | Delete single quote line | 1. Select quote line 2. Click Delete 3. Confirm | Line removed from quote | [ ] |
| UAT-QL021 | Delete parent with children | 1. Select parent line 2. Click Delete 3. Confirm | Parent and children removed | [ ] |
| UAT-QL022 | Bulk delete quote lines | 1. Select multiple lines 2. Click Delete 3. Confirm | All selected lines removed | [ ] |

### 4.4 Quote Line Validation

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-QL030 | Validate scheduled service without frequency | 1. Create scheduled service line 2. Leave frequency blank 3. Try to save | Error message displayed | [ ] |
| UAT-QL031 | Validate weekly service without days | 1. Set frequency to Weekly 2. Leave service days blank 3. Try to save | Error message displayed | [ ] |
| UAT-QL032 | Validate line without vendor | 1. Create quote line 2. Leave vendor blank 3. Try to progress | Error message displayed | [ ] |
| UAT-QL033 | Validate all required fields present | 1. Fill all required fields 2. Save | Validation passes | [ ] |

---

## 5. Vendor Selection & Management

### 5.1 Vendor Search

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-V001 | Search vendor by name | 1. Open vendor search 2. Type vendor name 3. Click Search | Matching vendors displayed | [ ] |
| UAT-V002 | Search vendor by partial name | 1. Type partial name (3+ chars) 2. Search | Vendors containing text shown | [ ] |
| UAT-V003 | Search with no results | 1. Search for non-existent vendor 2. Review results | "No vendors found" message | [ ] |
| UAT-V004 | Verify parent vendors filtered | 1. Search for vendor 2. Verify parent accounts not shown | Only child/individual vendors | [ ] |

### 5.2 Vendor Assignment

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-V010 | Assign vendor to quote line | 1. Open quote line 2. Search vendor 3. Select vendor 4. Save | Vendor assigned to line | [ ] |
| UAT-V011 | Assign vendor to parent and children | 1. Select parent line 2. Assign vendor 3. Save | Vendor on parent + all children | [ ] |
| UAT-V012 | Change vendor assignment | 1. Open line with vendor 2. Search new vendor 3. Select 4. Save | Vendor updated | [ ] |
| UAT-V013 | Clear vendor assignment | 1. Open line with vendor 2. Clear vendor field 3. Save | Vendor removed | [ ] |

### 5.3 Vendor Validation

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-V020 | Assign inactive vendor | 1. Try to assign inactive vendor | Error: Vendor is inactive | [ ] |
| UAT-V021 | Verify active vendor | 1. Assign active vendor 2. Save | Vendor assigned successfully | [ ] |
| UAT-V022 | WM vendor without MAS library | 1. Assign WM vendor without MAS 2. Try to progress | Error: MAS library required | [ ] |
| UAT-V023 | WM vendor with MAS library | 1. Assign WM vendor with MAS 2. Progress | Validation passes | [ ] |

---

## 6. Pricing & Cost Configuration

### 6.1 Cost Entry

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-P001 | Enter unit cost | 1. Open quote line 2. Navigate to Cost tab 3. Enter unit cost 4. Save | Cost saved | [ ] |
| UAT-P002 | Select cost UOM | 1. Open quote line 2. Select cost unit of measure 3. Save | UOM saved | [ ] |
| UAT-P003 | Enter cost model | 1. Configure cost model 2. Save | Cost model saved | [ ] |
| UAT-P004 | Calculate total cost | 1. Enter quantity and unit cost 2. Verify total calculation | Total = Qty x Unit Cost | [ ] |

### 6.2 Price Entry

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-P010 | Enter list price | 1. Open quote line 2. Navigate to Pricing tab 3. Enter list price 4. Save | Price saved | [ ] |
| UAT-P011 | Select price UOM | 1. Select price unit of measure 2. Save | UOM saved | [ ] |
| UAT-P012 | Apply discount | 1. Enter discount percentage 2. Save 3. Verify net price | Net price calculated | [ ] |
| UAT-P013 | Enter stepped pricing | 1. Configure stepped pricing tiers 2. Save | Tiers saved correctly | [ ] |
| UAT-P014 | Select pricing method | 1. Choose pricing method 2. Save | Method applied | [ ] |

### 6.3 Cost/Price Validation

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-P020 | Missing cost UOM at Cost stage | 1. Leave cost UOM blank 2. Try to progress to Cost Configured | Error message displayed | [ ] |
| UAT-P021 | Missing price UOM at Price stage | 1. Leave price UOM blank 2. Try to progress to Price Configured | Error message displayed | [ ] |
| UAT-P022 | Missing list price | 1. Leave list price blank 2. Try to finalize | Error message displayed | [ ] |
| UAT-P023 | WM management fee validation | 1. Configure WM fee 2. Verify validation rules | Validation per business rules | [ ] |

---

## 7. Delivery & Order Creation

### 7.1 Creating Deliveries

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-D001 | Create delivery for new service | 1. Open finalized quote 2. Click "Create Delivery" 3. Confirm | Quote Order created | [ ] |
| UAT-D002 | Create delivery for existing service | 1. Open quote for existing service 2. Create Delivery 3. Verify asset comparison | Comparison performed | [ ] |
| UAT-D003 | Create delivery with multiple lines | 1. Quote with 5+ lines 2. Create Delivery 3. Verify all orders | Orders for all lines | [ ] |
| UAT-D004 | View delivery confirmation | 1. After delivery creation 2. Review confirmation screen | Summary of created orders | [ ] |

### 7.2 Delivery Types

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-D010 | Create delivery order | 1. Select delivery type 2. Create delivery | Order type = Delivery | [ ] |
| UAT-D011 | Create pickup order | 1. Select pickup type 2. Create order | Order type = Pickup | [ ] |
| UAT-D012 | Create swap order | 1. Select swap type 2. Create order | Order type = Swap | [ ] |
| UAT-D013 | Create removal order | 1. Add removal line 2. Create delivery | Removal processed | [ ] |

### 7.3 Haul & Removal Lines

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-D020 | Create haul line | 1. Add haul product 2. Configure 3. Create delivery | Haul order created | [ ] |
| UAT-D021 | Create removal line | 1. Add removal product 2. Configure 3. Create delivery | Removal order created | [ ] |
| UAT-D022 | Haul + Removal combination | 1. Add both haul and removal 2. Create delivery | Both orders created | [ ] |

### 7.4 Delivery Validation

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-D030 | Validate before delivery | 1. Incomplete quote 2. Try to create delivery | Validation errors shown | [ ] |
| UAT-D031 | Missing vendor before delivery | 1. Quote line without vendor 2. Try to create | Error: Vendor required | [ ] |
| UAT-D032 | Successful delivery validation | 1. Complete all requirements 2. Create delivery | Delivery created | [ ] |

---

## 8. SLA Management

### 8.1 SLA Date Handling

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-SLA001 | View SLA date on quote | 1. Open quote 2. Locate SLA date field | SLA date visible | [ ] |
| UAT-SLA002 | SLA calculated from entitlement | 1. Quote with entitlement 2. Verify SLA date | Date matches entitlement | [ ] |
| UAT-SLA003 | Edit SLA date | 1. Open quote 2. Modify SLA date 3. Save | Date updated | [ ] |

### 8.2 SLA Override

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-SLA010 | Override SLA with reason | 1. Open quote 2. Click "Override SLA" 3. Enter reason 4. Save | Override saved with comment | [ ] |
| UAT-SLA011 | View SLA override comment | 1. Quote with override 2. View comments/history | Override comment visible | [ ] |
| UAT-SLA012 | Override from intake screen | 1. Intake screen 2. Override SLA 3. Verify comment | Comment created | [ ] |
| UAT-SLA013 | Override from Flow/MIF | 1. Trigger MIF flow 2. Override SLA 3. Verify | Comment with reason | [ ] |

### 8.3 Backdated Service Detection

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-SLA020 | Detect backdated SLA | 1. Set SLA date in past 2. Save 3. Verify detection | Backdated indicator shown | [ ] |
| UAT-SLA021 | Backdated triggers special handling | 1. Set past SLA date 2. Verify special handling flag | Special Handling = Yes | [ ] |

---

## 9. Special Handling

### 9.1 Auto-Detection Scenarios

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-SH001 | Backdated service detected | 1. Set SLA date before today 2. Save | Special Handling auto-set | [ ] |
| UAT-SH002 | Certificate of Destruction | 1. Check Certificate of Destruction 2. Save | Special Handling = Yes | [ ] |
| UAT-SH003 | Certificate of Disposal | 1. Check Certificate of Disposal 2. Save | Special Handling = Yes | [ ] |
| UAT-SH004 | Gate code required | 1. Enter gate code 2. Save | Special Handling = Yes | [ ] |
| UAT-SH005 | Time window restriction | 1. Set service start/end time 2. Save | Special Handling = Yes | [ ] |
| UAT-SH006 | Restriction details | 1. Enter restriction details 2. Save | Special Handling = Yes | [ ] |

### 9.2 Special Handling Reason

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-SH010 | View special handling reason | 1. Quote with special handling 2. View reason field | Reason populated | [ ] |
| UAT-SH011 | Multiple reasons | 1. Trigger multiple scenarios 2. View reason | All reasons listed | [ ] |

### 9.3 Clearing Special Handling

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-SH020 | Remove backdated date | 1. Change SLA to future 2. Save | Special Handling cleared | [ ] |
| UAT-SH021 | Remove certificate requirement | 1. Uncheck certificates 2. Save | Special Handling cleared | [ ] |
| UAT-SH022 | Clear all special scenarios | 1. Remove all triggers 2. Save | Special Handling = No | [ ] |

---

## 10. Favorites Management

### 10.1 Viewing Favorites

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-F001 | View my favorites | 1. Go to Favorites section 2. View list | User's favorites displayed | [ ] |
| UAT-F002 | Search favorites | 1. Open favorites 2. Search by name | Matching favorites shown | [ ] |
| UAT-F003 | Filter favorites by category | 1. Apply category filter 2. View results | Filtered favorites shown | [ ] |

### 10.2 Using Favorites

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-F010 | Add quote from favorite | 1. Select favorite 2. Click "Add to Quote" 3. Verify | Quote created from favorite | [ ] |
| UAT-F011 | Add quote line from favorite | 1. Open quote 2. Select favorite 3. Add | Quote line created | [ ] |
| UAT-F012 | Convert favorite to non-favorite | 1. Add from favorite 2. Modify 3. Save as new | New line (not linked to favorite) | [ ] |

### 10.3 Managing Favorites

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-F020 | Create new favorite | 1. Configure product 2. Save as favorite | Favorite created | [ ] |
| UAT-F021 | Edit favorite | 1. Open favorite 2. Modify settings 3. Save | Favorite updated | [ ] |
| UAT-F022 | Delete favorite | 1. Select favorite 2. Delete 3. Confirm | Favorite removed | [ ] |

---

## 11. Asset & Equipment Management

### 11.1 Asset Availability

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-A001 | View availability indicator | 1. Open quote line 2. View availability icon | Bell icon with status | [ ] |
| UAT-A002 | View availability message | 1. Hover over availability icon | Message displayed | [ ] |
| UAT-A003 | Override availability | 1. Open quote line 2. Override availability 3. Save | Override saved | [ ] |

### 11.2 Asset Comparison (Existing Service)

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-A010 | View asset comparison | 1. Open existing service quote 2. View comparison | Current vs proposed shown | [ ] |
| UAT-A011 | Changes highlighted | 1. Modify quote line 2. View comparison | Changed fields highlighted | [ ] |
| UAT-A012 | No changes scenario | 1. Quote matches asset 2. View comparison | "No changes" indicated | [ ] |

### 11.3 Equipment Configuration

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-A020 | Select equipment size | 1. Add product 2. Select size 3. Save | Size assigned | [ ] |
| UAT-A021 | View equipment details | 1. Open quote line 2. View equipment tab | All details visible | [ ] |
| UAT-A022 | Change equipment size | 1. Edit quote line 2. Change size 3. Save | Size updated | [ ] |

---

## 12. Work Order Integration

### 12.1 Work Order Creation

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-WO001 | Work order created from delivery | 1. Create delivery 2. View work orders | Work order created | [ ] |
| UAT-WO002 | View work order details | 1. Navigate to work order 2. Review fields | All fields populated | [ ] |
| UAT-WO003 | Link to quote visible | 1. Open work order 2. View quote reference | Quote linked correctly | [ ] |

### 12.2 Work Order Updates

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-WO010 | Update work order status | 1. Open work order 2. Change status 3. Save | Status updated | [ ] |
| UAT-WO011 | Add work order notes | 1. Open work order 2. Add notes 3. Save | Notes saved | [ ] |
| UAT-WO012 | View work order history | 1. Open work order 2. View history tab | All changes logged | [ ] |

---

## 13. Commercial Products

### 13.1 Commercial Product Configuration

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-CP001 | Add commercial product | 1. Select commercial product 2. Configure 3. Save | Product added | [ ] |
| UAT-CP002 | Commercial customer validation | 1. Non-commercial customer 2. Add commercial product | Validation or warning | [ ] |
| UAT-CP003 | Commercial pricing | 1. Configure commercial product 2. Set pricing 3. Verify | Commercial rates applied | [ ] |

### 13.2 Commercial Delivery

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-CP010 | Commercial delivery creation | 1. Commercial quote 2. Create delivery | Commercial order created | [ ] |
| UAT-CP011 | Verify commercial handling | 1. View delivery details 2. Check commercial flags | Commercial handling applied | [ ] |

---

## 14. Haul Away Services

### 14.1 Haul Away Configuration

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-HA001 | Add Haul Away product | 1. Select Haul Away product 2. Add to quote | Product added | [ ] |
| UAT-HA002 | Auto vendor assignment | 1. Add Haul Away product 2. Verify vendor | Vendor auto-assigned | [ ] |
| UAT-HA003 | Location-based vendor | 1. Add Haul Away 2. Verify location mapping | Correct vendor by location | [ ] |

### 14.2 Haul Away Processing

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-HA010 | Haul Away task creation | 1. Process Haul Away 2. View tasks | Task created | [ ] |
| UAT-HA011 | Haul Away delivery | 1. Create delivery with Haul Away 2. Verify order | Haul order created | [ ] |
| UAT-HA012 | Missing vendor mapping | 1. Location without mapping 2. Add Haul Away | Error or manual assignment | [ ] |

---

## 15. Error Handling & Validation Messages

### 15.1 Validation Error Messages

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-E001 | Clear error message for missing frequency | 1. Trigger frequency error 2. Read message | Message explains issue clearly | [ ] |
| UAT-E002 | Clear error message for missing vendor | 1. Trigger vendor error 2. Read message | Message explains issue clearly | [ ] |
| UAT-E003 | Clear error message for missing cost | 1. Trigger cost error 2. Read message | Message explains issue clearly | [ ] |
| UAT-E004 | Clear error message for missing price | 1. Trigger price error 2. Read message | Message explains issue clearly | [ ] |
| UAT-E005 | Multiple validation errors | 1. Trigger multiple errors 2. View all | All errors listed | [ ] |

### 15.2 Error Recovery

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-E010 | Fix validation error and retry | 1. Get validation error 2. Fix issue 3. Retry | Action succeeds | [ ] |
| UAT-E011 | Cancel after error | 1. Get error 2. Cancel operation | Returns to previous state | [ ] |
| UAT-E012 | Error doesn't lose data | 1. Enter data 2. Get error 3. Verify data retained | Data not lost | [ ] |

### 15.3 System Error Handling

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-E020 | Graceful timeout handling | 1. Long operation 2. Observe behavior | User-friendly message | [ ] |
| UAT-E021 | Integration error handling | 1. Trigger integration (MAS) 2. If error, view message | Clear error explanation | [ ] |

---

## 16. Performance & Usability

### 16.1 Page Load Times

| Test ID | Test Scenario | Acceptable Time | Actual Time | Pass/Fail |
|---------|---------------|-----------------|-------------|-----------|
| UAT-PF001 | Quote list page load | < 3 seconds | | [ ] |
| UAT-PF002 | Quote detail page load | < 3 seconds | | [ ] |
| UAT-PF003 | Quote line list load (10 lines) | < 2 seconds | | [ ] |
| UAT-PF004 | Quote line list load (50 lines) | < 4 seconds | | [ ] |
| UAT-PF005 | Vendor search results | < 2 seconds | | [ ] |
| UAT-PF006 | Save quote operation | < 3 seconds | | [ ] |
| UAT-PF007 | Create delivery operation | < 5 seconds | | [ ] |

### 16.2 Usability Checks

| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---------|---------------|-------|-----------------|-----------|
| UAT-PF010 | UI layout consistent | 1. Navigate all quote screens 2. Check layout | Layout matches previous | [ ] |
| UAT-PF011 | Button placement | 1. Verify all action buttons 2. Check positions | Buttons in expected places | [ ] |
| UAT-PF012 | Field labels correct | 1. Review all field labels 2. Verify accuracy | Labels match expectations | [ ] |
| UAT-PF013 | Help text available | 1. Hover over fields with help 2. Verify text | Help text displays | [ ] |
| UAT-PF014 | Tab order logical | 1. Tab through form fields 2. Check order | Logical tab sequence | [ ] |

### 16.3 Browser Compatibility

| Test ID | Browser | Version | Status | Pass/Fail |
|---------|---------|---------|--------|-----------|
| UAT-PF020 | Chrome | Latest | | [ ] |
| UAT-PF021 | Firefox | Latest | | [ ] |
| UAT-PF022 | Edge | Latest | | [ ] |
| UAT-PF023 | Safari | Latest (if applicable) | | [ ] |

---

## 17. Sign-Off Criteria

### 17.1 Acceptance Criteria

| Criteria | Requirement | Status |
|----------|-------------|--------|
| All P0 test cases pass | 100% | [ ] |
| All P1 test cases pass | 95%+ | [ ] |
| All P2 test cases pass | 90%+ | [ ] |
| No critical defects open | 0 | [ ] |
| No high severity defects open | 0 | [ ] |
| Medium defects documented | With workarounds | [ ] |
| Performance benchmarks met | All within limits | [ ] |
| User experience acceptable | Approved by PO | [ ] |

### 17.2 UAT Summary

| Category | Total Tests | Passed | Failed | Blocked | Pass Rate |
|----------|-------------|--------|--------|---------|-----------|
| Quote Creation | | | | | |
| Quote Lines | | | | | |
| Vendor Management | | | | | |
| Pricing & Cost | | | | | |
| Delivery | | | | | |
| SLA Management | | | | | |
| Special Handling | | | | | |
| Favorites | | | | | |
| Assets | | | | | |
| Work Orders | | | | | |
| Commercial | | | | | |
| Haul Away | | | | | |
| Error Handling | | | | | |
| Performance | | | | | |
| **TOTAL** | | | | | |

### 17.3 Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Business Owner | | | |
| Product Owner | | | |
| QA Lead | | | |
| UAT Lead | | | |
| IT Manager | | | |

### 17.4 Known Issues / Workarounds

| Issue ID | Description | Workaround | Severity | Target Fix |
|----------|-------------|------------|----------|------------|
| | | | | |
| | | | | |
| | | | | |

### 17.5 Go-Live Recommendation

- [ ] **APPROVED** - System ready for production deployment
- [ ] **CONDITIONALLY APPROVED** - Ready with documented workarounds
- [ ] **NOT APPROVED** - Critical issues must be resolved

**Comments:**
_______________________________________________
_______________________________________________
_______________________________________________

---

## Appendix A: Test Execution Log Template

| Date | Tester | Test ID | Result | Defect # | Notes |
|------|--------|---------|--------|----------|-------|
| | | | | | |
| | | | | | |
| | | | | | |

---

## Appendix B: Defect Reporting Template

**Defect ID:** _______________
**Title:** _______________
**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low
**Priority:** [ ] P0 [ ] P1 [ ] P2 [ ] P3

**Description:**
_______________________________________________

**Steps to Reproduce:**
1. _______________
2. _______________
3. _______________

**Expected Result:**
_______________________________________________

**Actual Result:**
_______________________________________________

**Screenshots/Attachments:**
_______________________________________________

**Environment:**
- Org: _______________
- Browser: _______________
- User: _______________

---

## Appendix C: Contact Information

| Role | Name | Email | Phone |
|------|------|-------|-------|
| UAT Coordinator | | | |
| Technical Lead | | | |
| Business Analyst | | | |
| Support Contact | | | |
