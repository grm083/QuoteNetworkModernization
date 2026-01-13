# Quote Network Modernization Project Charter

## Document Control
| Field | Value |
|-------|-------|
| **Document Version** | 1.0 |
| **Date** | September 2025 |
| **Project Name** | Quote Network Modernization Initiative |
| **Project Code** | QNM-2025 |
| **Sponsor** | [Executive Sponsor Name] |
| **Project Manager** | [Project Manager Name] |
| **Status** | Approved for Execution |

---

## Executive Summary

The Quote Network Modernization Initiative is a strategic technical transformation project to decompose the monolithic `QuoteProcurementController` class—currently at 5,753 lines of code with 98 methods—into a modern, service-oriented architecture following SOLID principles.

This controller has become the single largest maintenance burden in our Salesforce codebase, responsible for 40% of all production incidents related to quote processing. The tightly coupled design makes changes risky, testing difficult, and onboarding new developers a 3-4 week endeavor.

Through systematic extraction of business logic into specialized services with feature-flag protection, this project will reduce defect rates by 60%, cut developer onboarding time by 85%, and establish an architectural foundation that supports the upcoming Add/Change enhancement initiative and future quote-related features.

**Investment:** $680,000 | **Duration:** 4 months | **ROI:** 425% over 3 years

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

The Quote Network Modernization Initiative will systematically refactor the monolithic `QuoteProcurementController` into a clean, testable, maintainable service-oriented architecture. This is a **technical transformation project** focused on code quality, maintainability, and developer productivity—not new feature development.

#### **The Problem We're Solving**

Our current `QuoteProcurementController.cls` has grown organically over 6+ years into an unmanageable monolith:

| Problem Metric | Current State | Industry Standard |
|----------------|---------------|-------------------|
| Lines of code | 5,753 | <500 per class |
| Methods per class | 98 | <20 per class |
| Cyclomatic complexity | 847 | <50 per class |
| Longest method | 533 lines (`createDelivery()`) | <50 lines |
| Duplicate code patterns | 27+ vendor checks | 0 duplicates |
| Test setup complexity | 50+ dependencies | <10 dependencies |
| Code review time | 2-4 hours | 30-60 minutes |
| Developer onboarding | 3-4 weeks | 3-5 days |

#### **Root Causes**

1. **Organic Growth**: Features added without architectural consideration
2. **No Service Layer**: All business logic embedded in controller
3. **Copy-Paste Culture**: Same validation logic duplicated 27+ times
4. **Fear of Refactoring**: Changes too risky without comprehensive tests
5. **Tribal Knowledge**: Only 2-3 developers understand the full codebase

#### **Core Capabilities to Be Delivered**

| Capability | Description |
|------------|-------------|
| **Service Layer Architecture** | Extract business logic into 50+ specialized, single-responsibility services |
| **Validation Framework** | Unified validation service with configurable rules and stage-based processing |
| **Delivery Orchestration** | Decompose 533-line `createDelivery()` into coordinated service calls |
| **Feature Flag Infrastructure** | Enable/disable services without code deployment for safe rollout |
| **Comprehensive Test Coverage** | 95%+ coverage with isolated, fast-running unit tests |
| **Developer Documentation** | Complete reference guide mapping functionality to code |

#### **Target Architecture**

```
BEFORE (Monolithic):                    AFTER (Service-Oriented):
┌─────────────────────────┐            ┌─────────────────────────┐
│ QuoteProcurementController│            │ QuoteProcurementController│
│        (5,753 lines)     │            │    (Thin Orchestration)  │
│                         │            │      (~4,200 lines)      │
│  ┌─────────────────────┐│            └───────────┬─────────────┘
│  │ Validation Logic    ││                        │
│  │ (scattered, duped)  ││            ┌───────────┴───────────┐
│  ├─────────────────────┤│            │     SERVICE LAYER     │
│  │ Delivery Creation   ││            ├───────────────────────┤
│  │ (533 lines, complex)││            │ QuoteLineValidation   │
│  ├─────────────────────┤│            │ DeliveryOrchestration │
│  │ Vendor Operations   ││            │ QuoteLineOperations   │
│  │ (27+ duplicate chks)││            │ QuoteDataMapper       │
│  ├─────────────────────┤│            │ VendorManagement      │
│  │ SLA/Special Handling││            │ SLAManagement         │
│  │ (mixed concerns)    ││            │ SpecialHandling       │
│  ├─────────────────────┤│            │ + 45 more services    │
│  │ Data Mapping        ││            └───────────────────────┘
│  │ (UI transformations)││
│  └─────────────────────┘│
└─────────────────────────┘
```

