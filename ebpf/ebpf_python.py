#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
支持Golang闭包监控：捕获闭包函数参数，解决unknown opcode错误
"""
from bcc import BPF
import ctypes as ct
import os
import sys
import signal
import subprocess
import re

# 极致简化的BPF代码（仅传递原始值，无任何字符串操作）
bpf_source = """
#include <uapi/linux/ptrace.h>
#include <linux/sched.h>

// 仅传递原始数值，无字符串
struct event {
    u32 pid;
    u64 ts;
    char comm[TASK_COMM_LEN];
    u64 arg1;
    u64 arg2;
    u64 arg3;
    u64 arg4;
    u64 arg5;
    u64 arg6;
    u64 ret_val;
    u64 addr;  // 函数地址（用于用户态解析符号）
};

BPF_PERF_OUTPUT(events);
BPF_HASH(args_map, u64, struct event);  // key: pid_tgid

// x86_64寄存器宏
#ifdef __x86_64__
#define ARG1 PT_REGS_PARM1(ctx)
#define ARG2 PT_REGS_PARM2(ctx)
#define ARG3 PT_REGS_PARM3(ctx)
#define ARG4 PT_REGS_PARM4(ctx)
#define ARG5 PT_REGS_PARM5(ctx)
#define ARG6 PT_REGS_PARM6(ctx)
#define RET_VAL PT_REGS_RC(ctx)
#define FUNC_ADDR PT_REGS_IP(ctx)  // 当前函数地址
#endif

// 极简进程名检查（无字符串操作）
static inline int check_categraf(const char *comm) {
    // 快速匹配categraf子串
    for (int i = 0; i < TASK_COMM_LEN - 7; i++) {
        if (comm[i] == 'c' && comm[i+1] == 'a' && comm[i+2] == 't' &&
            comm[i+3] == 'e' && comm[i+4] == 'g' && comm[i+5] == 'r' &&
            comm[i+6] == 'a' && comm[i+7] == 'f') {
            return 1;
        }
    }
    return 0;
}

// 函数进入探针（仅存原始值）
int trace_entry(struct pt_regs *ctx) {
    u64 pid_tgid = bpf_get_current_pid_tgid();
    u32 pid = pid_tgid >> 32;
    char comm[TASK_COMM_LEN] = {0};

    bpf_get_current_comm(comm, sizeof(comm));
    if (!check_categraf(comm)) return 0;

    struct event evt = {0};
    evt.pid = pid;
    evt.ts = bpf_ktime_get_ns();
    bpf_probe_read_str(evt.comm, sizeof(evt.comm), comm);
    evt.arg1 = ARG1;
    evt.arg2 = ARG2;
    evt.arg3 = ARG3;
    evt.arg4 = ARG4;
    evt.arg5 = ARG5;
    evt.arg6 = ARG6;
    evt.addr = FUNC_ADDR;  // 记录当前函数地址

    args_map.update(&pid_tgid, &evt);
    return 0;
}

