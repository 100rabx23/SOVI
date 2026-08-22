---
name: Acoustic Intelligence System
colors:
  surface: '#10141a'
  surface-dim: '#10141a'
  surface-bright: '#353940'
  surface-container-lowest: '#0a0e14'
  surface-container-low: '#181c22'
  surface-container: '#1c2026'
  surface-container-high: '#262a31'
  surface-container-highest: '#31353c'
  on-surface: '#dfe2eb'
  on-surface-variant: '#bbc9cf'
  inverse-surface: '#dfe2eb'
  inverse-on-surface: '#2d3137'
  outline: '#859398'
  outline-variant: '#3c494e'
  surface-tint: '#3cd7ff'
  primary: '#a8e8ff'
  on-primary: '#003642'
  primary-container: '#00d4ff'
  on-primary-container: '#00586b'
  inverse-primary: '#00677e'
  secondary: '#7dffa2'
  on-secondary: '#003918'
  secondary-container: '#05e777'
  on-secondary-container: '#00622e'
  tertiary: '#cfe0fa'
  on-tertiary: '#213145'
  tertiary-container: '#b3c4de'
  on-tertiary-container: '#415167'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#b4ebff'
  primary-fixed-dim: '#3cd7ff'
  on-primary-fixed: '#001f27'
  on-primary-fixed-variant: '#004e5f'
  secondary-fixed: '#62ff96'
  secondary-fixed-dim: '#00e475'
  on-secondary-fixed: '#00210b'
  on-secondary-fixed-variant: '#005226'
  tertiary-fixed: '#d3e4fe'
  tertiary-fixed-dim: '#b7c8e1'
  on-tertiary-fixed: '#0b1c30'
  on-tertiary-fixed-variant: '#38485d'
  background: '#10141a'
  on-background: '#dfe2eb'
  surface-variant: '#31353c'
typography:
  display-metrics:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 24px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

The design system is engineered to evoke the precision of a high-end laboratory instrument and the forward-leaning aesthetic of a secure data-transmission node. The brand personality is rooted in **"Acoustic Integrity"**—positioning invisible file transfer as a tangible, high-performance feat of engineering.

The visual direction follows a **Modern Technical** aesthetic with **Glassmorphism** accents. It prioritizes clarity and functional density, ensuring the user feels in control of a complex physical process. High-transparency layers and vibrant accents against a deep void create a sense of depth and focus, mirroring the way sound waves travel through space.

## Colors

The palette is designed for high-contrast legibility in low-light environments, emphasizing signal over noise.

- **Primary (Electric Blue):** Reserved for active signals, data transmission indicators, and primary calls to action. It represents the "pulse" of the application.
- **Secondary (Emerald Green):** Used exclusively for security confirmations, successful handshake protocols, and completed transfers.
- **Neutral (Deep Navy & Slate):** The foundational "void." Slate grays are used for structural elements and secondary metadata to maintain a clean hierarchy.
- **Functional Accents:** Use low-opacity variants of the primary color for background glows to simulate active acoustic fields.

## Typography

This design system utilizes a dual-font approach to balance human readability with technical precision.

- **Primary Interface (Inter):** Used for all standard UI elements, headlines, and body copy. It provides a clean, modern, and trustworthy foundation.
- **Technical Metrics (JetBrains Mono):** Monospaced type is used for file sizes, transfer speeds, encryption keys, and timestamps. This reinforces the "engineered" nature of the product.
- **Display Metrics:** Large, bold weights are used for the primary data point (e.g., % of file transferred) to ensure it is the immediate focal point of the screen.

## Layout & Spacing

The layout is built on a **4px baseline grid** to ensure mathematical precision in element alignment. 

- **Grid System:** A 12-column fluid grid for desktop, collapsing to a single-column layout for mobile.
- **Information Density:** High density is encouraged for technical readouts, while "Action Zones" (like the transmission button) should be surrounded by generous whitespace to prevent errors.
- **Margins:** Standard 24px safe-area margins for mobile devices to accommodate edge-to-edge glass components.

## Elevation & Depth

Depth is conveyed through **Tonal Layering** and **Backdrop Blurs** rather than traditional heavy shadows.

- **Base Layer:** The deepest navy (#0A0E14), representing the silent background.
- **Surface Layer:** Semi-transparent containers (Background: `rgba(20, 27, 37, 0.7)`) with a `20px` backdrop blur. This creates a "glass" effect that suggests sophisticated technology.
- **Borders:** Use thin (1px), low-opacity slate borders (`rgba(100, 116, 139, 0.3)`) to define shapes without creating visual bulk.
- **Glows:** For active states, use a soft, 15% opacity outer glow of the Primary Electric Blue color to simulate a radiating acoustic signal.

## Shapes

The shape language is "Soft" yet disciplined. While most containers use a 0.25rem (4px) radius to maintain a professional, sharp-edged feel, specific interactive elements utilize larger radii for ergonomics.

- **Standard Containers:** 4px (Soft) radius for a precise, "rack-mounted" look.
- **Interactive Controls:** 8px (Large) radius for buttons and inputs to provide a clear hit-target affordance.
- **Progress Indicators:** Perfect circles are used for frequency oscillators and circular progress bars to mirror the physics of sound waves.

## Components

### Buttons
- **Primary:** Solid Electric Blue with white or deep navy text. 8px corner radius.
- **Secondary:** Ghost style with a 1px Slate border and transparent background.
- **Status:** Integrated icons for "Handshake" or "Signal Strength" status within the button label.

### Cards
- Glassmorphic construction. 1px Slate border. 
- Internal padding of 16px or 24px depending on data complexity.
- Headers should include a JetBrains Mono label for the technical category.

### Circular Progress Indicators
- A dual-ring system: a faint, static background ring and a high-glow Electric Blue active ring.
- Centered numerical percentage using the `display-metrics` type style.

### Acoustic Waveforms
- Real-time frequency visualizers should use 2px wide vertical bars with variable heights.
- Colors should oscillate between Primary Blue and Secondary Green to indicate signal health and security status.

### Inputs
- Dark-filled inputs with 1px borders that "ignite" (glow Primary Blue) upon focus.
- Monospaced text for data input to ensure character alignment (important for keys and codes).