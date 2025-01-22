---
published: false
title: grep命令使用总结
date: 2021-01-13 11:17:28
categories: 技术
tags: grep
---
`grep`是文本搜索最常用的命令，在日常日志排查过程中使用非常频繁。这篇文章对grep命令的使用方式做个总结
<!--more-->

## grep命令

> grep [-abcDEFGHhIiJLlmnOoqRSsUVvwxZ] [-A num] [-B num] [-C[num]]
>      [-e pattern] [-f file] [--binary-files=value] [--color=when]
>      [--context[=num]] [--directories=action] [--label] [--line-buffered]
>      [--null] [pattern] [file ...]

参数解释

- -i: 忽略大小写
- -v: 显示不匹配的行，反向选择。
- -n: 显示时加上匹配所在的行号
- -H: 当搜索多个文件时，显示文件名前缀
- -c: 显示匹配的行数
- -B: 显示匹配行以及前n行
- -A: 显示匹配行以及后n行
- -C: 显示匹配行以及前后n行
- --color=auto: 对匹配的信息高亮显示。可以简写 --col。centos7默认添加

### 使用场景

##### 例1：从文件中查询指定单词

```shell 
grep "chenzhihao" info.log --color
```

##### 例2：查询并忽略大小写

```shell
grep -i "error" info.log 
```

##### 例3：查询并显示行号

```shell
grep -n "chenzhihao" info.log
```

##### 例4：查询并显示包含匹配行在内的后10行
```shell
grep -A 10 "21h323423423423" error.log 
```
##### 例5：查询并显示包含匹配行在内的钱10行
```shell
grep -B 10 "21h323423423423" error.log 
```

##### 例6：查询并显示包含匹配行在内的前后10行
```shell
grep -C 10 "21h323423423423" error.log 
```
