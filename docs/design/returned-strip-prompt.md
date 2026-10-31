# Design brief — "Egasiga qaytdi" strip (Topildi)

Paste everything below into the design AI. It is written in English for the
model; every string the user actually sees is given in Uzbek (Latin) and must
be used verbatim.

---

## What Topildi is

A lost-and-found app for Uzbekistan. People post things they **found**
(`found`) or **lost** (`lost`). Someone who recognises an item sends a claim,
answers a hidden verification question, and if the author accepts, a private
chat opens. When the item changes hands, one side marks it returned and the
listing closes.

The app is iOS-first, Flutter, Uzbek/Russian. Design direction is called
**"Aniq"** (= *clear*): calm, flat, borders instead of shadows, no decoration
for its own sake.

## The problem this component solves

A new user has no reason to believe the app works. They see a feed of open
cases — things still lost, things still unclaimed — which reads as *nothing
here gets resolved*. We need visible evidence that items actually reach their
owners.

## What to design

A single horizontal strip that sits **above the feed grid**, under the
pinned segmented control and category chips. It shows items that were
returned to their owners.

It is **proof, not navigation**. Design accordingly:

- **Nothing in it is tappable.** A returned listing has no page worth
  opening — no claim to send, no chat to join. A tap would be a dead end, so
  there are no tap targets, no chevrons, no "see all".
- **No person is ever named.** The data model does not even carry the
  author's name. Do not design a slot for an avatar, a name, or a "thanks"
  quote — there is none to fill.
- **It disappears entirely when there is too little to show.** Below 3 items
  the strip is not rendered at all — no empty state, no placeholder, no
  reserved space. A wall with two items on it argues against the app. Do not
  design an empty state for this component.

## Exact data available per item

This is the whole contract. Nothing else exists; do not invent fields.

| Field | Type | Example | Notes |
|---|---|---|---|
| `title` | string | `"Uy kaliti"` | 3–60 chars, user-written, can be long |
| `category` | enum | `keys` | one of: documents\*, phones, keys, wallets, bags, electronics, clothes, kids, other — each has an icon |
| `district` | string | `"Chilonzor"` | district only, never a street |
| `returnedAt` | date | 2 days ago | rendered as "2 kun oldin" / "3 soat oldin" / "Hozirgina" |
| `photo` | url or null | — | **often null**; then the category icon is shown on a flat tinted square |

\* `documents` never appears — a returned passport is not advertised again.

Also available: a count of items returned in the last 7 days (an integer),
shown only when it is 3 or more.

## Strings (use verbatim — Uzbek Latin)

- Section title: `Egasiga qaytdi`
- Week count chip: `bu hafta {n}` (e.g. `bu hafta 7`)
- Relative time: `Hozirgina` · `{n} daqiqa oldin` · `{n} soat oldin` · `{n} kun oldin`
- Screen-reader label for the whole strip: `Egasiga qaytgan buyumlar`

Russian is also supported and is **longer** — `Egasiga qaytdi` becomes
`Вернулось владельцу`. The section title must survive that without breaking
the row.

## Design system — follow exactly

**Radii:** 6 / 8 / **12** / 16 / 24 / pill. 12 is the default for cards.

**Type scale** (Inter; only these are defined — do not invent sizes):

| Role | Size / line / weight |
|---|---|
| titleMedium | 16 / 24 / 600 |
| bodyLarge | 16 / 24 / 400 |
| bodyMedium | 14 / 20 / 400 |
| bodySmall | 12 / 16 / 400 |
| labelLarge | 14 / 20 / 600 |
| labelMedium | 12 / 16 / 600 |

**Colours — both themes are mandatory.** The dark theme is OLED: a pure black
page with near-black cards.

| Token | Light | Dark |
|---|---|---|
| page surface | `#F4F6FA` | `#000000` |
| card surface | `#FFFFFF` | `#111214` |
| primary text | `#172033` | `#F2F4F8` |
| muted text | `#8A94A6` | `#5F6672` |
| hairline border | `#DCE2EC` | `#26282D` |
| photo placeholder fill | `#DCE4F2` | `#17181B` |
| success | `#1E7A4E` | `#4D7FFF` |
| success container | `#DFF3E8` | `#14234A` |
| brand primary | `#2B5FD9` | `#4D7FFF` |

Note the dark theme's "success" is **blue, not green** — on OLED black the
green read as sickly, so the confirmation colour folds into the brand blue.
Keep that.

**Hard rules:**

- Borders, never shadows. Hairline is 1px at the token colour above.
- No ripple on anything (the app disables Material ink globally).
- Must survive **130% text scale** at **360px** width with no clipping and no
  overflow. This is tested automatically and is the single most common way a
  design fails here. Assume every text line can grow 30% taller.
- Design at 393px width (iPhone 15/16) and check 360px.
- Flat fills only — no gradients, no glow, no glass on this component.

## Deliverables

1. **2–3 distinct directions** for the strip, not variations of one. Think
   about: how heavy should proof feel? A quiet one-line ribbon and a rich
   photo rail are both legitimate answers.
2. Each direction in **light and dark**, at 393px wide.
3. Show each with **realistic content**: at least one very long title, at
   least one item with **no photo** (category icon only), and a mix of
   categories.
4. Show the strip **in place** — with the "Lenta" title, the
   Topilgan/Yoʻqolgan segmented control and the category chips above it, and
   the top row of the two-column feed grid below it, so the vertical rhythm
   can be judged.
5. Specify exact numbers: card width, photo height, gaps, paddings, which
   type role each text uses.

## What would make this fail

- Designing it as a list of listings people can browse into.
- Any affordance that suggests tapping.
- Making it so tall or so loud that it pushes the actual feed off screen —
  it must read as a footnote the eye passes on the way down, not as the
  page's hero.
- An empty state (there is none by design).
- Names, avatars, testimonials, star ratings, confetti.
