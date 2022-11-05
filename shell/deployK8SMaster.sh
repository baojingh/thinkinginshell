#!/usr/bin/bash

#ref for the article
#https://www.cnblogs.com/davis12/p/15129665.html


set -eou pipefail

# 原主机名 VM-4-15-centos
hostnamectl set-hostname m196.k8s.com

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
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF



# 安装 kubeadm kubectl 和 kubelet
yum makecache fast
yum install -y kubectl-1.18.0 kubeadm-1.18.0 kubelet-1.18.0 --nogpgcheck

# 1）公网部署，
# 如果是公网部署，需要将xx.xx更换成公网IP
kubeadm init --apiserver-advertise-address=121.5.73.196 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.18.0 --service-cidr=10.1.0.0/16 --pod-network-cidr=10.244.0.0/16


当出现"this can take up to 4m"，修改如下文件
vim /etc/kubernetes/manifests/etcd.yaml
# - --listen-client-urls=https://127.0.0.1:2379
# - --listen-peer-urls=https://127.0.0.1:2380


# 2）局域网部署, xx.xx就是局域网的IP
kubeadm init --apiserver-advertise-address=192.168.1.33 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.18.0 --service-cidr=10.1.0.0/16 --pod-network-cidr=10.244.0.0/16
# 因为etcd.yaml原配置监听的地址是公网地址，所以会导致etcd的容器运行失败，也就会导致kubelet运行错误。但是把etcd.yaml改完之后，这时k8s发现etcd容器启动失败问题后会自动重试，按照修改后的etcd.yaml重新创建新的etcd的容器去运行。


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# 查看集群状态
kubectl get node


# 公网部署文档
# http://t.zoukankan.com/shapman-p-15095516.html


# 问题排查
1. node已经加入集群，node节点执行命令出错
[root@n3 ~]# kubectl get nodes
error: no configuration has been provided, try setting KUBERNETES_MASTER environment variable

#解决办法
#master节点的admin.conf文件分别拷贝到node节点
scp  /etc/kubernetes/admin.conf  192.168.1.113:/etc/kubernetes/

#每个node节点分别执行

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#2. 测试nginx
## 测试kubernetes集群

在Kubernetes集群中创建一个pod，验证是否正常运行：

```
$ kubectl create deployment nginx --image=nginx
$ kubectl expose deployment nginx --port=80 --type=NodePort
$ kubectl get pod,svc
```

访问地址：http://NodeIP:Port
NodeIP是master的ip，Port是80对应的30361之类的端口

