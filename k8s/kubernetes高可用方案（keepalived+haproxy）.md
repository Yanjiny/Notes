<center>k8s Master高可用方案</center>



[TOC]



# 1、服务器规划列表

| ip          | 角色   | 软件                                            | 名称 |
| ----------- | ------ | ----------------------------------------------- | ---- |
| 10.2.41.111 | master | kubeadm+kubectl+kubelet+etcd+keepalived+haproxy | k8s2 |
| 10.2.41.112 | master | kubeadm+kubectl+kubelet+etcd+keepalived+haproxy | k8s1 |
| 10.2.7.114  | node   | kubeadm+kubectl+kubelet                         | k8s3 |
| 10.2.41.114 | master | kubeadm+kubectl+kubelet+etcd+keepalived+haproxy | k8s4 |
| 10.2.41.113 | vip    |                                                 |      |

# 2、**修改host文件**

```shell
cat >> /etc/hosts <<EOF
10.2.41.112 k8s1
10.2.41.111 k8s2
10.2.41.114 k8s4
10.2.7.114 k8s3
10.2.7.180 registry:5000
EOF
```

# 3、设置主机名

```shell
hostnamectl set-hostname k8s1
hostnamectl set-hostname k8s2
hostnamectl set-hostname k8s3
hostnamectl set-hostname k8s4
```

# 4、**关闭防火墙、selinux和swap**

```shell
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
```

# 5、**配置内核参数，将桥接的IPv4流量传递到iptables的链**

```shell
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

# 6、创建并分发密钥

```shell
 ssh-keygen -t rsa
```

分发公钥，用于免密登录其他服务器

```shell
for n in `seq -w 2 4`;do ssh-copy-id k8s$n;done
```

# 7、配置内核参数

k8s

```shell
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

haproxy

```shel
cat > /etc/sysctl.conf <<EOF
net.ipv4.ip_nonlocal_bind=1
EOF
sysctl -p
```

# 8、加载ipvs模块

```shell
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```

# 9、**配置国内Kubernetes源**

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

# 10、安装docker

```shell
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

```shell
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
```

```shell
yum install -y docker-ce-18.06.1.ce-3.el7
#设置开机自动启动
systemctl enable docker && systemctl start docker
```

```shell
cat > /etc/docker/daemon.json <<EOF
{
   "insecure-registries":["registry:5000"],
   "log-driver":"json-file",
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-opts": {"max-size":"100m", "max-file":"3"}
}
EOF
systemctl daemon-reload
systemctl restart docker
```

# 11、安装keepalived

安装

```shell
yum install -y keepalived haproxy
```

卸载

```shell
yum remove -y keepalived haproxy
```

# 12、配置keep

priority 100 #设置优先级 分别设置为100 90

```
/etc/keepalived/keepalived.conf
```

```shell
[root@k8s1 ~]# cat /etc/keepalived/keepalived.conf
cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    advert_int 1
    lvs_sync_daemon_inteface eth0
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.2.41.113/24
    }
}
EOF
```

# 13、**haproxy配置**

/usr/local/haproxy/haproxy.cfg

```shell
cat > /usr/local/haproxy/haproxy.cfg << EOF
global
        chroot  /var/lib/haproxy #chroot运行路径
        daemon #以后台形式运行harpoxy
        group haproxy #运行haproxy的用户所在的组
        user haproxy #运行haproxy的用户
        log 127.0.0.1:514 local0 warning  #定义haproxy 日志级别[error warringinfo debug]
        pidfile /var/lib/haproxy.pid  #haproxy 进程PID文件
        maxconn 20000  #默认最大连接数,需考虑ulimit-n限制
        spread-checks 3
        nbproc 8

defaults
        log     global
        mode    tcp #默认的模式mode { tcp|http|health }，tcp是4层，http是7层，health只会返回OK
        retries 3 #两次连接失败就认为是服务器不可用，也可以通过后面设置
        option redispatch

listen https-apiserver
        bind 10.2.41.113:8443 # keepalive 虚拟ip
        mode tcp
        balance roundrobin
        timeout server 900s
        timeout connect 15s

        server apiserver01 10.2.41.112:6443 check port 6443 inter 5000 fall 5
        server apiserver02 10.2.41.111:6443 check port 6443 inter 5000 fall 5
        server apiserver03 10.2.41.114:6443 check port 6443 inter 5000 fall 5

EOF
```

## 启动服务

```shell
systemctl enable keepalived && systemctl start keepalived 
systemctl enable haproxy && systemctl start haproxy 
```

## 查看配置

```shell
ip addr show eth0
[root@k8s1 ~]# ip addr show eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:29:5b:02 brd ff:ff:ff:ff:ff:ff
    inet 10.2.41.112/24 brd 10.2.41.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet 10.2.41.113/24 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::a69f:eec3:f1e:4b9f/64 scope link tentative noprefixroute dadfailed 
       valid_lft forever preferred_lft forever
    inet6 fe80::976c:e7d7:ea10:36d3/64 scope link tentative noprefixroute dadfailed 
       valid_lft forever preferred_lft forever
    inet6 fe80::3409:52eb:319:950d/64 scope link tentative noprefixroute dadfailed 
       valid_lft forever preferred_lft forever

