# Add/Change Service Enhancement Project Charter

## Document Control
| Field | Value |
|-------|-------|
| **Document Version** | 1.0 |
| **Date** | January 2026 |
| **Project Name** | Add/Change Service Enhancement Initiative |
| **Project Code** | ACSE-2026 |
| **Sponsor** | [Executive Sponsor Name] |
| **Project Manager** | [Project Manager Name] |
| **Status** | Draft |

---

## Executive Summary

The Add/Change Service Enhancement Initiative is a strategic 6-month project to transform how our organization handles service modifications, additions, and amendments within our Quote-to-Service lifecycle. Building upon the recently completed Quote Network Modernization effort (which refactored 5,753 lines of monolithic code into 52 specialized services), this project will deliver a unified, automated, and highly efficient Add/Change processing capability.

Currently, Add/Change functionality exists in a fragmented state across multiple systems and processes, leading to manual workarounds, processing delays, and revenue leakage. This initiative will consolidate scattered logic, automate approval workflows, and create a seamless experience for both internal users and customers—ultimately reducing processing time by 60% and recovering an estimated $2.4M annually in operational efficiency and revenue protection.

---

## Table of Contents

1. [Project Description](#1-project-description)
2. [Project Risks](#2-project-risks)
3. [Project Assumptions](#3-project-assumptions)
4. [Project Constraints](#4-project-constraints)
5. [Financial Benefits](#5-financial-benefits)
6. [Cost of Inaction](#6-cost-of-inaction)
7. [Project Timeline](#7-project-timeline)
8. [Appendices](#appendices)

---

## 1. Project Description

### 1.1 What Is This Project About?

The Add/Change Service Enhancement Initiative will create a comprehensive, unified platform for managing all service modifications across the customer lifecycle. This includes:

#### **Core Capabilities to Be Delivered**

| Capability | Description |
|------------|-------------|
| **Unified Add/Change Service** | A centralized service layer that handles all service additions and modifications through a single, consistent workflow |
| **Amendment Processing Engine** | Automated amendment quote creation, validation, and approval with configurable business rules |
| **Asset Modification Orchestration** | End-to-end tracking and execution of asset changes including swaps, upgrades, downgrades, and replacements |
| **Vendor Change Management** | Streamlined vendor transition workflows with service continuity validation |
| **Quote State Machine** | Formalized quote lifecycle management with clear state transitions and validation gates |
| **Approval Automation** | Rules-based approval routing with escalation, delegation, and SLA tracking |
| **Change Impact Analysis** | Real-time financial impact calculations for proposed service changes |
| **Self-Service Portal** | Customer-facing interface for common Add/Change requests |

#### **Current State vs. Future State**

| Dimension | Current State | Future State |
|-----------|---------------|--------------|
| **Processing Model** | Manual, fragmented across teams | Automated, unified workflow |
| **Average Processing Time** | 5-7 business days | 1-2 business days |
| **Error Rate** | 12-15% rework required | <2% error rate |
| **Customer Visibility** | Limited status updates | Real-time tracking portal |
| **Revenue Protection** | Gaps in change capture | 100% change billing capture |
| **Approval Workflow** | Email-based, manual tracking | Automated, SLA-monitored |
| **Code Architecture** | Duplicated logic, 15+ locations | Single service, reusable |
| **Audit Trail** | Incomplete, manual documentation | Complete, automated logging |

#### **Scope Definition**

**In Scope:**
- Add Service to existing customer accounts
- Change/Modify existing service configurations
- Service cancellation and end-dating
- Equipment swaps, upgrades, and downgrades
- Vendor changes and transitions
- Pricing amendments (increases/decreases)
- Schedule and frequency modifications
- Amendment quote generation and approval
- Work order creation for service changes
- Customer self-service portal (Phase 2)
- Integration with MAS, Acorn, and billing systems

**Out of Scope:**
- New customer acquisition workflows
- Contract renegotiation (separate project)
- Accounts receivable modifications
- Non-quote-based service adjustments
- Legacy system decommissioning

### 1.2 Business Drivers

| Driver | Description |
|--------|-------------|
| **Operational Efficiency** | Reduce manual processing and eliminate duplicate data entry |
| **Revenue Assurance** | Capture all billable changes and eliminate revenue leakage |
| **Customer Experience** | Faster turnaround and transparent status visibility |
| **Regulatory Compliance** | Complete audit trails for service modifications |
| **Scalability** | Support business growth without proportional headcount increases |
| **Technical Debt Reduction** | Consolidate fragmented logic following Quote Network Modernization |

### 1.3 Strategic Alignment

This project directly supports the following organizational objectives:
- **Digital Transformation**: Automate manual processes and enable self-service
- **Customer Centricity**: Reduce friction in service modification requests
- **Operational Excellence**: Standardize and optimize core business processes
- **Revenue Growth**: Protect existing revenue and enable faster upsell execution

---

## 2. Project Risks

### 2.1 Risk Register

| Risk ID | Risk Description | Probability | Impact | Risk Score | Mitigation Strategy |
|---------|------------------|-------------|--------|------------|---------------------|
| R-001 | **Integration Complexity**: MAS, Acorn, and billing system integrations may require more effort than estimated | High | High | **Critical** | Early integration spikes; dedicated integration team; fallback manual processes |
| R-002 | **Data Migration Issues**: Historical Add/Change data may have quality issues affecting migration | Medium | High | **High** | Data profiling early; cleansing scripts; parallel run period |
| R-003 | **User Adoption Resistance**: Operations teams may resist process changes | Medium | Medium | **Medium** | Change management program; super-user network; phased rollout |
| R-004 | **Scope Creep**: Stakeholders may request additional features during development | High | Medium | **High** | Strict change control; documented scope baseline; steering committee governance |
| R-005 | **Resource Availability**: Key developers may be pulled to production support | Medium | High | **High** | Dedicated team allocation; backfill plan; knowledge redundancy |
| R-006 | **Performance Degradation**: New services may not meet performance requirements | Low | High | **Medium** | Performance testing gates; governor limit monitoring; optimization sprints |
| R-007 | **Vendor API Changes**: External vendor systems may change during development | Low | Medium | **Low** | API versioning; contract agreements; abstraction layers |
| R-008 | **Regulatory Changes**: New compliance requirements may emerge | Low | Medium | **Low** | Regulatory monitoring; flexible architecture; compliance checkpoints |
| R-009 | **Testing Coverage Gaps**: Complex scenarios may be missed in testing | Medium | High | **High** | Comprehensive test plan; UAT with real scenarios; production shadowing |
| R-010 | **Go-Live Disruption**: Cutover may cause temporary service disruption | Medium | High | **High** | Phased rollout; feature flags; instant rollback capability |

### 2.2 Risk Mitigation Investment

| Mitigation Category | Estimated Investment | Purpose |
|---------------------|---------------------|---------|
| Integration Testing | $75,000 | Early integration validation |
| Data Quality | $50,000 | Data profiling and cleansing |
| Change Management | $100,000 | Training, communication, adoption |
| Performance Engineering | $40,000 | Load testing, optimization |
| Contingency Reserve | $150,000 | Unforeseen issues (15% of budget) |
| **Total Risk Mitigation** | **$415,000** | |

---

## 3. Project Assumptions

### 3.1 Business Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-001 | Current Add/Change volume of ~2,500 requests/month will remain stable or grow | Capacity planning may be incorrect; may need to scale sooner |
| A-002 | Business rules for amendments and approvals are documented and stable | Delays in requirements; potential rework |
| A-003 | Customer self-service adoption will reach 30% within 6 months of launch | Lower efficiency gains; higher operational costs |
| A-004 | Existing pricing models will not change significantly during development | Rework of pricing engine; schedule delays |
| A-005 | Current vendor contracts allow for system integration modifications | May need contract renegotiation; legal delays |

### 3.2 Technical Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-010 | Quote Network Modernization services are stable and can be extended | Additional refactoring required; schedule impact |
| A-011 | Salesforce platform limits are sufficient for projected transaction volumes | Architecture redesign; potential platform upgrade costs |
| A-012 | MAS and Acorn APIs will remain stable during development | Integration rework; additional testing cycles |
| A-013 | Development and UAT sandbox environments are available | Delays in development and testing phases |
| A-014 | Existing authentication and security frameworks are sufficient | Security architecture work; compliance delays |
| A-015 | Feature flag infrastructure from Quote Network Modernization is reusable | Need to build new toggle mechanism; additional effort |

### 3.3 Resource Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-020 | 6 dedicated Salesforce developers available for project duration | Reduced velocity; extended timeline |
| A-021 | Business analysts with Add/Change domain expertise are available | Requirements delays; incorrect implementations |
| A-022 | QA resources can support 40% test automation target | More manual testing; longer test cycles |
| A-023 | Operations SMEs available 20% of their time for requirements and UAT | Requirements gaps; UAT delays |
| A-024 | External contractor support available if needed | May not be able to accelerate if behind schedule |

### 3.4 Organizational Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-030 | Executive sponsorship remains strong throughout project | Decisions delayed; resource conflicts |
| A-031 | No major organizational restructuring during project | Team disruption; knowledge loss |
| A-032 | Budget approved and protected from reallocation | Scope reduction; timeline extension |
| A-033 | Parallel projects will not compete for same resources | Resource conflicts; delivery delays |

---

## 4. Project Constraints

### 4.1 Time Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **6-Month Delivery Window** | Project must be completed within 6 months due to fiscal year alignment and regulatory deadlines | Limits scope; requires aggressive timeline management |
| **Q3 Freeze Period** | No production deployments allowed during Q3 financial close (3 weeks) | Compresses available deployment windows |
| **Training Lead Time** | Operations teams require 4 weeks training before go-live | Training must begin in Month 5 |
| **Customer Communication** | 60-day advance notice required for customer-facing changes | Portal launch requires early notification |

### 4.2 Budget Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Capital Budget: $1.2M** | Total approved project budget including contingency | Scope must fit within budget; trade-offs required |
| **No Additional Headcount** | Must be delivered with existing team plus contractors | Limits parallel workstreams |
| **Contractor Rate Caps** | Maximum contractor rates per corporate policy | May limit access to specialized skills |
| **Annual Subscription Limits** | No new platform subscriptions without separate approval | Must use existing tools and platforms |

### 4.3 Technical Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Salesforce Platform** | Must be built on existing Salesforce org | Architecture decisions bounded by platform |
| **Governor Limits** | Must operate within Salesforce governor limits | Design for bulk operations; async processing |
| **Existing Integrations** | Must work with current MAS, Acorn, billing integrations | Cannot redesign integration architecture |
| **Data Retention** | 7-year data retention requirement for audit compliance | Storage planning required |
| **Browser Support** | Must support Chrome, Edge, Firefox (latest 2 versions) | Cross-browser testing required |

### 4.4 Regulatory Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **SOX Compliance** | All financial transactions require audit trail | Comprehensive logging required |
| **Data Privacy** | Customer data handling per privacy regulations | Data masking; access controls |
| **Environmental Reporting** | Service changes must update environmental compliance records | Integration with compliance systems |

### 4.5 Organizational Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Change Advisory Board** | All production changes require CAB approval | Deployment scheduling dependencies |
| **Code Review Requirements** | All code requires peer review and security scan | Development velocity impact |
| **Documentation Standards** | Full technical and user documentation required | Documentation effort in scope |

---

## 5. Financial Benefits

### 5.1 Executive Financial Summary

| Benefit Category | Year 1 | Year 2 | Year 3 | 3-Year Total |
|------------------|--------|--------|--------|--------------|
| **Operational Efficiency** | $890,000 | $1,120,000 | $1,180,000 | $3,190,000 |
| **Revenue Protection** | $720,000 | $840,000 | $920,000 | $2,480,000 |
| **Revenue Acceleration** | $340,000 | $520,000 | $680,000 | $1,540,000 |
| **Cost Avoidance** | $280,000 | $380,000 | $420,000 | $1,080,000 |
| **Total Annual Benefits** | **$2,230,000** | **$2,860,000** | **$3,200,000** | **$8,290,000** |

| Investment | Amount |
|------------|--------|
| Project Investment | $1,200,000 |
| **Net 3-Year Value** | **$7,090,000** |
| **ROI** | **591%** |
| **Payback Period** | **6.5 months** |

### 5.2 Operational Efficiency Gains

#### 5.2.1 Processing Time Reduction

| Metric | Current | Future | Improvement |
|--------|---------|--------|-------------|
| Average Add/Change processing time | 5.2 days | 1.8 days | 65% reduction |
| Requests processed per FTE per day | 8 | 22 | 175% increase |
| Manual data entry steps | 14 | 4 | 71% reduction |
| System handoffs | 6 | 2 | 67% reduction |

**Financial Impact Calculation:**

```
Current Add/Change Volume:        2,500 requests/month = 30,000/year
Current Processing Cost:          $45 per request (labor + overhead)
Future Processing Cost:           $16 per request
Annual Savings:                   30,000 × ($45 - $16) = $870,000

Efficiency Improvement (Year 1):  $870,000
Growth Adjustment (Year 2):       $1,100,000 (20% volume growth)
Growth Adjustment (Year 3):       $1,150,000 (continued growth)
```

#### 5.2.2 Labor Reallocation

| Role | Current FTEs on Add/Change | Future FTEs | Reallocation |
|------|----------------------------|-------------|--------------|
| Service Coordinators | 12 | 5 | 7 FTEs to higher-value work |
| Quote Specialists | 8 | 4 | 4 FTEs to complex quotes |
| Data Entry Clerks | 4 | 0 | 4 FTEs eliminated (attrition) |
| **Total** | **24 FTEs** | **9 FTEs** | **15 FTEs** |

*Note: Reallocation enables handling 30% volume growth without new hires*

### 5.3 Revenue Protection

#### 5.3.1 Revenue Leakage Recovery

| Leakage Source | Current Annual Loss | Recovery Rate | Annual Recovery |
|----------------|---------------------|---------------|-----------------|
| Unbilled service additions | $380,000 | 85% | $323,000 |
| Missed price increases | $290,000 | 80% | $232,000 |
| Delayed change implementation | $180,000 | 90% | $162,000 |
| Equipment upgrade gaps | $95,000 | 75% | $71,000 |
| **Total Leakage** | **$945,000** | | **$788,000** |

**Calculation Basis:**
- Analysis of 12 months of billing adjustments and credits
- Customer audit findings from past 2 years
- Benchmark comparison with industry standards

#### 5.3.2 Billing Accuracy Improvement

| Metric | Current | Target | Revenue Impact |
|--------|---------|--------|----------------|
| First-time billing accuracy | 87% | 98% | $180,000/year saved in adjustments |
| Invoice dispute rate | 4.2% | 1.0% | $120,000/year in avoided credits |
| Collection cycle (days) | 38 | 32 | Improved cash flow |

### 5.4 Revenue Acceleration

#### 5.4.1 Faster Upsell Execution

| Scenario | Current Cycle | Future Cycle | Annual Revenue Impact |
|----------|---------------|--------------|----------------------|
| Equipment upgrades | 14 days | 3 days | $185,000 earlier recognition |
| Service additions | 10 days | 2 days | $120,000 earlier recognition |
| Frequency increases | 7 days | 1 day | $95,000 earlier recognition |

**Total Revenue Acceleration (Year 1):** $340,000
*(Based on earlier revenue recognition and reduced customer churn during long processing)*

#### 5.4.2 Customer Retention Impact

| Metric | Current | Target | Financial Impact |
|--------|---------|--------|------------------|
| Add/Change satisfaction score | 3.2/5.0 | 4.5/5.0 | Reduced churn |
| Customer churn from service issues | 2.8% | 1.5% | $280,000 retained revenue |
| NPS impact | +5 points | +15 points | Long-term revenue growth |

### 5.5 Cost Avoidance

#### 5.5.1 Avoided Technology Costs

| Item | Without Project | With Project | Savings |
|------|-----------------|--------------|---------|
| Legacy system maintenance | $180,000/year | $60,000/year | $120,000/year |
| Manual workaround tools | $45,000/year | $0 | $45,000/year |
| Duplicate data storage | $35,000/year | $10,000/year | $25,000/year |

#### 5.5.2 Avoided Headcount

| Scenario | Cost Avoided |
|----------|--------------|
| Without automation, 30% volume growth requires 6 additional FTEs | $420,000/year |
| Reduced overtime during peak periods | $60,000/year |

### 5.6 Financial Summary by Year

```
                            Year 1      Year 2      Year 3
                           --------    --------    --------
BENEFITS
Operational Efficiency     $890,000   $1,120,000  $1,180,000
Revenue Protection         $720,000     $840,000    $920,000
Revenue Acceleration       $340,000     $520,000    $680,000
Cost Avoidance            $280,000     $380,000    $420,000
                          ---------   ----------  ----------
Total Benefits          $2,230,000   $2,860,000  $3,200,000

COSTS
Project Investment      $1,200,000          $0          $0
Ongoing Support           $150,000    $160,000    $170,000
                        ----------   ---------   ---------
Total Costs             $1,350,000    $160,000    $170,000

NET BENEFIT               $880,000  $2,700,000  $3,030,000
Cumulative Net Benefit    $880,000  $3,580,000  $6,610,000
```

---

## 6. Cost of Inaction

### 6.1 Executive Summary: What Happens If We Don't Do This?

Failing to modernize our Add/Change capabilities will result in:
- **$4.7M in lost value over 3 years** (opportunity cost + direct losses)
- **Declining customer satisfaction** and increased churn
- **Inability to scale** operations to support business growth
- **Increasing technical debt** and system fragility
- **Competitive disadvantage** as market moves to digital self-service

### 6.2 Direct Financial Losses

| Loss Category | Year 1 | Year 2 | Year 3 | 3-Year Total |
|---------------|--------|--------|--------|--------------|
| Continued revenue leakage | $380,000 | $420,000 | $460,000 | $1,260,000 |
| Missed billing opportunities | $290,000 | $320,000 | $350,000 | $960,000 |
| Processing inefficiency costs | $450,000 | $520,000 | $580,000 | $1,550,000 |
| **Total Direct Losses** | **$1,120,000** | **$1,260,000** | **$1,390,000** | **$3,770,000** |

### 6.3 Competitive & Strategic Risks

#### 6.3.1 Customer Experience Degradation

| Risk | Probability | Impact | Description |
|------|-------------|--------|-------------|
| Customer churn increase | High | $500K+/year | Competitors offering faster, digital service |
| Negative reviews/reputation | Medium | Unquantified | Social media amplification of poor experiences |
| Lost upsell opportunities | High | $300K/year | Customers avoid changes due to friction |

#### 6.3.2 Market Position Erosion

| Factor | Current Position | Risk Without Investment |
|--------|------------------|------------------------|
| Service modification speed | Average | Below average within 2 years |
| Digital self-service | Limited | Significantly behind competitors |
| Customer portal | Basic | Outdated compared to market |

### 6.4 Operational Risks

#### 6.4.1 Scalability Failure

| Scenario | Impact |
|----------|--------|
| 30% volume growth with current process | Require 6+ new FTEs ($420K/year) |
| 50% volume growth with current process | Process breakdown, SLA failures |
| Acquisition integration | Unable to absorb additional volume |

#### 6.4.2 Key Person Dependencies

| Risk | Current State | Impact of Inaction |
|------|---------------|-------------------|
| Tribal knowledge | 3 people know full Add/Change process | Business continuity risk |
| Manual workarounds | Undocumented, person-dependent | Process failures when staff changes |
| System expertise | Concentrated in 2 developers | Development bottleneck |

### 6.5 Technical Debt Accumulation

#### 6.5.1 Growing Maintenance Burden

| Year | Additional Maintenance Cost | Cumulative |
|------|----------------------------|------------|
| Year 1 | $80,000 | $80,000 |
| Year 2 | $120,000 | $200,000 |
| Year 3 | $180,000 | $380,000 |

*Costs increase exponentially as fragmented code becomes harder to maintain*

#### 6.5.2 Integration Fragility

| System | Risk Level | Potential Impact |
|--------|------------|------------------|
| MAS Integration | High | Service orders fail; revenue impact |
| Billing Integration | High | Invoicing errors; customer disputes |
| Acorn Integration | Medium | Work order delays; service failures |

### 6.6 Regulatory & Compliance Risks

| Risk | Probability | Potential Cost |
|------|-------------|----------------|
| Audit finding: incomplete change trails | Medium | $200,000+ remediation |
| SOX compliance gap | Low | Material weakness finding |
| Environmental reporting errors | Medium | Regulatory fines |

### 6.7 Summary: 3-Year Cost of Inaction

| Category | 3-Year Cost |
|----------|-------------|
| Direct financial losses | $3,770,000 |
| Required additional headcount | $1,260,000 |
| Technical debt / maintenance | $380,000 |
| Competitive position impact | Unquantified |
| Compliance risk exposure | $200,000+ potential |
| **Total Quantified Cost** | **$5,610,000+** |

### 6.8 Comparison: Act vs. Don't Act

| Scenario | 3-Year Net Position |
|----------|---------------------|
| **Invest in Add/Change Enhancement** | +$6,610,000 (net benefits) |
| **Do Nothing** | -$5,610,000 (costs and losses) |
| **Difference** | **$12,220,000** |

---

## 7. Project Timeline

### 7.1 High-Level Timeline

```
Month 1        Month 2        Month 3        Month 4        Month 5        Month 6
|--------------|--------------|--------------|--------------|--------------|--------------|
[    PHASE 1: FOUNDATION     ][        PHASE 2: CORE BUILD        ][  PHASE 3: INTEGRATION  ]
                                                                    [PHASE 4: DEPLOY & ADOPT]
```

### 7.2 Detailed Phase Breakdown

#### Phase 1: Foundation (Weeks 1-8)

| Week | Activities | Deliverables |
|------|------------|--------------|
| 1-2 | Project kickoff, team onboarding | Project plan, RACI matrix |
| 2-3 | Requirements gathering, current state analysis | Requirements document |
| 3-4 | Architecture design, technical specifications | Technical design document |
| 4-5 | Environment setup, development standards | Dev environments ready |
| 5-6 | Core service framework development | AddChangeService foundation |
| 6-7 | Quote state machine implementation | State transition framework |
| 7-8 | Phase 1 testing and documentation | Phase 1 complete |

**Key Milestones:**
- Week 2: Requirements sign-off
- Week 4: Architecture approval
- Week 8: Foundation complete, demo to stakeholders

#### Phase 2: Core Build (Weeks 9-18)

| Week | Activities | Deliverables |
|------|------------|--------------|
| 9-10 | Amendment Processing Engine | Amendment service |
| 10-11 | Add Service workflow | Add Service capability |
| 11-12 | Change Service workflow | Change Service capability |
| 12-13 | Asset Modification orchestration | Asset change service |
| 13-14 | Vendor Change management | Vendor transition workflow |
| 14-15 | Approval automation engine | Approval routing service |
| 15-16 | Change impact calculator | Financial impact analysis |
| 16-17 | Work Order integration | Automated WO generation |
| 17-18 | Phase 2 integration testing | Core functionality complete |

**Key Milestones:**
- Week 12: Core Add/Change functionality demo
- Week 15: Approval automation demo
- Week 18: Core build complete, ready for integration

#### Phase 3: Integration (Weeks 19-22)

| Week | Activities | Deliverables |
|------|------------|--------------|
| 19 | MAS integration | MAS service changes flowing |
| 19-20 | Billing integration | Billing updates automated |
| 20-21 | Acorn integration | Work orders integrated |
| 21 | End-to-end testing | Integration test results |
| 21-22 | Performance testing | Performance benchmarks met |
| 22 | Security testing | Security approval |

**Key Milestones:**
- Week 20: All integrations functional
- Week 22: Integration phase complete, ready for UAT

#### Phase 4: Deployment & Adoption (Weeks 23-26)

| Week | Activities | Deliverables |
|------|------------|--------------|
| 23 | UAT execution | UAT sign-off |
| 23-24 | User training | Trained user base |
| 24 | Production deployment preparation | Deployment runbook |
| 25 | Phased production rollout | Production live |
| 25-26 | Hypercare support | Issue resolution |
| 26 | Project closure | Project complete |

**Key Milestones:**
- Week 23: UAT sign-off
- Week 25: Go-live
- Week 26: Project closure, transition to support

### 7.3 Resource Allocation

| Role | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Total Effort |
|------|---------|---------|---------|---------|--------------|
| Project Manager | 1.0 FTE | 1.0 FTE | 1.0 FTE | 1.0 FTE | 6 months |
| Business Analyst | 1.5 FTE | 1.0 FTE | 0.5 FTE | 0.5 FTE | 3.5 FTE-months |
| Technical Architect | 1.0 FTE | 0.5 FTE | 0.5 FTE | 0.25 FTE | 2.25 FTE-months |
| Senior Developers | 2.0 FTE | 4.0 FTE | 3.0 FTE | 1.0 FTE | 10 FTE-months |
| Junior Developers | 1.0 FTE | 2.0 FTE | 2.0 FTE | 0.5 FTE | 5.5 FTE-months |
| QA Engineers | 0.5 FTE | 1.5 FTE | 2.0 FTE | 1.0 FTE | 5 FTE-months |
| DevOps Engineer | 0.5 FTE | 0.5 FTE | 1.0 FTE | 0.5 FTE | 2.5 FTE-months |
| Training Specialist | 0 | 0 | 0.5 FTE | 1.0 FTE | 1.5 FTE-months |

### 7.4 Critical Path

```
Requirements → Architecture → Core Framework → Amendment Engine → Integration → UAT → Go-Live
     |              |              |                |              |         |
   Week 3        Week 4         Week 8          Week 14        Week 22   Week 25
```

**Critical Path Activities:**
1. Requirements completion (dependency: all design)
2. Architecture approval (dependency: development start)
3. Core framework completion (dependency: all services)
4. Amendment engine completion (dependency: integration)
5. Integration testing completion (dependency: UAT)
6. UAT sign-off (dependency: go-live)

### 7.5 Key Dependencies

| Dependency | Required By | Owner | Status |
|------------|-------------|-------|--------|
| Business requirements sign-off | Week 3 | Business Sponsor | Pending |
| Development environments | Week 4 | IT Operations | Pending |
| MAS API documentation | Week 19 | Integration Team | Pending |
| Billing system access | Week 19 | Finance IT | Pending |
| UAT test users | Week 23 | Operations | Pending |
| Production deployment window | Week 25 | CAB | Pending |

### 7.6 Quality Gates

| Gate | Week | Criteria | Approver |
|------|------|----------|----------|
| G1: Requirements | 3 | Requirements document approved | Business Sponsor |
| G2: Architecture | 4 | Technical design approved | Technical Architect |
| G3: Foundation | 8 | Core framework demonstrated | Project Sponsor |
| G4: Core Build | 18 | All core services functional | Project Manager |
| G5: Integration | 22 | All integrations tested | Integration Lead |
| G6: UAT | 23 | UAT sign-off received | Business Sponsor |
| G7: Go-Live | 25 | Production deployment approved | CAB |

---

## Appendices

### Appendix A: Stakeholder Register

| Stakeholder | Role | Interest | Influence | Engagement Strategy |
|-------------|------|----------|-----------|---------------------|
| Executive Sponsor | Decision maker | High | High | Weekly steering meetings |
| Operations Director | Primary user | High | High | Bi-weekly reviews |
| IT Director | Technical oversight | High | High | Architecture reviews |
| Finance Director | Budget owner | Medium | High | Monthly budget reviews |
| Customer Service Manager | End user | High | Medium | Sprint demos |
| Vendor Management | Affected process | Medium | Medium | Integration reviews |
| Customers | End beneficiary | High | Low | Portal feedback |

### Appendix B: Communication Plan

| Audience | Frequency | Channel | Content |
|----------|-----------|---------|---------|
| Steering Committee | Weekly | Meeting | Status, decisions, risks |
| Project Team | Daily | Standup | Progress, blockers |
| Stakeholders | Bi-weekly | Email | Progress report |
| Operations | Monthly | Presentation | Feature previews |
| All Staff | Quarterly | Newsletter | Project updates |

### Appendix C: Success Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| Add/Change processing time | 5.2 days | 1.8 days | Average cycle time |
| First-time accuracy | 87% | 98% | Error rate tracking |
| Customer satisfaction | 3.2/5.0 | 4.5/5.0 | Survey scores |
| Revenue leakage | $945K/year | <$100K/year | Billing audits |
| Self-service adoption | 0% | 30% | Portal analytics |
| Processing cost per request | $45 | $16 | Cost tracking |

### Appendix D: Approval Signatures

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Executive Sponsor | | | |
| Project Sponsor | | | |
| IT Director | | | |
| Finance Director | | | |
| Operations Director | | | |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | January 2026 | [Author] | Initial draft |
| 1.0 | January 2026 | [Author] | Final version for approval |
