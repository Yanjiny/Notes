# redis集群安装（三主三从）

## 参考资料

```shell
https://www.cnblogs.com/xuliangxing/p/7146868.html
```

* redis version 5.0.5
* gem 4.1.2
* rubyy 4.6.3

## 1、下载redis安装包

```shell
http://download.redis.io/releases/
```

## 2、下载gem包

```shell
https://rubygems.org/gems/redis/versions/4.1.2
```

## 3、检查安装redis集群需要的环境是否满足

```shell
yum install -y gcc-c++ && yum install -y ruby && yum install -y rubygems
```

* 安装日志如下

```shell
[root@localhost home]# yum install gcc-c++ && yum install ruby && yum install rubygems
已加载插件：fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * base: mirrors.tuna.tsinghua.edu.cn
 * extras: mirrors.tuna.tsinghua.edu.cn
 * updates: mirrors.huaweicloud.com
base                                                                                                                                                                                 | 3.6 kB  00:00:00
docker-ce-stable                                                                                                                                                                     | 3.5 kB  00:00:00
extras                                                                                                                                                                               | 3.4 kB  00:00:00
updates                                                                                                                                                                              | 3.4 kB  00:00:00
正在解决依赖关系
--> 正在检查事务
---> 软件包 gcc-c++.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 gcc-c++.x86_64.0.4.8.5-36.el7_6.2 将被 更新
--> 正在处理依赖关系 libstdc++-devel = 4.8.5-36.el7_6.2，它被软件包 gcc-c++-4.8.5-36.el7_6.2.x86_64 需要
--> 正在处理依赖关系 libstdc++ = 4.8.5-36.el7_6.2，它被软件包 gcc-c++-4.8.5-36.el7_6.2.x86_64 需要
--> 正在处理依赖关系 gcc = 4.8.5-36.el7_6.2，它被软件包 gcc-c++-4.8.5-36.el7_6.2.x86_64 需要
--> 正在检查事务
---> 软件包 gcc.x86_64.0.4.8.5-36.el7 将被 升级
--> 正在处理依赖关系 gcc = 4.8.5-36.el7，它被软件包 gcc-gfortran-4.8.5-36.el7.x86_64 需要
--> 正在处理依赖关系 gcc = 4.8.5-36.el7，它被软件包 libquadmath-devel-4.8.5-36.el7.x86_64 需要
---> 软件包 gcc.x86_64.0.4.8.5-36.el7_6.2 将被 更新
--> 正在处理依赖关系 libgomp = 4.8.5-36.el7_6.2，它被软件包 gcc-4.8.5-36.el7_6.2.x86_64 需要
--> 正在处理依赖关系 cpp = 4.8.5-36.el7_6.2，它被软件包 gcc-4.8.5-36.el7_6.2.x86_64 需要
--> 正在处理依赖关系 libgcc >= 4.8.5-36.el7_6.2，它被软件包 gcc-4.8.5-36.el7_6.2.x86_64 需要
---> 软件包 libstdc++.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libstdc++.x86_64.0.4.8.5-36.el7_6.2 将被 更新
---> 软件包 libstdc++-devel.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libstdc++-devel.x86_64.0.4.8.5-36.el7_6.2 将被 更新
--> 正在检查事务
---> 软件包 cpp.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 cpp.x86_64.0.4.8.5-36.el7_6.2 将被 更新
---> 软件包 gcc-gfortran.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 gcc-gfortran.x86_64.0.4.8.5-36.el7_6.2 将被 更新
--> 正在处理依赖关系 libquadmath = 4.8.5-36.el7_6.2，它被软件包 gcc-gfortran-4.8.5-36.el7_6.2.x86_64 需要
--> 正在处理依赖关系 libgfortran = 4.8.5-36.el7_6.2，它被软件包 gcc-gfortran-4.8.5-36.el7_6.2.x86_64 需要
---> 软件包 libgcc.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libgcc.x86_64.0.4.8.5-36.el7_6.2 将被 更新
---> 软件包 libgomp.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libgomp.x86_64.0.4.8.5-36.el7_6.2 将被 更新
---> 软件包 libquadmath-devel.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libquadmath-devel.x86_64.0.4.8.5-36.el7_6.2 将被 更新
--> 正在检查事务
---> 软件包 libgfortran.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libgfortran.x86_64.0.4.8.5-36.el7_6.2 将被 更新
---> 软件包 libquadmath.x86_64.0.4.8.5-36.el7 将被 升级
---> 软件包 libquadmath.x86_64.0.4.8.5-36.el7_6.2 将被 更新
--> 解决依赖关系完成

依赖关系解决

============================================================================================================================================================================================================
 Package                                               架构                                       版本                                                    源                                           大小
============================================================================================================================================================================================================
正在更新:
 gcc-c++                                               x86_64                                     4.8.5-36.el7_6.2                                        updates                                     7.2 M
为依赖而更新:
 cpp                                                   x86_64                                     4.8.5-36.el7_6.2                                        updates                                     5.9 M
 gcc                                                   x86_64                                     4.8.5-36.el7_6.2                                        updates                                      16 M
 gcc-gfortran                                          x86_64                                     4.8.5-36.el7_6.2                                        updates                                     6.7 M
 libgcc                                                x86_64                                     4.8.5-36.el7_6.2                                        updates                                     102 k
 libgfortran                                           x86_64                                     4.8.5-36.el7_6.2                                        updates                                     300 k
 libgomp                                               x86_64                                     4.8.5-36.el7_6.2                                        updates                                     158 k
 libquadmath                                           x86_64                                     4.8.5-36.el7_6.2                                        updates                                     189 k
 libquadmath-devel                                     x86_64                                     4.8.5-36.el7_6.2                                        updates                                      53 k
 libstdc++                                             x86_64                                     4.8.5-36.el7_6.2                                        updates                                     305 k
 libstdc++-devel                                       x86_64                                     4.8.5-36.el7_6.2                                        updates                                     1.5 M

事务概要
============================================================================================================================================================================================================
升级  1 软件包 (+10 依赖软件包)

总计：39 M
Is this ok [y/d/N]: y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  正在更新    : libquadmath-4.8.5-36.el7_6.2.x86_64                                                                                                                                                    1/22
  正在更新    : libgcc-4.8.5-36.el7_6.2.x86_64                                                                                                                                                         2/22
  正在更新    : libstdc++-4.8.5-36.el7_6.2.x86_64                                                                                                                                                      3/22
  正在更新    : libstdc++-devel-4.8.5-36.el7_6.2.x86_64                                                                                                                                                4/22
  正在更新    : libgfortran-4.8.5-36.el7_6.2.x86_64                                                                                                                                                    5/22
  正在更新    : cpp-4.8.5-36.el7_6.2.x86_64                                                                                                                                                            6/22
  正在更新    : libgomp-4.8.5-36.el7_6.2.x86_64                                                                                                                                                        7/22
  正在更新    : gcc-4.8.5-36.el7_6.2.x86_64                                                                                                                                                            8/22
  正在更新    : libquadmath-devel-4.8.5-36.el7_6.2.x86_64                                                                                                                                              9/22
  正在更新    : gcc-gfortran-4.8.5-36.el7_6.2.x86_64                                                                                                                                                  10/22
  正在更新    : gcc-c++-4.8.5-36.el7_6.2.x86_64                                                                                                                                                       11/22
  清理        : gcc-gfortran-4.8.5-36.el7.x86_64                                                                                                                                                      12/22
  清理        : gcc-c++-4.8.5-36.el7.x86_64                                                                                                                                                           13/22
  清理        : libquadmath-devel-4.8.5-36.el7.x86_64                                                                                                                                                 14/22
  清理        : gcc-4.8.5-36.el7.x86_64                                                                                                                                                               15/22
  清理        : libgfortran-4.8.5-36.el7.x86_64                                                                                                                                                       16/22
  清理        : libstdc++-devel-4.8.5-36.el7.x86_64                                                                                                                                                   17/22
  清理        : libstdc++-4.8.5-36.el7.x86_64                                                                                                                                                         18/22
  清理        : libgcc-4.8.5-36.el7.x86_64                                                                                                                                                            19/22
  清理        : libquadmath-4.8.5-36.el7.x86_64                                                                                                                                                       20/22
  清理        : cpp-4.8.5-36.el7.x86_64                                                                                                                                                               21/22
  清理        : libgomp-4.8.5-36.el7.x86_64                                                                                                                                                           22/22
  验证中      : libgfortran-4.8.5-36.el7_6.2.x86_64                                                                                                                                                    1/22
  验证中      : gcc-4.8.5-36.el7_6.2.x86_64                                                                                                                                                            2/22
  验证中      : libstdc++-4.8.5-36.el7_6.2.x86_64                                                                                                                                                      3/22
  验证中      : libgcc-4.8.5-36.el7_6.2.x86_64                                                                                                                                                         4/22
  验证中      : libgomp-4.8.5-36.el7_6.2.x86_64                                                                                                                                                        5/22
  验证中      : libstdc++-devel-4.8.5-36.el7_6.2.x86_64                                                                                                                                                6/22
  验证中      : gcc-c++-4.8.5-36.el7_6.2.x86_64                                                                                                                                                        7/22
  验证中      : gcc-gfortran-4.8.5-36.el7_6.2.x86_64                                                                                                                                                   8/22
  验证中      : libquadmath-devel-4.8.5-36.el7_6.2.x86_64                                                                                                                                              9/22
  验证中      : libquadmath-4.8.5-36.el7_6.2.x86_64                                                                                                                                                   10/22
  验证中      : cpp-4.8.5-36.el7_6.2.x86_64                                                                                                                                                           11/22
  验证中      : libgcc-4.8.5-36.el7.x86_64                                                                                                                                                            12/22
  验证中      : libstdc++-4.8.5-36.el7.x86_64                                                                                                                                                         13/22
  验证中      : gcc-4.8.5-36.el7.x86_64                                                                                                                                                               14/22
  验证中      : gcc-gfortran-4.8.5-36.el7.x86_64                                                                                                                                                      15/22
  验证中      : gcc-c++-4.8.5-36.el7.x86_64                                                                                                                                                           16/22
  验证中      : libstdc++-devel-4.8.5-36.el7.x86_64                                                                                                                                                   17/22
  验证中      : cpp-4.8.5-36.el7.x86_64                                                                                                                                                               18/22
  验证中      : libgomp-4.8.5-36.el7.x86_64                                                                                                                                                           19/22
  验证中      : libquadmath-4.8.5-36.el7.x86_64                                                                                                                                                       20/22
  验证中      : libquadmath-devel-4.8.5-36.el7.x86_64                                                                                                                                                 21/22
  验证中      : libgfortran-4.8.5-36.el7.x86_64                                                                                                                                                       22/22

更新完毕:
  gcc-c++.x86_64 0:4.8.5-36.el7_6.2

作为依赖被升级:
  cpp.x86_64 0:4.8.5-36.el7_6.2      gcc.x86_64 0:4.8.5-36.el7_6.2          gcc-gfortran.x86_64 0:4.8.5-36.el7_6.2       libgcc.x86_64 0:4.8.5-36.el7_6.2     libgfortran.x86_64 0:4.8.5-36.el7_6.2
  libgomp.x86_64 0:4.8.5-36.el7_6.2  libquadmath.x86_64 0:4.8.5-36.el7_6.2  libquadmath-devel.x86_64 0:4.8.5-36.el7_6.2  libstdc++.x86_64 0:4.8.5-36.el7_6.2  libstdc++-devel.x86_64 0:4.8.5-36.el7_6.2

完毕！
已加载插件：fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * base: mirrors.tuna.tsinghua.edu.cn
 * extras: mirrors.tuna.tsinghua.edu.cn
 * updates: mirrors.huaweicloud.com
正在解决依赖关系
--> 正在检查事务
---> 软件包 ruby.x86_64.0.2.0.0.648-33.el7_4 将被 升级
---> 软件包 ruby.x86_64.0.2.0.0.648-35.el7_6 将被 更新
--> 正在处理依赖关系 ruby-libs(x86-64) = 2.0.0.648-35.el7_6，它被软件包 ruby-2.0.0.648-35.el7_6.x86_64 需要
--> 正在检查事务
---> 软件包 ruby-libs.x86_64.0.2.0.0.648-33.el7_4 将被 升级
---> 软件包 ruby-libs.x86_64.0.2.0.0.648-35.el7_6 将被 更新
--> 解决依赖关系完成

依赖关系解决

============================================================================================================================================================================================================
 Package                                         架构                                         版本                                                      源                                             大小
============================================================================================================================================================================================================
正在更新:
 ruby                                            x86_64                                       2.0.0.648-35.el7_6                                        updates                                        72 k
为依赖而更新:
 ruby-libs                                       x86_64                                       2.0.0.648-35.el7_6                                        updates                                       2.8 M

事务概要
============================================================================================================================================================================================================
升级  1 软件包 (+1 依赖软件包)

总计：2.9 M
Is this ok [y/d/N]: y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  正在更新    : ruby-libs-2.0.0.648-35.el7_6.x86_64                                                                                                                                                     1/4
  正在更新    : ruby-2.0.0.648-35.el7_6.x86_64                                                                                                                                                          2/4
  清理        : ruby-2.0.0.648-33.el7_4.x86_64                                                                                                                                                          3/4
  清理        : ruby-libs-2.0.0.648-33.el7_4.x86_64                                                                                                                                                     4/4
  验证中      : ruby-libs-2.0.0.648-35.el7_6.x86_64                                                                                                                                                     1/4
  验证中      : ruby-2.0.0.648-35.el7_6.x86_64                                                                                                                                                          2/4
  验证中      : ruby-2.0.0.648-33.el7_4.x86_64                                                                                                                                                          3/4
  验证中      : ruby-libs-2.0.0.648-33.el7_4.x86_64                                                                                                                                                     4/4

更新完毕:
  ruby.x86_64 0:2.0.0.648-35.el7_6

作为依赖被升级:
  ruby-libs.x86_64 0:2.0.0.648-35.el7_6

完毕！
已加载插件：fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * base: mirrors.tuna.tsinghua.edu.cn
 * extras: mirrors.tuna.tsinghua.edu.cn
 * updates: mirrors.huaweicloud.com
正在解决依赖关系
--> 正在检查事务
---> 软件包 rubygems.noarch.0.2.0.14.1-33.el7_4 将被 升级
---> 软件包 rubygems.noarch.0.2.0.14.1-35.el7_6 将被 更新
--> 解决依赖关系完成

依赖关系解决

============================================================================================================================================================================================================
 Package                                        架构                                         版本                                                       源                                             大小
============================================================================================================================================================================================================
正在更新:
 rubygems                                       noarch                                       2.0.14.1-35.el7_6                                          updates                                       220 k

事务概要
============================================================================================================================================================================================================
升级  1 软件包

总计：220 k
Is this ok [y/d/N]: y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  正在更新    : rubygems-2.0.14.1-35.el7_6.noarch                                                                                                                                                       1/2
  清理        : rubygems-2.0.14.1-33.el7_4.noarch                                                                                                                                                       2/2
  验证中      : rubygems-2.0.14.1-35.el7_6.noarch                                                                                                                                                       1/2
  验证中      : rubygems-2.0.14.1-33.el7_4.noarch                                                                                                                                                       2/2

更新完毕:
  rubygems.noarch 0:2.0.14.1-35.el7_6

完毕！
[root@localhost home]#

```



