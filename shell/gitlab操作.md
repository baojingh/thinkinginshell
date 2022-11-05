# Gitlab部署



- gitlab15.3

```
gitlab/gitlab-ee   latest    07a0704dcfbd   13 days ago   2.87GB
```



```yaml
version: '3'
services:
  web:
    image: 'gitlab/gitlab-ee:latest'
    restart: always
    container_name: gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://43.142.94.192:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
    ports:
      - '8929:80'
      - '2224:22'
    volumes:
      - '/data/dockerImages/gitlab/config:/etc/gitlab'
      - '/data/dockerImages/gitlab/logs:/var/log/gitlab'
      - '/data/dockerImages/gitlab/data:/var/opt/gitlab'
    shm_size: '256m'

```







```bash



cat >> /data/dockerImages/gitlab/config/gitlab.rb << EOF
external_url 'http://43.142.94.192'
EOF
```



```bash

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



```

