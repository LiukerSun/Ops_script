#!/bin/bash

# 安装编译工具和依赖项
sudo apt-get update
sudo apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev

# 下载Nginx源码
wget https://nginx.org/download/nginx-1.25.4.tar.gz

# 解压源码
tar -xzvf nginx-1.25.4.tar.gz
cd nginx-1.25.4

# 配置、编译和安装Nginx
./configure --prefix=/opt/nginx
make
sudo make install

# 添加Nginx到环境变量
echo 'export PATH=$PATH:/opt/nginx/sbin' >> ~/.bashrc
source ~/.bashrc

# 启动Nginx
sudo /opt/nginx/sbin/nginx

# 打印安装完成信息
echo "Nginx has been installed successfully!"
