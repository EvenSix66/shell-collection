#!/bin/bash

function add_docker_firewall() {
    # 添加docker防火墙规则到 /etc/ufw/after.rules
    cat <<EOF | sudo tee -a /etc/ufw/after.rules
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
EOF
    sudo ufw reload
    echo "已成功添加docker防火墙规则。"
}

function add_docker_port_rule() {
    # 读取用户输入的Docker容器ID
    read -p "请输入Docker容器ID: " container_id

    # 获取容器的IP地址
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)

    if [ -z "$container_ip" ]; then
        echo "无法获取容器IP地址。"
        exit 1
    fi

    # 获取用户输入的IP地址（默认为服务器外网IPv4地址）
    read -p "请输入IP地址（默认为服务器外网IPv4地址）: " user_ip
    ip1=${user_ip:-$(curl -s ifconfig.me)}

    # 获取用户输入的端口号
    read -p "请输入端口号: " port

    # 执行ufw命令
    ufw route allow proto tcp from $ip1 to $container_ip port $port

    if [ $? -eq 0 ]; then
        echo "已成功添加docker端口规则。"
    else
        echo "添加docker端口规则失败。"
    fi
}

# 显示功能选择菜单
while true; do
    echo "功能选择："
    echo "1. 添加docker防火墙"
    echo "2. 添加docker端口规则"
    echo "0. 退出脚本"
    
    read -p "请选择要执行的操作： " choice

    case $choice in
        1)
            add_docker_firewall
            ;;
        2)
            add_docker_port_rule
            ;;
        0)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效选择，请重新输入。"
            ;;
    esac
done
