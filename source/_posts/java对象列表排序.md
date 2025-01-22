---
published: false
title: java对象列表排序
date: 2019-05-26 10:51:04
categories: 技术
tags: java
---

在开发中需要对List<T>列表进行自定义排序，如 需要对资源对象列表排序后扔到前台展示。你们可能要说了，直接Sql语句排序好扔出来不就ok？ 那我再加一个条件，Sql查出后序列化到缓存中，再从缓存反序列化出到List集合，已经乱序了吧？ 那么再次排序该咋搞？

<!--more-->

在开发中需要对List<T>列表进行自定义排序，如 需要对资源对象列表排序后扔到前台展示。你们可能要说了，直接Sql语句排序好扔出来不就ok？ 那我再加一个条件，Sql查出后序列化到缓存中，再从缓存反序列化出到List集合，已经乱序了吧？ 那么再次排序该咋搞？

## Collections.sort(List<T> , Comparator)

使用Collections对象的sort方法，对List集合中的元素进行排序，排序依据Comparator接口的实现类

## 创建实现Comparator<T>接口

实现compare(T ,T)方法， 该方法的返回值为int类型。 返回一个正数，表示t1 > t2; 返回一个负数，表示t1<t2; 返回0表示t1=t2

```java
// 添加实现方法
public int compare(T t1, Resource t2) {
    return 0;
}
```

将该类的对象传入sort方法的第二个参数中，可对List中的对象进行排序
