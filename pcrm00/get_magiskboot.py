#!/usr/bin/env python3
#
# Obtain a Linux (x86_64) `magiskboot` by pulling it out of the official Magisk
# release APK (lib/x86_64/libmagiskboot.so). The Magisk project ships magiskboot
# inside the APK for every arch; the x86_64 one runs directly on the Ubuntu
# runner.
#
#   python3 pcrm00/get_magiskboot.py [output_dir]
#
# Result: <output_dir>/magiskboot
#
import os
import subprocess
import sys
import urllib.request

# NOTE: pin to Magisk v27.0, NOT the latest release. Newer Magisk compiles the
# x86_64 magiskboot with AVX512 instructions, which SIGILL (Illegal instruction,
# exit 132) on GitHub Actions runners that lack AVX512 — observed during
# `magiskboot repack`. v27.0's x86_64 magiskboot runs cleanly on the runner.
MAGISK_APK = "https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk"


def gh_json(url, token=None):
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main():
    out_dir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.getcwd())
    token = os.environ.get("GITHUB_TOKEN", "")
    apk_url = MAGISK_APK
    tag_name = apk_url.rsplit("/", 1)[-1].removesuffix(".apk")

    apk_path = os.path.join(out_dir, "magisk.apk")
    print(f"Fetching {tag_name} -> {apk_path}")
    open(apk_path, "wb").write(gh_json(apk_url, token))

    extract_dir = os.path.join(out_dir, "apkout")
    subprocess.run(["unzip", "-o", "-q", apk_path,
                    "lib/x86_64/libmagiskboot.so", "-d", extract_dir], check=True)
    src = os.path.join(extract_dir, "lib/x86_64/libmagiskboot.so")
    dst = os.path.join(out_dir, "magiskboot")
    os.replace(src, dst)
    os.chmod(dst, 0o755)
    print(f"magiskboot -> {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())