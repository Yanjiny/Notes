[参考连接](https://blog.csdn.net/javaloveiphone/article/details/74276506)

1、删除历史记录

```shell
service mysql stop
find / -name mysql
```

将查询结果进行删除

```shell
rm -rf  ***
```

2、上传安装包

3、复制到安装目录

```shell
mv ./mysql-5.6.47-linux-glibc2.12-x86_64.tar.gz /usr/local
```

4、解压

```shell
cd /usr/local
tar -zxvf mysql-5.6.47-linux-glibc2.12-x86_64.tar.gz
```

5、重命名

```shell
mv /usr/local/mysql-5.6.47-linux-glibc2.12-x86_64 /usr/local/mysql
```

6、新建data目录

```shell
mkdir /usr/local/mysql/data
```

7、新建mysql用户、mysql用户组

```shell
# mysql用户组
groupadd mysql
# mysql用户
useradd mysql -g mysql
```

8、将mysql的所有者及所属组改为mysql

```shell
chown -R mysql.mysql /usr/local/mysql
```

9、安装

```shell
/usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data
```

```shell
Installing MySQL system tables...2020-01-15 21:44:20 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2020-01-15 21:44:20 0 [Note] Ignoring --secure-file-priv value as server is running with --bootstrap.
2020-01-15 21:44:20 0 [Note] /usr/local/mysql//bin/mysqld (mysqld 5.6.47-log) starting as process 168865 ...
2020-01-15 21:44:20 168865 [Note] InnoDB: Using atomics to ref count buffer pool pages
2020-01-15 21:44:20 168865 [Note] InnoDB: The InnoDB memory heap is disabled
2020-01-15 21:44:20 168865 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2020-01-15 21:44:20 168865 [Note] InnoDB: Memory barrier is not used
2020-01-15 21:44:20 168865 [Note] InnoDB: Compressed tables use zlib 1.2.11
2020-01-15 21:44:20 168865 [Note] InnoDB: Using Linux native AIO
2020-01-15 21:44:20 168865 [Note] InnoDB: Using CPU crc32 instructions
2020-01-15 21:44:20 168865 [Note] InnoDB: Initializing buffer pool, size = 128.0M
2020-01-15 21:44:20 168865 [Note] InnoDB: Completed initialization of buffer pool
2020-01-15 21:44:20 168865 [Note] InnoDB: The first specified data file ./ibdata1 did not exist: a new database to be created!
2020-01-15 21:44:20 168865 [Note] InnoDB: Setting file ./ibdata1 size to 12 MB
2020-01-15 21:44:20 168865 [Note] InnoDB: Database physically writes the file full: wait...
2020-01-15 21:44:20 168865 [Note] InnoDB: Setting log file ./ib_logfile101 size to 48 MB
2020-01-15 21:44:20 168865 [Note] InnoDB: Setting log file ./ib_logfile1 size to 48 MB
2020-01-15 21:44:21 168865 [Note] InnoDB: Renaming log file ./ib_logfile101 to ./ib_logfile0
2020-01-15 21:44:21 168865 [Warning] InnoDB: New log files created, LSN=45781
2020-01-15 21:44:21 168865 [Note] InnoDB: Doublewrite buffer not found: creating new
2020-01-15 21:44:21 168865 [Note] InnoDB: Doublewrite buffer created
2020-01-15 21:44:21 168865 [Note] InnoDB: 128 rollback segment(s) are active.
2020-01-15 21:44:21 168865 [Warning] InnoDB: Creating foreign key constraint system tables.
2020-01-15 21:44:21 168865 [Note] InnoDB: Foreign key constraint system tables created
2020-01-15 21:44:21 168865 [Note] InnoDB: Creating tablespace and datafile system tables.
2020-01-15 21:44:21 168865 [Note] InnoDB: Tablespace and datafile system tables created.
2020-01-15 21:44:21 168865 [Note] InnoDB: Waiting for purge to start
2020-01-15 21:44:21 168865 [Note] InnoDB: 5.6.47 started; log sequence number 0
2020-01-15 21:44:21 168865 [Note] RSA private key file not found: /data//private_key.pem. Some authentication plugins will not work.
2020-01-15 21:44:21 168865 [Note] RSA public key file not found: /data//public_key.pem. Some authentication plugins will not work.
2020-01-15 21:44:29 168865 [Note] Binlog end
2020-01-15 21:44:29 168865 [Note] InnoDB: FTS optimize thread exiting.
2020-01-15 21:44:29 168865 [Note] InnoDB: Starting shutdown...
2020-01-15 21:44:31 168865 [Note] InnoDB: Shutdown completed; log sequence number 1625977
OK

Filling help tables...2020-01-15 21:44:31 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2020-01-15 21:44:31 0 [Note] Ignoring --secure-file-priv value as server is running with --bootstrap.
2020-01-15 21:44:31 0 [Note] /usr/local/mysql//bin/mysqld (mysqld 5.6.47-log) starting as process 168896 ...
2020-01-15 21:44:31 168896 [Note] InnoDB: Using atomics to ref count buffer pool pages
2020-01-15 21:44:31 168896 [Note] InnoDB: The InnoDB memory heap is disabled
2020-01-15 21:44:31 168896 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2020-01-15 21:44:31 168896 [Note] InnoDB: Memory barrier is not used
2020-01-15 21:44:31 168896 [Note] InnoDB: Compressed tables use zlib 1.2.11
2020-01-15 21:44:31 168896 [Note] InnoDB: Using Linux native AIO
2020-01-15 21:44:31 168896 [Note] InnoDB: Using CPU crc32 instructions
2020-01-15 21:44:31 168896 [Note] InnoDB: Initializing buffer pool, size = 128.0M
2020-01-15 21:44:31 168896 [Note] InnoDB: Completed initialization of buffer pool
2020-01-15 21:44:31 168896 [Note] InnoDB: Highest supported file format is Barracuda.
2020-01-15 21:44:31 168896 [Note] InnoDB: 128 rollback segment(s) are active.
2020-01-15 21:44:31 168896 [Note] InnoDB: Waiting for purge to start
2020-01-15 21:44:31 168896 [Note] InnoDB: 5.6.47 started; log sequence number 1625977
2020-01-15 21:44:31 168896 [Note] RSA private key file not found: /data//private_key.pem. Some authentication plugins will not work.
2020-01-15 21:44:31 168896 [Note] RSA public key file not found: /data//public_key.pem. Some authentication plugins will not work.
2020-01-15 21:44:32 168896 [Note] Binlog end
2020-01-15 21:44:32 168896 [Note] InnoDB: FTS optimize thread exiting.
2020-01-15 21:44:32 168896 [Note] InnoDB: Starting shutdown...
2020-01-15 21:44:33 168896 [Note] InnoDB: Shutdown completed; log sequence number 1625987
OK

To start mysqld at boot time you have to copy
support-files/mysql.server to the right place for your system

PLEASE REMEMBER TO SET A PASSWORD FOR THE MySQL root USER !
To do so, start the server, then issue the following commands:

  /usr/local/mysql//bin/mysqladmin -u root password 'new-password'
  /usr/local/mysql//bin/mysqladmin -u root -h bogon password 'new-password'

Alternatively you can run:

  /usr/local/mysql//bin/mysql_secure_installation

which will also give you the option of removing the test
databases and anonymous user created by default.  This is
strongly recommended for production servers.

See the manual for more instructions.

You can start the MySQL daemon with:

  cd . ; /usr/local/mysql//bin/mysqld_safe &

You can test the MySQL daemon with mysql-test-run.pl

  cd mysql-test ; perl mysql-test-run.pl

Please report any problems at http://bugs.mysql.com/

The latest information about MySQL is available on the web at

  http://www.mysql.com

Support MySQL by buying support/licenses at http://shop.mysql.com

New default config file was created as /usr/local/mysql//my.cnf and
will be used by default by the server when you start it.
You may edit this file to change server settings

WARNING: Default config file /etc/my.cnf exists on the system
This file will be read by default by the MySQL server
If you do not want to use this, either remove it, or use the
--defaults-file argument to mysqld_safe when starting the server
```

10、添加环境变量

```shell
vi /etc/profile
export PATH=$PATH:/usr/local/mysql/bin

source /etc/profile
```

11、设置my.cnf

```shell
vi /etc/my.cnf
[mysqld]
datadir=/data
basedir=/usr/local/mysql
socket=/tmp/mysql.sock
user=mysql
port=3306
## 同一局域网内注意要唯一
server-id=210
# 取消密码验证
skip-grant-tables
# skip-grant-tables
#取消大小写检验
lower_case_table_names=1
#设置服务器允许接收的单行最大限制
max_allowed_packet=100M
#设置连接池空闲超时时间
wait_timeout=31536000
interactive_timeout=31536000
max_allowed_packet=1G
innodb_log_file_size=1G
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
!includedir /etc/my.cnf.d
```

12、启用mysql

```shell
将mysql加入服务
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
开机启动
chkconfig mysql on
启动
service mysql start
```

13、设置密码

```shell
[root@bogon local]# /usr/local/mysql/bin/mysql -u root -p
# 操作mysql数据库
mysql> use mysql;
# 修改密码
mysql> UPDATE user SET Password=PASSWORD('password') where USER='root';
mysql> flush privileges;
mysql> exit;
```

执行结果

```shell
[root@bogon local]# /usr/local/mysql/bin/mysql -u root -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 185
Server version: 5.6.47-log MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use mysql;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> update user set authentication_string=password('P@ssw0rdNP') where user='root';
Query OK, 4 rows affected (0.00 sec)
Rows matched: 4  Changed: 4  Warnings: 0

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

mysql> exit;
Bye
```

14、开启远程连接

```shell
/usr/local/mysql/bin/mysql -u root -p
UPDATE user SET `Host` = '%' WHERE `User` = 'root' LIMIT 1;
flush privileges;
exit;
```

