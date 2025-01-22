---
published: false
title: 记录一次使用Lombok时打印对象缺少字段值的问题
date: 2019-05-26 13:23:17
updated: 2019-05-26 13:23:17
categories: 技术
tags: lombok
---
## 问题现象

对类级别采用Lombok注解`@Data`（图省事儿，代码还简洁）。

该注解可以为对象提供属性的访问器、toString等方法。详细可以了解Lombok

问题在于，类A与类B存在继承关系时，在调用toString、Equals以及HashCode等方法时，无法自动调用父类。代码：

```java
@Data
public class A {
    private String name;
}
 
@Data
public class B extends A{
    private Integer age;
}
 
// ~ 测试代码（简略）
B b = new B();
b.setAge(11);
b.setName("小强");
System.out.println(b.toString()); // out: B(age=11)
```
对象b的输出结果只有age属性，why？

此问题在于，Lombok的@Data注解自动生成的toString方法并不支持调用父类方法，需要手动设置调用父类的标记

```java
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
```
这两个注解定义在类级别上，显示声明对于toString、equals和hashCode方法自动调用父类

再次执行单元测试，完美解决。
