---
published: true
title: 给Linux带上Google Authenticator安全套
date: 2019-05-26 11:22:13
updated: 2019-05-26 11:22:13
categories: 技术
tags: linux
---
先说说什么是Google Authenticator（以下简称GA），你可以把它想成开源的QQ手机令牌，基于时间和一定的算法生成6位动态口令。

<!--more-->

先说说什么是Google Authenticator（以下简称GA），你可以把它想成开源的QQ手机令牌，基于时间和一定的算法生成6位动态口令。一听到动态口令，顿时安全感提升了一大截。在次之前我也基于GA加固了自己项目的管理员认证这一部分，算法特别简单，过两天我在单独写一个GA算法的文章。

## 环境及依赖

1. Centos7    6.4也可以，我只是喜欢新东西而已:)
2. chrony
3. pam-devel
4. libpam-google-authenticator-1.0-source.tar.bz2
5. qrencode－3.4.4 用于生成二维码，贼拉牛逼
6. libpng、libpng-devel

## 安装开发者工具
```bash 
yum groupinstall "Development Tools" -y
```
## 安装pam开发包
```bash
yum install pam-devel -y
```
## 安装chrony，更快更精准同步系统时间
```bash 
yum install chrony -y
```
更新系统时间
```bash
[root@shimmer ~]# chronyc sources
210 Number of sources = 3
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^+ 120.25.115.19                 2  10   377    80   +814us[ +814us] +/-   71ms
^* time4.aliyun.com              2  10   377   779   -608us[ -502us] +/-   47ms
^- 120.25.115.20                 2  10   357   200   +550us[ +550us] +/-   71ms
```

## 下载GA源码
```bash
git clone https://github.com/google/google-authenticator-libpam.git
```

## 编译安装GA
```bash
[root@shimmer ~]# ./bootstrap.sh 
[root@shimmer ~]# ./configure
[root@shimmer ~]# make && make install
```
## 配置PAM使ssh支持GA认证
编辑sshd文件，在第一行添加如下内容

```bash
[root@shimmer ~]# vim /etc/pam.d/sshd 
auth       required pam_google_authenticator.so no_increment_hotp
```

## 配置sshd
```bash
[root@shimmer ~]# nano /etc/ssh/sshd_config
```
修改如下3个参数值

- PasswordAuthentication  yes
- ChallengeResponseAuthentication  yes
- UsePAM  yes

## 创建软连
```bash
[root@shimmer ~]# ln -s /usr/local/lib/security/pam_google_authenticator.so /usr/lib64/security/pam_google_authenticator.so
```
## 重启ssh服务
```bash
[root@shimmer ~]# systemctl restart sshd
# Centos 6 重启直接执行如下命令
[root@shimmer ~]# service sshd restart
```

## 为当前用户设置GA
```bash
[root@shimmer ~]# google-authenticator
```
执行该命令后，产生一个连接和二维码，直接使用GA客户端扫描二维码添加一个令牌到手机。

并且还会产生五个code，用于在客户端令牌丢失的情况下使用，每使用一个失效一个。后期登录成功后可再次生成

```bash
--- #为隐私隐藏部分 ---
Your new secret key is: SLZ#############
Your verification code is 237785
Your emergency scratch codes are:
  5#######
  9#######
  5#######
  2#######
  9#######
```

会出现五个问题，建议全部Y
```
第1个：问你是否想做一个基于时间的令牌 【y】
第2个：是否更新你的google认证文件，由于第一次设置，所以【y】
第3个：是否禁止口令多用，这里选择y，禁止它，以防止中间人欺骗。【y】
第4个：默认情况，1个口令的有效期是30s，这里是为了防止主机时间和口令客户端时间不一致，设置的误差，可以选择y，也可选n，看要求严谨程度
第5个：是否打开尝试次数限制，默认情况，30s内不得超过3次登陆测试，防止别人暴力破解。【y】
```

## 测试
退出，重新连接服务器
```bash
chenzhihao-mac:~ chenzhihao$ ssh root@172.###.###.### -p###
Verification code: 输入GAcode，不回显
Password: 输入用户密码，不回显
Last login: Sun Dec 11 13:31:43 2016 from 172.###.###.###
```
