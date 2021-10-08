
#安装yum package
yum_install(){
	local _i="";
	local _wpn=`yum list installed`;
        for _i in $@; do
			if [ `echo $_wpn|tr " " "\n"|grep -e "^${_i}"|wc -l` -eq "0" ];then
				echo $_i
				yum -y install $_i;
			fi
        done
}

yum_uninstall() {
	local _i='';
	local _wpn=`yum list installed`;
    for _i in $@;
    do
        if [ `echo $_wpn|tr " " "\n"|grep -e "^${_i}"|wc -l` -gt "0" ];then
        	yum -y remove $_i
        fi
	done
}

if [ ! -f /etc/centos-release ] || [ `cat /etc/centos-release|grep -e "CentOS Linux release 7\." -e "CentOS Linux release 8\."  |wc -l` -eq "0" ];then
	echo '必须运行在CentOS7 OR CentOS8系统环境!'
	exit
fi

SYSTEM_VERSION="centos7"
if [ `cat /etc/centos-release|grep -e "CentOS Linux release 8\."|wc -l` -gt 0 ]; then
	SYSTEM_VERSION="centos8"
fi

if [ "$CURRENT_IS_QUIET" = '0' ];then

    #设置时区
    rm -f /etc/localtime
    cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    #关闭selinux
    if [ -s /etc/selinux/config ]; then
	    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    fi


    #加载基础库
    if [ ! -f /etc/ld.so.conf.d/lnmp-utils.conf ];then
    cat >> /etc/ld.so.conf.d/lnmp-utils.conf <<EOT
/usr/local/lib
/usr/local/lib64
EOT
    ldconfig -v
    fi

    #优化网络参数
    grep "^#patch by saasjit/lnmp-utils$" /etc/sysctl.conf >/dev/null
    if [ $? != 0 ]; then

        cat >>/etc/sysctl.conf<<EOF
#patch by zeroai-utils
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 8192 4336600 873200
net.ipv4.tcp_rmem = 32768 4336600 873200
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65000
vm.zone_reclaim_mode = 1
EOF
        sysctl -p >>/dev/null 2>&1
    fi


    #优化文件描述符
    grep "^#patch by saasjit/lnmp-utils$" /etc/security/limits.conf >/dev/null
    if [ $? != 0 ]; then

        cat >>/etc/security/limits.conf<<EOF
#patch by zeroai-utils
*               soft     nproc         65536
*               hard     nproc         65536

*               soft     nofile         102400
*               hard     nofile         102400
EOF

    fi
    ulimit -n 102400

	#添加用户
	user_add www www

	#安装必须的包
	yum_install make  libtool libtool-libs autoconf automake ntp ntpdate net-snmp-devel   net-snmp net-snmp-utils psmisc net-tools iptraf ncurses-devel  iptraf wget curl patch gcc gcc-c++  kernel-devel unzip zip pigz

	#同步时间
	ntpdate cn.pool.ntp.org
	hwclock --systohc
fi