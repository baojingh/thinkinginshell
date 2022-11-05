echo 'listen test_131_ssh_22
        mode tcp
        bind *:30068
        server test_131_ssh_22  10.192.27.131:22
        timeout connect      5000
        timeout client      50000
        timeout check      50000
        timeout server 30000' >> /usr/local/haproxy/haproxy.cfg
kill -9 $(ps -ef | grep haproxy | awk '{print $2}')

/usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/haproxy.cfg
ps -ef | grep haproxy