tcpdump -i eth0 vrrp -n
root@k8s1 ~]# tcpdump -i eth0 vrrp -n
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
22:36:33.136242 IP 10.2.41.252 > 224.0.0.18: VRRPv2, Advertisement, vrid 41, prio 120, authtype none, intvl 1s, length 20
22:36:33.136939 IP 10.2.41.252 > 224.0.0.18: VRRPv2, Advertisement, vrid 41, prio 120, authtype none, intvl 1s, length 20
22:36:33.300812 IP 10.2.41.112 > 224.0.0.18: VRRPv2, Advertisement, vrid 51, prio 101, authtype simple, intvl 1s, length 20
22:36:34.177389 IP 10.2.41.252 > 224.0.0.18: VRRPv2, Advertisement, vrid 41, prio 120, authtype none, intvl 1s, length 20
22:36:34.178128 IP 10.2.41.252 > 224.0.0.18: VRRPv2, Advertisement, vrid 41, prio 120, authtype none, intvl 1s, length 20
22:36:34.304956 IP 10.2.41.112 > 224.0.0.18: VRRPv2, Advertisement, vrid 51, prio 101, authtype simple, intvl 1s, length 20
^C
6 packets captured
7 packets received by filter
0 packets dropped by kernel

```

## 查看状态

### keepalived

```shell
[root@k8s1 ~]# systemctl status keepalived.service 
● keepalived.service - LVS and VRRP High Availability Monitor
   Loaded: loaded (/usr/lib/systemd/system/keepalived.service; enabled; vendor preset: disabled)
   Active: active (running) since 六 2020-06-06 22:31:57 CST; 5min ago
  Process: 4548 ExecStart=/usr/sbin/keepalived $KEEPALIVED_OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 4743 (keepalived)
    Tasks: 3
   Memory: 4.4M
   CGroup: /system.slice/keepalived.service
           ├─4743 /usr/sbin/keepalived -D
           ├─4744 /usr/sbin/keepalived -D
           └─4745 /usr/sbin/keepalived -D

6月 06 22:31:59 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:31:59 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:31:59 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:31:59 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:32:04 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:32:04 k8s1 Keepalived_vrrp[4745]: VRRP_Instance(VI_1) Sending/queueing gratuitous ARPs on eth0 for 10.2.41.113
6月 06 22:32:04 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:32:04 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:32:04 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113
6月 06 22:32:04 k8s1 Keepalived_vrrp[4745]: Sending gratuitous ARP on eth0 for 10.2.41.113

```

### haproxy

```shell
[root@k8s1 ~]# systemctl status haproxy.service 
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since 六 2020-06-06 22:31:55 CST; 5min ago
 Main PID: 4545 (haproxy-systemd)
    Tasks: 10
   Memory: 5.4M
   CGroup: /system.slice/haproxy.service
           ├─4545 /usr/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid
           ├─4551 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4575 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4576 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4577 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4578 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4579 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4580 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           ├─4581 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           └─4582 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds

6月 06 22:31:55 k8s1 systemd[1]: Started HAProxy Load Balancer.
6月 06 22:31:55 k8s1 haproxy-systemd-wrapper[4545]: haproxy-systemd-wrapper: executing /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
6月 06 22:31:56 k8s1 haproxy-systemd-wrapper[4545]: [WARNING] 157/223156 (4551) : config : missing timeouts for proxy 'https-apiserver'.
6月 06 22:31:56 k8s1 haproxy-systemd-wrapper[4545]: | While not properly invalid, you will certainly encounter various problems
6月 06 22:31:56 k8s1 haproxy-systemd-wrapper[4545]: | with such a configuration. To fix this, please ensure that all following
6月 06 22:31:56 k8s1 haproxy-systemd-wrapper[4545]: | timeouts are set to a non-zero value: 'client', 'connect', 'server'.

