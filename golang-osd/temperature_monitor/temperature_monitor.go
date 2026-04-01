package main

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

// 读取Windows硬件温度（CPU / GPU / 硬盘）
func main() {
	fmt.Println("===== Go 硬件温度检测（Windows）=====")

	// CPU 温度
	cpuTemp := getCPUTemp()
	if cpuTemp > 0 {
		fmt.Printf("CPU 温度: %.1f ℃\n", cpuTemp)
	} else {
		fmt.Println("CPU 温度: 无法读取（请以管理员运行）")
	}

	// GPU 温度
	gpuTemp := getGPUTemp()
	if gpuTemp > 0 {
		fmt.Printf("GPU 温度: %.1f ℃\n", gpuTemp)
	} else {
		fmt.Println("GPU 温度: 无法读取")
	}

	// 硬盘温度
	hddTemp := getHDDTemp()
	if hddTemp > 0 {
		fmt.Printf("硬盘温度: %.1f ℃\n", hddTemp)
	} else {
		fmt.Println("硬盘温度: 无法读取")
	}
}

// 读取CPU温度（WMI）
func getCPUTemp() float64 {
	cmd := exec.Command("powershell", `Get-WmiObject -Namespace root\WMI -Class MSAcpi_ThermalZoneTemperature | Select-Object -ExpandProperty CurrentTemperature`)
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	tempStr := strings.TrimSpace(string(out))
	temp, err := strconv.Atoi(tempStr)
	if err != nil {
		return 0
	}
	return float64(temp-2732) / 10.0 // 转换为摄氏度
}

// 读取GPU温度
func getGPUTemp() float64 {
	cmd := exec.Command("nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits")
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	tempStr := strings.TrimSpace(string(out))
	temp, _ := strconv.ParseFloat(tempStr, 64)
	return temp
}

// 读取硬盘温度
func getHDDTemp() float64 {
	cmd := exec.Command("powershell", `Get-PhysicalDisk | Get-StorageReliabilityCounter | Select-Object -ExpandProperty Temperature`)
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	tempStr := strings.TrimSpace(string(out))
	temp, _ := strconv.ParseFloat(tempStr, 64)
	return temp
}
