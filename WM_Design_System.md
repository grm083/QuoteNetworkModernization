# WM Quote Platform Design System
## Brand-Aligned Lightning Web Components

---

## Brand Colors (WM + Salesforce Lightning)

### Primary Palette (WM Brand)
```css
--wm-green-primary: #1c8200;      /* Primary actions, CTAs, success states */
--wm-green-dark: #135B00;         /* Hover states, darker accents */
--wm-teal-dark: #024731;          /* Headings, primary text, dark mode */
--wm-sand-light: #F8F8F2;         /* Section backgrounds, subtle contrast */
--wm-gray-neutral: #4f4f58;       /* Body text, secondary content */
```

### Extended Palette (Status & Semantic)
```css
/* Success (use WM green) */
--color-success: #1c8200;
--color-success-dark: #135B00;

/* Warning (balance WM brand with standard orange) */
--color-warning: #FF8B00;         /* Adjusted from standard #FFB75D for WM aesthetic */
--color-warning-light: #FFE6CC;

/* Error (standard Salesforce with slight WM warmth) */
--color-error: #C23934;           /* Slightly muted from pure red */
--color-error-light: #FEDED8;

/* Info (WM teal) */
--color-info: #024731;
--color-info-light: #CCE5DC;

/* In Progress (purple remains from SLDS) */
--color-progress: #9050E9;
--color-progress-light: #E8DCFF;
```

### Neutral Scale
```css
--color-background-primary: #FFFFFF;
--color-background-section: #F8F8F2;      /* WM sand */
--color-background-hover: #F3F3F3;
--color-background-selected: #E5F8E0;     /* Green tint for WM */

--color-text-primary: #024731;            /* WM teal */
--color-text-secondary: #4f4f58;          /* WM gray */
--color-text-tertiary: #999999;
--color-text-inverse: #FFFFFF;

--color-border-primary: #DDDDDD;
--color-border-secondary: #E5E5E5;
--color-border-focus: #1c8200;            /* WM green */
```

---

## Typography

### Font Families
```css
/* Primary: WM Maax family with fallbacks */
--font-family-primary: "Maax-Regular", -apple-system, BlinkMacSystemFont,
                       "Segoe UI", Arial, sans-serif;
--font-family-bold: "Maax-Bold", -apple-system, BlinkMacSystemFont,
                    "Segoe UI", Arial, sans-serif;
--font-family-black: "Maax-Black", -apple-system, BlinkMacSystemFont,
                     "Segoe UI", Arial, sans-serif;
--font-family-medium: "Maax-Medium", -apple-system, BlinkMacSystemFont,
                      "Segoe UI", Arial, sans-serif;

/* Monospace for code/IDs */
--font-family-mono: "Courier New", Courier, monospace;
```

**Note**: If Maax fonts are not available in Salesforce environment, fallback to system fonts. Consider using `@font-face` if licensing permits.

### Font Scale (Responsive)
```css
/* Mobile (375px - 767px) */
--font-size-h1: 2rem;        /* 32px */
--font-size-h2: 1.5rem;      /* 24px */
--font-size-h3: 1.25rem;     /* 20px */
--font-size-h4: 1.125rem;    /* 18px */
--font-size-body: 1rem;      /* 16px */
--font-size-small: 0.875rem; /* 14px */
--font-size-tiny: 0.75rem;   /* 12px */

/* Desktop (1024px+) */
@media (min-width: 1024px) {
  --font-size-h1: 3.375rem;  /* 54px - WM hero size */
  --font-size-h2: 2.75rem;   /* 44px */
  --font-size-h3: 1.5rem;    /* 24px */
  --font-size-h4: 1.25rem;   /* 20px */
  --font-size-body: 1rem;    /* 16px */
  --font-size-small: 0.875rem;
  --font-size-tiny: 0.75rem;
}
```

### Font Weights
```css
--font-weight-regular: 400;
--font-weight-medium: 500;
--font-weight-bold: 700;
--font-weight-black: 900;
```

---

## Spacing System

### Scale (Based on 8px grid)
```css
--spacing-xxxs: 0.125rem;  /* 2px */
--spacing-xxs: 0.25rem;    /* 4px */
--spacing-xs: 0.5rem;      /* 8px */
--spacing-sm: 0.75rem;     /* 12px */
--spacing-md: 1rem;        /* 16px */
--spacing-lg: 1.5rem;      /* 24px */
--spacing-xl: 2rem;        /* 32px */
--spacing-xxl: 3rem;       /* 48px */
--spacing-xxxl: 4rem;      /* 64px */
```

---

## Component Styles

### Buttons