```



# 14、安装kubeadm、kubelet、kubectl、etcd

```shell
yum install -y kubelet-1.17.0 kubeadm-1.17.0 kubectl-1.17.0 etcd
systemctl enable kubelet
```

## 修改初始化配置

初始化

```shell
kubeadm init --kubernetes-version=1.17.0 \
--control-plane-endpoint=10.2.41.113:8443 \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=192.168.0.0/16
```

> * control-plane-endpoint：集群的api访问路径。必须是vip通过haproxy进行负载均衡
> * image-repository：镜像地址
> * service-cidr：service资源的ip
> * pod-network-cidr：pod资源的ip，要与部署的网络插件一致 calico见下面

执行完输出如下表示初始化成功

```shell
[root@k8s1 home]# kubeadm init --kubernetes-version=1.17.0 \
> --apiserver-advertise-address=10.2.41.112 \
> --control-plane-endpoint=10.2.41.113:8443 \
> --apiserver-bind-port=6443 \
> --image-repository registry.aliyuncs.com/google_containers \
> --service-cidr=10.1.0.0/16 \
> --pod-network-cidr=192.168.0.0/16
W0606 21:13:13.308231   56559 validation.go:28] Cannot validate kubelet config - no validator is available
W0606 21:13:13.308356   56559 validation.go:28] Cannot validate kube-proxy config - no validator is available
[init] Using Kubernetes version: v1.17.0
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.1.0.1 10.2.41.112 10.2.41.113]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s1 localhost] and IPs [10.2.41.112 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s1 localhost] and IPs [10.2.41.112 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "admin.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
W0606 21:13:20.004926   56559 manifests.go:214] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[control-plane] Creating static Pod manifest for "kube-scheduler"
W0606 21:13:20.005955   56559 manifests.go:214] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.
[apiclient] All control plane components are healthy after 40.146018 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.17" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s1 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node k8s1 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: d59pw0.1vxgayeloqsokicd
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 10.2.41.113:8443 --token d59pw0.1vxgayeloqsokicd \
    --discovery-token-ca-cert-hash sha256:ab519a4ad6a705ac8ed2213895bc1ad6b199787ae9ea553008965b1404670902 \
    --control-plane 

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.2.41.113:8443 --token d59pw0.1vxgayeloqsokicd \
    --discovery-token-ca-cert-hash sha256:ab519a4ad6a705ac8ed2213895bc1ad6b199787ae9ea553008965b1404670902 
```

## master节点加入集群命令：

```shell
  kubeadm join 10.2.41.113:8443 --token d59pw0.1vxgayeloqsokicd \
    --discovery-token-ca-cert-hash sha256:ab519a4ad6a705ac8ed2213895bc1ad6b199787ae9ea553008965b1404670902 \
    --control-plane 
```

## node节点加入集群命令：

```shell
kubeadm join 10.2.41.113:8443 --token d59pw0.1vxgayeloqsokicd \
    --discovery-token-ca-cert-hash sha256:ab519a4ad6a705ac8ed2213895bc1ad6b199787ae9ea553008965b1404670902 
```

## master配置初始化

```shell
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

执行完此命令即可使用kebectl命令查看集群状态。

## 初始化网络插件

创建文件**calico.yml**并将以下内容复制到文件，最后上传到服务器。最后执行**kubectl apply -f calico.yml**

