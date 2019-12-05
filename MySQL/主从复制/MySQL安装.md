### 下载离线包

```shell
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz
```

### 安装前检查是否已经安装其他版本mysql需要先卸载

```shell
rpm -qa | grep mysql
##若有结果需要卸载
rpm -e 程序名　　// 普通删除模式
rpm -e --nodeps 程序名　　// 强力删除模式，如果使用上面命令删除时，提示有依赖的其它文件，则用该命令可以对其进行强力删除
```

### 复制到安装目录

```shell
mv ./mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz /usr/local
```

### 解压

```shell
tar -xvf mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz
```

### 重命名

```shell
mv /usr/local/mysql-5.7.22-linux-glibc2.12-x86_64 /usr/local/mysql
```

### 新建data目录

```shell
mkdir /usr/local/mysql/data
```

### 新建mysql用户、mysql用户组

```shell
# mysql用户组
groupadd mysql
# mysql用户
useradd mysql -g mysql
```

### 将mysql的所有者及所属组改为mysql

```shell
chown -R mysql.mysql /usr/local/mysql
```

### 配置

```shell
/usr/local/mysql/bin/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data
```

### 编辑/etc/my.cnf 设置临时密码

```shell
cd /etc
cp my.cnf my.cnf.back
cat > ./my.cnf << EOF
[mysqld]
datadir=/usr/local/mysql/data
basedir=/usr/local/mysql
socket=/tmp/mysql.sock
user=mysql
port=3306
character-set-server=utf8
## 同一局域网内注意要唯一
server-id=210  
## 开启二进制日志功能，可以随便取（关键）
log-bin=mysql-bin
# 取消密码验证
skip-grant-tables
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# skip-grant-tables
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
!includedir /etc/my.cnf.d
EOF
```

### 开启服务

- 将mysql加入服务

```shell
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
```

- 开机自启

```shell
chkconfig mysql on
```

- 开启

```shell
service mysql start
```

### 设置密码

登录（由于/etc/my.cnf中设置了取消密码验证，所以此处密码任意）

```shell
/usr/local/mysql/bin/mysql -u root -p
# 操作mysql数据库
>>use mysql;
# 修改密码
>>update user set authentication_string=password('123456') where user='root';
>>flush privileges;
>>exit;
```

将/etc/my.cnf中的skip-grant-tables删除

```shell
cat > /etc/my.cnf << EOF
[mysqld]
datadir=/usr/local/mysql/data
basedir=/usr/local/mysql
socket=/tmp/mysql.sock
user=mysql
port=3306
character-set-server=utf8
## 同一局域网内注意要唯一
server-id=210  
## 开启二进制日志功能，可以随便取（关键）
log-bin=mysql-bin
# 取消密码验证
#skip-grant-tables
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# skip-grant-tables
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
!includedir /etc/my.cnf.d
EOF
```

登录再次设置密码

```shell
/usr/local/mysql/bin/mysql -u root -p
 >>ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
 >>exit;
```

允许远程连接

```shell
/usr/local/mysql/bin/mysql -u root -p

>>use mysql;

>>update user set host='%' where user = 'root';

>>flush privileges;

>>exit;
```

添加快捷方式

```shell
ln -s /usr/local/mysql/bin/mysql /usr/bin
```



### 重构为主从配置

主节点修改

```shell
cat > /etc/my.cnf << EOF
[mysqld]
datadir=/usr/local/mysql/data
basedir=/usr/local/mysql
socket=/tmp/mysql.sock
user=mysql
port=3306
character-set-server=utf8
## 同一局域网内注意要唯一
server-id=210  
## 开启二进制日志功能，可以随便取（关键）
log-bin=mysql-bin
# 取消密码验证
#skip-grant-tables
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# skip-grant-tables
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
!includedir /etc/my.cnf.d
EOF
```

创建slave用户

```shell
/usr/local/mysql/bin/mysql -u root -p
>>use mysql;

>>CREATE USER 'slave'@'%' IDENTIFIED BY '123456';

>>GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'slave'@'%';

>>exit;
service mysql restart
```

从节点修改

```shell
cat > /etc/my.cnf << EOF
[mysqld]
datadir=/usr/local/mysql/data
basedir=/usr/local/mysql
socket=/tmp/mysql.sock
user=mysql
port=3306
character-set-server=utf8
## 同一局域网内注意要唯一
server-id=220 
## 开启二进制日志功能，以备Slave作为其它Slave的Master时使用
log-bin=mysql-slave-bin
## relay_log配置中继日志
relay_log=edu-mysql-relay-bin
# 取消密码验证
#skip-grant-tables
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# skip-grant-tables
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
!includedir /etc/my.cnf.d
EOF
service mysql restart
```

主节点查询

```shell
/usr/local/mysql/bin/mysql -u root -p
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000001 |      154 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
mysql>

```

slave节点执行

```shell
change master to master_host='10.2.40.220', master_user='slave', master_password='123456', master_port=3306, master_log_file='mysql-bin.000001', master_log_pos= 154, master_connect_retry=30;
```

```shell
show slave status \G;
mysql> show slave status \G;
*************************** 1. row ***************************
               Slave_IO_State:
                  Master_Host: 10.2.40.210
                  Master_User: slave
                  Master_Port: 3306
                Connect_Retry: 30
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 154
               Relay_Log_File: edu-mysql-relay-bin.000001
                Relay_Log_Pos: 4
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: No
            Slave_SQL_Running: No
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 154
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 0
                  Master_UUID:
             Master_Info_File: /usr/local/mysql/data/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State:
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)

ERROR:
No query specified


```

启动主从复制

```shell
mysql> start slave;
Query OK, 0 rows affected (0.00 sec)

mysql> show slave status \G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.2.40.210
                  Master_User: slave
                  Master_Port: 3306
                Connect_Retry: 30
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 154
               Relay_Log_File: edu-mysql-relay-bin.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 531
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 210
                  Master_UUID: 9b103a91-c99f-11e9-91d9-00155d0d710a
             Master_Info_File: /usr/local/mysql/data/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)

ERROR:
No query specified


```

