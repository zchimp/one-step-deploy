#安装
## ubuntu
sudo apt install bpftrace llvm clang libbpf-dev -y linux-headers-$(uname -r)
## 容器化
docker run --rm -it --pid=host --privileged quay.io/iovisor/bpftrace

# 使用方法
```
# 基本语法结构，探针和动作组成
bpftrace -e 'probe_list { actions }'

# 列出所有包含 "tcp" 的 tracepoint
sudo bpftrace -l 'tracepoint:*tcp*'

# 列出所有 kprobe 包含 "sys_open"
sudo bpftrace -l 'kprobe:*sys_open*'

# 监控用户态函数调用 (例如 bash 的 readline)
sudo bpftrace -e 'uprobe:/bin/bash:readline { printf("PID %d read line: %s\n", pid, str(arg0)); }'

# 慢 IO 监控
sudo bpftrace -e 'tracepoint:block:block_rq_complete /args->nr_bytes > 100000/ { @lat = hist(args->rq_time); }'

# 查找最慢的磁盘读写操作 (TOP 10)
sudo bpftrace -e 'tracepoint:block:block_rq_issue { @io[comm] = hist(arg0->bytes); }'

#  监控 open 系统调用的延迟分布
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /comm == "vim"/ { @start[tid] = nsecs; } tracepoint:syscalls:sys_exit_openat /@start[tid]/ { @lat = hist(nsecs - @start[tid]); delete(@start[tid]); }'

# 统计每秒的系统调用次数
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter /comm != "bpftrace"/ { @[comm] = count(); } interval:s:1 { print(@); clear(@); }'

# 统计名称中含有xxxxx字符串的进程的系统调用
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter /comm ~ "xxxxx"/ { printf("PID: %d, Comm: %s, Syscall: %s\n", pid, comm, str(args->syscall)); }'
```