```shell
---
# Source: calico/templates/calico-config.yaml
# This ConfigMap is used to configure a self-hosted Calico installation.
kind: ConfigMap
apiVersion: v1
metadata:
  name: calico-config
  namespace: kube-system
data:
  # Typha is disabled.
  typha_service_name: "none"
  # Configure the backend to use.
  calico_backend: "bird"


  # Configure the MTU to use
  veth_mtu: "1440"


  # The CNI network configuration to install on each node.  The special
  # values in this config will be automatically populated.
  cni_network_config: |-
    {
      "name": "k8s-pod-network",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "calico",
          "log_level": "info",
          "datastore_type": "kubernetes",
          "nodename": "__KUBERNETES_NODE_NAME__",
          "mtu": __CNI_MTU__,
          "ipam": {
              "type": "calico-ipam"
          },
          "policy": {
              "type": "k8s"
          },
          "kubernetes": {
              "kubeconfig": "__KUBECONFIG_FILEPATH__"
          }
        },
        {
          "type": "portmap",
          "snat": true,
          "capabilities": {"portMappings": true}
        }
      ]
    }


---
# Source: calico/templates/kdd-crds.yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
   name: felixconfigurations.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: FelixConfiguration
    plural: felixconfigurations
    singular: felixconfiguration
---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ipamblocks.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: IPAMBlock
    plural: ipamblocks
    singular: ipamblock


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: blockaffinities.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: BlockAffinity
    plural: blockaffinities
    singular: blockaffinity


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ipamhandles.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: IPAMHandle
    plural: ipamhandles
    singular: ipamhandle


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ipamconfigs.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: IPAMConfig
    plural: ipamconfigs
    singular: ipamconfig


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: bgppeers.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: BGPPeer
    plural: bgppeers
    singular: bgppeer


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: bgpconfigurations.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: BGPConfiguration
    plural: bgpconfigurations
    singular: bgpconfiguration


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ippools.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: IPPool
    plural: ippools
    singular: ippool


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: hostendpoints.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: HostEndpoint
    plural: hostendpoints
    singular: hostendpoint


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: clusterinformations.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: ClusterInformation
    plural: clusterinformations
    singular: clusterinformation


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: globalnetworkpolicies.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: GlobalNetworkPolicy
    plural: globalnetworkpolicies
    singular: globalnetworkpolicy


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: globalnetworksets.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: GlobalNetworkSet
    plural: globalnetworksets
    singular: globalnetworkset


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: networkpolicies.crd.projectcalico.org
spec:
  scope: Namespaced
  group: crd.projectcalico.org
  version: v1
  names:
    kind: NetworkPolicy
    plural: networkpolicies
    singular: networkpolicy


---


apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: networksets.crd.projectcalico.org
spec:
  scope: Namespaced
  group: crd.projectcalico.org
  version: v1
  names:
    kind: NetworkSet
    plural: networksets
    singular: networkset
---
# Source: calico/templates/rbac.yaml


# Include a clusterrole for the kube-controllers component,
# and bind it to the calico-kube-controllers serviceaccount.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: calico-kube-controllers
rules:
  # Nodes are watched to monitor for deletions.
  - apiGroups: [""]
    resources:
      - nodes
    verbs:
      - watch
      - list
      - get
  # Pods are queried to check for existence.
  - apiGroups: [""]
    resources:
      - pods
    verbs:
      - get
  # IPAM resources are manipulated when nodes are deleted.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - ippools
    verbs:
      - list
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - blockaffinities
      - ipamblocks
      - ipamhandles
    verbs:
      - get
      - list
      - create
      - update
      - delete
  # Needs access to update clusterinformations.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - clusterinformations
    verbs:
      - get
      - create
      - update
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: calico-kube-controllers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: calico-kube-controllers
subjects:
- kind: ServiceAccount
  name: calico-kube-controllers
  namespace: kube-system
---
# Include a clusterrole for the calico-node DaemonSet,
# and bind it to the calico-node serviceaccount.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: calico-node
rules:
  # The CNI plugin needs to get pods, nodes, and namespaces.
  - apiGroups: [""]
    resources:
      - pods
      - nodes
      - namespaces
    verbs:
      - get
  - apiGroups: [""]
    resources:
      - endpoints
      - services
    verbs:
      # Used to discover service IPs for advertisement.
      - watch
      - list
      # Used to discover Typhas.
      - get
  - apiGroups: [""]
    resources:
      - nodes/status
    verbs:
      # Needed for clearing NodeNetworkUnavailable flag.
      - patch
      # Calico stores some configuration information in node annotations.
      - update
  # Watch for changes to Kubernetes NetworkPolicies.
  - apiGroups: ["networking.k8s.io"]
    resources:
      - networkpolicies
    verbs:
      - watch
      - list
  # Used by Calico for policy information.
  - apiGroups: [""]
    resources:
      - pods
      - namespaces
      - serviceaccounts
    verbs:
      - list
      - watch
  # The CNI plugin patches pods/status.
  - apiGroups: [""]
    resources:
      - pods/status
    verbs:
      - patch
  # Calico monitors various CRDs for config.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - globalfelixconfigs
      - felixconfigurations
      - bgppeers
      - globalbgpconfigs
      - bgpconfigurations
      - ippools
      - ipamblocks
      - globalnetworkpolicies
      - globalnetworksets
      - networkpolicies
      - networksets
      - clusterinformations
      - hostendpoints
      - blockaffinities
    verbs:
      - get
      - list
      - watch
  # Calico must create and update some CRDs on startup.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - ippools
      - felixconfigurations
      - clusterinformations
    verbs:
      - create
      - update
  # Calico stores some configuration information on the node.
  - apiGroups: [""]
    resources:
      - nodes
    verbs:
      - get
      - list
      - watch
  # These permissions are only requried for upgrade from v2.6, and can
  # be removed after upgrade or on fresh installations.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - bgpconfigurations
      - bgppeers
    verbs:
      - create
      - update
  # These permissions are required for Calico CNI to perform IPAM allocations.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - blockaffinities
      - ipamblocks
      - ipamhandles
    verbs:
      - get
      - list
      - create
      - update
      - delete
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - ipamconfigs
    verbs:
      - get
  # Block affinities must also be watchable by confd for route aggregation.
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - blockaffinities
    verbs:
      - watch
  # The Calico IPAM migration needs to get daemonsets. These permissions can be
  # removed if not upgrading from an installation using host-local IPAM.
  - apiGroups: ["apps"]
    resources:
      - daemonsets
    verbs:
      - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: calico-node
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: calico-node
subjects:
- kind: ServiceAccount
  name: calico-node
  namespace: kube-system


---
# Source: calico/templates/calico-node.yaml
# This manifest installs the calico-node container, as well
# as the CNI plugins and network config on
# each master and worker node in a Kubernetes cluster.
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: calico-node
  namespace: kube-system
  labels:
    k8s-app: calico-node
spec:
  selector:
    matchLabels:
      k8s-app: calico-node
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        k8s-app: calico-node
      annotations:
        # This, along with the CriticalAddonsOnly toleration below,
        # marks the pod as a critical add-on, ensuring it gets
        # priority scheduling and that its resources are reserved
        # if it ever gets evicted.
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      nodeSelector:
        beta.kubernetes.io/os: linux
      hostNetwork: true
      tolerations:
        # Make sure calico-node gets scheduled on all nodes.
        - effect: NoSchedule
          operator: Exists
        # Mark the pod as a critical add-on for rescheduling.
        - key: CriticalAddonsOnly
          operator: Exists
        - effect: NoExecute
          operator: Exists
      serviceAccountName: calico-node
      # Minimize downtime during a rolling upgrade or deletion; tell Kubernetes to do a "force
      # deletion": https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods.
      terminationGracePeriodSeconds: 0
      priorityClassName: system-node-critical
      initContainers:
        # This container performs upgrade from host-local IPAM to calico-ipam.
        # It can be deleted if this is a fresh installation, or if you have already
        # upgraded to use calico-ipam.
        - name: upgrade-ipam
          image: calico/cni:v3.9.3
          command: ["/opt/cni/bin/calico-ipam", "-upgrade"]
          env:
            - name: KUBERNETES_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: CALICO_NETWORKING_BACKEND
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: calico_backend
          volumeMounts:
            - mountPath: /var/lib/cni/networks
              name: host-local-net-dir
            - mountPath: /host/opt/cni/bin
              name: cni-bin-dir
        # This container installs the CNI binaries
        # and CNI network config file on each node.
        - name: install-cni
          image: calico/cni:v3.9.3
          command: ["/install-cni.sh"]
          env:
            # Name of the CNI config file to create.
            - name: CNI_CONF_NAME
              value: "10-calico.conflist"
            # The CNI network config to install on each node.
            - name: CNI_NETWORK_CONFIG
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: cni_network_config
            # Set the hostname based on the k8s node name.
            - name: KUBERNETES_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            # CNI MTU Config variable
            - name: CNI_MTU
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: veth_mtu
            # Prevents the container from sleeping forever.
            - name: SLEEP
              value: "false"
          volumeMounts:
            - mountPath: /host/opt/cni/bin
              name: cni-bin-dir
            - mountPath: /host/etc/cni/net.d
              name: cni-net-dir
        # Adds a Flex Volume Driver that creates a per-pod Unix Domain Socket to allow Dikastes
        # to communicate with Felix over the Policy Sync API.
        - name: flexvol-driver
          image: calico/pod2daemon-flexvol:v3.9.3
          volumeMounts:
          - name: flexvol-driver-host
            mountPath: /host/driver
      containers:
        # Runs calico-node container on each Kubernetes node.  This
        # container programs network policy and routes on each
        # host.
        - name: calico-node
          image: calico/node:v3.9.3
          env:
            # Use Kubernetes API as the backing datastore.
            - name: DATASTORE_TYPE
              value: "kubernetes"
            # Wait for the datastore.
            - name: WAIT_FOR_DATASTORE
              value: "true"
            # Set based on the k8s node name.
            - name: NODENAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            # Choose the backend to use.
            - name: CALICO_NETWORKING_BACKEND
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: calico_backend
            # Cluster type to identify the deployment type
            - name: CLUSTER_TYPE
              value: "k8s,bgp"
            - name: IP_AUTODETECTION_METHOD
              value: "interface=eth.*"
            # Auto-detect the BGP IP address.
            - name: IP
              value: "autodetect"
            # Enable IPIP
            - name: CALICO_IPV4POOL_IPIP
              value: "Always"
            # Set MTU for tunnel device used if ipip is enabled
            - name: FELIX_IPINIPMTU
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: veth_mtu
            # The default IPv4 pool to create on startup if none exists. Pod IPs will be
            # chosen from this range. Changing this value after installation will have
            # no effect. This should fall within `--cluster-cidr`.
            - name: CALICO_IPV4POOL_CIDR
              value: "192.168.0.0/16"
            # Disable file logging so `kubectl logs` works.
            - name: CALICO_DISABLE_FILE_LOGGING
              value: "true"
            # Set Felix endpoint to host default action to ACCEPT.
            - name: FELIX_DEFAULTENDPOINTTOHOSTACTION
              value: "ACCEPT"
            # Disable IPv6 on Kubernetes.
            - name: FELIX_IPV6SUPPORT
              value: "false"
            # Set Felix logging to "info"
            - name: FELIX_LOGSEVERITYSCREEN
              value: "info"
            - name: FELIX_HEALTHENABLED
              value: "true"
          securityContext:
            privileged: true
          resources:
            requests:
              cpu: 250m
          livenessProbe:
            exec:
              command:
              - /bin/calico-node
              - -felix-live
            periodSeconds: 10
            initialDelaySeconds: 10
            failureThreshold: 6
          readinessProbe:
            exec:
              command:
              - /bin/calico-node
              - -felix-ready
              - -bird-ready
            periodSeconds: 10
          volumeMounts:
            - mountPath: /lib/modules
              name: lib-modules
              readOnly: true
            - mountPath: /run/xtables.lock
              name: xtables-lock
              readOnly: false
            - mountPath: /var/run/calico
              name: var-run-calico
              readOnly: false
            - mountPath: /var/lib/calico
              name: var-lib-calico
              readOnly: false
            - name: policysync
              mountPath: /var/run/nodeagent
      volumes:
        # Used by calico-node.
        - name: lib-modules
          hostPath:
            path: /lib/modules
        - name: var-run-calico
          hostPath:
            path: /var/run/calico
        - name: var-lib-calico
          hostPath:
            path: /var/lib/calico
        - name: xtables-lock
          hostPath:
            path: /run/xtables.lock
            type: FileOrCreate
        # Used to install CNI.
        - name: cni-bin-dir
          hostPath:
            path: /opt/cni/bin
        - name: cni-net-dir
          hostPath:
            path: /etc/cni/net.d
        # Mount in the directory for host-local IPAM allocations. This is
        # used when upgrading from host-local to calico-ipam, and can be removed
        # if not using the upgrade-ipam init container.
        - name: host-local-net-dir
          hostPath:
            path: /var/lib/cni/networks
        # Used to create per-pod Unix Domain Sockets
        - name: policysync
          hostPath:
            type: DirectoryOrCreate
            path: /var/run/nodeagent
        # Used to install Flex Volume Driver
        - name: flexvol-driver-host
          hostPath:
            type: DirectoryOrCreate
            path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec/nodeagent~uds
---


apiVersion: v1
kind: ServiceAccount
metadata:
  name: calico-node
  namespace: kube-system


---
# Source: calico/templates/calico-kube-controllers.yaml


# See https://github.com/projectcalico/kube-controllers
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calico-kube-controllers
  namespace: kube-system
  labels:
    k8s-app: calico-kube-controllers
spec:
  # The controllers can only have a single active instance.
  replicas: 1
  selector:
    matchLabels:
      k8s-app: calico-kube-controllers
  strategy:
    type: Recreate
  template:
    metadata:
      name: calico-kube-controllers
      namespace: kube-system
      labels:
        k8s-app: calico-kube-controllers
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      nodeSelector:
        beta.kubernetes.io/os: linux
      tolerations:
        # Mark the pod as a critical add-on for rescheduling.
        - key: CriticalAddonsOnly
          operator: Exists
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      serviceAccountName: calico-kube-controllers
      priorityClassName: system-cluster-critical
      containers:
        - name: calico-kube-controllers
          image: registry:5000/calico/kube-controllers:v3.9.3
          env:
            # Choose which controllers to run.
            - name: ENABLED_CONTROLLERS
              value: node
            - name: DATASTORE_TYPE
              value: kubernetes
          readinessProbe:
            exec:
              command:
              - /usr/bin/check-status
              - -r


---


apiVersion: v1
kind: ServiceAccount
metadata:
  name: calico-kube-controllers
  namespace: kube-system
---
# Source: calico/templates/calico-etcd-secrets.yaml


---
# Source: calico/templates/calico-typha.yaml


---
# Source: calico/templates/configure-canal.yaml
```