## 4、升级rubby

```shell
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB 

curl -sSL https://get.rvm.io | bash -s stable

find / -name rvm -print

source /usr/local/rvm/scripts/rvm

rvm list known
##选择一个版本安装
rvm install 2.6.3
##使用一个ruby版本
rvm use 2.6.3
##设置默认版本
rvm use 2.6.3 --default
##查看ruby版本
ruby --version
##安装redis：
gem install redis-4.1.2.gem

```

* 操作日志如下

```shell
[root@localhost home]# gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
gpg: 已创建目录‘/root/.gnupg’
gpg: 新的配置文件‘/root/.gnupg/gpg.conf’已建立
gpg: 警告：在‘/root/.gnupg/gpg.conf’里的选项于此次运行期间未被使用
gpg: 钥匙环‘/root/.gnupg/secring.gpg’已建立
gpg: 钥匙环‘/root/.gnupg/pubring.gpg’已建立
gpg: 下载密钥‘D39DC0E3’，从 hkp 服务器 keys.gnupg.net
gpg: 下载密钥‘39499BDB’，从 hkp 服务器 keys.gnupg.net
gpg: /root/.gnupg/trustdb.gpg：建立了信任度数据库
gpg: 密钥 D39DC0E3：公钥“Michal Papis (RVM signing) <mpapis@gmail.com>”已导入
gpg: 密钥 39499BDB：公钥“Piotr Kuczynski <piotr.kuczynski@gmail.com>”已导入
gpg: 没有找到任何绝对信任的密钥
gpg: 合计被处理的数量：2
gpg:           已导入：2  (RSA: 2)
[root@localhost home]# curl -sSL https://get.rvm.io | bash -s stable
Downloading https://github.com/rvm/rvm/archive/1.29.9.tar.gz
Downloading https://github.com/rvm/rvm/releases/download/1.29.9/1.29.9.tar.gz.asc
gpg: 于 2019年07月10日 星期三 16时31分02秒 CST 创建的签名，使用 RSA，钥匙号 39499BDB
gpg: 完好的签名，来自于“Piotr Kuczynski <piotr.kuczynski@gmail.com>”
gpg: 警告：这把密钥未经受信任的签名认证！
gpg:       没有证据表明这个签名属于它所声称的持有者。
主钥指纹： 7D2B AF1C F37B 13E2 069D  6956 105B D0E7 3949 9BDB
GPG verified '/usr/local/rvm/archives/rvm-1.29.9.tgz'
Creating group 'rvm'
Installing RVM to /usr/local/rvm/
Installation of RVM in /usr/local/rvm/ is almost complete:

  * First you need to add all users that will be using rvm to 'rvm' group,
    and logout - login again, anyone using rvm will be operating with `umask u=rwx,g=rwx,o=rx`.

  * To start using RVM you need to run `source /etc/profile.d/rvm.sh`
    in all your open shell windows, in rare cases you need to reopen all shell windows.
  * Please do NOT forget to add your users to the rvm group.
     The installer no longer auto-adds root or users to the rvm group. Admins must do this.
     Also, please note that group memberships are ONLY evaluated at login time.
     This means that users must log out then back in before group membership takes effect!
Thanks for installing RVM 🙏
Please consider donating to our open collective to help us maintain RVM.

👉  Donate: https://opencollective.com/rvm/donate


[root@localhost home]# find / -name rvm -print
/usr/local/rvm
/usr/local/rvm/src/rvm
/usr/local/rvm/src/rvm/bin/rvm
/usr/local/rvm/src/rvm/lib/rvm
/usr/local/rvm/src/rvm/scripts/rvm
/usr/local/rvm/bin/rvm
/usr/local/rvm/lib/rvm
/usr/local/rvm/scripts/rvm
[root@localhost home]# source /usr/local/rvm/scripts/rvm
[root@localhost home]# rvm list known
# MRI Rubies
[ruby-]1.8.6[-p420]
[ruby-]1.8.7[-head] # security released on head
[ruby-]1.9.1[-p431]
[ruby-]1.9.2[-p330]
[ruby-]1.9.3[-p551]
[ruby-]2.0.0[-p648]
[ruby-]2.1[.10]
[ruby-]2.2[.10]
[ruby-]2.3[.8]
[ruby-]2.4[.6]
[ruby-]2.5[.5]
[ruby-]2.6[.3]
[ruby-]2.7[.0-preview1]
ruby-head

# for forks use: rvm install ruby-head-<name> --url https://github.com/github/ruby.git --branch 2.2

# JRuby
jruby-1.6[.8]
jruby-1.7[.27]
jruby-9.1[.17.0]
jruby[-9.2.7.0]
jruby-head

# Rubinius
rbx-1[.4.3]
rbx-2.3[.0]
rbx-2.4[.1]
rbx-2[.5.8]
rbx-3[.107]
rbx-4[.3]
rbx-head

# TruffleRuby
truffleruby[-19.1.0]

# Opal
opal

# Minimalistic ruby implementation - ISO 30170:2012
mruby-1.0.0
mruby-1.1.0
mruby-1.2.0
mruby-1.3.0
mruby-1[.4.1]
mruby-2[.0.1]
mruby[-head]

# Ruby Enterprise Edition
ree-1.8.6
ree[-1.8.7][-2012.02]

# Topaz
topaz

# MagLev
maglev-1.0.0
maglev-1.1[RC1]
maglev[-1.2Alpha4]
maglev-head

# Mac OS X Snow Leopard Or Newer
macruby-0.10
macruby-0.11
macruby[-0.12]
macruby-nightly
macruby-head

# IronRuby
ironruby[-1.1.3]
ironruby-head
[root@localhost home]# rvm install 2.6.3
Searching for binary rubies, this might take some time.
No binary rubies available for: centos/7/x86_64/ruby-2.6.3.
Continuing with compilation. Please read 'rvm help mount' to get more information on binary rubies.
Checking requirements for centos.
Installing requirements for centos.
Installing required packages: libffi-devel, readline-devel, sqlite-devel, zlib-devel, openssl-devel................
Requirements installation successful.
Installing Ruby from source to: /usr/local/rvm/rubies/ruby-2.6.3, this may take a while depending on your cpu(s)...
ruby-2.6.3 - #downloading ruby-2.6.3, this may take a while depending on your connection...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 13.8M  100 13.8M    0     0  60871      0  0:03:58  0:03:58 --:--:-- 38180
ruby-2.6.3 - #extracting ruby-2.6.3 to /usr/local/rvm/src/ruby-2.6.3.....
ruby-2.6.3 - #configuring......................................................................
ruby-2.6.3 - #post-configuration..
ruby-2.6.3 - #compiling..............................................................................................
ruby-2.6.3 - #installing................................
ruby-2.6.3 - #making binaries executable..
ruby-2.6.3 - #downloading rubygems-3.0.6
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  866k  100  866k    0     0   267k      0  0:00:03  0:00:03 --:--:--  267k
No checksum for downloaded archive, recording checksum in user configuration.
ruby-2.6.3 - #extracting rubygems-3.0.6.....
ruby-2.6.3 - #removing old rubygems........
ruby-2.6.3 - #installing rubygems-3.0.6...............................................
ruby-2.6.3 - #gemset created /usr/local/rvm/gems/ruby-2.6.3@global
ruby-2.6.3 - #importing gemset /usr/local/rvm/gemsets/global.gems................................................................
ruby-2.6.3 - #generating global wrappers.......
ruby-2.6.3 - #gemset created /usr/local/rvm/gems/ruby-2.6.3
ruby-2.6.3 - #importing gemsetfile /usr/local/rvm/gemsets/default.gems evaluated to empty gem list
ruby-2.6.3 - #generating default wrappers.......
ruby-2.6.3 - #adjusting #shebangs for (gem irb erb ri rdoc testrb rake).
Install of ruby-2.6.3 - #complete
Ruby was built without documentation, to build it run: rvm docs generate-ri
[root@localhost home]# rvm use 2.6.3
Using /usr/local/rvm/gems/ruby-2.6.3
[root@localhost home]# rvm use 2.6.3 --default
Using /usr/local/rvm/gems/ruby-2.6.3
[root@localhost home]# ruby --version
ruby 2.6.3p62 (2019-04-16 revision 67580) [x86_64-linux]
```