#### **Scope Definition**

**In Scope:**
- Decomposition of `QuoteProcurementController.cls` (5,753 lines)
- Extraction of `QuoteTriggerHandler` business logic
- Creation of validation service with 15+ configurable rules
- Delivery workflow orchestration service
- Vendor management service consolidation
- SLA and special handling service extraction
- Quote data mapping and transformation services
- Feature flag infrastructure for all new services
- Comprehensive unit and integration tests
- Developer reference documentation

**Out of Scope:**
- New feature development (will be enabled by this work)
- UI/UX changes (no user-facing changes)
- Database schema modifications
- Integration endpoint changes
- Other controller refactoring (future phases)

### 1.2 Business Drivers

| Driver | Description | Urgency |
|--------|-------------|---------|
| **Production Stability** | 40% of quote-related incidents trace to this controller | Critical |
| **Development Velocity** | Changes take 3x longer due to complexity and risk | High |
| **Add/Change Initiative** | Upcoming project requires extensible quote architecture | High |
| **Developer Retention** | Engineers frustrated with legacy code maintenance | Medium |
| **Technical Debt** | Compounding interest making future changes harder | Medium |
| **Audit/Compliance** | Difficult to demonstrate change control with monolith | Medium |

### 1.3 Strategic Alignment

This project directly enables:
- **Add/Change Service Enhancement** (planned Q2 2026): Requires service layer for amendment processing
- **Customer Self-Service Portal** (planned Q3 2026): Needs reusable quote services
- **Mobile Quote Management** (future): Service layer enables multi-channel access
- **AI-Assisted Quoting** (future): Clean services enable ML integration

### 1.4 Success Criteria

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Controller size | 5,753 lines | <4,500 lines | Line count |
| Longest method | 533 lines | <100 lines | Code analysis |
| Duplicate patterns | 27+ | 0 | Code review |
| Code coverage | 67% | 95%+ | Test execution |
| Defect rate (monthly) | 12 | <5 | Incident tracking |
| Code review time | 2-4 hours | 30-60 min | Time tracking |
| Developer onboarding | 3-4 weeks | 3-5 days | HR tracking |
| Change lead time | 5 days | 2 days | Deployment metrics |

---

## 2. Project Risks

### 2.1 Risk Register

| Risk ID | Risk Description | Probability | Impact | Risk Score | Mitigation Strategy |
|---------|------------------|-------------|--------|------------|---------------------|
| R-001 | **Regression Introduction**: Refactoring may introduce bugs in production functionality | High | Critical | **Critical** | Feature flags for instant rollback; comprehensive test coverage; parallel testing |
| R-002 | **Incomplete Understanding**: Hidden business logic not documented may be missed | High | High | **Critical** | Deep code analysis; stakeholder interviews; production log analysis |
| R-003 | **Scope Creep**: Pressure to add features during refactoring | Medium | High | **High** | Strict scope governance; separate backlog for enhancements |
| R-004 | **Performance Degradation**: Service layer may add latency | Medium | High | **High** | Performance benchmarks; load testing; optimization sprints |
| R-005 | **Resource Availability**: Key developers may be pulled for production issues | High | Medium | **High** | Dedicated team; knowledge transfer; backup resources |
| R-006 | **Integration Failures**: Services may not integrate correctly with existing code | Medium | High | **High** | Integration testing gates; phased rollout; monitoring |
| R-007 | **Test Coverage Gaps**: Edge cases may not be covered in new tests | Medium | Medium | **Medium** | Production scenario analysis; shadow testing; UAT |
| R-008 | **Stakeholder Resistance**: Teams may resist new patterns | Low | Medium | **Medium** | Training; documentation; developer advocacy |
| R-009 | **Governor Limit Violations**: Service calls may exceed Salesforce limits | Low | High | **Medium** | Limit monitoring; bulk operation patterns; async processing |
| R-010 | **Timeline Pressure**: Aggressive timeline may force shortcuts | Medium | Medium | **Medium** | Quality gates; scope flexibility; buffer time |

### 2.2 Critical Risk: Regression Introduction

Given the complexity of the existing code, regression is our highest risk. Detailed mitigation:

| Layer | Mitigation |
|-------|------------|
| **Prevention** | Comprehensive test coverage before extraction; code review gates |
| **Detection** | Parallel execution comparing old vs new; production monitoring |
| **Recovery** | Feature flags enable instant rollback without deployment |
| **Communication** | Incident response plan; stakeholder notification process |

### 2.3 Risk Mitigation Investment

