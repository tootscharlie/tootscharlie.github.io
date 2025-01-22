---
published: true
title: mac安装phpMyAdmin管理mysql数据库
date: 2019-05-26 11:17:35
updated: 2019-05-26 11:17:35
categories: 技术
tags: phpmyadmin
---

在macbook系统上安装phpMyadmin工具管理mysql数据库。

## 环境

- macOS 10.12.1 （mysql5.7官方说支持到10.11，其实这个版本也可以安装）
- mysql5.7.16
- apache2.4.23 (macOS自带)
- PHP5.6.25 （macOS自带）
- MySQL Workbench (GPL)6.3.8
- phpMyAdmin4.4.10

## 安装mysql

1. 这里选择mac版mysql5.7.16（发帖最高）版本，通过Oracle官网下载
2. 安装后注意弹窗，会提示默认的初始密码，接下来会用到改密码初始化数据库。

## 安装MySQL Workbench工具初始化mysql数据库root账户

1. 在上一步mysql下载页面的下方会找到MySQL Workbench的下载链接，下载并安装
2. 启动软件，添加一个本地mysql数据库连接会话。输入初始密码后会提示密码未修改。再次提交后会提示输入Oldpassword和输入两次新密码。完成后 root账户到此初始化成功

## 将phpMyAdmin源码放入web主目录

目录地址：/Library/WebServer/Documents/ 为apache 的www目录


## 开启mac本地apache和php环境

使用 终端su命令输入密码后切换管理员账号，并输入一下命令

```bash
nano  /etc/apache2/httpd.conf
```
找到以下信息并修改
```xml
#LoadModule php5_module libexec/apache2/libphp5.so
改为
LoadModule php5_module libexec/apache2/libphp5.so
添加以下信息到该文件结尾处
 
<Directory "phpmyadmin存放目录">
 Options Indexes FollowSymLinks MultiViews
 AllowOverride all
 Order Deny,Allow
 Allow from all
</Directory>
```

## 配置phpMyAdmin

复制配置文件
```bash 
cp config.sample.inc.php config.inc.php
```
修改权限
```bash
chmod -R 777 /Library/WebServer/Documents/phpmyadmin/
```
启动apache测试环境
```bash
/usr/sbin/apachectl start
```
访问 http://localhost/phpmyadmin 输入帐密登录
