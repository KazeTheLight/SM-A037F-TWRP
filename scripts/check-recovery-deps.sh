#!/bin/bash
# Fail the build if any ELF in the recovery root has an unresolved DT_NEEDED.
# Usage: check-recovery-deps.sh <recovery-root>
set -u

ROOT="${1:-}"
if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
    echo "usage: $0 <recovery-root>" >&2
    exit 2
fi

libdirs=(
    "$ROOT/system/lib64" "$ROOT/system/lib"
    "$ROOT/system_ext/lib64" "$ROOT/system_ext/lib"
    "$ROOT/product/lib64" "$ROOT/product/lib"
    "$ROOT/vendor/lib64" "$ROOT/vendor/lib"
    "$ROOT/odm/lib64" "$ROOT/odm/lib"
)

find_lib() {
    local lib="$1" d
    for d in "${libdirs[@]}"; do
        if [ -e "$d/$lib" ]; then return 0; fi
    done
    return 1
}

missing=0
while IFS= read -r -d '' f; do
    magic=$(head -c 4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    [ "$magic" = "7f454c46" ] || continue
    rel=${f#"$ROOT/"}
    while IFS= read -r lib; do
        [ -n "$lib" ] || continue
        if ! find_lib "$lib"; then
            echo "MISSING: $rel -> $lib"
            missing=$((missing + 1))
        fi
    done < <(readelf -d "$f" 2>/dev/null | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p')
done < <(find "$ROOT/system/bin" "$ROOT/system/lib64" "$ROOT/system/lib" \
              "$ROOT/system_ext" "$ROOT/product" "$ROOT/vendor" "$ROOT/odm" \
              "$ROOT/sbin" -type f -print0 2>/dev/null)

if [ "$missing" -ne 0 ]; then
    echo "Recovery dependency check failed: $missing missing DT_NEEDED entries."
    exit 1
fi
echo "Recovery dependency check passed: no missing DT_NEEDED entries."
