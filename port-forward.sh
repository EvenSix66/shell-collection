#!/bin/bash

function check_port_forwarding_enabled() {
    sysctl net.ipv4.ip_forward | grep -q "net.ipv4.ip_forward = 1"

    if [ $? -eq 0 ]; then
        echo "端口转发功能已开启"
    else
        echo "端口转发功能未开启，现在将其开启"
        sudo sysctl -w net.ipv4.ip_forward=1
        sudo bash -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
        echo "端口转发功能已成功开启"
    fi
}

function check_ip_masquerade_enabled() {
    masquerade_enabled=$(firewall-cmd --list-all --zone=public | grep "masquerade")

    if [ -n "$masquerade_enabled" ]; then
        echo "IP伪装功能已开启"
    else
        echo "IP伪装功能未开启，现在将其开启"
        sudo firewall-cmd --zone=public --add-masquerade
        sudo firewall-cmd --zone=public --add-masquerade --permanent
        echo "IP伪装功能已成功开启"
    fi
}

function view_forwarding() {
    echo "当前端口转发情况："
    firewall-cmd --list-all --zone=public | awk '/forward-ports/,/source-ports/' | sed '/forward-ports\|source-ports/d'
}


function add_forwarding() {
    local_port="$1"
    remote_ip="$2"
    remote_port="$3"

    sudo firewall-cmd --zone=public --add-forward-port=port=${local_port}:proto=tcp:toaddr=${remote_ip}:toport=${remote_port}
    sudo firewall-cmd --zone=public --add-forward-port=port=${local_port}:proto=tcp:toaddr=${remote_ip}:toport=${remote_port} --permanent

    echo "已添加端口转发：${local_port} -> ${remote_ip}:${remote_port}"
}

function remove_forwarding() {
    local_port="$1"

    forward_ports=$(firewall-cmd --list-forward-ports --zone=public)

    for port in $forward_ports; do
        if [[ $port == *port=${local_port}:* ]]; then
            sudo firewall-cmd --zone=public --remove-forward-port=${port}
            sudo firewall-cmd --zone=public --remove-forward-port=${port} --permanent
            echo "已删除端口转发：${port}"
            return
        fi
    done

    echo "未找到与本地端口 ${local_port} 对应的端口转发"
}

while true; do
    echo "请选择操作："
    echo "0. 退出脚本"
    echo "1. 查看端口转发情况"
    echo "2. 添加新的端口转发"
    echo "3. 删除端口转发"
    echo "4. 检查并开启端口转发功能"
    echo "5. 检查并开启 IP 伪装功能"
    read -p "输入选项 (0/1/2/3/4/5): " choice

    case $choice in
        0)
            echo "退出脚本"
            exit 0
            ;;
        1)
            view_forwarding
            ;;
        2)
            read -p "输入本地端口: " local_port
            read -p "输入远程 IP: " remote_ip
            read -p "输入远程端口: " remote_port
            add_forwarding "$local_port" "$remote_ip" "$remote_port"
            ;;
        3)
            read -p "输入本地端口: " local_port
            remove_forwarding "$local_port"
            ;;
        4)
            check_port_forwarding_enabled
            ;;
        5)
            check_ip_masquerade_enabled
            ;;
        *)
            echo "无效选项"
            ;;
    esac
    echo "按回车键返回菜单"
    read
done
