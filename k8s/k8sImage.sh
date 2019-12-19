docker tag prom/prometheus:latest   registry:5000/prom/prometheus:latest;
docker tag prom/node-exporter:v0.16.0  registry:5000/prom/node-exporter:v0.16.0;
docker tag calico/node:v3.9.3  registry:5000/calico/node:v3.9.3;
docker tag calico/pod2daemon-flexvol:v3.9.3 registry:5000/calico/pod2daemon-flexvol:v3.9.3;
docker tag calico/cni:v3.9.3 registry:5000/calico/cni:v3.9.3;
docker tag calico/kube-controllers:v3.9.3 registry:5000/calico/kube-controllers:v3.9.3;
docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.15.3 registry:5000/google_containers/kube-proxy:v1.15.3;
docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.15.3 registry:5000/google_containers/kube-apiserver:v1.15.3;
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.15.3 registry:5000/google_containers/kube-controller-manager:v1.15.3;
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.15.3 registry:5000/google_containers/kube-scheduler:v1.15.3;
docker tag registry.aliyuncs.com/google_containers/coredns:1.3.1 registry:5000/google_containers/coredns:1.3.1;
docker tag registry.aliyuncs.com/google_containers/etcd:3.3.10 registry:5000/google_containers/etcd:3.3.10;
docker tag registry.aliyuncs.com/google_containers/pause:3.1  registry:5000/google_containers/pause:3.1;



docker push registry:5000/prom/prometheus:latest;
docker push registry:5000/prom/node-exporter:v0.16.0;
docker push registry:5000/calico/node:v3.9.3;
docker push registry:5000/calico/pod2daemon-flexvol:v3.9.3;
docker push registry:5000/calico/cni:v3.9.3;
docker push registry:5000/calico/kube-controllers:v3.9.3;
docker push registry:5000/google_containers/kube-proxy:v1.15.3;
docker push registry:5000/google_containers/kube-apiserver:v1.15.3;
docker push registry:5000/google_containers/kube-controller-manager:v1.15.3;
docker push registry:5000/google_containers/kube-scheduler:v1.15.3;
docker push registry:5000/google_containers/coredns:1.3.1;
docker push registry:5000/google_containers/etcd:3.3.10;
docker push registry:5000/google_containers/pause:3.1;


mkdir -pv /home/k8s/images/registry-5000/prom/
mkdir -pv /home/k8s/images/registry-5000/calico
mkdir -pv /home/k8s/images/registry-5000/google_containers/


docker save registry:5000/prom/prometheus:latest                               >    /home/k8s/images/registry-5000/prom/prometheus-latest.tar;
docker save registry:5000/prom/node-exporter:v0.16.0                           >    /home/k8s/images/registry-5000/prom/node-exporter-v0.16.0.tar;
docker save registry:5000/calico/node:v3.9.3                                   >    /home/k8s/images/registry-5000/calico/node-v3.9.3.tar;
docker save registry:5000/calico/pod2daemon-flexvol:v3.9.3                     >    /home/k8s/images/registry-5000/calico/pod2daemon-flexvol-v3.9.3.tar;
docker save registry:5000/calico/cni:v3.9.3                                    >    /home/k8s/images/registry-5000/calico/cni-v3.9.3.tar;
docker save registry:5000/calico/kube-controllers:v3.9.3                       >    /home/k8s/images/registry-5000/calico/kube-controllers-v3.9.3.tar;
docker save registry:5000/google_containers/kube-proxy:v1.15.3                 >    /home/k8s/images/registry-5000/google_containers/kube-proxy-v1.15.3.tar;
docker save registry:5000/google_containers/kube-apiserver:v1.15.3             >    /home/k8s/images/registry-5000/google_containers/kube-apiserver-v1.15.3.tar;
docker save registry:5000/google_containers/kube-controller-manager:v1.15.3    >    /home/k8s/images/registry-5000/google_containers/kube-controller-manager-v1.15.3.tar;
docker save registry:5000/google_containers/kube-scheduler:v1.15.3             >    /home/k8s/images/registry-5000/google_containers/kube-scheduler-v1.15.3.tar;
docker save registry:5000/google_containers/coredns:1.3.1                      >    /home/k8s/images/registry-5000/google_containers/coredns-1.3.1.tar;
docker save registry:5000/google_containers/etcd:3.3.10                        >    /home/k8s/images/registry-5000/google_containers/etcd-3.3.10.tar;
docker save registry:5000/google_containers/pause:3.1                          >    /home/k8s/images/registry-5000/google_containers/pause-3.1.tar;


docker rmi registry:5000/prom/prometheus:latest
docker rmi registry:5000/prom/node-exporter:v0.16.0
docker rmi registry:5000/calico/node:v3.9.3
docker rmi registry:5000/calico/pod2daemon-flexvol:v3.9.3
docker rmi registry:5000/calico/cni:v3.9.3
docker rmi registry:5000/calico/kube-controllers:v3.9.3
docker rmi registry:5000/google_containers/kube-proxy:v1.15.3
docker rmi registry:5000/google_containers/kube-apiserver:v1.15.3
docker rmi registry:5000/google_containers/kube-controller-manager:v1.15.3
docker rmi registry:5000/google_containers/kube-scheduler:v1.15.3
docker rmi registry:5000/google_containers/coredns:1.3.1
docker rmi registry:5000/google_containers/etcd:3.3.10
docker rmi registry:5000/google_containers/pause:3.1



docker load -i /home/k8s/images/registry-5000/prom/prometheus-latest.tar;
docker load -i /home/k8s/images/registry-5000/prom/node-exporter-v0.16.0.tar;
docker load -i /home/k8s/images/registry-5000/calico/node-v3.9.3.tar;
docker load -i /home/k8s/images/registry-5000/calico/pod2daemon-flexvol-v3.9.3.tar;
docker load -i /home/k8s/images/registry-5000/calico/cni-v3.9.3.tar;
docker load -i /home/k8s/images/registry-5000/calico/kube-controllers-v3.9.3.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/kube-proxy-v1.15.3.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/kube-apiserver-v1.15.3.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/kube-controller-manager-v1.15.3.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/kube-scheduler-v1.15.3.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/coredns-1.3.1.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/etcd-3.3.10.tar;
docker load -i /home/k8s/images/registry-5000/google_containers/pause-3.1.tar;