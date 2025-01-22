---
published: false
title: java虚拟机巧解泛型擦除与多态之间的矛盾
date: 2019-05-26 11:12:09
categories: 技术
tags: 泛型
---

从字面意义上来讲，泛型，即广泛的类型，这样就不难理解了。泛型是java程序设计的一个手段，可以想想为使用泛型编写的代码即是一个模板，使用泛型机制编写java程序在安全性和可读性上都会更有帮助。

<!--more-->

从字面意义上来讲，泛型，即广泛的类型，这样就不难理解了。泛型是java程序设计的一个手段，可以想想为使用泛型编写的代码即是一个模板，使用泛型机制编写java程序在安全性和可读性上都会更有帮助。

然而在学完泛型之后，会产生一个难以理解的问题。首先来看一下让我百思不得其解的地方。

## 代码

```java
//测试类
public class Test {
 
    public static void main(String[] args) {
        B b = new B();
        A<String> a = b;
        a.setSub("chen");
        System.out.println(a.getSub());
    }
 
}
 
//父类A
public class A<T> {
 
    private T sub;
 
    public T getSub() {
        return sub;
    }
 
    public void setSub(T sub) {
        this.sub = sub;
    }
}
 
//子类B
public class B extends A<String> {
 
    private final String TEMP = "_end";
 
    @Override
    public void setSub(String sub) {
        super.setSub(sub + TEMP);
    }
 
    @Override
    public String getSub() {
        return super.getSub();
    }
}
```

这里有三个类，类A为泛型类，其中有一个成员变量sub，并且提供了一组访问器。类B为泛型类A的子类，限定类型为String，提供一个常量TEMP，并且覆盖父类的访问器方法。

在测试类中创建子类B的对象且。声明一个限定类为String的父类A的引用 a，指向类B的对象，这里使用了多态。调用setSub方法设值，调用getSub取值并打印。

## 问题

我们都知道，泛型类编译后在虚拟机中是不存在限定类型的，即限定类型擦除。

类A擦除后变为

```java 
public class A {
 
    private Object sub;
 
    public Object getSub() {
        return sub;
    }
 
    public void setSub(Object sub) {
        this.sub = sub;
    }
}
```

在类A擦除后，虚拟机中类A仅存在签名为Object getSub()的方法和void setSub(Object)方法

类B擦除后变为

```java
public class B extends A {
 
    private final String TEMP = "_end";
 
    @Override
    public void setSub(String sub) {
        super.setSub(sub + TEMP);
    }
 
    @Override
    public String getSub() {
        return super.getSub();
    }
}
```
在类B擦除后，虚拟机中类B存在签名为void setSub(String) 和 String getSub()方法

然而在上述测试代码中，我们使用多态，将A类引用a指向了B类对象，此时A类引用a调用setSub()方法时，会首先去去调用类A的setSub(Object)方法，然而此时引用a的实际对象是类B的对象，所以实际调用的是类B的setSub(Object)方法，我们知道类B中并不存在这样的方法，那么此时就出现了java泛型方法擦除和多态产生的矛盾。然而此程序可以正常运行并输出的，那么java是如何解决这个问题的呢？

## java虚拟机的解决方法

我们再来回顾一下多态，即父类引用指向子类对象，该引用调用方法时，只可以调用父类已有的方法，具体实现看子类，如果子类覆盖了父类的方法，则调用子类的，父类的自动被覆盖掉。方法的覆盖要保证方法名、参数列表的一致。然而，上述问题调用的是父类的setSub(Object)方法，子类并没有覆盖。那么这样一来不就打破了多态的特性了么？

在阅读书籍和Google之后发现，java虚拟机原来提供了一种桥方法的东西来处理这个问题。即 在对应的类B中提供了与类A引用被调用方法签名一致的方法，在该方法的实现中调用了类B的方法并对参数进行强制转换。这样问题就解决了。即，在虚拟机中，类B其实存在着两个方法如下

```java 
public void setSub(String sub) {
    super.setSub(sub + TEMP);
}
 
//桥方法
public void setSub(Object sub){
    setSub((String)sub);
}
```

这样一来，问题就解决了。


## 隐藏问题

我们此处的问题已经得到了答案，java虚拟机在针对此类问题时，会自动的在子类中创建一个桥方法用来处理泛型擦除与多态之间的矛盾问题。那么 针对上述代码又有一个问题。

类A和类B中还有一个方法getSub()方法，根据我们的分析，虚拟机会对类A的所有方法在类B中创建签名相同的桥方法，即在虚拟机中，类B存在如下的两个方法

```java
String getSub() 
Object getSub()
```

我第一眼看到也想说，这样的方法能在同一个类中存在么？ 有些人可能想到了重载，问题是重载需要方法名相同，参数列表不同。 这两个方法并不是方法重载，那么为什么不报错呢？

归根到底还是虚拟机的事儿， 在虚拟机中是用参数类型和返回类型确定一个方法的，即参数列表和返回类型只要有一个不同，在虚拟机中就是不同的两个方法。