#### Primary Button (WM Green)
```css
.wm-button-primary {
  background-color: var(--wm-green-primary);
  color: var(--color-text-inverse);
  border: none;
  border-radius: 0.25rem;
  padding: 0.875rem 2rem;
  font-family: var(--font-family-bold);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  min-height: 3.5rem;
  cursor: pointer;
  transition: background-color 0.2s ease, box-shadow 0.2s ease;
}

.wm-button-primary:hover:not(:disabled) {
  background-color: var(--wm-green-dark);
  box-shadow: 0 4px 8px rgba(28, 130, 0, 0.3);
}

.wm-button-primary:focus {
  outline: 2px dashed var(--wm-green-primary);
  outline-offset: 4px;
}

.wm-button-primary:disabled {
  background-color: #CCCCCC;
  color: rgba(255, 255, 255, 0.6);
  cursor: not-allowed;
}
```

#### Secondary Button
```css
.wm-button-secondary {
  background-color: transparent;
  color: var(--wm-green-primary);
  border: 2px solid var(--wm-green-primary);
  border-radius: 0.25rem;
  padding: 0.875rem 2rem;
  font-family: var(--font-family-bold);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  min-height: 3.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.wm-button-secondary:hover:not(:disabled) {
  background-color: var(--wm-green-primary);
  color: var(--color-text-inverse);
}
```

#### Destructive Button
```css
.wm-button-destructive {
  background-color: var(--color-error);
  color: var(--color-text-inverse);
  /* ... similar structure to primary */
}
```

### Cards

```css
.wm-card {
  background-color: var(--color-background-primary);
  border: 1px solid var(--color-border-secondary);
  border-radius: 0.5rem;
  padding: var(--spacing-lg);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  transition: box-shadow 0.2s ease;
}

.wm-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.wm-card-header {
  font-family: var(--font-family-bold);
  font-size: var(--font-size-h4);
  color: var(--wm-teal-dark);
  margin-bottom: var(--spacing-md);
  padding-bottom: var(--spacing-sm);
  border-bottom: 2px solid var(--color-border-secondary);
}
```

### Status Badges

```css
.wm-badge-success {
  background-color: var(--wm-green-primary);
  color: var(--color-text-inverse);
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: var(--font-size-small);
  font-family: var(--font-family-medium);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.wm-badge-warning {
  background-color: var(--color-warning);
  color: var(--wm-teal-dark);
  /* ... similar structure */
}

.wm-badge-error {
  background-color: var(--color-error);
  color: var(--color-text-inverse);
  /* ... similar structure */
}

.wm-badge-info {
  background-color: var(--color-info);
  color: var(--color-text-inverse);
  /* ... similar structure */
}
```

### Form Inputs

```css
.wm-input {
  font-family: var(--font-family-primary);
  font-size: var(--font-size-body);
  color: var(--color-text-primary);
  background-color: var(--color-background-primary);
  border: 1px solid var(--color-border-primary);
  border-radius: 0.25rem;
  padding: 0.75rem 1rem;
  min-height: 2.5rem;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.wm-input:focus {
  outline: none;
  border-color: var(--wm-green-primary);
  box-shadow: 0 0 0 3px rgba(28, 130, 0, 0.1);
}

.wm-input:disabled {
  background-color: var(--color-background-section);
  color: var(--color-text-tertiary);
  cursor: not-allowed;
}

.wm-input-error {
  border-color: var(--color-error);
}

.wm-input-error:focus {
  box-shadow: 0 0 0 3px rgba(194, 57, 52, 0.1);
}
```

### Labels

```css
.wm-label {
  font-family: var(--font-family-medium);
  font-size: var(--font-size-small);
  color: var(--color-text-primary);
  margin-bottom: var(--spacing-xs);
  display: block;
}

.wm-label-required::after {
  content: " *";
  color: var(--color-error);
}
```

---

## Icons

### Icon Colors (Status-Based)
```css
.wm-icon-success { color: var(--wm-green-primary); }
.wm-icon-warning { color: var(--color-warning); }
.wm-icon-error { color: var(--color-error); }
.wm-icon-info { color: var(--color-info); }
.wm-icon-neutral { color: var(--color-text-secondary); }
```

### Icon Sizes
```css
--icon-size-xs: 16px;
--icon-size-sm: 20px;
--icon-size-md: 24px;
--icon-size-lg: 32px;
--icon-size-xl: 48px;
```

---

## Layout Breakpoints

```css
/* Mobile First */
--breakpoint-mobile: 375px;   /* Mobile (default) */
--breakpoint-tablet: 768px;   /* Tablet */
--breakpoint-desktop: 1024px; /* Desktop */
--breakpoint-wide: 1440px;    /* Wide desktop */
```

---

## Animation & Transitions

```css
--transition-fast: 0.15s ease;
--transition-normal: 0.2s ease;
--transition-slow: 0.3s ease;

--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
--ease-out: cubic-bezier(0.0, 0, 0.2, 1);
--ease-in: cubic-bezier(0.4, 0, 1, 1);
```

### Hover Effects
```css
.wm-hover-lift {
  transition: transform var(--transition-normal), box-shadow var(--transition-normal);
}

.wm-hover-lift:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}
```

---

## Accessibility

### Focus States
```css
.wm-focus-visible:focus-visible {
  outline: 2px dashed var(--wm-green-primary);
  outline-offset: 4px;
}
```