### 离线安装

```shell
###################################离线安装方法#####################
https://www.cnblogs.com/xuliangxing/p/7132656.html?utm_source=itdadao&utm_medium=referral
###################################离线安装方法#####################
http://www.ruby-lang.org/en/documentation/installation/#yum
```



## 5、redis安装

解压redis安装包，本教程目录为 /home/RedisCluster

```shell
tar -zxvf redis-5.0.5.tar.gz
```

修改名字为redis

```shell
mv redis-5.0.5 redis 
```

进入redis目录进行编译安装

```shell
cd redis
make && make install
```

若输出如下日志表示安装成功

```shell
Hint: It's a good idea to run 'make test' ;)

make[1]: 离开目录“/home/RedisCluster/redis/src”
cd src && make install
make[1]: 进入目录“/home/RedisCluster/redis/src”
    CC Makefile.dep
make[1]: 离开目录“/home/RedisCluster/redis/src”
make[1]: 进入目录“/home/RedisCluster/redis/src”

Hint: It's a good idea to run 'make test' ;)

    INSTALL install
    INSTALL install
    INSTALL install
    INSTALL install
    INSTALL install
make[1]: 离开目录“/home/RedisCluster/redis/src”

```



## 6、校验redis是否安装成功

修改redis.conf文件

```shell 
vi redis.conf
bind 127.0.0.1  >> bind 0.0.0.0
```

