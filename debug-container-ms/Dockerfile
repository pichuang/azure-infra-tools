# =============================================================================
# debug-container-ms — Microsoft-supported network troubleshooting container
# =============================================================================
# 基礎映像 : mcr.microsoft.com/azurelinux/base/core:3.0 (Azure Linux 3.0)
# 用途     : Docker + Kubernetes 網路疑難排解瑞士刀容器
# 架構     : amd64
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: fetcher — 下載預編譯二進位工具
# 使用原生平台下載，避免 QEMU 模擬問題
# 下載的是 amd64 Linux 二進位（與 host 架構無關，只是檔案下載）
# ---------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS fetcher

# 版本定義（更新時修改此處）
ARG CTOP_VERSION=0.7.7
ARG TERMSHARK_VERSION=2.4.0
ARG GRPCURL_VERSION=1.9.3
ARG FORTIO_VERSION=1.75.1
ARG TRIPPY_VERSION=0.13.0
ARG WEBSOCAT_VERSION=1.14.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget ca-certificates && rm -rf /var/lib/apt/lists/*

# ctop
RUN wget -q "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-amd64" \
    -O /tmp/ctop && chmod +x /tmp/ctop

# termshark
RUN wget -q "https://github.com/gcla/termshark/releases/download/v${TERMSHARK_VERSION}/termshark_${TERMSHARK_VERSION}_linux_x64.tar.gz" \
    -O /tmp/termshark.tar.gz && \
    tar -zxf /tmp/termshark.tar.gz -C /tmp && \
    mv /tmp/termshark_${TERMSHARK_VERSION}_linux_x64/termshark /tmp/termshark && \
    chmod +x /tmp/termshark

# grpcurl
RUN wget -q "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz" \
    -O /tmp/grpcurl.tar.gz && \
    tar --no-same-owner -zxf /tmp/grpcurl.tar.gz -C /tmp && \
    chmod +x /tmp/grpcurl

# fortio
RUN wget -q "https://github.com/fortio/fortio/releases/download/v${FORTIO_VERSION}/fortio-linux_amd64-${FORTIO_VERSION}.tgz" \
    -O /tmp/fortio.tgz && \
    tar -zxf /tmp/fortio.tgz -C /tmp && \
    mv /tmp/usr/bin/fortio /tmp/fortio && \
    chmod +x /tmp/fortio

# trippy
RUN wget -q "https://github.com/fujiapple852/trippy/releases/download/${TRIPPY_VERSION}/trippy-${TRIPPY_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    -O /tmp/trippy.tar.gz && \
    tar -zxf /tmp/trippy.tar.gz -C /tmp && \
    find /tmp -name 'trip' -type f -exec mv {} /tmp/trippy \; && \
    chmod +x /tmp/trippy

# websocat
RUN wget -q "https://github.com/vi/websocat/releases/download/v${WEBSOCAT_VERSION}/websocat.x86_64-unknown-linux-musl" \
    -O /tmp/websocat && chmod +x /tmp/websocat

# ---------------------------------------------------------------------------
# Stage 2: main — 完整網路診斷工具映像 (amd64)
# ---------------------------------------------------------------------------
FROM --platform=linux/amd64 mcr.microsoft.com/azurelinux/base/core:3.0

LABEL maintainer="pichuang" \
      description="Microsoft-supported network troubleshooting container based on Azure Linux 3.0" \
      org.opencontainers.image.base.name="mcr.microsoft.com/azurelinux/base/core:3.0" \
      org.opencontainers.image.source="https://github.com/pichuang/azure-infra-tools/tree/main/debug-container-ms" \
      org.opencontainers.image.description="Docker + Kubernetes network troubleshooting swiss-army container (Azure Linux edition)"

# ── Category A: tdnf 核心套件 ──────────────────────────────────────────────
# 以下為 Azure Linux 3.0 已確認可用的網路診斷、系統工具套件
RUN tdnf install -y \
    bash \
    bind-utils \
    ca-certificates \
    conntrack-tools \
    curl \
    ethtool \
    file \
    git \
    iproute \
    iputils \
    jq \
    mtr \
    nmap-ncat \
    openssl \
    procps-ng \
    python3 \
    python3-pip \
    socat \
    strace \
    tcpdump \
    traceroute \
    util-linux \
    vim \
    iperf3 \
    perl \
    && tdnf clean all

# ── Category B: 可選套件（逐一安裝，不可用則跳過）─────────────────────────
# 部分套件在 Azure Linux 3.0 可能不可用，逐一嘗試避免中斷
RUN for pkg in \
    bridge-utils \
    httpd-tools \
    ipset \
    iptables \
    net-snmp-utils \
    nftables \
    wireshark-cli \
    perl-Net-SSLeay \
    fping \
    iftop \
    ltrace \
    ngrep \
    tcptraceroute \
    wget \
    ; do \
      tdnf install -y "$pkg" 2>/dev/null || echo "SKIP: $pkg not available"; \
    done && tdnf clean all

# nc 相容性符號連結 (ncat -> nc)
RUN ln -sf /usr/bin/ncat /usr/bin/nc

# ── Category C: Python pip 安裝的套件 ─────────────────────────────────────
RUN pip3 install --no-cache-dir --break-system-packages \
    httpie \
    scapy \
    speedtest-cli

# ── Category D: 從 fetcher stage 複製預編譯二進位 ─────────────────────────

# ctop — top-like container monitor
COPY --from=fetcher /tmp/ctop /usr/local/bin/ctop

# termshark — terminal UI for tshark
COPY --from=fetcher /tmp/termshark /usr/local/bin/termshark

# grpcurl — curl for gRPC
COPY --from=fetcher /tmp/grpcurl /usr/local/bin/grpcurl

# fortio — load testing tool
COPY --from=fetcher /tmp/fortio /usr/local/bin/fortio

# trippy — network diagnostic tool (mtr alternative)
COPY --from=fetcher /tmp/trippy /usr/local/bin/trippy

# websocat — WebSocket CLI client
COPY --from=fetcher /tmp/websocat /usr/local/bin/websocat

# ── Category F: deadman — curses-based ping 監控工具 ──────────────────────
# 預設 conf 放在 /etc/deadman/deadman.conf，使用者可掛載自訂設定覆蓋
RUN git clone --depth=1 https://github.com/upa/deadman.git /opt/deadman \
    && ln -s /opt/deadman/deadman /usr/local/bin/deadman \
    && mkdir -p /etc/deadman \
    && cp /opt/deadman/deadman.conf /etc/deadman/deadman.conf

# ── Category E: Shell 環境設定 ─────────────────────────────────────────────

USER root
WORKDIR /root
ENV HOSTNAME=debug-container-ms

COPY bashrc .bashrc
COPY vimrc .vimrc
COPY motd motd

# 修正 OpenShift 和 tshark 權限
RUN chmod -R g=u /root \
    && if [ -f /usr/bin/dumpcap ]; then chown root:root /usr/bin/dumpcap; fi

CMD ["bash"]
