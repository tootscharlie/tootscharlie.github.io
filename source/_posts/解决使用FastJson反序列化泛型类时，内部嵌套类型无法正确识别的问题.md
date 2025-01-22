---
published: false
title: 解决使用FastJson反序列化泛型类时，内部嵌套类型无法正确识别的问题
date: 2019-05-26 12:28:14
categories: 技术
tags: fastjson
---

在开发中经常会遇到序列化和反序列化的问题，比较常用的是将对象序列化成json信息存储。

对于json信息的操作，我个人偏向于使用FastJson，这是一款java环境的json处理工具，由阿里爸爸开发。

项目地址：https://github.com/alibaba/fastjson

<!--more-->

在开发中经常会遇到序列化和反序列化的问题，比较常用的是将对象序列化成json信息存储。

对于json信息的操作，我个人偏向于使用FastJson，这是一款java环境的json处理工具，由阿里爸爸开发。

项目地址：https://github.com/alibaba/fastjson

## 问题描述

泛型类A中组合一泛型类对象，使用`FastJson的<T> T parseObject(String text, Class<T> clazz, @Nullable Feature... features)`方法对序列化后A对象的值进行反序列化时，无法正确识别类型擦除前嵌套类的真实类型，从而导致反序列化后的嵌套类类型为Object。

```java
class A<T> {
    private T t;
    // 省略get／set方法
}
 
class B {}
```
搞一下

```java
A<B> a = new A();
B b = new B();
a.setT(b);
System.out.println(a.getT().getClass().getName()); // B
String str = JSONObject.toJSONString(a); 
A<B> parsedA = JSONObject.<A<B>>parseObject(str,A.class);
System.out.println(a.getT().getClass().getName()); // java.lang.Object
//获取反序列化后A类中泛型类的属性值
String value = a.getT().getField(); // throw ClassCastException: JSONObject cannot be cast to B
```
首先创建类A的对象，类型约束为B。创建类B的对象，与A绑定。输出类A对象中绑定类的名称。

将类A对象序列化成json字符串，然后使用反序列化方法解析出原始对象。

此时再次输出类A对象中绑定类的名称，奇怪的是为何类型绑定出现问题。

与之同时调用该绑定类的某个获取属性值的方法，就会抛出类型转换异常。

## 解决思路

首先看一下当前使用的反序列话方法的API。
```java
public static <T> T parseObject(String text, Class<T> clazz, Feature... features) {
    return (T) parseObject(text, (Type) clazz, ParserConfig.getGlobalInstance(), DEFAULT_PARSER_FEATURE, features);
}
```
我们的需求是将序列化后的字符串反序列化成保留原始类型的对象，然而这个API的第二个参数为一个Class类型，需要传入目标对象的原始class对象。

这就会出现一个问题，泛型限定类表丢失，类型被擦除，根据java编译器的类型擦出原则，所有泛型类都会被擦除为Object类型，因为虚拟机不认泛型类。有的同学说了：怎么不可以啊，第二个参数我传Class<B>.class 不可以么？ 答案是不可以。别问为什么，Google去

说到这可以看得出，这个API不支持泛型类反序列化。那么我们在看一下关于fastJSON给出的反序列化工具还有什么？难道这是阿里在开发fastJSON时忽略的东西么？针对这个问题，我又搜索了一下，发现了如下API
```java
public static <T> T parseObject(String text, TypeReference<T> type, Feature... features);
public static <T> T parseObject(String input, Type clazz, Feature... features);
```
此API与我们使用的唯一不同的是，第二个参数使用了一个泛型类，`TypeReference<T>`，哇爽的一B，然而就在我点进去想看看这个类的API文档时，我去年买了个表！毛也没有。（后来我搜了一下项目仓库找到了，在参考资料处贴出）

```java
public class TypeReference<T> {
 
    private final Type type;
 
    protected TypeReference(){
        Type superClass = getClass().getGenericSuperclass();
 
        type = ((ParameterizedType) superClass).getActualTypeArguments()[0];
    }
 
    public Type getType() {
        return type;
    }
    
    public final static Type LIST_STRING = new TypeReference<List<String>>() {}.getType();
}
```
这个类将构造方法设置为 `protected`，很明显希望我去搞个类做（继）你（承）小（你）弟（呀），哪有呢么容易说继承就继承，让我先了解清楚。这个类有个私有常量，也提供了获取方法，在构造方法中，意图很明显，希望拿到大哥类型限定列表中的类型值。那好吧，既然你这么想当大哥，那就给你个机会。

> 旁白：“你真要做他小弟？”
> 我：“绝不，给他另找一个就得了”

新的实现方式如下A<B> a = new A();

```java
B b = new B();
a.setT(b);
System.out.println(a.getT().getClass().getName()); // B
String str = JSONObject.toJSONString(a); 
// 使用支持泛型反序列化的API
Type type = new TypeReference<A<B>>(){}.getType(); // 构造TypeReference的匿名内部类对象，直接获取Type对象
A<B> parsedA = JSON.parseObject(str, type); //使用第二个参数为 Type对象的反序列化API
System.out.println(a.getT().getClass().getName()); // B
//获取反序列化后A类中泛型类的属性值
String value = a.getT().getField(); // success
```
搞定！

## 总结
- 在序列化和反序列化过程中带有泛型类要特别注意类型擦出的问题，尽量使用支持泛型处理的序列化和反序列化API
- 通过出现的问题来锻炼自己解决问题的能力，实在不行Google呗，千万别用百度！千万别用百度！千万别用百度！
- 别随便做人小弟，都是出来混的，有事儿解决事儿，千万别委屈求全！滥用继承，只会让代码更臃肿

# 参考资料
- [TypeReference](https://github.com/alibaba/fastjson/wiki/TypeReference)
- 具体类型擦出，详见我的这篇文章：[《java虚拟机巧解泛型擦除与多态之间的矛盾》](/2019/05/26/java虚拟机巧解泛型擦除与多态之间的矛盾/)
- [fastjson如何json数组串转换为Object数组时如何指定各个数据项的数据类型](http://www.oschina.net/question/251451_150785)
