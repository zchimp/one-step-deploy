---
title: 内网IP冲突问题定位与排查
tags: IP冲突,Linux,网络
date: 2021.02.19
renderNumberedHeading: true
grammar_cjkRuby: true
---

# 问题
过完春节假期回到公司，发现一台Linux虚拟机登陆不了了。
打开VM管理界面发现这个机器还是开着的，并且使用内置控制台可以登陆，并且IP地址等配置正常。尝试用另一台机器尝试也是无法登陆。
在Linux虚拟机上看配置，防火墙是关闭的，netstat -tunlp查看发现22端口也是打开的。感觉不是系统配置的问题了。
在虚机上ping我本地的主机是可以通的，但是反过来本地ping虚机是无法ping通的。当虚机ping本机机器的同时，本地机器可以ping通虚机，当虚机不ping本机机器时，本地机器又无法ping通这个IP了。这一下我感觉是IP冲突了。
因为本机Windows和研发环境的虚机Linux不在同一网段上，于是我重新找了台223网段的Linux机器进行操作。

# 定位过程
## arping 发送广播包
使用arping发送发送广播包，注意使用-I参数指定网卡，网上有些arping使用的教程没有这个说明，不知道是不是主机没有多网卡就不用指定了。
![enter description here](./images/arping.png)
发现10.99.223.106的确有两个MAC地址，有两台机器给出了响应，说明IP地址冲突了。

## nmap探测
第一次返回的结果显示这个是一台VM虚机，并且3306等端口开启，应该是探测到了我的虚机。
![enter description here](./images/nmap1.png)
关闭这个虚机之后，再次使用nmap探测，返回结果
![enter description here](./images/nmap2.png)
第二次返回的结果发现该设备只开启了telnet端口，怀疑并不是虚机，可能是某个网络设备。使用nmap -A查看详细信息。等待一会之后，返回结果。
![enter description here](./images/nmap-A.png)
发现可能是一台思科的交换机占用了这个IP地址。

# 解决方法
惹不起网管只能灰溜溜换个IP地址。
使用nmap -sP 10.99.223.0/24，遍历一下当前网段。截取部分返回结果。
![enter description here](./images/1613737994704.png)
找了一个没有被占用的IP地址62，重新配置一下虚机的静态IP，问题解决，登陆成功。