#!/bin/bash


# config docker mirror
cat >> /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF




wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O/etc/yum.repos.d/docker-ce.repo
yum clean all
yum makecache
yum install  -y docker-ce-20.10.1-3.el7
systemctl start docker
systemctl enable docker
wget https://github.com/docker/compose/releases/download/1.25.4/docker-compose-Linux-x86_64 /root/docker-compose



#添加
firewall-cmd --zone=public --add-port=80/tcp --permanent （--permanent永久生效，没有此参数重启后失效）

#重新载入(添加,删除后要重新载入生效)
firewall-cmd --reload

#查看是否生效
firewall-cmd --zone=public --query-port=80/tcp

#删除
firewall-cmd --zone=public --remove-port=80/tcp --permanent

#查看所有打开的端口
firewall-cmd --zone=public --list-ports




#gitlab 修改root密码

[root@VM-4-15-centos info]# docker exec -it gitlab bash
root@823985e03d9e:/# gitlab-rails console -e production
--------------------------------------------------------------------------------
 Ruby:         ruby 2.7.5p203 (2021-11-24 revision f69aeb8314) [x86_64-linux]
 GitLab:       15.3.3-ee (1615d086ad8) EE
 GitLab Shell: 14.10.0
 PostgreSQL:   13.6
------------------------------------------------------------[ booted in 40.99s ]
Loading production environment (Rails 6.1.6.1)
irb(main):001:0> user = User.where(username: 'root').first
=> #<User id:1 @root>
irb(main):002:0> user.password = 'Bob.1qaz!QAZ'
=> "Bob.1qaz!QAZ"
irb(main):003:0> user.save!
=> true
irb(main):004:0> exit
root@823985e03d9e:/# exit
[root@VM-4-15-centos info]#


