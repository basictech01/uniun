# Design System Specification: The Ethereal Interface

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Weightless Canvas."** 

To move beyond the generic "app-in-a-box" look, we are abandoning rigid structures in favor of an editorial, high-end mobile experience. This system prioritizes breathing room (negative space) and tonal depth over physical lines. By utilizing intentional asymmetry and a "stacking" philosophy, we create a UI that feels less like a technical tool and more like a premium digital concierge. The goal is a "non-technical" interface where the technology disappears, leaving only the content and the user’s intent.

---

## 2. Color & Tonal Depth
We move away from flat hex codes and toward a logic of **Atmospheric Layering**.

### The "No-Line" Rule
Standard 1px borders are strictly prohibited for sectioning. Layout boundaries must be defined exclusively through background shifts. For example, a `surface-container-low` section should sit directly on a `background` or `surface` base. If two areas must be separated, use a `2.75rem` (8) vertical spacing gap or a subtle shift in tonal value.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine vellum.
- **Base Layer:** `surface` (#f8f9fb) or `surface-container-lowest` (#ffffff).
- **Secondary Layer:** `surface-container` (#edeef0) for grouping related content.
- **Elevation Layer:** `surface-bright` for floating elements that need to capture the user's focus.

### The "Glass & Signature" Rule
To inject "soul" into the minimalist aesthetic:
- **Glassmorphism:** For floating headers or bottom navigation, use `surface` at 80% opacity with a `20px` backdrop blur. This allows content to bleed through, softening the interface.
- **Signature Gradients:** Main CTAs should not be flat. Use a subtle linear gradient from `primary` (#005ab6) to `primary-container` (#1672df) at a 135-degree angle to create a sense of tactile curvature.

---

## 3. Typography: The Editorial Voice
We use **Inter** as our primary typeface, leaning into its modern, neutral letterforms to convey "beginner-friendly" sophistication.

- **Display (display-lg/md):** Reserved for high-impact hero moments. Use `display-md` (2.75rem) with `-0.02em` letter spacing to create an authoritative, editorial look.
- **Headlines (headline-sm):** Use `headline-sm` (1.5rem) for page titles. Bold weight is preferred to anchor the page against the airy layout.
- **Body (body-lg):** The workhorse. Use `body-lg` (1rem) for all primary reading. Increase line-height to `1.6` to ensure the "breathable" feel is maintained even in text-heavy areas.
- **Labels (label-sm):** Used for micro-copy. Always in `on-surface-variant` (#414753) to ensure they feel secondary to the primary content.

---

## 4. Elevation & Depth
In this system, depth is felt, not seen. We avoid heavy drop shadows in favor of **Tonal Layering**.

- **The Layering Principle:** To create a "card" effect without a border, place a `surface-container-lowest` (#ffffff) object on top of a `surface-container` (#edeef0) background. The subtle 2-bit difference in gray creates a natural, soft lift.
- **Ambient Shadows:** When an element must float (e.g., a FAB or a Modal), use an ultra-diffused shadow: `0px 12px 32px rgba(0, 90, 182, 0.06)`. Note the use of a tinted shadow (using the `primary` hue) rather than black; this mimics natural light refraction.
- **The "Ghost Border" Fallback:** If a container sits on an identical color and requires definition, use `outline-variant` (#c1c6d5) at **15% opacity**. It should be felt as a whisper of an edge, never a hard line.

---

## 5. Components

### Buttons
- **Primary:** Gradient fill (`primary` to `primary-container`), `xl` (1.5rem) rounded corners. Text is `on-primary` (#ffffff), bold.
- **Secondary:** `surface-container-high` fill with `primary` text. No border.
- **Tertiary:** Transparent background, `primary` text, with a slightly increased letter-spacing for a sophisticated "link" look.

### Input Fields
- **Styling:** Use `surface-container-low` (#f2f4f6) as the fill. 
- **Interaction:** On focus, the background remains, but a 1px `primary` "Ghost Border" (20% opacity) appears. Avoid heavy focus rings.
- **Corners:** Stick strictly to the `lg` (1rem) rounding for a friendly, approachable feel.

### Cards & Lists
- **The Divider Ban:** Never use horizontal lines to separate list items. Use `1rem` (3) of vertical padding and a change in text weight to distinguish items.
- **Visual Grouping:** Group related list items inside a single `surface-container-lowest` container with `xl` (1.5rem) rounded corners to create a "nested" look.

### Signature Component: The "Content Halo"
For featured items, use a wide, soft glow using the `secondary-container` (#b8cfff) color at 30% opacity behind the element to draw the eye without using a traditional "border" or "shadow."

---

## 6. Do's and Don'ts

### Do:
- **Use Asymmetric Whitespace:** Allow more padding at the top of a container than the bottom to create a "weighted" editorial feel.
- **Stack Surfaces:** Use `surface-container-lowest` on top of `surface-container` to define sections.
- **Trust the Typography:** Let the font size and weight do the heavy lifting for hierarchy.

### Don't:
- **Don't use 1px solid borders:** This immediately breaks the high-end, "weightless" aesthetic.
- **Don't use pure black text:** Always use `on-surface` (#191c1e) to keep the contrast soft and readable.
- **Don't crowd the edges:** Maintain a minimum screen gutter of `2rem` (6) to ensure the design feels airy and premium.
- **Don't use standard shadows:** Avoid the default "black-at-25%" shadow; it makes the UI feel "dirty" and "technical."