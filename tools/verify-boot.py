#!/usr/bin/env python3
"""Verify the Nikel Android boot header, kernel, DTB and initramfs."""
import argparse
import gzip
import hashlib
from pathlib import Path
import struct
import zlib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("image", type=Path)
args = parser.parse_args()
data = args.image.read_bytes()
assert data[:8] == b"ANDROID!", "Android boot magic"
kernel_size, kernel_addr, ramdisk_size, ramdisk_addr, second_size, second_addr, tags_addr, page, dt_size, unused = struct.unpack_from("<10I", data, 8)
assert page == 2048 and second_size == 0 and dt_size == 0
assert kernel_addr == 0x40080000 and ramdisk_addr == 0x45000000
assert tags_addr == 0x44000000 and len(data) <= 16777216
align = lambda size: (size + page - 1) // page * page
kernel = data[page:page + kernel_size]
offset = page + align(kernel_size)
ramdisk = data[offset:offset + ramdisk_size]
assert len(data) == offset + align(ramdisk_size)
digest = hashlib.sha1()
for section in (kernel, ramdisk, b""):
    digest.update(section)
    digest.update(struct.pack("<I", len(section)))
assert data[576:596] == digest.digest(), "Boot header SHA1"
device = Path(__file__).resolve().parents[1]
assert kernel == (device / "prebuilt/kernel").read_bytes()
decoder = zlib.decompressobj(31)
image = decoder.decompress(kernel)
assert decoder.eof and image[56:60] == b"ARM\x64"
dtb = decoder.unused_data
magic, total = struct.unpack_from(">II", dtb)
assert magic == 0xd00dfeed and total == len(dtb)
archive = gzip.decompress(ramdisk)
files = {}
cursor = 0
while cursor < len(archive):
    assert archive[cursor:cursor + 6] == b"070701", "newc CPIO header"
    fields = [int(archive[cursor + 6 + i * 8:cursor + 14 + i * 8], 16) for i in range(13)]
    size, name_size = fields[6], fields[11]
    name = archive[cursor + 110:cursor + 110 + name_size - 1].decode()
    cursor = (cursor + 110 + name_size + 3) & ~3
    files[name.removeprefix("./")] = archive[cursor:cursor + size]
    cursor = (cursor + size + 3) & ~3
    if name == "TRAILER!!!":
        break
required = ("init", "init.rc", "init.mt6797.rc", "init.mt6797.services.rc",
            "init.mt6797.modem.rc", "fstab.mt6797", "ueventd.mt6797.rc",
            "sepolicy", "file_contexts", "init.zygote64_32.rc")
assert all(files.get(name) for name in required), "Missing initramfs files"
for name in ("init.mt6797.rc", "init.mt6797.services.rc", "init.mt6797.modem.rc",
             "fstab.mt6797", "ueventd.mt6797.rc"):
    assert files[name] == (device / "rootdir" / name).read_bytes(), name
assert b"androidboot.hardware=mt6797" in data[64:576]
print(f"Validated Android boot image: {len(data)} bytes")
print(f"Kernel: {kernel_size} bytes; DTB: {len(dtb)} bytes")
print(f"Ramdisk: {ramdisk_size} bytes; {len(files)} CPIO entries")
print(f"SHA256: {hashlib.sha256(data).hexdigest()}")
print("Hardware boot, encryption and radio operation require phone validation.")
