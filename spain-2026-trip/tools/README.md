# Resolving the map links

The dashboard has 56 `maps.app.goo.gl` short links (55 unique) with no place
name attached. The environment the dashboard was built in has no general
outbound internet access, so those links could never be followed from there —
which is why those places have no coordinates and don't appear on any route.

Your own machine has ordinary internet access, so it can do in one step what
that environment cannot.

---

## Windows — PowerShell (no installs needed)

**Option A — run the script.** Put `resolve_links.ps1` and
`unresolved_links.json` in the same folder, open that folder, and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\resolve_links.ps1
```

The `-ExecutionPolicy Bypass` applies to that one run only; it changes nothing
on your system. Writes `resolved.tsv`.

**Option B — paste, no files.** If script execution is locked down, open
`paste_into_powershell.txt`, copy the whole thing, and paste it into a
PowerShell window. The links are embedded, so it needs no other file, and it
puts the results on your clipboard.

Either way: paste the results back into the chat.

## macOS / Linux

```bash
python3 resolve_links.py          # writes resolved.tsv
bash    resolve_links.sh          # curl-only fallback
```

---

## What it does

For each short link it follows the redirect and reads the long Google Maps URL
it lands on, which contains the place name and its coordinates:

```
https://www.google.com/maps/place/Palacio+de+Liria/@40.4271,-3.7109,17z/...!3d40.4272!4d-3.7113
                                  ^^^^^^^^^^^^^^^^                          ^^^^^^^  ^^^^^^^
                                  name                                      the pin itself
```

It prefers the `!3d`/`!4d` pin coordinates over the `/@` pair, because `/@` is
only where the map was centred, not where the place is.

The only requests made are to Google — the same ones your browser makes when
you click one of these links. Nothing else is contacted and nothing is uploaded.

## If a link fails

Some may come back `no-data` (a link to a saved list or a search rather than a
single pin) or error out. That's fine — send what resolved and we'll do the
rest by name.

## Testing status

The Python resolver's URL parser is unit-tested against six real Google Maps
URL shapes. The PowerShell versions use the same logic but were **not** executed
before shipping (no PowerShell in the build environment) — if one errors, paste
the error and it'll get fixed.
