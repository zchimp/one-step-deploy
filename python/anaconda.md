windows安装
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