| Mitigation Category | Estimated Investment | Purpose |
|---------------------|---------------------|---------|
| Extended Testing | $45,000 | Additional QA cycles, shadow testing |
| Performance Engineering | $25,000 | Load testing, optimization |
| Documentation | $20,000 | Comprehensive technical documentation |
| Training | $15,000 | Developer enablement |
| Contingency Reserve | $70,000 | Unforeseen issues (10% of budget) |
| **Total Risk Mitigation** | **$175,000** | |

---

## 3. Project Assumptions

### 3.1 Technical Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-001 | Existing unit tests accurately represent expected behavior | May extract incorrect logic; need production validation |
| A-002 | All business logic is contained within identified classes | May miss logic in triggers, flows, or other controllers |
| A-003 | Current code comments accurately describe intent | May misunderstand business rules; require stakeholder clarification |
| A-004 | Salesforce governor limits are sufficient for service layer | May need to redesign for async processing |
| A-005 | Feature flag pattern is supported by current infrastructure | May need additional framework development |
| A-006 | Test data factories can be created for isolated testing | May need significant test infrastructure investment |
| A-007 | No undocumented external integrations exist | May break unknown dependencies |

### 3.2 Business Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-010 | Business rules have not changed since code was written | May need business rule validation workshops |
| A-011 | Current functionality, even if buggy, is expected behavior | May need to preserve "bugs" as features |
| A-012 | Stakeholders can validate extracted service behavior | May not have business knowledge for validation |
| A-013 | No major regulatory changes during project | May need to accommodate new requirements |
| A-014 | Quote volume will remain stable during refactoring | Performance testing assumptions may be invalid |

### 3.3 Resource Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-020 | 4 senior Salesforce developers dedicated full-time | Reduced velocity; extended timeline |
| A-021 | Developers have experience with service-oriented patterns | May need training; slower initial progress |
| A-022 | Technical architect available for design guidance | May make suboptimal architectural decisions |
| A-023 | QA resources can support 50% automation target | More manual testing; longer cycles |
| A-024 | Subject matter experts available for requirements clarification | May implement incorrect business logic |

### 3.4 Organizational Assumptions

| ID | Assumption | Impact if Invalid |
|----|------------|-------------------|
| A-030 | Executive support for "no new features" scope | Scope creep pressure |
| A-031 | Production deployments allowed during project | May need to batch deployments; risk accumulation |
| A-032 | No competing projects for same resources | Resource conflicts |
| A-033 | Budget approved and protected | Scope reduction required |

---

## 4. Project Constraints

### 4.1 Time Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **4-Month Window** | Must complete before Add/Change initiative begins | Aggressive timeline; limited scope flexibility |
| **Deployment Windows** | Weekly deployment windows only | Must plan incremental releases |
| **Holiday Freeze** | No deployments during December holidays | Compresses Q4 timeline |
| **UAT Availability** | Business users available only 2 weeks for testing | Concentrated UAT period |

### 4.2 Budget Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Capital Budget: $680,000** | Total approved project budget | Must prioritize high-value extractions |
| **No External Contractors** | Must use internal resources | Limited by internal capacity |
| **No New Tools** | Must use existing development tools | Work within current capabilities |

### 4.3 Technical Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Zero Downtime** | Cannot take system offline for refactoring | Must use feature flags and gradual rollout |
| **Backward Compatibility** | All existing APIs must continue to function | Cannot change method signatures |
| **Salesforce Platform** | Must remain on current Salesforce version | Limited by platform capabilities |
| **Governor Limits** | Must operate within Salesforce limits | Design for efficiency |
| **Existing Integrations** | Cannot modify integration contracts | Service layer must be internal |

### 4.4 Quality Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **95% Code Coverage** | Minimum test coverage for all new services | Significant testing effort |
| **Code Review Required** | All changes require peer review | Development velocity impact |
| **Security Scan** | All code must pass security scanning | May identify issues requiring rework |
| **Documentation** | All services must be documented | Documentation effort in scope |

### 4.5 Organizational Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Change Advisory Board** | All production changes require CAB approval | Deployment scheduling |
| **Incident Response** | Team must support production issues | May interrupt development |
| **Knowledge Transfer** | Cannot rely on single developer | Pair programming requirement |

---

## 5. Financial Benefits

### 5.1 Executive Financial Summary

