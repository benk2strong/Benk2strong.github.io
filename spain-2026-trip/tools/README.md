# Resolving the map links

The dashboard has 56 `maps.app.goo.gl` short links with no place name attached.
The environment the dashboard was built in has no general outbound internet
access, so those links could never be followed from there — which is why those
places have no coordinates and don't appear on any route.

Your machine has ordinary internet access, so it can do in one step what that
environment cannot.

## Run it

```bash
cd spain-2026-trip/tools
python3 resolve_links.py
```

Takes about 30 seconds (it pauses between requests to be polite to Google).
It writes `resolved.tsv`. Paste that file's contents back into the chat.

No Python? Use the curl version instead:

```bash
bash resolve_links.sh > resolved.txt
```

## What it does

For each short link it follows the redirect and reads the long Google Maps URL
you land on, which contains the place name and its coordinates:

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

Some may come back `no-data` (a link to a list or a search rather than a single
pin) or error out. That's fine — send what resolved and we'll handle the rest by
name.
