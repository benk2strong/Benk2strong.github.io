# Spain 2026 — Trip Dashboard

`index.html` is a single self-contained file: no build step, no dependencies.
Open it in a browser, or view it live at
`https://benk2strong.github.io/spain-2026-trip/`.

Built from `Spain_Trip_Itinerary_.xlsx` (Sheet2). Sep 9–27, 2026:
**Madrid → San Sebastián → Bordeaux → Paris.**

## Tabs

- **Overview** — the 19-day spine, the legs, and the open questions.
- **Schedule** — the spreadsheet's own shape (days across, time of day down),
  with reservations pulled out and every link clickable. Filterable.
- **Routes & Map** — pick a day; it plots the located places and solves the
  visiting order, and reports the result against the order in the sheet.
- **Locked In** — everything with a time attached, in date order.
- **Places** — the geocoded inventory, plus the links still needing names.

## Committed stops vs options

The sheet mixes two different things: places you plan to go, and places you
*might* go — "potential spots below", "maybe check this out", "Jazz bar?",
"Recommendations for Grace". Treating both as stops would produce absurd
18-stop days.

So items whose own wording is optional carry `cand:1`. They are geocoded and
drawn on the map as hollow pins, and listed under the route with their distance
from the nearest committed stop — but they never enter the schedule or the
distance total. Flipping one into the route is a one-word change.

## How the routing works

For each day the page builds a distance matrix over that day's located places
(haversine, inflated by a detour factor: ×1.25 walking, ×1.30 driving), then
orders them by **cheapest insertion followed by 2-opt**.

The score being minimised is not pure distance. It is:

```
km + 0.6·(minutes late + minutes past closing) + 0.12·(minutes of late start) + 0.02·(displacement from your listed order)
```

Which encodes four rules:

1. **Reservations are pinned.** Any order that reaches a booking after its time
   is charged heavily, so the solver will happily walk further to make it.
2. **Opening hours are respected** where known — the Capucins market closing at
   14:30 and Liria Palace at 19:00 both come straight from your sheet.
3. **The day shouldn't open at a 3pm reservation.** Waiting *before the first
   stop* is charged; mid-day gaps are not, because charging those would pay the
   solver to wander further just to burn the clock.
4. **Ties go to your order.** When two routes cost the same, the one closer to
   how you wrote it down wins.

Travel days pin their endpoints (`from`/`to`), so 14 Sep runs
Madrid → Segovia → Burgos → San Sebastián rather than an unanchored loop,
and day trips return to where they started.

The panel reports the result against your listed order, so the saving is
always visible and checkable.

## Known limits

- **Coordinates are hand-entered** from place names, not geocoded. Good enough
  to order a day; not good enough to navigate by. Places flagged `verify`
  in the Places tab are the least certain.
- **4 links remain unplaced** (of the original 56). The rest were resolved by
  running `tools/resolve_links.py` on a machine with internet access, so their
  coordinates are Google's own. The leftovers: a directions link (a route, not
  a place), one shop that returned no address, and two non-Google links.
  Coordinates still marked `verify` were placed by hand from a street address.
- **Travel times are modelled, not live** — straight-line distance with a
  detour factor and a flat speed. No traffic, no transit schedules.

## Editing

Everything renders from two objects at the top of the script in `index.html`:

- `PLACES` — `id → {n, lat, lng, city, k, d}`, plus optional `o:[open,close]`
  opening hours and `v:1` to flag a coordinate as unverified.
- `DAYS` — one entry per date, each with `items[]`. An item is
  `{b:block, t:"HH:MM", txt, u:url(s), p:place id(s), k:kind}`.
  `alt:1` marks an either/or; `cand:1` marks an option — mapped as a hollow pin
  and listed under the route, but never scheduled. A day may carry `from`/`to`
  to pin its endpoints.
  A day may also carry `variants[]` to model a fork — two competing plans shown
  as a toggle. Nothing uses it right now (the 16 Sep Picos/Biarritz fork was
  resolved in favour of Biarritz), but the machinery is still there.

Naming an unresolved link is a two-line change: add the place to `PLACES`,
then put its `p:` on the matching item.