| Benefit Category | Year 1 | Year 2 | Year 3 | 3-Year Total |
|------------------|--------|--------|--------|--------------|
| **Developer Productivity** | $420,000 | $480,000 | $520,000 | $1,420,000 |
| **Defect Reduction** | $285,000 | $310,000 | $340,000 | $935,000 |
| **Faster Time-to-Market** | $180,000 | $250,000 | $320,000 | $750,000 |
| **Reduced Onboarding Cost** | $95,000 | $110,000 | $125,000 | $330,000 |
| **Infrastructure Efficiency** | $65,000 | $75,000 | $85,000 | $225,000 |
| **Total Annual Benefits** | **$1,045,000** | **$1,225,000** | **$1,390,000** | **$3,660,000** |

| Investment | Amount |
|------------|--------|
| Project Investment | $680,000 |
| **Net 3-Year Value** | **$2,980,000** |
| **ROI** | **438%** |
| **Payback Period** | **7.8 months** |

### 5.2 Developer Productivity Gains

#### 5.2.1 Code Change Velocity

| Metric | Current | Future | Improvement |
|--------|---------|--------|-------------|
| Average time to implement quote change | 5 days | 2 days | 60% reduction |
| Time spent understanding code | 40% | 15% | 63% reduction |
| Time spent in code review | 4 hours | 1 hour | 75% reduction |
| Regression testing per change | 8 hours | 2 hours | 75% reduction |

**Financial Impact Calculation:**

```
Developer fully-loaded cost:           $180,000/year = $90/hour
Quote-related changes per year:        240 changes
Current hours per change:              40 hours (avg)
Future hours per change:               16 hours (avg)
Hours saved per year:                  240 × (40-16) = 5,760 hours
Annual savings:                        5,760 × $90 = $518,400

Productivity Factor (Year 1):          80% realization = $414,720 ≈ $420,000
Year 2 (improved proficiency):         92% realization = $476,928 ≈ $480,000
Year 3 (full optimization):            100% realization = $518,400 ≈ $520,000
```

#### 5.2.2 Parallel Development Enablement

| Scenario | Current | Future |
|----------|---------|--------|
| Developers working on controller simultaneously | 1 | 4+ |
| Merge conflicts per sprint | 8-12 | 1-2 |
| Blocked developer hours per sprint | 24 | 4 |

**Impact**: Enables team scaling without proportional conflict increase

### 5.3 Defect Reduction

#### 5.3.1 Production Incident Reduction

| Metric | Current | Target | Financial Impact |
|--------|---------|--------|------------------|
| Monthly quote-related incidents | 12 | 4 | $180,000/year |
| Average incident resolution time | 4 hours | 2 hours | $54,000/year |
| Incidents requiring rollback | 3/month | 0.5/month | $45,000/year |
| Customer-impacting incidents | 4/month | 1/month | $90,000/year |

**Total Defect Reduction (Year 1):** $285,000

#### 5.3.2 Defect Prevention

| Factor | Impact |
|--------|--------|
| Isolated testing | Catch bugs before integration |
| Single responsibility | Reduce side effects |
| Code reviews | Faster, more effective reviews |
| Clear boundaries | Easier to reason about changes |

### 5.4 Faster Time-to-Market

#### 5.4.1 Feature Development Acceleration

| Feature Type | Current Lead Time | Future Lead Time | Revenue Impact |
|--------------|-------------------|------------------|----------------|
| Quote workflow changes | 4 weeks | 1.5 weeks | Earlier capability |
| Validation rule updates | 2 weeks | 3 days | Faster compliance |
| Integration enhancements | 6 weeks | 2 weeks | Earlier value delivery |

**Financial Impact:**
- Faster feature delivery enables earlier revenue recognition
- Competitive advantage through rapid response to market needs
- Estimated impact: $180,000 Year 1, growing as more features built on new architecture

#### 5.4.2 Add/Change Initiative Enablement

The Add/Change Service Enhancement project (estimated $2.2M Year 1 benefits) **depends on this modernization**:
- Amendment processing requires extensible validation framework
- Service layer enables workflow automation
- Feature flags enable safe rollout of complex changes

**Dependency Value**: Without modernization, Add/Change project would require 6+ additional months and $400,000+ additional investment.

### 5.5 Reduced Onboarding Cost

#### 5.5.1 Developer Onboarding

| Metric | Current | Future | Savings |
|--------|---------|--------|---------|
| Time to productivity (quote work) | 3-4 weeks | 3-5 days | 75% reduction |
| Senior developer mentoring time | 60 hours | 16 hours | 73% reduction |
| Documentation reading time | 40 hours | 8 hours | 80% reduction |
| First meaningful contribution | 4 weeks | 1 week | 75% faster |

**Financial Calculation:**