## 证书发放

```shell
cat > /home/k8sMaster.sh << EOF
USER=root
CONTROL_PLANE_IPS="k8s2 k8s3" #master节点域名注意空格
for host in ${CONTROL_PLANE_IPS}; do
    ssh "${USER}"@$host "mkdir -p /etc/kubernetes/pki/etcd"
    scp /etc/kubernetes/pki/ca.* "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.* "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.* "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/etcd/ca.* "${USER}"@$host:/etc/kubernetes/pki/etcd/
    scp /etc/kubernetes/admin.conf "${USER}"@$host:/etc/kubernetes/
done
EOF
```

```shell
sh /home/k8sMaster.sh
```

```shell
[root@k8s1 home]# sh k8smaster 
ca.crt                                                                                                                                        100% 1025    77.5KB/s   00:00    
ca.key                                                                                                                                        100% 1675    40.0KB/s   00:00    
sa.key                                                                                                                                        100% 1679   803.5KB/s   00:00    
sa.pub                                                                                                                                        100%  451   221.3KB/s   00:00    
front-proxy-ca.crt                                                                                                                            100% 1038   123.2KB/s   00:00    
front-proxy-ca.key                                                                                                                            100% 1679    33.9KB/s   00:00    
ca.crt                                                                                                                                        100% 1017   223.5KB/s   00:00    
ca.key                                                                                                                                        100% 1675    97.0KB/s   00:00    
admin.conf                                                                                                                                    100% 5451   448.2KB/s   00:00  
```