### Skip Links
```css
.wm-skip-link {
  position: absolute;
  left: -9999px;
  top: auto;
  width: 1px;
  height: 1px;
  overflow: hidden;
}

.wm-skip-link:focus {
  position: fixed;
  top: 0;
  left: 0;
  width: auto;
  height: auto;
  padding: var(--spacing-md);
  background-color: var(--wm-green-primary);
  color: var(--color-text-inverse);
  z-index: 10000;
}
```

### Screen Reader Only
```css
.wm-sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

---

## Component-Specific Patterns

### Progress Bar
```css
.wm-progress-bar {
  width: 100%;
  height: 8px;
  background-color: var(--color-border-secondary);
  border-radius: 4px;
  overflow: hidden;
}

.wm-progress-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--wm-green-primary), var(--wm-green-dark));
  transition: width var(--transition-normal);
}
```

### Validation States
```css
.wm-validation-success {
  border-left: 4px solid var(--wm-green-primary);
  background-color: rgba(28, 130, 0, 0.05);
  padding: var(--spacing-md);
  border-radius: 0.25rem;
}

.wm-validation-warning {
  border-left: 4px solid var(--color-warning);
  background-color: rgba(255, 139, 0, 0.05);
  padding: var(--spacing-md);
  border-radius: 0.25rem;
}

.wm-validation-error {
  border-left: 4px solid var(--color-error);
  background-color: rgba(194, 57, 52, 0.05);
  padding: var(--spacing-md);
  border-radius: 0.25rem;
}
```

### Alert Icons Hierarchy
```css
/* Blocker (must fix) */
.wm-alert-blocker {
  color: var(--color-error);
  font-size: var(--icon-size-lg);
  animation: pulse 2s infinite;
}

/* Warning (should fix) */
.wm-alert-warning {
  color: var(--color-warning);
  font-size: var(--icon-size-md);
}

/* Info (FYI) */
.wm-alert-info {
  color: var(--color-info);
  font-size: var(--icon-size-sm);
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}
```

---

## Usage in Lightning Web Components

### CSS Module Example
```css
/* quoteFlowContainer.css */
:host {
  display: block;
  font-family: var(--font-family-primary);
  color: var(--color-text-primary);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--spacing-lg);
  background-color: var(--color-background-section);
}

.header {
  background-color: var(--color-background-primary);
  padding: var(--spacing-lg) var(--spacing-xl);
  border-bottom: 2px solid var(--wm-green-primary);
}

.header-title {
  font-family: var(--font-family-bold);
  font-size: var(--font-size-h2);
  color: var(--wm-teal-dark);
}

/* Mobile adjustments */
@media (max-width: 767px) {
  .container {
    padding: var(--spacing-md);
  }

  .header {
    padding: var(--spacing-md);
  }
}
```

### Lightning Button Override
```html
<!-- Use lightning-button with custom class -->
<lightning-button
  label="Get Pricing"
  class="wm-button-primary"
  onclick={handleGetPricing}>
</lightning-button>
```

### Custom CSS Variables in LWC
```css
/* Apply WM theme to Lightning components */
lightning-button.wm-button-primary {
  --slds-c-button-brand-color-background: var(--wm-green-primary);
  --slds-c-button-brand-color-background-hover: var(--wm-green-dark);
  --slds-c-button-brand-text-color: var(--color-text-inverse);
}

lightning-progress-bar.wm-progress {
  --slds-c-progress-bar-color-background: var(--color-border-secondary);
  --slds-c-progress-bar-color-background-fill: var(--wm-green-primary);
}
```

---

## Component Class Naming Convention

```
.wm-{component}-{element}-{modifier}

Examples:
.wm-card
.wm-card-header
.wm-card-header-large

.wm-button-primary
.wm-button-primary-disabled

.wm-wizard-step
.wm-wizard-step-active
.wm-wizard-step-complete
```

---

## Brand Personality in UI Text

Following WM's professional, action-oriented tone:

**Do:**
- "Get Pricing" (action-oriented, clear)
- "Service Ready" (positive, active)
- "Fix Now" (direct, helpful)
- "Why this date?" (conversational, transparent)

**Don't:**
- "Click here to request pricing" (passive, wordy)
- "Your service is complete" (passive voice)
- "There is an error" (vague)
- "SLA calculation explanation" (jargon)

---

## Implementation Checklist

- [ ] Import WM brand colors as CSS custom properties
- [ ] Apply Maax fonts (or fallback to system fonts)
- [ ] Override Lightning component styling with WM theme
- [ ] Test all interactive states (hover, focus, disabled)
- [ ] Verify color contrast ratios (WCAG AA minimum 4.5:1 for text)
- [ ] Test keyboard navigation with focus indicators
- [ ] Validate responsive behavior at 375px, 768px, 1024px
- [ ] Ensure consistent spacing using 8px grid
- [ ] Apply WM button styling to primary actions
- [ ] Use WM green for success states, not SLDS green
