# /bin/sh

# 程序出错时，会自动退出，不会继续执行
# 如果部署过程中出现问题，需要根据日志手动修复问题，重新执行部署脚本
# 说明
#  echo $? 输出上一条指令的执行状态。0 正常；非0异常并且会退出
#  cat a.txt 输出是0；cat a.txt  | grep x 如果a.txt文件中没有x，整个命令的输出是1
set -e errexit

# Centos7.*部署Spindle服务

# 内存大小
echo `date '+%Y-%m-%d %H:%M:%S'` 'total memory:'  `free -h | sed -n '2p' | awk '{print $2}'`
# CPU核数
echo `date '+%Y-%m-%d %H:%M:%S'` 'total CPU cores:' `cat /proc/cpuinfo | grep "processor" |wc -l `
echo ''

# CPU指令集信息
echo `date '+%Y-%m-%d %H:%M:%S'` 'total CPU cores:' `cat /proc/cpuinfo`


# 查看系统版本
echo `date '+%Y-%m-%d %H:%M:%S'` 'check the CentOS version and Linux kernal version'
cat /etc/redhat-release
uname -a
echo ''

# 修改selinux,设置为disabled,重启系统后生效
echo `date '+%Y-%m-%d %H:%M:%S'` 'check selinux status and disable it, rebootting OS needed'
sestatus
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config
sestatus
echo ''

# 指定时区
# echo `date '+%Y-%m-%d %H:%M:%S'` 'add Asia/Shanghai in system'
# touch /etc/timezone && echo 'Asia/Shanghai' >  /etc/timezone
# cat /etc/timezone
# echo ''

# 手动指定日期时间(同时会自动同步到硬件)
# timedatectl set-time "2022-01-18 17:10:00"

# 是否使用ntp取决于客户环境；多机部署时，需要指定ntp，保证各服务器时钟同步
# yum -y install ntp
# systemctl start ntp
# systemctl enable ntp
# systemctl status ntp
# ntpdate 0.asia.pool.ntp.org
# hwclock --systohc

# 临时关闭防火墙
echo `date '+%Y-%m-%d %H:%M:%S'` 'stop and disable firewall' 
systemctl stop firewalld
systemctl disable firewalld
echo ''

# 根据实际需要，决定是否将后端以及数据库端口暴露出来
# 如果防火墙没有开启，执行如下命令会提示防火墙当前是关闭状态
# firewall-cmd --zone=public --add-port=8030/tcp --permanent
# firewall-cmd --zone=public --add-port=9095/tcp --permanent
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --zone=public --add-port=6379/tcp --permanent
# firewall-cmd --zone=public --add-port=9042/tcp --permanent
# firewall-cmd --zone=public --add-port=2375/tcp --permanent

# ulimit -a 查看open files 数量，默认的1024不够，要求102400
# data_process服务所在服务器上需要设置文件句柄数量，102400。以下操作需要重启后生效
echo `date '+%Y-%m-%d %H:%M:%S'` 'set open file limit' 
cat /etc/sysctl.conf | grep fs.file-max || true
if [ `grep -c "fs.file-max = 102400" "/etc/sysctl.conf"` -ne '1' ];then
    echo  'fs.file-max = 102400' >> /etc/sysctl.conf
    echo "add fs.file-max success"
fi
cat /etc/sysctl.conf | grep fs.file-max || true


cat /etc/security/limits.conf | tail -n 10
if [ `grep -c "* soft     nproc          102400" "/etc/security/limits.conf"` -ne '1' ];then
    echo '
* soft     nproc          102400
* hard     nproc          102400
* soft     nofile         102400
* hard     nofile         102400
' >> /etc/security/limits.conf
    echo "add limits.conf success"
fi
cat /etc/security/limits.conf | tail -n 10
echo ''

echo `date '+%Y-%m-%d %H:%M:%S'` 'start uncompress spindleSystemDeploy.zip' 
if [ ! -d "spindleSystemDeploy" ]; then
        echo 'current path has NO spindleSystemDeploy'
        unzip spindleSystemDeploy.zip
        \cp -r spindleSystemDeploy/* /data
else
        echo 'current path has spindleSystemDeploy and ignore'
fi
echo `date '+%Y-%m-%d %H:%M:%S'` 'finish uncompress spindleSystemDeploy.zip' 
echo ''

# 安装telnet
echo `date '+%Y-%m-%d %H:%M:%S'` 'install telnet for portValidate function' 
if [ ! "$(command -v telnet)" ]; then
        rpm -Uivh /data/data_spindle_prod/software/telnet-0.17-66.el7.x86_64.rpm --nodeps --force
else
        echo 'system has telnet'
fi
echo ''


# 在线安装docker
# sudo yum install -y docker-ce-20.10.5-3.el7

# 基于yum离线部署docker
# \cp -r /data/data_spindle_prod/software/docker-ce-offline.repo /etc/yum.repos.d/
# echo "add docker-ce-offline.repo success"
# rpm -ivh       /data/data_spindle_prod/software/dockerLocalRepo/createrepo/*.rpm
# createrepo -d /data/data_spindle_prod/software/dockerLocalRepo/data
# mkdir -p /data/dockerMetaData
# yum clean all
# yum makecache
# yum install -y docker-ce

# 手动安装docker rpm，不判断依赖问题
echo `date '+%Y-%m-%d %H:%M:%S'` 'install docker offline and update docker meta'
if [ ! "$(command -v docker)" ]; then
        rpm -Uivh /data/data_spindle_prod/software/dockerLocalRepo/data/*.rpm --nodeps --force
else
        echo 'system has docker'
fi
if [ `grep -c "dockerMetaData" "/usr/lib/systemd/system/docker.service"` -ne '1' ];then
    sudo sed -i  's/containerd.sock*/& --graph=\/data\/dockerMetaData\/docker -H tcp:\/\/0.0.0.0:2375 /g' /usr/lib/systemd/system/docker.service
    echo "add dockerMetaData success"
