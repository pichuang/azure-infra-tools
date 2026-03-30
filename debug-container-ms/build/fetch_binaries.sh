#!/usr/bin/env bash
# =============================================================================
# fetch_binaries.sh — 下載預編譯二進位工具 (amd64 only)
# 來源: 參考 nicolaka/netshoot build/fetch_binaries.sh，改為僅 amd64
# =============================================================================
set -euo pipefail

# Auto-detect architecture
MACHINE=$(uname -m)
case "$MACHINE" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $MACHINE"; exit 1 ;;
esac
echo "[fetch] Detected architecture: $ARCH ($MACHINE)"

get_latest_release() {
  # Write to temp file first to avoid QEMU pipe issues on cross-arch builds
  local tmpfile="/tmp/_gh_release_$$.json"
  curl --retry 3 --silent "https://api.github.com/repos/$1/releases/latest" -o "$tmpfile"
  local tag
  tag=$(grep '"tag_name":' "$tmpfile" | sed -E 's/.*"([^"]+)".*/\1/')
  rm -f "$tmpfile"
  echo "$tag"
}

# ---------------------------------------------------------------------------
# ctop — top-like container monitor
# ---------------------------------------------------------------------------
get_ctop() {
  local VERSION
  VERSION=$(get_latest_release bcicen/ctop | sed -e 's/^v//')
  local LINK="https://github.com/bcicen/ctop/releases/download/v${VERSION}/ctop-${VERSION}-linux-${ARCH}"
  echo "[fetch] ctop v${VERSION}"
  wget -q "$LINK" -O /tmp/ctop && chmod +x /tmp/ctop
}

# ---------------------------------------------------------------------------
# calicoctl — Calico CLI
# ---------------------------------------------------------------------------
get_calicoctl() {
  local VERSION
  VERSION=$(get_latest_release projectcalico/calico)
  local LINK="https://github.com/projectcalico/calico/releases/download/${VERSION}/calicoctl-linux-${ARCH}"
  echo "[fetch] calicoctl ${VERSION}"
  wget -q "$LINK" -O /tmp/calicoctl && chmod +x /tmp/calicoctl
}

# ---------------------------------------------------------------------------
# termshark — terminal UI for tshark
# ---------------------------------------------------------------------------
get_termshark() {
  local VERSION
  VERSION=$(get_latest_release gcla/termshark | sed -e 's/^v//')
  local TERM_ARCH
  if [ "$ARCH" = "amd64" ]; then TERM_ARCH="x64"; else TERM_ARCH="$ARCH"; fi
  local LINK="https://github.com/gcla/termshark/releases/download/v${VERSION}/termshark_${VERSION}_linux_${TERM_ARCH}.tar.gz"
  echo "[fetch] termshark v${VERSION} (${TERM_ARCH})"
  wget -q "$LINK" -O /tmp/termshark.tar.gz
  tar -zxf /tmp/termshark.tar.gz -C /tmp
  find /tmp -name 'termshark' -type f -exec mv {} /tmp/termshark_bin \; 2>/dev/null || true
  mv /tmp/termshark_bin /tmp/termshark
  chmod +x /tmp/termshark
}

# ---------------------------------------------------------------------------
# grpcurl — curl for gRPC
# ---------------------------------------------------------------------------
get_grpcurl() {
  local VERSION
  VERSION=$(get_latest_release fullstorydev/grpcurl | sed -e 's/^v//')
  local GRPC_ARCH
  if [ "$ARCH" = "amd64" ]; then GRPC_ARCH="x86_64"; else GRPC_ARCH="$ARCH"; fi
  local LINK="https://github.com/fullstorydev/grpcurl/releases/download/v${VERSION}/grpcurl_${VERSION}_linux_${GRPC_ARCH}.tar.gz"
  echo "[fetch] grpcurl v${VERSION}"
  wget -q "$LINK" -O /tmp/grpcurl.tar.gz
  tar --no-same-owner -zxf /tmp/grpcurl.tar.gz -C /tmp
  chmod +x /tmp/grpcurl
  chown root:root /tmp/grpcurl
}

# ---------------------------------------------------------------------------
# fortio — load testing & server
# ---------------------------------------------------------------------------
get_fortio() {
  local VERSION
  VERSION=$(get_latest_release fortio/fortio | sed -e 's/^v//')
  local LINK="https://github.com/fortio/fortio/releases/download/v${VERSION}/fortio-linux_${ARCH}-${VERSION}.tgz"
  echo "[fetch] fortio v${VERSION}"
  wget -q "$LINK" -O /tmp/fortio.tgz
  tar -zxf /tmp/fortio.tgz -C /tmp
  mv /tmp/usr/bin/fortio /tmp/fortio
  chmod +x /tmp/fortio
}

# ---------------------------------------------------------------------------
# trippy — network diagnostic tool (mtr alternative)
# ---------------------------------------------------------------------------
get_trippy() {
  local VERSION
  VERSION=$(get_latest_release fujiapple852/trippy | sed -e 's/^v//')
  local TRIPPY_ARCH
  if [ "$ARCH" = "amd64" ]; then TRIPPY_ARCH="x86_64"; else TRIPPY_ARCH="aarch64"; fi
  local LINK="https://github.com/fujiapple852/trippy/releases/download/${VERSION}/trippy-${VERSION}-${TRIPPY_ARCH}-unknown-linux-musl.tar.gz"
  echo "[fetch] trippy v${VERSION}"
  wget -q "$LINK" -O /tmp/trippy.tar.gz
  tar -zxf /tmp/trippy.tar.gz -C /tmp
  # The binary may be at root or inside a directory; find and move it
  find /tmp -name 'trip' -type f -exec mv {} /tmp/trippy \; 2>/dev/null || true
  chmod +x /tmp/trippy
}

# ---------------------------------------------------------------------------
# websocat — WebSocket CLI client
# ---------------------------------------------------------------------------
get_websocat() {
  local VERSION
  VERSION=$(get_latest_release vi/websocat | sed -e 's/^v//')
  local WS_ARCH
  if [ "$ARCH" = "amd64" ]; then WS_ARCH="x86_64"; else WS_ARCH="aarch64"; fi
  local LINK="https://github.com/vi/websocat/releases/download/v${VERSION}/websocat.${WS_ARCH}-unknown-linux-musl"
  echo "[fetch] websocat v${VERSION}"
  wget -q "$LINK" -O /tmp/websocat && chmod +x /tmp/websocat
}

# ---------------------------------------------------------------------------
# swaks — Swiss Army Knife for SMTP (Perl script)
# ---------------------------------------------------------------------------
get_swaks() {
  local VERSION
  VERSION=$(get_latest_release jetmore/swaks | sed -e 's/^v//')
  local LINK="https://github.com/jetmore/swaks/releases/download/v${VERSION}/swaks-${VERSION}.tar.gz"
  echo "[fetch] swaks v${VERSION}"
  wget -q "$LINK" -O /tmp/swaks.tar.gz
  tar -zxf /tmp/swaks.tar.gz -C /tmp
  mv "/tmp/swaks-${VERSION}/swaks" /tmp/swaks
  chmod +x /tmp/swaks
}

# === Execute all fetchers ===
get_ctop
get_calicoctl
get_termshark
get_grpcurl
get_fortio
get_trippy
get_websocat
get_swaks

echo "[fetch] All binaries downloaded successfully."