// 函数退出探针（仅存返回值）
int trace_return(struct pt_regs *ctx) {
    u64 pid_tgid = bpf_get_current_pid_tgid();
    u32 pid = pid_tgid >> 32;
    char comm[TASK_COMM_LEN] = {0};

    bpf_get_current_comm(comm, sizeof(comm));
    if (!check_categraf(comm)) return 0;

    struct event *evt = args_map.lookup(&pid_tgid);
    if (!evt) return 0;

    struct event out_evt = *evt;
    out_evt.ret_val = RET_VAL;
    args_map.delete(&pid_tgid);

    // 输出事件（无任何字符串处理）
    events.perf_submit(ctx, &out_evt, sizeof(out_evt));
    return 0;
}
"""

# 定义用户态事件结构体
class Event(ct.Structure):
    _fields_ = [
        ("pid", ct.c_uint),
        ("ts", ct.c_ulonglong),
        ("comm", ct.c_char * 16),
        ("arg1", ct.c_ulonglong),
        ("arg2", ct.c_ulonglong),
        ("arg3", ct.c_ulonglong),
        ("arg4", ct.c_ulonglong),
        ("arg5", ct.c_ulonglong),
        ("arg6", ct.c_ulonglong),
        ("ret_val", ct.c_ulonglong),
        ("addr", ct.c_ulonglong),
    ]

# 解析符号和地址（包含闭包）
def parse_symbols_with_address(exe_path):
    """
    返回：{地址: 符号名} 字典，包含所有闭包符号
    """
    sym_map = {}
    try:
        # 解析nm输出（包含地址和符号名）
        cmd = f"nm -D {exe_path} 2>/dev/null | grep 'T ' | awk '{{print $1, $3}}'"
        result = subprocess.check_output(cmd, shell=True).decode()
        for line in result.split('\n'):
            line = line.strip()
            if not line:
                continue
            addr_hex, sym = line.split(' ', 1)
            addr = int(addr_hex, 16)
            sym_map[addr] = sym

        # 补充静态链接符号
        if not sym_map:
            cmd = f"nm {exe_path} 2>/dev/null | grep 'T ' | awk '{{print $1, $3}}'"
            result = subprocess.check_output(cmd, shell=True).decode()
            for line in result.split('\n'):
                line = line.strip()
                if not line:
                    continue
                addr_hex, sym = line.split(' ', 1)
                addr = int(addr_hex, 16)
                sym_map[addr] = sym

    except subprocess.CalledProcessError:
        pass

    # 过滤出main/categraf相关的符号（包含闭包）
    filtered = {}
    for addr, sym in sym_map.items():
        if sym.startswith(("main.", "categraf.")):
            filtered[addr] = sym

    return filtered

# 查找目标进程
def find_target_processes():
    targets = []
    for pid_str in os.listdir("/proc"):
        if not pid_str.isdigit():
            continue
        pid = int(pid_str)
        try:
            with open(f"/proc/{pid}/comm", "r") as f:
                comm = f.read().strip()
            if "categraf" in comm:
                exe_path = os.readlink(f"/proc/{pid}/exe")
                targets.append((pid, exe_path))
        except Exception:
            continue
    return targets

# 用户态解析闭包并格式化输出
def print_event(cpu, data, size):
    global sym_maps  # 全局符号映射表
    evt = ct.cast(data, ct.POINTER(Event)).contents
    ts = evt.ts / 1000000000.0

    # 格式化参数
    args_str = (
        f"arg1=0x{evt.arg1:x}, arg2=0x{evt.arg2:x}, arg3=0x{evt.arg3:x}, "
        f"arg4=0x{evt.arg4:x}, arg5=0x{evt.arg5:x}, arg6=0x{evt.arg6:x}"
    )
    ret_str = f"0x{evt.ret_val:x}"

    # 解析函数名（优先用预解析的符号表，兼容闭包）
    func_name = "unknown"
    pid = evt.pid
    if pid in sym_maps:
        # 匹配最接近的地址（闭包地址可能略有偏移）
        sym_map = sym_maps[pid]
        closest_addr = min(sym_map.keys(), key=lambda x: abs(x - evt.addr))
        if abs(closest_addr - evt.addr) < 0x100:  # 地址偏移小于256字节
            func_name = sym_map[closest_addr]

    # 输出（包含闭包函数名和参数）
    print(f"[{ts:.6f}] PID: {pid} | COMM: {evt.comm.decode().strip()}")
    print(f"  函数: {func_name} (0x{evt.addr:x})")
    print(f"  入参: {args_str}")
    print(f"  出参: {ret_str}")
    print("-" * 80)

# 优雅退出
def handle_exit(signal_num, frame):
    print("\n[INFO] 停止监控，清理eBPF资源...")
    sys.exit(0)

if __name__ == "__main__":
    global sym_maps
    sym_maps = {}  # {pid: {addr: sym}}

    # 检查root权限
    if os.geteuid() != 0:
        print("错误：必须以root权限运行！")
        print(f"执行命令：sudo python3 {sys.argv[0]}")
        sys.exit(1)

    # 检查依赖
    try:
        from bcc import BPF
    except ImportError:
        print("错误：未安装bpfcc-tools！")
        print("Ubuntu/Debian: sudo apt install bcc bcc-tools linux-headers-$(uname -r)")
        print("CentOS/RHEL: sudo yum install bcc bcc-devel kernel-devel-$(uname -r)")
        sys.exit(1)

    # 检查nm命令
    try:
        subprocess.check_output(["nm", "--version"], stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        print("错误：未安装binutils！")
        print("Ubuntu/Debian: sudo apt install binutils")
        print("CentOS/RHEL: sudo yum install binutils")
        sys.exit(1)

    # 查找目标进程
    target_procs = find_target_processes()
    if not target_procs:
        print("未找到包含 'categraf' 字符串的进程！")
        sys.exit(0)
    print(f"找到 {len(target_procs)} 个目标进程：")
    for pid, exe in target_procs:
        print(f"  PID: {pid} | 路径: {exe}")

    # 加载BPF程序（极致简化版）
    try:
        b = BPF(text=bpf_source)
    except Exception as e:
        print(f"BPF编译失败：{e}")
        sys.exit(1)

    # 附加探针（直接附加到地址，支持闭包）
    attach_count = 0
    for pid, exe_path in target_procs:
        # 解析所有符号（包含闭包）
        sym_map = parse_symbols_with_address(exe_path)
        sym_maps[pid] = sym_map

        if not sym_map:
            print(f"警告：PID {pid} 无可用符号（可能已剥离）")
            continue

        # 遍历所有地址附加探针（包含闭包）
        for addr, sym in sym_map.items():
            try:
                # 附加uprobe到内存地址（支持闭包）
                b.attach_uprobe(
                    name=exe_path,
                    addr=addr,  # 直接用地址，不用符号名
                    pid=pid,
                    fn_name="trace_entry"
                )
                # 附加uretprobe
                b.attach_uretprobe(
                    name=exe_path,
                    addr=addr,
                    pid=pid,
                    fn_name="trace_return"
                )
                attach_count += 1
                print(f"  已附加探针到: {sym} (0x{addr:x}) (PID: {pid})")
            except Exception as e:
                # 跳过无法附加的符号，不影响整体
                print(f"  跳过 {sym}: {str(e)}")
                continue

    if attach_count == 0:
        print("警告：未附加任何探针！")
        print("可能原因：Golang程序编译时使用了 -ldflags '-s -w' 剥离符号")
    else:
        print(f"\n成功附加 {attach_count} 个探针（包含闭包），开始监控（Ctrl+C退出）...")
        print("-" * 80)

    # 设置回调
    b["events"].open_perf_buffer(print_event)

    # 注册退出信号
    signal.signal(signal.SIGINT, handle_exit)
    signal.signal(signal.SIGTERM, handle_exit)

    # 主循环
    while True:
        try:
            b.perf_buffer_poll()
        except KeyboardInterrupt:
            break

    print("\n监控结束！")
