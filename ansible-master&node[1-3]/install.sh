#!/bin/bash

#################################################################################
## 常规设置

echo "change time zone"
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

echo "set aliyum repo"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo


echo "install soft"
rpm -Uvh https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm

yum clean all && yum makecache fast
yum install vim wget curl tree net-tools -y

# enable ntp to sync time
echo 'sync time'
systemctl start ntpd
systemctl enable ntpd

echo 'disable selinux'
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

echo 'enable iptable kernel parameter'
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
EOF
sysctl -p

echo 'set host name resolution'
cat >> /etc/hosts <<EOF
172.17.6.10 master
172.17.6.11 node1
172.17.6.12 node2
172.17.6.13 node3
EOF

cat /etc/hosts

echo 'set nameserver'
cat > /etc/resolv.conf << EOF 
nameserver 223.5.5.5
nameserver 8.8.8.8"
EOF
cat /etc/resolv.conf

echo 'disable swap'
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# set ssh key for mac && win
echo "add ssh key"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDd2IX7HndNRsqEjsFhow+K52eO4L7Vjx5Ce54l0GZwcsiwCp3tAv39KiV48wMioqRoMUCPVZsfTgy8v/9eKNiSdW0NAhUaA8Y0wzSFUcZbeTvGIdJCaBKLpD6ehKtEwCjoZBWpaMlT2/WfGsSktCIaMwS2m3GlT+Rp94fs6AzpeaM9yO2Z7bWvIcDzff5Wc9n28U75NhXzuEDVvAyDeN8GkIAxnHTLHvWwQx8fHWun6NzNppbiXrD5jdntcXFeG6f9kWwRC8U+VMpTs8tWWAKr8z0TNiS3JpF1yfBvCACEs8go/l+FU82n4ilzNNmUqUBFMGdCYayxVG93sRa0YiiZeigm9pmN+kYe61HiDsUEgHFe0bCnbkaUyPJVhyruo520H4sWHU6k+w1tw3Jqy51nOmPYdLpN1lRE3NazKaODExoWG+So14Fz1qaBA+rN7UQWm+YYtglJllTfFYDlnnx30wVtOwb/2v4IuhxyuLEOxhMKN32TJFtP6piKzwcqUqs= Vixtel@DESKTOP-UNFIOA1" >> /home/vagrant/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuf+zd/jzUOWSYovhzoKiEB6JWyUnPE5yducO3RDhsAyxRUlnMBvEP43MkOBSGgmdAkhz3kZi9twP/fOX4518/S4FvJo3YC2UILOQVgHbgwNqNZUbPrlbKfVE9uN2ikHW/POOhohWcl0Pb0cwi21a0beZ8yNww1vGErftkVEXoDEK+gDiC7w5qsQ+9nBDhAkSbqvANfMucFkNUgH8O0M/1gpaejPc1S9RbseZxEhuS6A7Cb5NhY8lvlJYvKDzrSf1iNBshZ3MwtjNcYIKBL2jQxLC21QfNxMxgDt7eJMGRbUNAn6vCWrF8zbMqSA0u1sSKzTCJk1pwKhcPUvCaQA6F lijunjiang2012@163.com" >> /home/vagrant/.ssh/authorized_keys
#################################################################################


echo "master install ansible"
if [[ $1 == "master" ]]; then
    yum install ansible -y
fi

