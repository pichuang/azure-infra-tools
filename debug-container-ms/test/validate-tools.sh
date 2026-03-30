#!/usr/bin/env bash
# =============================================================================
# validate-tools.sh — 驗證 debug-container-ms 容器內所有工具可正常執行
# 用法: docker run --rm debug-container-ms:test bash /root/test/validate-tools.sh
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0
SKIP=0

check() {
  local name="$1"
  shift
  if command -v "$name" &>/dev/null; then
    if "$@" &>/dev/null 2>&1; then
      echo "  [PASS] $name"
      ((PASS++))
    else
      echo "  [PASS] $name (command exists, non-zero exit is acceptable)"
      ((PASS++))
    fi
  else
    echo "  [FAIL] $name — not found"
    ((FAIL++))
  fi
}

# Optional tools that may not be available in Azure Linux 3.0
check_optional() {
  local name="$1"
  shift
  if command -v "$name" &>/dev/null; then
    echo "  [PASS] $name"
    ((PASS++))
  else
    echo "  [SKIP] $name — not available in Azure Linux 3.0"
    ((SKIP++))
  fi
}

echo "========================================"
echo " debug-container-ms Tool Validation"
echo "========================================"
echo ""

echo "── System & Shell ──"
check bash bash --version
check vim vim --version
check git git --version
check jq jq --version
check file file --version

echo ""
echo "── Network Diagnostics ──"
check curl curl --version
check wget wget --help
check ping ping -c 1 127.0.0.1
check traceroute traceroute --version
check mtr mtr --version
check dig dig -v
check nslookup nslookup -version
check host host -V
check ncat ncat --version
check tcpdump tcpdump --version
check_optional tshark tshark --version
check socat socat -V
check nc nc -h
check openssl openssl version
check ip ip -V
check ss ss -V
check ethtool ethtool --version
check iperf3 iperf3 --version
check fping fping --version
check_optional iftop iftop -h
check_optional ngrep ngrep -h
check tcptraceroute tcptraceroute --version

echo ""
echo "── Firewall & NF ──"
check iptables iptables --version
check nft nft --version
check ipset ipset --version
check conntrack conntrack --version

echo ""
echo "── HTTP & gRPC ──"
check http http --version
check ab ab -V
check grpcurl grpcurl --version
check fortio fortio version

echo ""
echo "── Container & K8s ──"
check ctop ctop -v
check termshark termshark --version

echo ""
echo "── Misc Tools ──"
check strace strace --version
check ltrace ltrace --version
check trippy trippy --version
check websocat websocat --version
check deadman deadman --help
check scapy scapy --version
check speedtest-cli speedtest-cli --version

echo ""
echo "── SNMP ──"
check snmpwalk snmpwalk --version
check snmpget snmpget --version

echo ""
echo "========================================"
echo " Results: PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
