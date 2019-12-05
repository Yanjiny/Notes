# NFS实现服务器间挂载

## 1、下载安装包

```shell
yum -y install nfs rpcbind --downloadonly --downloaddir /home/temp
```

## 2、离线安装

```shell
cd /home/temp
rpm -ivh *.rpm  --force --nodeps
```

## 3、验证是否安装成功

```shell
service nfs status
service rpcbind status
```

## 4、设置挂载目录

```shell
#创建需要共享的目录
mkdir  /sharedata
#设置目录权限
chmod -R 777 /sharedata
```

## 5、修改配置

```shell
#修改/etc/exports 没有需要创建
# 格式为 dir(需要共享的目录)  ip(可以读取的目标服务器ip) rw(读写权限)
vi /etc/exports
/sharedata 10.2.40.224(rw)
```

## 6、启动nfs rpcbind服务

```shell
service rpcbind start
service nfs start
```

## 7、目标服务器开启挂载

```shell
#创建需要挂载的空目录
mkdir /sharedata
#设置权限
chmod -R 777  /sharedata
```

## 8、挂载共享目录

```shell
mount 10.2.40.223:/sharedata /sharedata
```

