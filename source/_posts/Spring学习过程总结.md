---
published: false
title: Spring学习过程总结
date: 2019-12-03 14:39:14
categories: 技术
tags: Spring
---

项目做得不少，但总觉的底子不牢，根基不深。相信很多同学跟我有同样的感受。我自认为原因在于基础打的不牢，根基不够深。我认识的一位大佬在面试我的时候跟我说过一句话，`万丈高楼平地起`，如果基础打得不牢，越往上走越觉得`脚下无力`，`基础不牢`这块短板就会慢慢显现出来，成为影响自己进步的后腿，慢慢就会垮掉。换个角度说，就像在游戏中，前期发育不好，后期无论是打团还是单带都有气无力，最后可能连气都喘不上。从我自身成长的角度来看，需要以官方文档为切入点深入源码，细细研究Spring框架的功能及内部实现细节。欢迎同学和大佬多提意见！

<!--more-->

## 背景

项目做得不少，但总觉的底子不牢，根基不深。相信很多同学跟我有同样的感受。我自认为原因在于基础打的不牢，根基不够深。我认识的一位大佬在面试我的时候跟我说过一句话，`万丈高楼平地起`，如果基础打得不牢，越往上走越觉得`脚下无力`，`基础不牢`这块短板就会慢慢显现出来，成为影响自己进步的后腿，慢慢就会垮掉。换个角度说，就像在游戏中，前期发育不好，后期无论是打团还是单带都有气无力，最后可能连气都喘不上。从我自身成长的角度来看，需要以官方文档为切入点深入源码，细细研究Spring框架的功能及内部实现细节。欢迎同学和大佬多提意见！

## Spring官方文档

在本文创建时，SpringFramework最新版本为5.2.1，而本文以`Spring4.×`最后一个版本`4.3.25`为学习目标。由于`Spring4.×`已经全面支持`JDK8`特性，而大部分互联网公司的Java运行环境还尚处于8.0版本，而`4.3.25`作为该系列最后一个版本，是市面上使用最广、代码健壮性、稳定性、可用性最强的一版。为什么没有使用最新版本呢？首先，`Spring5.×`版本的口号是全面拥抱`JDK9`特性，源码在一定程度上引入了JDK9的语法支持，而目前`JDK8`仍然是各大互联网公司的标配。其次，`Spring5.×`版本仍处于小版本的快速迭代期，现有文档的时效性会很差，不利于巩固学习。

综上所述，个人建议，以`Spring4.×`为目标来深入学习Spring是个不错的选择。下面提供`Spring-Framework-4.3.25.RELEASE`官方文档地址，若同学们想了解其他版本，请参阅Spring官方网站提供的[Spring-Framework Learning学习平台](https://spring.io/projects/spring-framework#learn)


`Spring-Framework-4.3.25.RELEASE`官方文档阅读/PDF下载地址
[Spring-Framework-4.3.25.RELEASE 官方文档（HTML）](https://docs.spring.io/spring/docs/4.3.25.RELEASE/spring-framework-reference/htmlsingle)

[Spring-Framework-4.3.25.RELEASE 官方文档（PDF）](https://docs.spring.io/spring/docs/4.3.25.RELEASE/spring-framework-reference/pdf/spring-framework-reference.pdf)


## 目录

1. {% post_path /Users/didi/Documents/development/blog/source/_posts/Spring:白话一下IoC %}
2. {% post_path /Users/didi/Documents/development/blog/source/_posts/Spring-简单摆弄一下SpringIoC容器 %}
3. {% post_path /Users/didi/Documents/development/blog/source/_posts/Spring:Bean的实例化配置及依赖注入 %}
4. {% post_path /Users/didi/Documents/development/blog/source/_posts/Spring-浅谈依赖注入 %}
5.  {% post_path /Users/didi/Documents/development/blog/source/_posts/Spring-属性注入那点事儿 %}
