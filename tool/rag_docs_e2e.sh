#!/usr/bin/env bash
# Indexes PDFs on a phone with the real embedder, then asks messy user-style
# questions and reports whether the right page came back.
#
#   tool/rag_docs_e2e.sh <adb-device-id> [extra-dir]
#
# Always uses the committed fixture (test/_helpers/fixtures/pdf/aranya_*).
# [extra-dir] may hold your own *.pdf plus a queries.json in the same format as
# aranya_land_records_review_q2_2026.queries.json ("doc" = the pdf's file name
# without .pdf); its PDFs and questions are added. Keep private documents out
# of the repo. Indexing costs ~13 s per chunk, so allow time.
# SKIP_SELF_CHECK=1 skips the every-chunk-finds-itself check (one embedding per chunk).
set -euo pipefail
dev="${1:?usage: $0 <adb-device-id> [extra-dir]}"
extra="${2:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
fx="$root/test/_helpers/fixtures/pdf"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
cp "$fx"/aranya_land_records_review_q2_2026.pdf "$stage/"
python3 - "$fx/aranya_land_records_review_q2_2026.queries.json" "${extra:+$extra/queries.json}" "$stage/queries.json" <<'PY'
import json, os, sys
*srcs, out = sys.argv[1:]
merged = []
for s in srcs:
    if s and os.path.exists(s):
        merged += json.load(open(s))
json.dump(merged, open(out, "w"), ensure_ascii=False)
PY
if [ -n "$extra" ]; then cp "$extra"/*.pdf "$stage/"; fi

# With the screen off Android runs the app on the phone's slow cores and every
# chunk takes ~5x longer (65 s vs 12 s measured), so wake and unlock it, and keep
# it awake while plugged in. (The lock screen must be a swipe, not a PIN.)
adb -s "$dev" shell "svc power stayon usb; input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard; input keyevent KEYCODE_HOME" >/dev/null 2>&1 || true

# The app's own external folder is the only place it can read without
# permissions, and `flutter test` reinstalls the app (wiping it), so keep
# pushing until the test has started and picked the files up.
dest=/sdcard/Android/data/in.uniun.app/files/rag_docs
# Old files from an earlier run would be indexed too.
adb -s "$dev" shell "rm -rf $dest" 2>/dev/null || true
log="${TMPDIR:-/tmp}/rag_docs_e2e.log"
( cd "$root" && flutter test integration_test/document_rag_e2e_test.dart -d "$dev" \
    --plain-name 'documents answer messy user questions' \
    --dart-define=RAG_DOCS_DIR="$dest" ${SKIP_SELF_CHECK:+--dart-define=SKIP_SELF_CHECK=true} \
    > "$log" 2>&1 ) &
pid=$!
for _ in $(seq 1 120); do
  adb -s "$dev" shell "mkdir -p $dest" 2>/dev/null || true
  for f in "$stage"/*; do adb -s "$dev" push "$f" "$dest/" >/dev/null 2>&1 || true; done
  grep -q "documents answer messy user questions" "$log" 2>/dev/null && break
  sleep 3
done
# The test dumps every chunk and question vector so ranking variants can be
# tried offline (tool/eval_retrieval.dart). Pull it before the run ends: the
# app is uninstalled afterwards. It holds document text - keep it out of the repo.
dump="${TMPDIR:-/tmp}/rag_dump.json"
while kill -0 "$pid" 2>/dev/null; do
  if grep -q "REAL dump written" "$log" 2>/dev/null; then
    adb -s "$dev" pull "$dest/dump.json" "$dump" >/dev/null 2>&1 && { echo "dump: $dump"; break; }
  fi
  sleep 5
done
wait "$pid" || true
grep -E "REAL|DocumentIndexer|Some tests|All tests|Expected|Actual|did not complete|\[E\]" "$log" || true
echo "full log: $log"