在其他master节点执行如下命令加入集群

```shell
kubeadm join 10.2.41.113:8443 --token d59pw0.1vxgayeloqsokicd \
    --discovery-token-ca-cert-hash sha256:ab519a4ad6a705ac8ed2213895bc1ad6b199787ae9ea553008965b1404670902 \
    --control-plane 
```

在node节点执行如下命令加入集群

```shell
  kubeadm join 10.2.41.113:8443 --token d59pw0.1vxgayeloqsokicd \
    --discovery-token-ca-cert-hash sha256:ab519a4ad6a705ac8ed2213895bc1ad6b199787ae9ea553008965b1404670902
```

因为token有效很短，如果过期执行如下命令重新生成

```shell
kubeadm token create --print-join-command
```

# 15、k8s常用命令

## 查看节点状态

```shell
kubectl get nodes

[root@k8s1 ~]# kubectl get nodes
NAME   STATUS   ROLES    AGE    VERSION
k8s1   Ready    master   101m   v1.17.0
k8s2   Ready    master   97m    v1.17.0
k8s3   Ready    <none>   96m    v1.17.0
k8s4   Ready    master   40m    v1.17.0
```

## 查看namespace

```shell
kubectl get ns
[root@k8s1 ~]# kubectl get ns
NAME                STATUS   AGE
cattle-prometheus   Active   68m
cattle-system       Active   87m
default             Active   102m
kube-node-lease     Active   102m
kube-public         Active   102m
kube-system         Active   102m
```