```
New developers per year:               4
Current onboarding cost:               $35,000 per developer
Future onboarding cost:                $9,000 per developer
Annual savings:                        4 × ($35,000 - $9,000) = $104,000

Conservative estimate (Year 1):        $95,000
```

### 5.6 Infrastructure Efficiency

| Benefit | Annual Savings |
|---------|----------------|
| Reduced test execution time (faster CI/CD) | $25,000 |
| Smaller deployment packages | $15,000 |
| Reduced debugging/logging overhead | $20,000 |
| Simplified monitoring | $15,000 |
| **Total** | **$75,000** |

### 5.7 Intangible Benefits

| Benefit | Description |
|---------|-------------|
| **Developer Satisfaction** | Engineers prefer working with clean code |
| **Talent Attraction** | Modern architecture attracts better candidates |
| **Knowledge Distribution** | Reduced key-person dependencies |
| **Audit Readiness** | Easier to demonstrate change control |
| **Future Flexibility** | Foundation for future enhancements |

---

## 6. Cost of Inaction

### 6.1 Executive Summary: What Happens If We Don't Do This?

Failing to modernize the Quote Network will result in:
- **$2.8M in direct costs over 3 years** from continued inefficiency and defects
- **Inability to execute Add/Change initiative** on planned timeline
- **Increasing developer turnover** due to frustration with legacy code
- **Growing incident rate** as complexity compounds
- **Eventual system failure** requiring emergency rewrite

### 6.2 Direct Financial Losses

| Loss Category | Year 1 | Year 2 | Year 3 | 3-Year Total |
|---------------|--------|--------|--------|--------------|
| Continued developer inefficiency | $320,000 | $360,000 | $400,000 | $1,080,000 |
| Production incident costs | $285,000 | $340,000 | $400,000 | $1,025,000 |
| Extended project timelines | $180,000 | $220,000 | $260,000 | $660,000 |
| Technical debt interest | $80,000 | $120,000 | $180,000 | $380,000 |
| **Total Direct Losses** | **$865,000** | **$1,040,000** | **$1,240,000** | **$3,145,000** |

### 6.3 Technical Debt Compound Interest

Technical debt grows exponentially. Current trajectory:

| Year | Complexity Index | Change Effort Multiplier | Defect Rate |
|------|------------------|--------------------------|-------------|
| Current | 847 | 1.0x | 12/month |
| Year 1 | 920 | 1.2x | 15/month |
| Year 2 | 1,050 | 1.5x | 20/month |
| Year 3 | 1,250 | 2.0x | 28/month |

**Projection**: By Year 3, changes will take **twice as long** and produce **2.3x more defects**.

### 6.4 Add/Change Initiative Impact

Without Quote Network Modernization:

| Impact | Consequence | Financial Effect |
|--------|-------------|------------------|
| Extended timeline | 6+ additional months | $400,000 additional cost |
| Reduced scope | Cannot deliver full capability | $800,000 reduced benefits |
| Higher risk | Building on unstable foundation | Increased failure probability |
| Technical debt | Adding complexity to monolith | Future costs accelerate |

**Total Add/Change Impact**: $1,200,000+ in delayed/reduced benefits

### 6.5 Developer Retention Risk

| Factor | Current Risk | Consequence |
|--------|--------------|-------------|
| Developer frustration | 3 of 8 quote developers considering leaving | Knowledge loss |
| Replacement cost | $50,000-80,000 per developer | Direct expense |
| Productivity loss | 6 months to full productivity | Velocity impact |
| Competitive disadvantage | Best engineers avoid legacy systems | Talent acquisition |

**Estimated Annual Risk**: $200,000 in turnover-related costs

### 6.6 System Stability Risk

**Current Incident Trend:**
```
2023 Q1: 8 incidents/month
2023 Q2: 10 incidents/month
2023 Q3: 11 incidents/month
2023 Q4: 12 incidents/month
2024 Q1: 14 incidents/month (projected)
```

**Projection**: Without intervention, by Q4 2025:
- 20+ incidents per month
- 1-2 critical outages per quarter
- Customer-impacting events increasing 50%

### 6.7 Competitive Disadvantage

| Factor | Impact |
|--------|--------|
| Slower feature delivery | Competitors respond faster to market |
| Higher costs | Less investment available for innovation |
| Quality perception | More customer-visible issues |
| Partner integration | Difficult to integrate with modern systems |

### 6.8 Summary: 3-Year Cost of Inaction

| Category | 3-Year Cost |
|----------|-------------|
| Direct operational losses | $3,145,000 |
| Add/Change initiative impact | $1,200,000 |
| Developer retention risk | $600,000 |
| Emergency remediation (probability-weighted) | $400,000 |
| **Total Quantified Cost** | **$5,345,000** |

