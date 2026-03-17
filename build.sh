#!/usr/bin/env bash
set -euo pipefail

# =========================
# SETTINGS
# =========================
DEFCONFIG="${1:-physwizz}"
OUT="out"
THREADS="$(nproc)"
LOG="build.log"

CLANG_DIR="$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin"

# Change this if your 32-bit toolchain is gnueabihf instead of gnueabi
CROSS32="arm-linux-gnueabi-"

# =========================
# ENVIRONMENT
# =========================
export ARCH=arm64
export SUBARCH=arm64
export PLATFORM_VERSION=13
export ANDROID_PLATFORM_VERSION=13

export PATH="$CLANG_DIR:$PATH"

export CC=clang
export HOSTCC=gcc
export HOSTCXX=g++

# =========================
# CHECKS
# =========================
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[!] Missing required tool: $1"
    exit 1
  }
}

need_cmd clang
need_cmd ld.lld
need_cmd llvm-ar
need_cmd llvm-nm
need_cmd llvm-objcopy
need_cmd llvm-objdump
need_cmd llvm-strip
need_cmd llvm-readelf
need_cmd aarch64-linux-gnu-as
need_cmd aarch64-linux-gnu-ld.bfd
need_cmd "${CROSS32}as"
need_cmd make
need_cmd gcc
need_cmd g++

# =========================
# INFO
# =========================
echo "============================="
echo " Kernel Build Script"
echo " Defconfig : $DEFCONFIG"
echo " Threads   : $THREADS"
echo " Clang     : $(command -v clang)"
echo " AArch64 AS: $(command -v aarch64-linux-gnu-as)"
echo " ARM32 AS  : $(command -v ${CROSS32}as)"
echo "============================="

# =========================
# CLEAN
# =========================
echo "[*] Cleaning build directory..."
rm -rf "$OUT"
rm -f "$LOG"

# =========================
# CONFIG
# =========================
echo "[*] Generating defconfig..."
make O="$OUT" "${DEFCONFIG}_defconfig"

echo "[*] Syncing config..."
set +o pipefail
yes "" | make O="$OUT" oldconfig
set -o pipefail

# =========================
# BUILD
# =========================
echo "[*] Starting kernel build..."

make -j"$THREADS" O="$OUT" \
  ARCH=arm64 \
  CC=clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32="${CROSS32}" \
  LD=aarch64-linux-gnu-ld.bfd \
  AR=llvm-ar \
  NM=llvm-nm \
  OBJCOPY=llvm-objcopy \
  OBJDUMP=llvm-objdump \
  STRIP=llvm-strip \
  READELF=llvm-readelf \
  HOSTCC=gcc \
  HOSTCXX=g++ \
  KCFLAGS="-Wno-gnu-variable-sized-type-not-at-end" \
  2>&1 | tee "$LOG"

# =========================
# RESULT
# =========================
echo
echo "============================="
echo " Build Finished"
echo "============================="
echo "Kernel outputs:"
find "$OUT/arch/arm64/boot" -maxdepth 1 -type f 2>/dev/null || true