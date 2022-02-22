#!/bin/bash

###############################################################################
## 服务器信息
# 部署方式: Vagrant + VirtualBox
# vm.box: "centos/7"
# box_version: "2004.01"
# vm.box_url: "https://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-2004_01.VirtualBox.box"
###############################################################################
## description
# 安装k8s 基本软件环境: Docker kubelet kubeadm kubectl
# 但不进行k8s集群初始化
###############################################################################
## 相关源信息：
# 采用aliyun相关源配置
###############################################################################

### 软件版本信息
docker_version="19.03.9-3.el7"
kubeadm_version=""
kubelet_version=""
kubectl_version=""

nptdate_server="ntp.aliyun.com"
timezone="Asia/Shanghai"

###############################################################################
### 设置时区
echo "Set TimeZone"
timedatectl set-timezone ${timezone}

###############################################################################
### 配置yum源
## centos base源
echo "Set CentOS Base Repo"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

# 非阿里云ECS用户会出现 Couldn't resolve host 'mirrors.cloud.aliyuncs.com' 信息，不影响使用。用户也可自行修改相关配置
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

## docker源
echo "Set Docker Repo"
yum-config-manager --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo 

sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+'\
    /etc/yum.repos.d/docker-ce.repo

## k8s源
echo "Set Kubernetes Repo"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

echo "Update Yum Repo Cache"
yum clean all && yum makecache -y
###############################################################################、
### 安装必备软件
echo "Install The Necessary Tools"
yum install -y nptdate tree wget jq psmisc vim net-tools \
    telnet yum-utils device-mapper-persistent-data lvm2 git

###############################################################################
### 同步时间
echo "Synchronised Time"
ntpdate ${nptdate_server}

###############################################################################
### 配置hosts
### 目前不确证用什么方式动态的生成
echo "Set hosts"
cat /vagrant/hosts > /etc/hosts
###############################################################################
### 禁用swap
echo "Disable Swap"
swapoff -a && sysctl -w vm.swappiness=0
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

###############################################################################
### 禁用 SElinux 
echo "Disable SElinux"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disable/' /etc/selinux/config
sed -i 's/^SELINUX=enforcing$/SELINUX=disable/' /etc/sysconfig/selinux

sed -i 's/^SELINUX=permissive$/SELINUX=disable/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disable/' /etc/sysconfig/selinux

###############################################################################
### 关闭并禁用防火墙
echo "Stop and Disable Firewalld Service"
systemctl stop firewalld && systemctl disable firewalld

###############################################################################
### 关闭dnsmasq - 提供 DNS 缓存和 DHCP 服务功能
### 没有安装可以忽略
echo "Disable Dnsmasq Service"
systemctl disable --now dnsmasq

###############################################################################
### 关闭 NetworkManage
### 公有云不可关闭
# echo "Disable NetworkManage Service"
# systemctl disable --now NetworkManage

###############################################################################
### 允许IPTALBES 检查桥接流量
echo "Set Kernel Parameters"
modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
vm.max_map_count=262144
EOF

sysctl --system

###############################################################################
### 安装runtime
## 安装相关依赖
echo "Install Runtime - Docker"
# yum install -y yum-utils
# yum install -y yum-utils device-mapper-persistent-data lvm2

## 清理历史版本
yum remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

## 安装docker
yum -y install docker-ce-${docker_version}

## 配置加速
mkdir /etc/docker -pv
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": [
        "https://8xpk5wnt.mirror.aliyuncs.com"
    ],

    "insecure-registries": [
        "172.16.7.139:5000"
    ]
}
EOF

# 普通用户使用docker 及 开机自启
gpasswd -a vagrant docker
systemctl start docker
chmod a+rw /var/run/docker.sock 

systemctl enable docker

###############################################################################
### 安装 kubeadm kubelet kubectl
echo "Install Kubeadm Kubelet Kubectl"

###############################################################################
# 配置cgroup 驱动程序


###############################################################################
### 其它主机配置
## 配置sshd，允许key认证
sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config 
systemctl restart sshd

## 添加密钥 
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa

echo "add ssh key"echo "add ssh key"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuf+zd/jzUOWSYovhzoKiEB6JWyUnPE5yducO3RDhsAyxRUlnMBvEP43MkOBSGgmdAkhz3kZi9twP/fOX4518/S4FvJo3YC2UILOQVgHbgwNqNZUbPrlbKfVE9uN2ikHW/POOhohWcl0Pb0cwi21a0beZ8yNww1vGErftkVEXoDEK+gDiC7w5qsQ+9nBDhAkSbqvANfMucFkNUgH8O0M/1gpaejPc1S9RbseZxEhuS6A7Cb5NhY8lvlJYvKDzrSf1iNBshZ3MwtjNcYIKBL2jQxLC21QfNxMxgDt7eJMGRbUNAn6vCWrF8zbMqSA0u1sSKzTCJk1pwKhcPUvCaQA6F lijunjiang2012@163.com" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuf+zd/jzUOWSYovhzoKiEB6JWyUnPE5yducO3RDhsAyxRUlnMBvEP43MkOBSGgmdAkhz3kZi9twP/fOX4518/S4FvJo3YC2UILOQVgHbgwNqNZUbPrlbKfVE9uN2ikHW/POOhohWcl0Pb0cwi21a0beZ8yNww1vGErftkVEXoDEK+gDiC7w5qsQ+9nBDhAkSbqvANfMucFkNUgH8O0M/1gpaejPc1S9RbseZxEhuS6A7Cb5NhY8lvlJYvKDzrSf1iNBshZ3MwtjNcYIKBL2jQxLC21QfNxMxgDt7eJMGRbUNAn6vCWrF8zbMqSA0u1sSKzTCJk1pwKhcPUvCaQA6F lijunjiang2012@163.com" >> /home/vagrant/.ssh/authorized_keys
###############################################################################