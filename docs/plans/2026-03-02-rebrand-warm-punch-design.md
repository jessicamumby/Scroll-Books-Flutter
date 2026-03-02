# Rebrand: Warm Punch — Design

## Overview

Apply the new "Warm Punch" branding guidelines to the Scroll Books Flutter app. The rebrand replaces the current "Antique Study" palette (warm parchment, amber/gold accent) with a brighter cream base and a bold red/coral primary accent, and swaps the typeface pair from Playfair Display + DM Sans to Lora + Nunito.

Source: https://github.com/jessicamumby/Scroll-Books-Branding/blob/main/branding

---

## Colour Palette

| Current name | Current value | New name | New value |
|---|---|---|---|
| `page` | `#F4EDD8` | `page` | `#FFF9F2` |
| `surface` | `#FAF6EE` | `surface` | `#FFF0E0` |
| `surfaceAlt` | `#EDE0C4` | `surfaceAlt` | `#F0E0CC` |
| `border` | `#D3C09A` | `border` | `#F0E0CC` |
| `borderSoft` | `#E3D5B4` | `borderSoft` | `#F5EDE0` |
| `ink` | `#1E1A14` | `ink` | `#1C0F00` |
| `tobacco` | `#6B5B43` | `tobacco` | `#7A5C44` |
| `pewter` | `#9A8C78` | `pewter` | `#A08060` |
| `amber` (primary accent) | `#9A6F2A` | **`brand`** | `#FF4D2E` |
| `amberRich` | `#B8852E` | **`brandDark`** | `#E03A1C` |
| `amberPale` | `#E8D4A0` | **`brandPale`** | `#FFD0C8` |
| `amberWash` | `#F0E6C4` | **`brandWash`** | `#FFF2F0` |
| *(new)* | — | **`amber`** | `#FFB830` |

`fog`, `mahogany`, `sienna`, `forest`, `forestPale`, `coverDeep`, `coverRich` are unchanged.

The warm yellow `#FFB830` is introduced as a standalone `amber` secondary accent token.

---

## Typography

| Role | Current | New |
|---|---|---|
| Display / headings | Playfair Display | **Lora** |
| UI / body / labels | DM Sans | **Nunito** |

- Every `GoogleFonts.playfairDisplay(...)` → `GoogleFonts.lora(...)`
- Every `GoogleFonts.dmSans(...)` → `GoogleFonts.nunito(...)`
- `theme.dart` base: `dmSansTextTheme()` → `nunitoTextTheme()`
- Font weights and sizes unchanged

---

## Files

### Modified: `lib/core/theme.dart`
- All colour values updated per table above
- Token renames: `amber`→`brand`, `amberRich`→`brandDark`, `amberPale`→`brandPale`, `amberWash`→`brandWash`
- New `amber = Color(0xFFFFB830)` added
- `dmSansTextTheme()` → `nunitoTextTheme()`
- All `playfairDisplay` → `lora`, all `dmSans` → `nunito` within the theme

### Modified: all screens and widgets with inline references
Two mechanical passes on each file:
1. `AppTheme.amber` → `AppTheme.brand` (+ `amberRich`→`brandDark`, `amberPale`→`brandPale`, `amberWash`→`brandWash`)
2. `GoogleFonts.playfairDisplay(` → `GoogleFonts.lora(`, `GoogleFonts.dmSans(` → `GoogleFonts.nunito(`

Affected files:
- `lib/screens/landing_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/signup_screen.dart`
- `lib/screens/forgot_password_screen.dart`
- `lib/screens/change_password_screen.dart`
- `lib/screens/email_confirm_screen.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/screens/library_screen.dart`
- `lib/screens/book_detail_screen.dart`
- `lib/screens/reader_screen.dart`
- `lib/screens/stats_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/reading_style_screen.dart`
- `lib/widgets/app_shell.dart`
- `lib/widgets/reader/reader_card.dart` (if applicable)

### Unmodified
- All test files (no colour assertions; `GoogleFonts.config.allowRuntimeFetching = false` is font-agnostic)
- `lib/core/router.dart`, `lib/main.dart`, data files, services

---

## Out of Scope

- Font weight or size adjustments
- Layout or spacing changes
- Dark mode
- Any new UI components
