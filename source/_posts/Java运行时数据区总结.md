---
title: Java运行时数据区总结
date: 2021-02-04 23:14:31
categories: 技术
tags: JVM
---

# 程序计数器
> 特点：
> 1. 线程私有
> 2. JVM规范中唯一没有规定抛出“OutOfMemoryError”异常的区域
> 3. 如果运行非Native方法时，存储Jvm虚拟机当前线程正在执行的字节码指令的地址；否则，存储的是undefined

程序计数器又名“PC寄存器”



# Java虚拟机栈

# 本地方法栈

# Java堆

# 方法区