#!/usr/bin/env bash
set -eo pipefail

device_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cm_root=$(cd -- "$device_dir/../../.." && pwd)
source "$cm_root/vendor/cm/build/tools/extract_utils.sh"
setup_vendor nikel xiaomi "$cm_root" false true
DEVICE=nikel
write_headers
write_makefiles "$device_dir/proprietary-blobs.txt"
write_footers