启动redis

```shell 
[root@localhost redis]# redis-server ./redis.conf
24107:C 30 Aug 2019 23:28:23.133 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
24107:C 30 Aug 2019 23:28:23.133 # Redis version=5.0.5, bits=64, commit=00000000, modified=0, pid=24107, just started
24107:C 30 Aug 2019 23:28:23.133 # Configuration loaded
24107:M 30 Aug 2019 23:28:23.133 * Increased maximum number of open files to 10032 (it was originally set to 1024).
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 5.0.5 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 24107
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

24107:M 30 Aug 2019 23:28:23.136 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
24107:M 30 Aug 2019 23:28:23.136 # Server initialized
24107:M 30 Aug 2019 23:28:23.136 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
24107:M 30 Aug 2019 23:28:23.136 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
24107:M 30 Aug 2019 23:28:23.136 * Ready to accept connections


```

打开新窗口输入 redis-cli 

```shell
[root@localhost ~]# redis-cli
127.0.0.1:6379> keys *
(empty list or set)
127.0.0.1:6379>
```

# 开始部署集群（三主三从）

## 1、创建集群目录

redis启动信息都记录在redis.conf，所以部署集群，我们只需要修改redis.conf分别准备六份。

在`/home/RedisCluster`目录下创建六个目录

```shell
mkdir redis9001 && mkdir redis9002 && mkdir redis9003 && mkdir redis9004 && mkdir redis9005 && mkdir redis9006
```

