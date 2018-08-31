#!/bin/bash

updateSystem(){

    echo -e "请输入域名(本地访问请输入localhost): \c"
    read domain
    if  [ ! -n "$domain" ] ; then
    echo "域名不能为空!"
    exit
    fi

    echo -e "请输入要创建的数据库用户名: \c"
    read dbuser
    if  [ ! -n "$dbuser" ] ; then
    echo "数据库用户名不能为空!"
    exit
    fi

    echo -e "请输入要创建的数据库密码: \c"
    read dbpasswd
    if  [ ! -n "$dbpasswd" ] ; then
    echo "数据库密码不能为空!"
    exit
    fi

    echo "开始更新软件列表."

    sudo apt-get update -y 
    sudo apt-get upgrade -y  
    sudo apt-get install -y python-software-properties vim curl 
}

installNginx(){
    echo "开始安装Nginx."

    sudo add-apt-repository ppa:nginx/stable -y
    sudo apt-get install -y nginx 
    sudo sed -i '/sendfile on;/ i client_max_body_size 1024M;' /etc/nginx/nginx.conf

    echo "server {
         listen 80;
         server_name $domain;
         access_log off;
         location /
         {
              proxy_set_header Host \$host;
              proxy_set_header X-Real-Ip \$remote_addr;
              proxy_set_header X-Forwarded-For \$remote_addr;
              proxy_buffer_size 128k;
              proxy_buffers 32 32k;
              proxy_busy_buffers_size 128k;
              proxy_pass http://127.0.0.1:8088/;
         }
    }" |sudo tee /etc/nginx/sites-enabled/docker_edusoho

    sudo service nginx restart

}

installDocker(){
    echo "开始安装Docker."

    curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh -   

    echo "DOCKER_OPTS=\"\$DOCKER_OPTS --registry-mirror=https://51z15ah9.mirror.aliyuncs.com\"" | sudo tee -a /etc/default/docker

    sudo service docker restart

}

installEduSoho(){
    echo "开始安装EduSoho."

    sudo docker pull edusoho/edusoho

    sudo docker run --name edusoho -tid \
        -p 8088:80 \
        -e DOMAIN="$domain" \
        -e MYSQL_USER="$dbuser" \
        -e MYSQL_PASSWORD="$dbpasswd" \
        edusoho/edusoho
    
}

cleanup(){
    echo "开始清理安装包."
    
    sudo apt-get autoremove 
    sudo apt-get autoclean 

    echo "恭喜您,安装成功!在浏览器输入域名即可访问.(本地访问请localhost)"

}

echo "------------------------------------------"
echo "   欢迎使用EduSoho-Docker一键安装脚本!  "
echo "------------------------------------------"
echo "           脚本将完成以下内容:"
echo "           1. 更新软件列表"
echo "           2. 安装Nginx"
echo "           3. 安装Docker"
echo "           4. 安装EduSoho"
echo "           5. 清理安装包"
echo "------------------------------------------"

updateSystem
installNginx
installDocker
installEduSoho
cleanup
