#!/bin/bash -ex

# 设置最大内存占用百分比
PID_MEM_MAX="85"

# 设置最大系统负载
SYS_LOAD_MAX="3"

# 设置需要监控的服务名称
NAME_LIST="caddy v2ray"

for NAME in $NAME_LIST
do
    # 初始化内存统计
    PID_MEM_SUM=0

    # 获取该程序总进程数
    PID_NUM_SUM=`ps aux | grep $NAME | grep -v grep | wc -l`

    # 列出每个进程内存占用百分比
    PID_MEM_LIST=`ps aux | grep $NAME |grep -v grep | awk '{print $4}'`

    # 计算所有进程总内存占用
    for PID_MEM in $PID_MEM_LIST
    do
        PID_MEM_SUM=`echo $PID_MEM_SUM + $PID_MEM | bc`
    done

    # 获取最近五分钟系统负载
    SYS_LOAD=`uptime | awk '{print $(NF-1)}' | sed 's/,//'`

    # 比较内存占用和系统负载是否超过阀值
    MEM_VULE=`awk 'BEGIN{print('"$PID_MEM_SUM"'>='"$PID_MEM_MAX"'?"1":"0")}'`
    LOAD_VULE=`awk 'BEGIN{print('"$SYS_LOAD"'>='"$SYS_LOAD_MAX"'?"1":"0")}'`

    # 如果系统内存占用和系统负载超过阀值，则进行下面操作。
    if [ $MEM_VULE = 1 ] || [ $LOAD_VULE = 1 ] ;then
        #  写入日志
        echo $(date +"%y-%m-%d %H:%M:%S") "killall $NAME" "(MEM:$PID_MEM_SUM,LOAD:$SYS_LOAD)">> /var/log/autoreboot.log
        # 正常停止服务
        systemctl stop $NAME
        sleep   3
      #  重启
        systemctl start $NAME
      #写入日志
        echo $(date +"%y-%m-%d %H:%M:%S") "start $NAME" "(MEM:$PID_MEM_SUM,LOAD:$SYS_LOAD)" >> /var/log/autoreboot.log
    else
        echo "$NAME very health!(MEM:$PID_MEM_SUM,LOAD:$SYS_LOAD)" > /dev/null
    fi
done