fi

systemctl daemon-reload
systemctl start docker
systemctl enable docker
docker version
docker info
echo ''

# 部署docker-compose, version: docker-compose version 1.25.4, build 8d51620a
echo `date '+%Y-%m-%d %H:%M:%S'` 'install docker-compose' 
if [ ! "$(command -v docker-compose)" ]; then
        \cp /data/data_spindle_prod/software/docker-compose /usr/local/bin
        sudo chown root:root /usr/local/bin/docker-compose
        sudo chmod u+x  /usr/local/bin/docker-compose
        echo 'system has docker-compose'
fi
echo ''


# 修改镜像名称
# docker tag 3816db78c729 basic-centos:1.0

# 导入docker镜像
echo `date '+%Y-%m-%d %H:%M:%S'` 'start load docker images' 

if [ $[`docker images | wc -l`] -lt 12 ]; then
        chmod u+x /data/data_spindle_prod/dockerImages/dockerLoad.sh
        /bin/sh   /data/data_spindle_prod/dockerImages/dockerLoad.sh
fi
echo 'current docker images count:' `docker images | wc -l`
echo ''

docker images
echo ''


# 更改系统语言(需要重启)
# sed -i 's/ LANG / /g'  /etc/ssh/sshd_config
# sed -i 's/ LANG / /g'  /etc/ssh/ssh_config
# systemctl  restart sshd
# 关闭当前会话窗口并重新登录即可生效


# 修改cassandra JVM堆参数,获取服务器一半的内存,注意sed需要用双引号才能解析shell变量
echo `date '+%Y-%m-%d %H:%M:%S'` 'update JVM properties for cassandra' 
export CASSANDRAMEM=$[`free -g | sed -n '2p' | awk '{print $2}'`  / 2]
sed -i "s/-Xms[0-9]\{1,3\}G/-Xms${CASSANDRAMEM}G/g"  /data/db_images/cassandra/config/jvm.options
sed -i "s/-Xmx[0-9]\{1,3\}G/-Xmx${CASSANDRAMEM}G/g"  /data/db_images/cassandra/config/jvm.options
echo ''


# 添加服务开机自启动,如果600s后服务还未正常启动，操作系统就不会继续启动Spindle系统
# rc.local文件的touch /var/lock/subsys/local 不能删除，否则开机无法执行相关脚本

if [ `grep -c "start_db" "/etc/rc.d/rc.local"` -ne '1' ];then
    echo 'timeout 600 nohup  /bin/sh /data/data_spindle_prod/basic/start_db.sh > /data/data_spindle_prod/logs/startUp/startUp.log 2>&1 &' >> /etc/rc.d/rc.local
    echo 'sleep 200' >> /etc/rc.d/rc.local
    echo 'timeout 600 nohup  /bin/sh /data/data_spindle_prod/basic/start_app.sh >> /data/data_spindle_prod/logs/startUp/startUp.log 2>&1 &' >> /etc/rc.d/rc.local
    chmod u+x /etc/rc.d/rc.local
    echo "add auto start success"
fi

# 测试开机自启动脚本
echo `date '+%Y-%m-%d %H:%M:%S'` 'start up spindle database system' 
chmod u+x /data/data_spindle_prod/basic/*.sh
timeout 600 nohup  sh /data/data_spindle_prod/basic/start_up.sh > /data/data_spindle_prod/logs/startUp/startUp.log 2>&1 &

# 等待数据库全部启动
echo `date '+%Y-%m-%d %H:%M:%S'` 'sleep 200s......'
sleep 200

echo 'current database docker container count:' `docker ps | wc -l`
echo ''



# 自动导入mysql数据
echo `date '+%Y-%m-%d %H:%M:%S'` 'start import mysql table schema' 
sed -i 's/\r//' /data/db_images/mysql/sqlScript/importDevTables.sh
chmod u+x       /data/db_images/mysql/sqlScript/importDevTables.sh
/bin/sh         /data/db_images/mysql/sqlScript/importDevTables.sh
echo ''


# 自动导入cassandra数据
echo `date '+%Y-%m-%d %H:%M:%S'` 'start import cassandra table schema' 
chmod u+x        /data/db_images/cassandra/sqlScript/importDevTables.sh
sed -i 's/\r//'  /data/db_images/cassandra/sqlScript/importDevTables.sh
/bin/sh          /data/db_images/cassandra/sqlScript/importDevTables.sh
echo ''


# 更新cassandra表ttl
echo `date '+%Y-%m-%d %H:%M:%S'` 'start import cassandra table ttl' 
chmod u+x        /data/db_images/cassandra/sqlScript/updateTableTTL.sh
sed -i 's/\r//'  /data/db_images/cassandra/sqlScript/updateTableTTL.sh
/bin/sh          /data/db_images/cassandra/sqlScript/updateTableTTL.sh
echo ''

echo `date '+%Y-%m-%d %H:%M:%S'` 'start spindle application service' 
timeout 600 nohup  sh /data/data_spindle_prod/basic/start_app.sh >> /data/data_spindle_prod/logs/startUp/startUp.log 2>&1 &

# 等待应用程序全部启动
echo `date '+%Y-%m-%d %H:%M:%S'` 'sleep 200s......'
sleep 200

echo 'current application docker container count:' `docker ps | wc -l`
echo ''


