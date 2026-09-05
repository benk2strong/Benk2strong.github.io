#!/usr/bin/env bash
# Curl-only version of resolve_links.py, for machines without Python.
# Run on your own machine:   bash resolve_links.sh > resolved.txt
# Then paste resolved.txt back into the chat.
set -uo pipefail
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36'

grep -o 'https://maps\.app\.goo\.gl/[A-Za-z0-9]*' unresolved_links.json | sort -u | while read -r short; do
  full=$(curl -sL -A "$UA" -o /dev/null -w '%{url_effective}' --max-time 20 "$short")
  printf '%s\t%s\n' "$short" "$full"
  sleep 0.4
done