### 6.9 Comparison: Act vs. Don't Act

| Scenario | 3-Year Net Position |
|----------|---------------------|
| **Invest in Quote Network Modernization** | +$2,980,000 (net benefits) |
| **Do Nothing** | -$5,345,000 (costs and losses) |
| **Difference** | **$8,325,000** |

---

## 7. Project Timeline

### 7.1 High-Level Timeline

```
Month 1        Month 2        Month 3        Month 4
|--------------|--------------|--------------|--------------|
[  PHASE 1    ][       PHASE 2              ][   PHASE 3   ]
 Foundation     Core Service Extraction       Integration &
                                              Stabilization
```

### 7.2 Phased Delivery Approach

The project will use a phased approach with feature flags, allowing incremental delivery and instant rollback capability.

#### Phase 1: Foundation (Weeks 1-4)

| Week | Activities | Deliverables |
|------|------------|--------------|
| 1 | Project kickoff, code analysis | Detailed extraction plan |
| 1-2 | Feature flag infrastructure | Toggle framework ready |
| 2-3 | Validation service framework | QuoteLineValidationService shell |
| 3-4 | First validation rules extraction | 5 validation rules migrated |
| 4 | Phase 1 testing and documentation | Phase 1 complete |

**Key Milestones:**
- Week 1: Extraction plan approved
- Week 2: Feature flag infrastructure deployed
- Week 4: First service in production (behind flag)

**Deliverables:**
- QuoteLineValidationService with strategy pattern
- 5 validation rules (ScheduleFrequency, VendorRequired, VendorActive, MASLibrary, OccurrenceType)
- Feature flag: `USE_VALIDATION_SERVICE`
- Test coverage: 95%+

#### Phase 2: Core Service Extraction (Weeks 5-12)

| Week | Focus Area | Services |
|------|------------|----------|
| 5-6 | Delivery Orchestration | DeliveryOrchestrationService, QuoteLineCollectorService |
| 6-7 | Asset & Baseline | AssetComparisonService, BaselineUpdateService |
| 7-8 | Order Creation | QuoteOrderFactory, ServiceDateManager |
| 8-9 | Quote Line Operations | QuoteLineOperationsService |
| 9-10 | Data Mapping | QuoteDataMapperService |
| 10-11 | Vendor Management | VendorManagementService (consolidate 27 checks) |
| 11-12 | Integration Services | MASIntegrationService, AssetAvailabilityService |

**Key Milestones:**
- Week 6: `createDelivery()` reduced from 533 to <50 lines
- Week 8: Delivery orchestration complete
- Week 10: Vendor checks consolidated (27→1)
- Week 12: Core extraction complete

**Deliverables per Sprint:**
- 3-5 new service classes
- Feature flags for each service
- Unit tests (95%+ coverage)
- Integration tests
- Updated documentation

#### Phase 3: Integration & Stabilization (Weeks 13-16)

| Week | Activities | Deliverables |
|------|------------|--------------|
| 13 | SLA Management Service | SLAManagementService |
| 13-14 | Special Handling Service | SpecialHandlingService |
| 14 | Product Configuration Service | ProductConfigurationService |
| 14-15 | Favorites Service | FavoritesService, FavoritesManagementService |
| 15 | End-to-end integration testing | Integration test results |
| 15-16 | Performance optimization | Performance benchmarks met |
| 16 | Documentation and training | Developer reference guide |
| 16 | Feature flag cleanup | Stable flags enabled by default |

**Key Milestones:**
- Week 14: All services extracted
- Week 15: Integration testing complete
- Week 16: Production stabilization complete

### 7.3 Service Extraction Schedule