将安装目录下`/usr/local/bin`的redis-cli、redis-server文件拷贝至上一步创建的六个目录下

```shell
cd /usr/local/bin
\cp -rf  redis-cli redis-server /home/RedisCluster/redis9001 
\cp -rf  redis-cli redis-server /home/RedisCluster/redis9002 
\cp -rf  redis-cli redis-server /home/RedisCluster/redis9003 
\cp -rf  redis-cli redis-server /home/RedisCluster/redis9004  
\cp -rf  redis-cli redis-server /home/RedisCluster/redis9005 
\cp -rf  redis-cli redis-server /home/RedisCluster/redis9006
```

## 2、为每个目录新增redis.conf

分别执行以下命令为每个目录新增redis.conf文件

```shell
############################命令1#######################################
cat > /home/RedisCluster/redis9001/redis.conf << EOF
# 对应各自的端口号
port 9001
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file nodes.conf
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/RedisCluster/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
EOF
############################命令2#######################################
cat > /home/RedisCluster/redis9002/redis.conf << EOF
# 对应各自的端口号
port 9002 
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file nodes.conf
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/RedisCluster/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
EOF
############################命令3#######################################
cat > /home/RedisCluster/redis9003/redis.conf << EOF
# 对应各自的端口号
port 9003
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file nodes.conf
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/RedisCluster/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
EOF
############################命令4#######################################
cat > /home/RedisCluster/redis9004/redis.conf << EOF  
# 对应各自的端口号
port 9004 
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file nodes.conf
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/RedisCluster/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
EOF
############################命令5#######################################
cat > /home/RedisCluster/redis9005/redis.conf << EOF 
# 对应各自的端口号
port 9005 
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file nodes.conf
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/RedisCluster/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
EOF
############################命令6#######################################
cat > /home/RedisCluster/redis9006/redis.conf << EOF
# 对应各自的端口号
port 9006 
# 后端启动
appendonly no
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file nodes.conf
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/RedisCluster/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
EOF
```

