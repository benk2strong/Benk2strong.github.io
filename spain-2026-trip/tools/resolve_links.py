#!/usr/bin/env python3
"""
Resolve the Google Maps short links from the Spain 2026 planning sheet into
place names and coordinates.

Run this on YOUR machine (it needs ordinary internet access, which the
environment the dashboard was built in does not have):

    python3 resolve_links.py

It writes resolved.tsv next to itself and prints a summary. Paste the
contents of resolved.tsv back into the chat and the places fold straight
into the dashboard's routing.

Nothing is sent anywhere except to Google, which is the same request your
browser makes when you click one of these links.
"""
import json, os, re, sys, time
from urllib.parse import unquote
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

HERE = os.path.dirname(os.path.abspath(__file__))
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/125.0 Safari/537.36")


def final_url(url, timeout=20):
    """Follow redirects and return the URL we land on."""
    req = Request(url, headers={"User-Agent": UA,
                                "Accept-Language": "en-US,en;q=0.9"})
    with urlopen(req, timeout=timeout) as r:
        return r.geturl()


def parse(u):
    """Pull a place name and coordinates out of a long Google Maps URL."""
    name = None
    m = re.search(r"/(?:place|search)/([^/@?]+)", u)
    if m:
        name = unquote(m.group(1)).replace("+", " ").strip()
        if name.lower().startswith("data="):
            name = None

    lat = lng = None
    # !3d/!4d is the place pin itself; /@ is only the map viewport centre.
    m = re.search(r"!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)", u)
    if not m:
        m = re.search(r"/@(-?\d+\.\d+),(-?\d+\.\d+)", u)
    if m:
        lat, lng = float(m.group(1)), float(m.group(2))
    return name, lat, lng


def main():
    with open(os.path.join(HERE, "unresolved_links.json"), encoding="utf-8") as f:
        items = json.load(f)

    rows, failed = [], 0
    for i, it in enumerate(items, 1):
        short = it["u"]
        try:
            full = final_url(short)
            name, lat, lng = parse(full)
            ok = "ok" if (name or lat) else "no-data"
        except (URLError, HTTPError, OSError) as e:
            full, name, lat, lng, ok = "", None, None, None, f"error: {e}"
            failed += 1

        rows.append([it["date"], it["b"], it.get("txt", ""), short,
                     name or "", "" if lat is None else f"{lat:.6f}",
                     "" if lng is None else f"{lng:.6f}", ok, full])
        print(f"[{i:2}/{len(items)}] {it['date']} {ok:9} {name or '-'}")
        time.sleep(0.4)          # be polite; these are Google's servers

    out = os.path.join(HERE, "resolved.tsv")
    with open(out, "w", encoding="utf-8") as f:
        f.write("date\tblock\tsheet_text\tshort_url\tname\tlat\tlng\tstatus\tfinal_url\n")
        for r in rows:
            f.write("\t".join(str(c).replace("\t", " ") for c in r) + "\n")

    got = sum(1 for r in rows if r[4] or r[5])
    print(f"\nresolved {got}/{len(rows)}  ({failed} network failures)")
    print(f"wrote {out}")
    print("\nPaste that file's contents back into the chat.")


if __name__ == "__main__":
    main()
