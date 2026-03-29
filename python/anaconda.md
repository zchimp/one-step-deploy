# windows安装
下载路径： https://www.anaconda.com/download/
双击安装，下一步

打开Anaconda Prompt

创建一个名为pytorch-test的虚拟环境，python版本是3.11.5
conda create -n pytorch-test python=3.11.5

开启这个pytorch-test环境，默认环境是base。
conda activate pytorch-test
退出
conda deactivate

配置
在base环境中执行
conda config --set show_channel_urls yes

打开.condarc,路径在C:\Users\用户名称\目录下
```
channels:
  - defaults
show_channel_urls: true
default_channels:
  - http://mirrors.aliyun.com/anaconda/pkgs/main
  - http://mirrors.aliyun.com/anaconda/pkgs/r
  - http://mirrors.aliyun.com/anaconda/pkgs/msys2
custom_channels:
  conda-forge: http://mirrors.aliyun.com/anaconda/cloud
  msys2: http://mirrors.aliyun.com/anaconda/cloud
  bioconda: http://mirrors.aliyun.com/anaconda/cloud
  menpo: http://mirrors.aliyun.com/anaconda/cloud
  pytorch: http://mirrors.aliyun.com/anaconda/cloud
  simpleitk: http://mirrors.aliyun.com/anaconda/cloud
```
在Anaconda prompt 命令窗口运行 conda clean -i 清除索引缓存，保证用的是镜像站提供的索引。然后输入y。

conda install pytorch torchvision torchaudio cpuonly -c pytorch

# ubuntu linux 安装
## 更新依赖
```
sudo apt update && sudo apt install -y wget bzip2 libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
```

## 下载安装包
```
# x86_64 架构（主流 Ubuntu 机器）
wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O anaconda.sh

# aarch64 架构（ARM/鲲鹏）
# wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-aarch64.sh -O anaconda.sh

# x86_64 架构（国内镜像源）
wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O anaconda.sh

# aarch64 架构（国内镜像源）
# wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/Anaconda3-2023.09-0-Linux-aarch64.sh -O anaconda.sh
```

## 执行安装
```
chmod +x anaconda.sh
bash anaconda.sh
```

## 验证
```
# 检查 conda 版本
conda --version
# 正常输出示例：conda 23.7.4

# 检查 Python 版本（Anaconda 自带）
python --version
# 正常输出示例：Python 3.11.5 :: Anaconda, Inc.

# 创建名为 otel-env 的虚拟环境（Python 3.9）
conda create -n otel-env python=3.9 -y

# 激活虚拟环境
conda activate otel-env

# 验证环境激活（终端前缀显示 (otel-env)）
echo $CONDA_DEFAULT_ENV
# 正常输出：otel-env

```