---
id: brandkit-usage-altitudenow
title: "BrandKit Usage: AltitudeNow"
category: design-system
priority: p2
---

# BrandKit Usage — AltitudeNow

AltitudeNow brand: emerald `#33A673` / forest `#0E4A2C` / sage `#7DD3A1`

## Colors

```swift
// Brand accent
Text("Altitude").foregroundStyle(Color.brandPrimary)
Circle().fill(Color.brandSecondary)
Image(systemName: "mountain.2").foregroundStyle(Color.brandTint)

// Semantic surfaces
RoundedRectangle(cornerRadius: Radius.md).fill(Color.surface)
Text("Secondary info").foregroundStyle(Color.onSurfaceSecondary)

// Status
Text("GPS locked").foregroundStyle(Color.success)
Text("Low accuracy").foregroundStyle(Color.warning)
Text("Sensor error").foregroundStyle(Color.error)
```

## Typography

```swift
Text("AltitudeNow").font(Typography.h1)        // largeTitle rounded heavy
Text("Current altitude").font(Typography.h2)   // title rounded bold
Text("Section header").font(Typography.h3)     // title3 semibold
Text("Description").font(Typography.body)
Text("Important note").font(Typography.bodyEmphasis)
Text("Hint text").font(Typography.caption)
Text("1,234").font(Typography.displayNumber)   // 56pt heavy rounded — altitude readout
Text("1234 m").font(Typography.tabularBody)    // monospaced digits for altitude
```

## Spacing

```swift
VStack(spacing: Spacing.md) { ... }            // 16 pt gap
.padding(.horizontal, Spacing.lg)              // 24 pt side padding
.padding(.vertical, Spacing.sm)                // 8 pt vertical
HStack(spacing: Spacing.xs) { ... }            // 4 pt tight gap
```

## Corner radius

```swift
.cornerRadius(Radius.sm)                       // 6 — small chips
.cornerRadius(Radius.md)                       // 12 — cards, buttons
.cornerRadius(Radius.lg)                       // 20 — sheets, modals
Capsule() // or .cornerRadius(Radius.pill)     // 999 — pill badges
```

## Shadow / elevation

```swift
CardView()
    .brandCardShadow()                         // Elevation.card default
    .brandCardShadow(Elevation.hover)          // hover / focused state
```

## Migration guide

Replace scattered magic values with BrandKit tokens:

| Before | After |
|--------|-------|
| `Color.green` (brand use) | `Color.brandPrimary` |
| `Color.green.opacity(0.2)` (card bg) | `Color.brandPrimary.opacity(0.2)` |
| `Color(red: 0.20, green: 0.65, blue: 0.45)` | `Color.brandPrimary` |
| `Font.system(.title)` | `Typography.h2` |
| `padding(16)` | `padding(Spacing.md)` |
| `.cornerRadius(16)` | `.cornerRadius(Radius.lg)` |
| `shadow(radius: 6)` | `.brandCardShadow()` |

**Rule: no new magic values in new code. Use BrandKit semantic tokens.**
