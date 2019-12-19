# 安装记录

https://blog.csdn.net/fy_long/article/details/88829070

https://www.kubernetes.org.cn/5462.html

## 1、设置主机名

```shell
hostnamectl set-hostname k8s1
hostnamectl set-hostname k8s2
hostnamectl set-hostname k8s3
```

## 2、修改host文件 

```shell
cat >> /etc/hosts <<EOF
192.168.233.129  k8s1
192.168.233.130  k8s2
192.168.233.131  k8s3
EOF
```

## 3、关闭防火墙、selinux和swap

```shell
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
```

## 4、配置内核参数，将桥接的IPv4流量传递到iptables的链

```shell
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

## 5、配置国内yum源

```shell
yum install -y wget
mkdir /etc/yum.repos.d/bak && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
yum clean all && yum makecache
```

## 6、配置国内Kubernetes源

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

## 7、配置 docker 源

```shell
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
```

## 8、安装docker

```shell
yum install -y docker-ce-18.06.1.ce-3.el7
#设置开机自动启动
systemctl enable docker && systemctl start docker
```

## 9、安装kubeadm、kubelet、kubectl

```shell
yum install -y kubelet kubeadm kubectl etcd
systemctl enable kubelet
```

## 10、部署master 节点

```shell
kubeadm init --kubernetes-version=1.15.2 \
--apiserver-advertise-address=192.168.233.129 \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=192.168.0.0/16

--apiserver-advertise-address 为master节点ip
--image-repository 指定为阿里镜像地址目录 例如registry:5000
--pod-network-cidr 指定创建的pod的ip段，如果网络使用calico要与calico配置一致
```

报错

```shell
[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1


cat > /etc/default/kubelet << EOF
Environment=
KUBELET_EXTRA_ARGS=--cgroup-driver=systemd
EOF
systemctl restart docker
```



```shell
##执行后输出，在node节点执行可以加入到集群
kubeadm join 192.168.233.129:6443 --token is7akj.0a91xymeqmijka65 \
    --discovery-token-ca-cert-hash sha256:abe6f4a45a31ca4747686f27c0fbc3849750787ea79de09f70a9ea84b0db800d

```

## 11、配置kubectl工具

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
##查看节点状态
kubectl get nodes
kubectl get cs
```

## 12、部署flannel网络

```shell
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
```

calico

```yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
```

## 13、部署Dashboard

```shell
#在master节点上进行如下操作
wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
##不支持科学上网，所以需要修改kubernetes-dashboard.yaml中的镜像地址，在阿里云或则dockerhub找到对应的镜像
## 比如：registry.cn-hangzhou.aliyuncs.com/lusifeng/kubernetes-dashboard-amd64:v1.10.1

```

![1565365805081](C:\Users\yanjiny\AppData\Roaming\Typora\typora-user-images\1565365805081.png)

此外，需要在Dashboard Service内容加入nodePort： 30001和type: NodePort两项内容，将Dashboard访问端口映射为节点端口，以供外部访问

![1565365905753](C:\Users\yanjiny\AppData\Roaming\Typora\typora-user-images\1565365905753.png)

```yml
# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ------------------- Dashboard Secret ------------------- #

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kube-system
type: Opaque

---
# ------------------- Dashboard Service Account ------------------- #

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Role & Role Binding ------------------- #

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
rules:
  # Allow Dashboard to create 'kubernetes-dashboard-key-holder' secret.
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create"]
  # Allow Dashboard to create 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create"]
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
  verbs: ["get", "update", "delete"]
  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["kubernetes-dashboard-settings"]
  verbs: ["get", "update"]
  # Allow Dashboard to get metrics from heapster.
- apiGroups: [""]
  resources: ["services"]
  resourceNames: ["heapster"]
  verbs: ["proxy"]
- apiGroups: [""]
  resources: ["services/proxy"]
  resourceNames: ["heapster", "http:heapster:", "https:heapster:"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard-minimal
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Deployment ------------------- #

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
      - name: kubernetes-dashboard
        image: registry.cn-hangzhou.aliyuncs.com/lusifeng/kubernetes-dashboard-amd64:v1.10.1
        ports:
        - containerPort: 8443
          protocol: TCP
        args:
          - --auto-generate-certificates
          # Uncomment the following line to manually specify Kubernetes API server Host
          # If not specified, Dashboard will attempt to auto discover the API server and connect
          # to it. Uncomment only if the default does not work.
          # - --apiserver-host=http://my-address:port
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
          # Create on-disk volume to store exec logs
        - mountPath: /tmp
          name: tmp-volume
        livenessProbe:
          httpGet:
            scheme: HTTPS
            path: /
            port: 8443
          initialDelaySeconds: 30
          timeoutSeconds: 30
      volumes:
      - name: kubernetes-dashboard-certs
        secret:
          secretName: kubernetes-dashboard-certs
      - name: tmp-volume
        emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule

---
# ------------------- Dashboard Service ------------------- #

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort：30001
  type: NodePort
  selector:
    k8s-app: kubernetes-dashboard

```



开始部署 

```shell
kubectl create -f kubernetes-dashboard.yaml
```

检查运行状态

```shell
kubectl get deployment kubernetes-dashboard -n kube-system
kubectl get pods -n kube-system -o wide
kubectl get services -n kube-system
netstat -ntlp|grep 30001
```

查看访问Dashboard的认证令牌

```shell
kubectl create serviceaccount  dashboard-admin -n kube-system

kubectl create clusterrolebinding  dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
```

![1565366076416](C:\Users\yanjiny\AppData\Roaming\Typora\typora-user-images\1565366076416.png)

使用火狐登陆

![1565366139362](C:\Users\yanjiny\AppData\Roaming\Typora\typora-user-images\1565366139362.png)

## 14、

```shell
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/grafana.yaml
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml

#修改镜像地址


```

## 15、部署仪表盘

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
```





## 14、常用命令

```shell
#查看pod状态
kubectl get pod -n kube-system
[root@k8s1 home]# kubectl get pod -n kube-system
NAME                                   READY   STATUS              RESTARTS   AGE
coredns-5c98db65d4-ldxvx               1/1     Running             2          6h47m
coredns-5c98db65d4-lvcb5               1/1     Running             2          6h47m
etcd-k8s1                              1/1     Running             5          6h47m
heapster-598cfcfd59-dbrd5              0/1     RunContainerError   0          55m
kube-apiserver-k8s1                    1/1     Running             5          6h47m
kube-controller-manager-k8s1           1/1     Running             47         6h47m
kube-flannel-ds-amd64-2lxxm            1/1     Running             1          134m
kube-flannel-ds-amd64-cc76p            1/1     Running             1          134m
kube-flannel-ds-amd64-fdhzg            1/1     Running             2          175m
kube-proxy-4rm74                       1/1     Running             5          6h47m
kube-proxy-6r96t                       1/1     Running             2          134m
kube-proxy-n7bgz                       1/1     Running             1          134m
kube-scheduler-k8s1                    1/1     Running             40         6h46m
monitoring-grafana-68b7968bd4-tnkh2    1/1     Running             0          55m
monitoring-influxdb-68b6989bb9-zdthd   1/1     Running             0          55m


#查看节点日志
kubectl -n kube-system describe pod <name>
```

