---
published: true
title: 升级mac系统后git丢失
date: 2019-05-26 11:05:13
updated: 2019-05-26 11:05:13
categories: 技术
tags:
    - mac
---
今天手贱升级max最新系统后，打开Idea提示git环境异常，提示如下信息：

    xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools), missing xcrun at: /Library/Developer/CommandLineTools/usr/bin/xcrun

完美解决方法：xcode-select –install