| Phase | Service | Lines Extracted | Complexity | Feature Flag |
|-------|---------|-----------------|------------|--------------|
| 1 | QuoteLineValidationService | ~500 | High | USE_VALIDATION_SERVICE |
| 2 | DeliveryOrchestrationService | ~800 | Critical | USE_DELIVERY_ORCHESTRATION_SERVICE |
| 2 | QuoteLineCollectorService | ~235 | Medium | (part of delivery) |
| 2 | AssetComparisonService | ~175 | Medium | (part of delivery) |
| 2 | BaselineUpdateService | ~150 | Medium | (part of delivery) |
| 2 | ServiceDateManager | ~190 | Low | (part of delivery) |
| 2 | QuoteOrderFactory | ~310 | Medium | (part of delivery) |
| 2 | QuoteLineOperationsService | ~600 | High | USE_QUOTE_LINE_OPERATIONS_SERVICE |
| 2 | QuoteDataMapperService | ~450 | Medium | USE_DATA_MAPPER_SERVICE |
| 2 | VendorManagementService | ~300 | Medium | USE_VENDOR_SERVICE |
| 2 | MASIntegrationService | ~335 | High | USE_MAS_SERVICE |
| 2 | AssetAvailabilityService | ~360 | Medium | USE_AVAILABILITY_SERVICE |
| 3 | SLAManagementService | ~200 | Medium | USE_SLA_MANAGEMENT_SERVICE |
| 3 | SpecialHandlingService | ~150 | Low | USE_SPECIAL_HANDLING_SERVICE |
| 3 | ProductConfigurationService | ~250 | Medium | USE_PRODUCT_CONFIG_SERVICE |
| 3 | FavoritesService | ~140 | Low | (extracted from different controller) |

**Total New Service Code**: ~15,000+ lines
**Controller Reduction**: 5,753 → ~4,200 lines (27% reduction)

### 7.4 Resource Allocation

| Role | Phase 1 | Phase 2 | Phase 3 | Total Effort |
|------|---------|---------|---------|--------------|
| Technical Lead | 0.5 FTE | 0.5 FTE | 0.5 FTE | 2 FTE-months |
| Senior Developers | 2.0 FTE | 3.0 FTE | 2.0 FTE | 7 FTE-months |
| Mid-Level Developers | 1.0 FTE | 2.0 FTE | 1.5 FTE | 4.5 FTE-months |
| QA Engineers | 0.5 FTE | 1.0 FTE | 1.5 FTE | 3 FTE-months |
| Technical Writer | 0.25 FTE | 0.25 FTE | 0.5 FTE | 1 FTE-month |

### 7.5 Quality Gates

| Gate | Week | Criteria | Approver |
|------|------|----------|----------|
| G1: Extraction Plan | 1 | Plan approved, risks identified | Tech Lead |
| G2: Foundation | 4 | First service deployed, flags working | Project Manager |
| G3: Core Complete | 8 | Delivery orchestration working | Tech Lead |
| G4: Extraction Complete | 12 | All services extracted | Project Sponsor |
| G5: Integration | 15 | All integration tests passing | QA Lead |
| G6: Production Ready | 16 | Performance verified, documentation complete | Project Sponsor |

### 7.6 Deployment Strategy

```
Week 4:  ░░░░░░░░░░ QuoteLineValidationService (10% → 50% → 100%)
Week 6:  ░░░░░░░░░░ DeliveryOrchestrationService (10% → 50% → 100%)
Week 8:  ░░░░░░░░░░ QuoteLineOperationsService (10% → 50% → 100%)
Week 10: ░░░░░░░░░░ QuoteDataMapperService (10% → 50% → 100%)
Week 10: ░░░░░░░░░░ VendorManagementService (10% → 50% → 100%)
Week 12: ░░░░░░░░░░ Integration Services (10% → 50% → 100%)
Week 14: ░░░░░░░░░░ SLA/SpecialHandling (10% → 50% → 100%)
Week 16: ░░░░░░░░░░ All flags enabled by default, fallbacks removed
```

Each service follows gradual rollout:
1. **10%**: Initial production validation
2. **50%**: Expanded testing with monitoring
3. **100%**: Full production with fallback available
4. **Fallback Removal**: After 2 weeks at 100% with no issues

---

## Appendices

### Appendix A: Current Code Analysis

#### QuoteProcurementController.cls Breakdown

| Category | Methods | Lines | Complexity |
|----------|---------|-------|------------|
| Validation Logic | 12 | 890 | High |
| Delivery/Order Creation | 8 | 1,240 | Critical |
| Vendor Operations | 9 | 680 | Medium |
| Quote Line CRUD | 15 | 920 | Medium |
| Data Mapping/Wrappers | 11 | 750 | Medium |
| SLA/Special Handling | 6 | 380 | Medium |
| Integration Calls | 7 | 520 | High |
| Utility/Helper | 30 | 373 | Low |
| **Total** | **98** | **5,753** | |

#### Top 10 Methods by Complexity

| Method | Lines | Cyclomatic Complexity | Risk |
|--------|-------|----------------------|------|
| createDelivery() | 533 | 67 | Critical |
| buildWrapper() | 287 | 42 | High |
| validateStageQ() | 198 | 38 | High |
| addQuoteandQuoteine() | 245 | 35 | High |
| updateVendorDetails() | 156 | 28 | Medium |
| getQuoteProducts() | 134 | 24 | Medium |
| validateMASFields() | 142 | 26 | Medium |
| createQuoteOrders() | 178 | 31 | High |
| searchVendors() | 89 | 18 | Medium |
| updateSpecialHandling() | 94 | 19 | Medium |

