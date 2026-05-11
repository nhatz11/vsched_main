#!/usr/bin/env bash

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"
    if [ "$result" = "ok" ]; then
        echo "  ✅ $label"
        ((PASS++))
    else
        echo "  ❌ $label — $result"
        ((FAIL++))
    fi
}

echo "======================================="
echo "         vSched Sanity Check"
echo "======================================="

echo ""
echo "--- Processes ---"
pgrep -x vcap > /dev/null 2>&1 && check "vcap running" "ok" || check "vcap running" "not found"
pgrep -x vtop > /dev/null 2>&1 && check "vtop running" "ok" || check "vtop running" "not found"
pgrep -x atc  > /dev/null 2>&1 && check "atc running"  "ok" || check "atc running"  "not found (IVH off)"

echo ""
echo "--- Kernel Module ---"
lsmod | grep -q vsched_module && check "vsched_module loaded" "ok" || check "vsched_module loaded" "not in lsmod"

echo ""
echo "--- Proc Interfaces ---"
for f in /proc/vcap_info /proc/vcapacity_write /proc/vav_capacity_write /proc/vlatency_write; do
    [ -e "$f" ] && check "$f exists" "ok" || check "$f exists" "missing"
done

echo ""
echo "--- Cgroups ---"
[ -d /sys/fs/cgroup/hi_prgroup ] && check "hi_prgroup cgroup" "ok" || check "hi_prgroup cgroup" "missing"
[ -d /sys/fs/cgroup/lw_prgroup ] && check "lw_prgroup cgroup" "ok" || check "lw_prgroup cgroup" "missing"

echo ""
echo "--- BPF Hooks (IVH) ---"
PROGLIST=$(sudo bpftool prog list 2>/dev/null)
for name in test test3 test4 test6 test32; do
    echo "$PROGLIST" | grep -q "name $name" \
        && check "hook '$name' loaded" "ok" \
        || check "hook '$name' loaded" "not found"
done

TOTAL=$((PASS + FAIL))
echo ""
echo "======================================="
echo " Results: $PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ] && echo " ✅ All checks passed — ready to benchmark" || echo " ❌ $FAIL check(s) failed — fix before running"
echo "======================================="