## 4、新增日志存放目录

```shell 
cd /home/RedisCluster
mkdir logs
```



## 3、编写集群启动文件

```shell
cat > /home/RedisCluster/startAll.sh << EOF
cd /home/RedisCluster/redis9001 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9002 &&  ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9003 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9004 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9005 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9006 && ./redis-server redis.conf
kill -2
cd ..
EOF

```

## 4、启动redis

```shell 
sh /home/RedisCluster/startAll.sh
```

* 执行结果如下

```shell
[root@localhost RedisCluster]# sh startAll.sh
kill: 用法:kill [-s 信号声明 | -n 信号编号 | -信号声明] 进程号 | 任务声明 ... 或 kill -l [信号声明]
kill: 用法:kill [-s 信号声明 | -n 信号编号 | -信号声明] 进程号 | 任务声明 ... 或 kill -l [信号声明]
kill: 用法:kill [-s 信号声明 | -n 信号编号 | -信号声明] 进程号 | 任务声明 ... 或 kill -l [信号声明]
kill: 用法:kill [-s 信号声明 | -n 信号编号 | -信号声明] 进程号 | 任务声明 ... 或 kill -l [信号声明]
kill: 用法:kill [-s 信号声明 | -n 信号编号 | -信号声明] 进程号 | 任务声明 ... 或 kill -l [信号声明]
kill: 用法:kill [-s 信号声明 | -n 信号编号 | -信号声明] 进程号 | 任务声明 ... 或 kill -l [信号声明]
[root@localhost RedisCluster]#

```