## 查看所有pod

```shell 
kubectl get pod -A

[root@k8s1 ~]# kubectl get pod -A
NAMESPACE           NAME                                                       READY   STATUS    RESTARTS   AGE
cattle-prometheus   exporter-kube-state-cluster-monitoring-6db64f7d4b-ss8qw    1/1     Running   0          68m
cattle-prometheus   exporter-node-cluster-monitoring-bm8r4                     1/1     Running   0          68m
cattle-prometheus   exporter-node-cluster-monitoring-f9wdn                     1/1     Running   1          68m
cattle-prometheus   exporter-node-cluster-monitoring-mk7lb                     1/1     Running   0          68m
cattle-prometheus   exporter-node-cluster-monitoring-xxh87                     1/1     Running   0          41m
cattle-prometheus   grafana-cluster-monitoring-65cbc8749-cjqck                 2/2     Running   0          68m
cattle-prometheus   prometheus-cluster-monitoring-0                            5/5     Running   1          49m
cattle-prometheus   prometheus-operator-monitoring-operator-5b66559965-jkzln   1/1     Running   0          68m
cattle-system       cattle-cluster-agent-6487f9855b-bf62b                      1/1     Running   0          87m
cattle-system       cattle-node-agent-74gjj                                    1/1     Running   0          87m
cattle-system       cattle-node-agent-drfbd                                    1/1     Running   0          87m
cattle-system       cattle-node-agent-jtppg                                    1/1     Running   0          41m
cattle-system       cattle-node-agent-mfmrj                                    1/1     Running   3          87m
kube-system         calico-kube-controllers-6d5f95648d-hrg2d                   1/1     Running   0          30m
kube-system         calico-node-4tw8f                                          1/1     Running   4          100m
kube-system         calico-node-rmpjm                                          1/1     Running   0          97m
kube-system         calico-node-rrp6w                                          1/1     Running   0          98m
kube-system         calico-node-rz72v                                          1/1     Running   0          41m
kube-system         coredns-9d85f5447-jmdd5                                    1/1     Running   0          30m
kube-system         coredns-9d85f5447-nsqhl                                    1/1     Running   0          30m
kube-system         etcd-k8s1                                                  1/1     Running   4          102m
kube-system         etcd-k8s2                                                  1/1     Running   3          98m
kube-system         etcd-k8s4                                                  1/1     Running   0          38m
kube-system         kube-apiserver-k8s1                                        1/1     Running   4          102m
kube-system         kube-apiserver-k8s2                                        1/1     Running   5          98m
kube-system         kube-apiserver-k8s4                                        1/1     Running   0          38m
kube-system         kube-controller-manager-k8s1                               1/1     Running   6          102m
kube-system         kube-controller-manager-k8s2                               1/1     Running   3          98m
kube-system         kube-controller-manager-k8s4                               1/1     Running   0          38m
kube-system         kube-proxy-bppsm                                           1/1     Running   0          98m
kube-system         kube-proxy-dwqgg                                           1/1     Running   0          41m
kube-system         kube-proxy-kjsft                                           1/1     Running   0          97m
kube-system         kube-proxy-r7lm9                                           1/1     Running   4          102m
kube-system         kube-scheduler-k8s1                                        1/1     Running   6          102m
kube-system         kube-scheduler-k8s2                                        1/1     Running   1          98m
kube-system         kube-scheduler-k8s4                                        1/1     Running   1          38m
```

## 查看指定的pod状态

