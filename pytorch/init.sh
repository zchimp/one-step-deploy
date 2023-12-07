#!/bin/bash
sudo apt install -y python
sudo apt install python3-pip
pip3 install torch torchvision torchaudio
echo "\
import torch
x = torch.rand(5, 3)
print(x)
" > test_pytorch.py

python test_pytorch.py