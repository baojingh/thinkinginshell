#!/usr/bin/bash
set -eou pipefail

# 原主机名 VM-4-15-centos
hostnamectl set-hostname n192.k8s.com

sestatus
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config 
sestatus

systemctl stop firewalld

cat >> /etc/hosts << EOF
121.5.73.196    m196.k8s.com
43.142.94.192   n192.k8s.com
EOF


# 将桥接的IPV4流量传递到iptables 的链
cat >> /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

yum install ntpdate -y
ntpdate cn.pool.ntp.org


# 安装docker
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O/etc/yum.repos.d/docker-ce.repo
yum clean all
yum makecache
yum -y install docker-ce
systemctl start docker
systemctl enable docker




cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF



# 安装 kubeadm kubectl 和 kubelet
yum makecache fast
yum install -y kubectl-1.18.0 kubeadm-1.18.0 kubelet-1.18.0 --nogpgcheck

# 参照master节点的init输出执行如下。
kubeadm join 121.5.73.196:6443 --token zb8g8p.ijow4w8laeo7veoh     --discovery-token-ca-cert-hash sha256:9688e193fc60f70e2407f093d9ad5145efbf70485ffd5b29aadd7abb91981a4c


# 在master执行如下命令，复制文件过去后，接着在node机器执行以下命令
scp /etc/kubernetes/admin.conf root@n192.k8s.com:/etc/kubernetes/

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config