## 5、查看redis是否启动

执行`netstat -tnulp | grep redis`和`ps  aux | grep redis`查看集群端口号

```shell
[root@localhost RedisCluster]# netstat -tnulp | grep redis
tcp        0      0 0.0.0.0:9001            0.0.0.0:*               LISTEN      35698/./redis-serve
tcp        0      0 0.0.0.0:9002            0.0.0.0:*               LISTEN      35700/./redis-serve
tcp        0      0 0.0.0.0:9003            0.0.0.0:*               LISTEN      35705/./redis-serve
tcp        0      0 0.0.0.0:9004            0.0.0.0:*               LISTEN      35710/./redis-serve
tcp        0      0 0.0.0.0:9005            0.0.0.0:*               LISTEN      35718/./redis-serve
tcp        0      0 0.0.0.0:9006            0.0.0.0:*               LISTEN      35723/./redis-serve
tcp        0      0 0.0.0.0:19001           0.0.0.0:*               LISTEN      35698/./redis-serve
tcp        0      0 0.0.0.0:19002           0.0.0.0:*               LISTEN      35700/./redis-serve
tcp        0      0 0.0.0.0:19003           0.0.0.0:*               LISTEN      35705/./redis-serve
tcp        0      0 0.0.0.0:19004           0.0.0.0:*               LISTEN      35710/./redis-serve
tcp        0      0 0.0.0.0:19005           0.0.0.0:*               LISTEN      35718/./redis-serve
tcp        0      0 0.0.0.0:19006           0.0.0.0:*               LISTEN      35723/./redis-serve
[root@localhost RedisCluster]# ps  aux | grep redis
root      35698  0.0  0.0 160032 11800 ?        Ssl  23:47   0:00 ./redis-server 0.0.0.0:9001 [cluster]
root      35700  0.0  0.0 160032 11800 ?        Ssl  23:47   0:00 ./redis-server 0.0.0.0:9002 [cluster]
root      35705  0.0  0.0 160032 11800 ?        Ssl  23:47   0:00 ./redis-server 0.0.0.0:9003 [cluster]
root      35710  0.0  0.0 160032 11800 ?        Ssl  23:47   0:00 ./redis-server 0.0.0.0:9004 [cluster]
root      35718  0.0  0.0 160032 11800 ?        Ssl  23:47   0:00 ./redis-server 0.0.0.0:9005 [cluster]
root      35723  0.0  0.0 160032 11800 ?        Ssl  23:47   0:00 ./redis-server 0.0.0.0:9006 [cluster]
root      36753  0.0  0.0 112724   988 pts/1    S+   23:48   0:00 grep --color=auto redis
[root@localhost RedisCluster]#

```

## 6、启动集群

执行以下命令启动集群

```shell
redis-cli --cluster  create --cluster-replicas 1  127.0.0.1:9001  127.0.0.1:9002  127.0.0.1:9003  127.0.0.1:9004  127.0.0.1:9005  127.0.0.1:9006
```

`--cluster-replicas 1` 表示我们希望为集群中的每个主节点创建一个从节点

* 启动日志如下

```shell
[root@localhost RedisCluster]# redis-cli --cluster  create --cluster-replicas 1  127.0.0.1:9001  127.0.0.1:9002  127.0.0.1:9003  127.0.0.1:9004  127.0.0.1:9005  127.0.0.1:9006
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 127.0.0.1:9005 to 127.0.0.1:9001
Adding replica 127.0.0.1:9006 to 127.0.0.1:9002
Adding replica 127.0.0.1:9004 to 127.0.0.1:9003
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: 2cc55de2f2308bf9344e92b42309f9a399cf4872 127.0.0.1:9001
   slots:[0-5460] (5461 slots) master
M: 7f592333e648d7d65c1c335fb555d55697ca7027 127.0.0.1:9002
   slots:[5461-10922] (5462 slots) master
M: 3a167a0a3d422f5e98d66bc0168a774fe07d0343 127.0.0.1:9003
   slots:[10923-16383] (5461 slots) master
S: 3b11839dd2791e6b0fd587d3b2ceff37f8ce142f 127.0.0.1:9004
   replicates 3a167a0a3d422f5e98d66bc0168a774fe07d0343
S: 983dab615b2ce2df9d8d29fee70e2ad7f134f5f5 127.0.0.1:9005
   replicates 2cc55de2f2308bf9344e92b42309f9a399cf4872
S: ac02e4af4358826f9600d9d4092d5031c8a81911 127.0.0.1:9006
   replicates 7f592333e648d7d65c1c335fb555d55697ca7027
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
....
>>> Performing Cluster Check (using node 127.0.0.1:9001)
M: 2cc55de2f2308bf9344e92b42309f9a399cf4872 127.0.0.1:9001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 983dab615b2ce2df9d8d29fee70e2ad7f134f5f5 127.0.0.1:9005
   slots: (0 slots) slave
   replicates 2cc55de2f2308bf9344e92b42309f9a399cf4872
M: 7f592333e648d7d65c1c335fb555d55697ca7027 127.0.0.1:9002
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: 3a167a0a3d422f5e98d66bc0168a774fe07d0343 127.0.0.1:9003
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 3b11839dd2791e6b0fd587d3b2ceff37f8ce142f 127.0.0.1:9004
   slots: (0 slots) slave
   replicates 3a167a0a3d422f5e98d66bc0168a774fe07d0343
S: ac02e4af4358826f9600d9d4092d5031c8a81911 127.0.0.1:9006
   slots: (0 slots) slave
   replicates 7f592333e648d7d65c1c335fb555d55697ca7027
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
[root@localhost RedisCluster]#

```

