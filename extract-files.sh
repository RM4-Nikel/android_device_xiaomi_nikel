#!/usr/bin/env bash
set -eo pipefail

if [[ $# -ne 1 || ! -d "$1/system" ]]; then
    echo "Usage: $0 <unpacked Nikel stock dump>" >&2
    exit 2
fi

device_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cm_root=$(cd -- "$device_dir/../../.." && pwd)
blob_list="$device_dir/proprietary-blobs.txt"
stock_dir=$(cd -- "$1" && pwd)

if [[ ! -s "$blob_list" ]]; then
    echo "Missing blob list: $blob_list" >&2
    exit 1
fi

source "$cm_root/vendor/cm/build/tools/extract_utils.sh"
parse_file_list "$blob_list"
for entry in "${PRODUCT_COPY_FILES_LIST[@]}" "${PRODUCT_PACKAGES_LIST[@]}"; do
    source_path=${entry%%:*}
    if [[ ! -f "$stock_dir/system/$source_path" ]]; then
        echo "Missing stock file: system/$source_path" >&2
        exit 1
    fi
done

setup_vendor nikel xiaomi "$cm_root" false true
DEVICE=nikel
extract "$blob_list" "$stock_dir"

for entry in "${PRODUCT_COPY_FILES_LIST[@]}" "${PRODUCT_PACKAGES_LIST[@]}"; do
    test -f "$cm_root/$OUTDIR/proprietary/$(target_file "$entry")"
done

write_headers
write_makefiles "$blob_list"
write_footers
