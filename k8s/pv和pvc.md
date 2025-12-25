# 概述
## 支持的PV类型
| 类型 | 说明 |
| :----: | :----: |
| cephfs | 容器存储接口 (CSI) |
| csi | CephFS volume |
| fc | Fibre Channel (FC) 存储 |
| hostPath | HostPath 卷 <br>（仅供单节点测试使用；不适用于多节点集群；请尝试使用 local 卷作为替代） |
| iscsi | iSCSI (SCSI over IP) 存储 |
| local | 节点上挂载的本地存储设备 |
| nfs | 网络文件系统 (NFS) 存储 |
| rbd | Rados 块设备 (RBD) 卷 |

本地的存储卷一般有local和hostPath两种，hostPath不推荐使用在生产环境中，下面教程使用local作为示例。



PV 的创建：即在 k8s 中创建一个 pv 对象  
PV 的挂载：即创建 Pod 指定使用该 PVC，Pod 启动后 PV 被挂载到 Pod 中  
其中创建部分又可以分为两种：  
静态供应：即管理员手动创建 PV  
动态供应：由 k8s 根据 PVC 自动创建对应   
主流的方式为 动态供应，毕竟管理员无法预估集群使用者需要什么样的 PV，也就不可能提前创建好一模一样的 PV，开发人员又可能不了解存储，无法自己创建，最终只能等 Pod 启动时在通知管理员创建 PV ，这样就太麻烦了。  