## 7、设置集群密码

进入各个Redis集群中的实时配置,这种方式可以将配置写入redis.conf并且不需要重启集群服务，所有节点密码必须一致

```shell
redis-cli -c -p 9001 
config set masterauth P@ssw0rd 
config set requirepass P@ssw0rd 
auth P@ssw0rd
config rewrite 

redis-cli -c -p 9002 
config set masterauth P@ssw0rd 
config set requirepass P@ssw0rd 
auth P@ssw0rd
config rewrite 

redis-cli -c -p 9003 
config set masterauth P@ssw0rd 
config set requirepass P@ssw0rd 
auth P@ssw0rd
config rewrite 

redis-cli -c -p 9004 
config set masterauth P@ssw0rd 
config set requirepass P@ssw0rd 
auth P@ssw0rd
config rewrite 

redis-cli -c -p 9005 
config set masterauth P@ssw0rd 
config set requirepass P@ssw0rd 
auth P@ssw0rd
config rewrite 

redis-cli -c -p 9006 
config set masterauth P@ssw0rd 
config set requirepass P@ssw0rd 
auth P@ssw0rd
config rewrite 
```

若提示`(error) NOAUTH Authentication required.`执行auth 123456，输入密码即可

```shell
# 对应各自的端口号
port 9001
# 启用守护线程
appendonly yes
# 启用集群
cluster-enabled yes
# 后端启动
daemonize yes
# 关联集群配置文件
cluster-config-file "nodes.conf"
#设置超时
cluster-node-timeout 5000
#日志信息
logfile "/home/redis/logs/redis.log"
# 指定访问的IP地址，设置为0.0.0.0表示允许所有IP访问
bind 0.0.0.0
# Generated by CONFIG REWRITE
dir "/home/redis9001"
masterauth "123456"
requirepass "123456"
```

## 8 、查看集群信息

```shell
[root@localhost RedisCluster]# redis-cli -c -p 9001 -a 123456 cluster nodes
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
983dab615b2ce2df9d8d29fee70e2ad7f134f5f5 127.0.0.1:9005@19005 slave 2cc55de2f2308bf9344e92b42309f9a399cf4872 0 1567181831784 5 connected
7f592333e648d7d65c1c335fb555d55697ca7027 127.0.0.1:9002@19002 master - 0 1567181831000 2 connected 5461-10922
3a167a0a3d422f5e98d66bc0168a774fe07d0343 127.0.0.1:9003@19003 master - 0 1567181830000 3 connected 10923-16383
3b11839dd2791e6b0fd587d3b2ceff37f8ce142f 127.0.0.1:9004@19004 slave 3a167a0a3d422f5e98d66bc0168a774fe07d0343 0 1567181831000 4 connected
ac02e4af4358826f9600d9d4092d5031c8a81911 127.0.0.1:9006@19006 slave 7f592333e648d7d65c1c335fb555d55697ca7027 0 1567181830584 6 connected
2cc55de2f2308bf9344e92b42309f9a399cf4872 127.0.0.1:9001@19001 myself,master - 0 1567181831000 1 connected 0-5460
[root@localhost RedisCluster]#

```

## 9、redis集群常用命令

查看集群端口号

```shell
netstat -tnulp | grep redis
ps  aux | grep redis
```

停止集群

```shell
cat > /home/RedisCluster/stopAll.sh << EOF
redis-cli -h 127.0.0.1 -p 9001 -a 123456 shutdown &&\
redis-cli -h 127.0.0.1 -p 9002 -a 123456 shutdown &&\
redis-cli -h 127.0.0.1 -p 9003 -a 123456 shutdown &&\
redis-cli -h 127.0.0.1 -p 9004 -a 123456 shutdown &&\
redis-cli -h 127.0.0.1 -p 9005 -a 123456 shutdown &&\
redis-cli -h 127.0.0.1 -p 9006 -a 123456 shutdown
EOF
```

启动集群

```shell
cat > /home/RedisCluster/startAll.sh << EOF
cd /home/RedisCluster/redis9001 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9002 &&  ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9003 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9004 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9005 && ./redis-server redis.conf
kill -2
cd ..
cd /home/RedisCluster/redis9006 && ./redis-server redis.conf
kill -2
cd ..
EOF
```

