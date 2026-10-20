# Topildi: design handoff for implementation

Topildi is a lost & found app (Flutter, Material 3, Android + iOS). Someone who finds an item posts it, and the owner proves ownership with a **hidden detail** before the item is returned. People who lose something can also post a "Lost" listing.

All UI text is **Uzbek Latin**. Use `ʻ` (U+02BB) in oʻ/gʻ and `ʼ` (U+02BC) in words like eʼlon. Never use `'` or `‘`.

## What's in this folder

| Path | What it is |
|---|---|
| `topildi_theme.dart` | **Source of truth for tokens.** Light/dark `ThemeData`, `TopildiColors` ThemeExtension (found/lost/status), `TSpace`, `TRadius`, `TSize`. Copy it to `lib/core/theme/`. |
| `screens/*.dc.html` | Design source for each screen (HTML + inline styles). Read them for layout, spacing, copy and behaviour. **Don't port the HTML.** Rebuild each one as Flutter widgets. Colours inside them are tokens. `t.pr` = primary, `t.fd` = found, `t.ls` = lost, `t.mu` = onSurfaceVariant, `t.ln` = outlineVariant, `t.sf` = surfaceContainerLowest, `t.sf2` = surfaceContainerHigh, `t.bg` = surface. Each file has light (`L`) and dark (`D`) values in its `<script>` block. |
| `screens/Tokens.dc.html`, `screens/Components.dc.html` | Visual reference for the token sheet and the component library. |
| `screens/StateScreen.dc.html` | Loading / empty / error / offline states for 6 screens, with all the copy. |

## Screens → files

| # | Screen | File | Notes |
|---|---|---|---|
| 1 | Splash | Splash | Primary background, logo, tagline |
| 2 | Onboarding ×3 | Onboarding1–3 | Skip → SignIn; dots indicator; last slide "Boshlash" |
| 3 | Sign in | SignIn | `+998` prefix + mask `90 123 45 67`; Google button; privacy hint |
| 4 | SMS code | SmsCode | 6 boxes, auto-advance, 45s resend countdown |
| 5 | Profile setup | ProfileSetup | Optional photo, first name, optional surname (others only see the initial: "Malika K.") |
| 6 | Feed | Home | Location selector, search, filter button, Topilgan/Yoʻqolgan tabs, category chips, list↔map toggle, horizontal cards (104px photo on the left) |
| 7 | Filters | Filters | Bottom sheet: categories (multi-select), city/district, date (Bugun / 7 kun / 30 kun / Tanlash), live result count in CTA |
| 8 | Map | MapView | Pins coloured by type, cluster bubble, my-location button, tapping a pin shows a preview card → Detail |
| 9 | Listing detail | Detail | Gallery + thumbnails, badges, description, approximate location, finder (name + avatar only), report, sticky "Bu meniki" |
| 10 | Create listing | Create1, Create2, Create3, Review, Posted | 3-step progress bar. Step 2 has the **hidden detail** field ("Buni faqat siz koʻrasiz"). Step 3 picks an approximate area (~300 m). Review masks the hidden detail behind an eye toggle |
| 11 | "Bu meniki" claim | Claim, ClaimSent | Explains *why* we ask; free-text answer; optional proof photo; 3 attempts; status timeline |
| 12 | Claims (finder) | Claims | Hidden detail shown above each claimant's answer; Accept → opens chat, Reject → confirm dialog |
| 13 | Chats | ChatList, Chat | Chat exists only after a claim is accepted; listing mini-card pinned at top with "Qaytarildi" button; safety tip |
| 14 | Success | Success | Warm thank-you, owner's note, "Mehribon qoʻshni" badge |
| 15 | Notifications | Notifications | Grouped (Bugun / Shu hafta), unread tint + dot, "Oʻqildi" |
| 16 | Profile | Profile | Stats, my listings (Faol / Qaytarilgan), settings: language, theme (Tizim/Yorugʻ/Qorongʻi), notifications, sign out |

The `"Prototip: topuvchi tomoniga oʻtish"` button on ClaimSent exists **only for the prototype**. Don't build it. In the real app the finder gets a push notification instead.

## Key flows

1. **Post:** Home "+" → Create1 → Create2 → Create3 → Review → Posted → Detail
2. **Ownership:** Detail "Bu meniki" → Claim → ClaimSent … finder: Notification → Claims → Accept → Chat → "Qaytarildi" → Success

## Hard rules

- **Phone numbers are never shown to other users.** That covers the UI, API responses and push payloads. All contact goes through in-app chat.
- **The hidden detail is visible only to the listing's author.** It must never be returned by public listing endpoints.
- Public location = an **approximate area** (~300 m), never the exact pin.
- Tap targets ≥ 48×48 dp, text contrast WCAG AA (the tokens already pass), and support text scaling up to 130%.
- Found and Lost are never told apart by colour alone: every badge also says "Topilgan" or "Yoʻqolgan".
- Icons: Material Symbols Rounded (`material_symbols_icons` package), 24dp; 20dp inside inputs.
- Base frame is 390×844. Layouts must not break at 360 wide: use Flexible/Expanded and avoid fixed widths.
- Every list screen implements four states: loading (skeleton matching the real layout), empty, error, offline. Copy is in `StateScreen.dc.html`.
