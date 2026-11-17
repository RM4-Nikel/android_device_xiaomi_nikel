#!/usr/bin/env python3
"""Check extracted Nikel files against a stock dump and ELF ABI dependencies."""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("stock", type=Path)
args = parser.parse_args()
device = Path(__file__).resolve().parents[1]
root = device.parents[2]
vendor = root / "vendor/xiaomi/nikel/proprietary"
platform = set("""
libc libc++ libdl libm liblog libutils libcutils libhardware libbinder
libGLESv1_CM libGLESv2 libEGL libui libgui libion libsync libz libbase
libstdc++ libmedia libstagefright libstagefright_foundation libcrypto libssl
libicuuc libnativehelper libnetutils libnetd_client libhardware_legacy
libtinyalsa libtinyxml libcurl libaudioutils libexpat libxml2 libbacktrace
libunwind libpower libcamera_client libcamera_metadata libdrmframework
libskia libselinux libpng
""".split())
count = 0
for line in (device / "proprietary-blobs.txt").read_text().splitlines():
    if not line or line.startswith("#"):
        continue
    original = args.stock / "system" / line
    blob = vendor / line
    assert hashlib.sha256(original.read_bytes()).digest() == hashlib.sha256(blob.read_bytes()).digest(), line
    ident = blob.read_bytes()[:5]
    if ident[:4] != b"\x7fELF":
        continue
    abi = "lib64" if ident[4] == 2 else "lib"
    if line.startswith(("lib/", "lib64/")):
        assert line.split("/")[0] == abi, line
    dynamic = subprocess.check_output(["readelf", "-d", blob], text=True)
    for name in re.findall(r"NEEDED.*?\[(.*?)\]", dynamic):
        if name.removesuffix(".so") in platform:
            continue
        dependency = vendor / abi / name
        assert dependency.is_file(), (line, name)
        assert dependency.read_bytes()[:5] == ident, (line, name, "ABI")
    count += 1
print(f"Verified stock hashes and same-ABI dependency paths for {count} ELF files.")
print("Platform library symbol compatibility still requires runtime validation.")