#### Duplicate Code Patterns Identified

| Pattern | Occurrences | Lines Duplicated |
|---------|-------------|------------------|
| Vendor status check | 27 | ~135 |
| MAS library validation | 10 | ~80 |
| Quote line number calculation | 8 | ~40 |
| SLA date calculation | 5 | ~75 |
| Error message formatting | 15 | ~45 |

### Appendix B: Service Dependency Map

```
QuoteProcurementController
    │
    ├── QuoteLineValidationService
    │       └── ValidationRules (15 rules)
    │
    ├── DeliveryOrchestrationService
    │       ├── QuoteLineCollectorService
    │       ├── AssetComparisonService
    │       ├── BaselineUpdateService
    │       ├── ServiceDateManager
    │       ├── QuoteOrderFactory
    │       └── CommercialProductHandler
    │
    ├── QuoteLineOperationsService
    │       └── HaulAwayService
    │
    ├── QuoteDataMapperService
    │       └── AssetAvailabilityService
    │
    ├── VendorManagementService
    │
    ├── SLAManagementService
    │       └── EntitlementMatchingService
    │
    ├── SpecialHandlingService
    │
    ├── MASIntegrationService
    │
    └── ProductConfigurationService
```

### Appendix C: Feature Flag Implementation

```apex
// QuoteProcurementController.cls

// Feature flags for gradual rollout
@TestVisible private static Boolean USE_VALIDATION_SERVICE = true;
@TestVisible private static Boolean USE_DELIVERY_ORCHESTRATION_SERVICE = true;
@TestVisible private static Boolean USE_QUOTE_LINE_OPERATIONS_SERVICE = true;
@TestVisible private static Boolean USE_DATA_MAPPER_SERVICE = true;
@TestVisible private static Boolean USE_VENDOR_SERVICE = true;
@TestVisible private static Boolean USE_MAS_SERVICE = true;
@TestVisible private static Boolean USE_AVAILABILITY_SERVICE = true;
@TestVisible private static Boolean USE_SLA_MANAGEMENT_SERVICE = true;
@TestVisible private static Boolean USE_SPECIAL_HANDLING_SERVICE = true;
@TestVisible private static Boolean USE_PRODUCT_CONFIG_SERVICE = true;
@TestVisible private static Boolean USE_POSITION_SERVICE = true;
@TestVisible private static Boolean USE_WORK_ORDER_SERVICE = true;

// Usage pattern
@AuraEnabled
public static void someMethod() {
    if (USE_VALIDATION_SERVICE) {
        try {
            validationService.validate(quoteLine);
            return;
        } catch (Exception ex) {
            // Log and fall back
        }
    }
    // Original implementation as fallback
}
```

### Appendix D: SDT Stories Addressed

| Story | Description | Service |
|-------|-------------|---------|
| SDT-45005 | Filter parent vendors from search | VendorManagementService |
| SDT-29645 | Vendor facility codes | VendorManagementService |
| SDT-32753 | Removal/swapout size validation | QuoteLineValidationService |
| SDT-41532 | Stepped pricing validation | QuoteLineValidationService |
| SDT-30089 | Special handling auto-detection | SpecialHandlingService |
| SDT-31144 | Special handling details clearing | SpecialHandlingService |
| SDT-25005 | SLA override comments | SLAManagementService |
| SDT-48501 | Comment record creation | SLAManagementService |
| SDT-44574 | Haul Away integration | HaulAwayService |
| SDT-32782 | Extra pickup handling | DeliveryOrchestrationService |
| SDT-41184 | Recursive trigger prevention | DeliveryOrchestrationService |
| SDT-30092 | Commercial product delivery | CommercialProductHandler |
| SDT-29961 | SLA for alternate products | SLAManagementService |
| SDT-39637 | Location timezone SLA | SLAManagementService |
| SDT-45007 | Entitlement timezone | SLAManagementService |

### Appendix E: Approval Signatures

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Executive Sponsor | | | |
| Project Sponsor | | | |
| Technical Lead | | | |
| IT Director | | | |
| Operations Director | | | |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | September 2025 | [Author] | Initial draft |
| 0.2 | September 2025 | [Author] | Added financial analysis |
| 1.0 | September 2025 | [Author] | Final version for approval |
