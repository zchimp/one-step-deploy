# 条件
系统要求：Linux 4.15+ 内核（建议 5.0+），开启 BPF 支持
## 安装编译eBPF的依赖
sudo apt install -y clang llvm libbpf-dev linux-headers-$(uname -r)
## Go依赖
go get github.com/cilium/ebpf@latest
go get github.com/cilium/ebpf/cmd/bpf2go@latest

# 实现
编写c代码 bpf_program.c文件（eBPF 字节码，捕获 sched_switch 事件）
```
#include <vmlinux.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

// 定义eBPF Map，存储每个PID的CPU耗时（单位：ns）
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 10240);
    __type(key, u32);       // key: PID
    __type(value, u64);     // value: 累计CPU耗时（ns）
} pid_cpu_time SEC(".maps");

// 存储上一次调度的PID和时间
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1);
    __type(key, u32);       // 固定key: 0
    __type(value, u64);     // value: {prev_pid, prev_timestamp}
} prev_sched SEC(".maps");

// 捕获进程切换事件（sched_switch）
SEC("tracepoint/sched/sched_switch")
int tracepoint__sched__sched_switch(struct trace_event_raw_sched_switch *ctx) {
    u64 now = bpf_ktime_get_ns();  // 当前时间（ns）
    u32 prev_pid = ctx->prev_pid;  // 切换出的PID
    u32 next_pid = ctx->next_pid;  // 切换入的PID
    u32 key = 0;
    u64 *prev_data, prev_time;
    
    // 读取上一次调度的时间
    prev_data = bpf_map_lookup_elem(&prev_sched, &key);
    if (prev_data && *prev_data != 0) {
        prev_time = *prev_data;
        // 计算上一个进程的CPU耗时，并累加到Map
        if (prev_pid != 0 && now > prev_time) {
            u64 *cpu_time = bpf_map_lookup_elem(&pid_cpu_time, &prev_pid);
            u64 delta = now - prev_time;
            if (cpu_time) {
                *cpu_time += delta;
            } else {
                bpf_map_update_elem(&pid_cpu_time, &prev_pid, &delta, BPF_ANY);
            }
        }
    }
    
    // 更新当前调度时间（为下一次计算做准备）
    bpf_map_update_elem(&prev_sched, &key, &now, BPF_ANY);
    return 0;
}

```

golang代码
```
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

// 生成eBPF字节码的Go绑定（编译时自动生成）
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -cc clang bpf bpf_program.c -- -I./ -D__TARGET_ARCH_x86_64

func main() {
	// 1. 提升RLIMIT_MEMLOCK限制（eBPF必需）
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("移除内存锁限制失败: %v", err)
	}

	// 2. 加载eBPF程序和Map
	objs := bpfObjects{}
	if err := loadBpfObjects(&objs, nil); err != nil {
		log.Fatalf("加载eBPF程序失败: %v", err)
	}
	defer objs.Close()

	// 3. 附加tracepoint（绑定sched_switch事件）
	tp, err := link.Tracepoint("sched", "sched_switch", objs.TracepointSchedSchedSwitch, nil)
	if err != nil {
		log.Fatalf("附加tracepoint失败: %v", err)
	}
	defer tp.Close()

	log.Println("eBPF程序加载成功，开始采集CPU信息（按Ctrl+C退出）")

	// 4. 处理退出信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 5. 定时读取eBPF Map数据（每2秒输出一次）
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-sigChan:
			log.Println("退出采集...")
			return
		case <-ticker.C:
			// 读取PID-CPU耗时Map
			iter := objs.PidCpuTime.Iterate()
			var key uint32
			var value uint64
			fmt.Println("=== 进程CPU耗时统计（ns） ===")
			for iter.Next(&key, &value) {
				// 转换为毫秒，便于阅读
				ms := value / 1000000
				fmt.Printf("PID: %d \t CPU耗时: %d ms\n", key, ms)
				// 重置统计（可选，根据需求保留累计或清零）
				zero := uint64(0)
				objs.PidCpuTime.Update(&key, &zero, ebpf.UpdateAny)
			}
			if err := iter.Err(); err != nil {
				log.Printf("读取Map失败: %v", err)
			}
		}
	}
}
```

# 编译运行
## 生成eBPF绑定
go generate

## 编译运行（需要 root 权限，因为操作 eBPF）
go build -o ebpf-cpu-monitor
sudo ./ebpf-cpu-monitor

2026/02/18 15:00:00 eBPF程序加载成功，开始采集CPU信息（按Ctrl+C退出）
=== 进程CPU耗时统计（ns） ===
PID: 1      CPU耗时: 120 ms
PID: 1234      CPU耗时: 890 ms
PID: 5678      CPU耗时: 450 ms

# 总结
eBPF Map：是内核态和用户态通信的核心，示例中pid_cpu_time存储 PID 的 CPU 耗时，prev_sched存储上一次调度的时间戳。 
Tracepoint：sched_switch是内核追踪点，每次进程切换时触发，是统计进程 CPU 耗时的核心事件。 
时间计算：用bpf_ktime_get_ns()获取内核高精度时间（纳秒），通过两次调度的时间差计算进程 CPU 占用。 
权限要求：操作 eBPF 需要 root 权限，普通用户无法加载 eBPF 程序。  
## 扩展场景（适合 Agent 开发）  
按 CPU 核心统计：修改 eBPF 程序，捕获cpu_id（bpf_get_smp_processor_id()），统计每个核心的使用率。  
系统调用 CPU 耗时：使用kprobe捕获系统调用（如sys_execve），统计每个系统调用的 CPU 耗时。  
CPU 使用率计算：结合总 CPU 时间和空闲时间，计算实时 CPU 使用率（比/proc/stat更实时）。  
数据上报：将读取到的 PID-CPU 耗时数据，通过 HTTP/GRPC 上报到监控平台（集成到你之前的 Agent 逻辑）。  

## 
Go + eBPF 采集 CPU 信息的核心是：通过cilium/ebpf库加载 eBPF 程序，利用内核 Tracepoint/Kprobe 捕获 CPU 相关事件，通过 eBPF Map 实现内核态 - 用户态数据交互；
相比读取/proc文件，eBPF 能实现细粒度、低开销、实时的 CPU 监控（进程级 / 系统调用级），但需要内核版本支持且开发复杂度更高；
实际 Agent 开发中，可根据需求选择：基础系统 CPU 使用率用/proc/stat，精细化 CPU 行为分析用 eBPF。