```shell
kubectl describe -n kube-system pod kube-scheduler-k8s4 -o wide

[root@k8s1 ~]# kubectl describe -n kube-system pod kube-scheduler-k8s4 -o wide
Error: unknown shorthand flag: 'o' in -o
See 'kubectl describe --help' for usage.
[root@k8s1 ~]# kubectl describe -n kube-system pod kube-scheduler-k8s4
Name:                 kube-scheduler-k8s4
Namespace:            kube-system
Priority:             2000000000
Priority Class Name:  system-cluster-critical
Node:                 k8s4/10.2.41.114
Start Time:           Sat, 06 Jun 2020 22:18:09 +0800
Labels:               component=kube-scheduler
                      tier=control-plane
Annotations:          kubernetes.io/config.hash: ef597d905c3006a0826f3e90c95561d5
                      kubernetes.io/config.mirror: ef597d905c3006a0826f3e90c95561d5
                      kubernetes.io/config.seen: 2020-06-06T22:17:46.604117997+08:00
                      kubernetes.io/config.source: file
Status:               Running
IP:                   10.2.41.114
IPs:
  IP:           10.2.41.114
Controlled By:  Node/k8s4
Containers:
  kube-scheduler:
    Container ID:  docker://45c742366d224ecdf4d3c33fad0dbb8e1f86c6e5efc059d2c51059e82c39a640
    Image:         registry.aliyuncs.com/google_containers/kube-scheduler:v1.17.0
    Image ID:      docker-pullable://registry.aliyuncs.com/google_containers/kube-scheduler@sha256:e35a9ec92da008d88fbcf97b5f0945ff52a912ba5c11e7ad641edb8d4668fc1a
    Port:          <none>
    Host Port:     <none>
    Command:
      kube-scheduler
      --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
      --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
      --bind-address=127.0.0.1
      --kubeconfig=/etc/kubernetes/scheduler.conf
      --leader-elect=true
    State:          Running
      Started:      Sat, 06 Jun 2020 22:32:10 +0800
    Last State:     Terminated
      Reason:       Error
      Exit Code:    255
      Started:      Sat, 06 Jun 2020 22:18:20 +0800
      Finished:     Sat, 06 Jun 2020 22:32:07 +0800
    Ready:          True
    Restart Count:  1
    Requests:
      cpu:        100m
    Liveness:     http-get https://127.0.0.1:10259/healthz delay=15s timeout=15s period=10s #success=1 #failure=8
    Environment:  <none>
    Mounts:
      /etc/kubernetes/scheduler.conf from kubeconfig (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kubeconfig:
    Type:          HostPath (bare host directory volume)
    Path:          /etc/kubernetes/scheduler.conf
    HostPathType:  FileOrCreate
QoS Class:         Burstable
Node-Selectors:    <none>
Tolerations:       :NoExecute
Events:
  Type    Reason   Age                From           Message
  ----    ------   ----               ----           -------
  Normal  Pulled   25m (x2 over 39m)  kubelet, k8s4  Container image "registry.aliyuncs.com/google_containers/kube-scheduler:v1.17.0" already present on machine
  Normal  Created  25m (x2 over 39m)  kubelet, k8s4  Created container kube-scheduler
  Normal  Started  25m (x2 over 39m)  kubelet, k8s4  Started container kube-scheduler

```

```shell
[root@k8s1 ~]# kubectl get -n kube-system pod kube-scheduler-k8s4 -o wide
NAME                  READY   STATUS    RESTARTS   AGE   IP            NODE   NOMINATED NODE   READINESS GATES
kube-scheduler-k8s4   1/1     Running   1          40m   10.2.41.114   k8s4   <none>           <none>

```

## 查看pod的yaml

```shell
[root@k8s1 ~]# kubectl get -n kube-system pod kube-scheduler-k8s4 -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubernetes.io/config.hash: ef597d905c3006a0826f3e90c95561d5
    kubernetes.io/config.mirror: ef597d905c3006a0826f3e90c95561d5
    kubernetes.io/config.seen: "2020-06-06T22:17:46.604117997+08:00"
    kubernetes.io/config.source: file
  creationTimestamp: "2020-06-06T14:18:09Z"
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler-k8s4
  namespace: kube-system
  ownerReferences:
  - apiVersion: v1
    controller: true
    kind: Node
    name: k8s4
    uid: 5b217ae2-941d-40f8-8914-c39a9ee3a5b4
  resourceVersion: "12394"
  selfLink: /api/v1/namespaces/kube-system/pods/kube-scheduler-k8s4
  uid: 56953144-fe39-4a6b-a27d-ed10d6584866
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
    image: registry.aliyuncs.com/google_containers/kube-scheduler:v1.17.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 15
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 15
    name: kube-scheduler
    resources:
      requests:
        cpu: 100m
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  hostNetwork: true
  nodeName: k8s4
  priority: 2000000000
  priorityClassName: system-cluster-critical
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    operator: Exists
  volumes:
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2020-06-06T14:18:09Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2020-06-06T14:32:11Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2020-06-06T14:32:11Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2020-06-06T14:18:09Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://45c742366d224ecdf4d3c33fad0dbb8e1f86c6e5efc059d2c51059e82c39a640
    image: registry.aliyuncs.com/google_containers/kube-scheduler:v1.17.0
    imageID: docker-pullable://registry.aliyuncs.com/google_containers/kube-scheduler@sha256:e35a9ec92da008d88fbcf97b5f0945ff52a912ba5c11e7ad641edb8d4668fc1a
    lastState:
      terminated:
        containerID: docker://2f2dbef1307145a86f792d3fac710bf89cd244f5b24e199e9b6bcc5d209c7309
        exitCode: 255
        finishedAt: "2020-06-06T14:32:07Z"
        reason: Error
        startedAt: "2020-06-06T14:18:20Z"
    name: kube-scheduler
    ready: true
    restartCount: 1
    started: true
    state:
      running:
        startedAt: "2020-06-06T14:32:10Z"
  hostIP: 10.2.41.114
  phase: Running
  podIP: 10.2.41.114
  podIPs:
  - ip: 10.2.41.114
  qosClass: Burstable
  startTime: "2020-06-06T14:18:09Z"
```

## node打标签

```shell
kubectl label nodes <node-name> <label-key>
kubectl label nodes k8s key=value
```

## 删除标签

```shell
kubectl label nodes  k8s key=value-
```

## 设置master可调度

```shell
kubectl taint node <node-name> node-role.kubernetes.io/master-
```





