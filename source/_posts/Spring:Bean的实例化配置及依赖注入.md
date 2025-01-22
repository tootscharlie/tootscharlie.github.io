---
published: false
title: 'Spring:Bean的实例化配置及依赖注入'
date: 2019-11-29 11:14:01
categories: 技术
tags: Spring
---

上一篇文章{% post_link Spring-简单摆弄一下SpringIoC容器 %}简单介绍了SpringIoC容器，并创建了一个Demo项目，演示了两种配置元数据的创建方式，以及利用相应的`ApplicationContext`读取配置元数据初始化SpringIoC容器，最后在测试方法中启动IoC容器并从容器中根据名称、类型获取Bean的过程。本篇总结一下如何在配置元数据中配置Bean的实例化方式以及Bean所需的外部依赖注入方式（依赖输入），换句话说，以哪些方式告诉SpringIoC容器实例化Bean的方法，以及Bean所需的外部依赖如何注入到Bean中。

<!--more-->


## 絮叨絮叨

&#160; &#160; &#160; &#160;在配置元数据（特别是基于XML的配置元数据）中，定义一个Bean（例如：使用`<bean>`标签）本质上是告诉Spring IoC容器如何创建一个Bean，换句话说，使用配置元数据向IoC容器提供一个`配方`（Bean定义），使IoC容器知道通过什么方式、注入什么依赖和参数去实例化一个Bean。当客户端调用IoC容器的获取Bean的方法时，IoC容器将查看所有的`配方`，并根据这些`配方`封装的配置元数据来创建（或从当前容器或其父容器获取）`实例对象`。

&#160; &#160; &#160; &#160;这些`Bean的配置信息`在IoC容器初始化时，会读取配置元数据中的配置信息，将Bean定义中配置的所有`属性`和`依赖`映射为`BeanDefinition`对象中的属性，最终在IoC容器中形成一大堆`BeanDefinition`对象。这也就解释了，为什么Spring会很轻松的提供多种`配置元数据`支持，任何显示的`配置元数据`定义都会在IoC容器初始化时被映射为`BeanDefinition`对象。


## Bean实例化配置

Spring为开发者提供了`基于构造函数`、`基于静态工厂方法`和`基于实例工厂方法`三种Bean的实例化配置方式，以下分别对上述三种方式做一个总结，附带一些Demo示例。

### 基于构造函数
使用`基于构造函数`的Bean实例化配置引导IoC容器创建该Bean实例的过程，等效于在普通Java程序中使用`new`操作符调用类的`构造函数`实例化对象的过程。Spring几乎可以对任何Java类进行整合配置，使其被SpringIoC容器所管理。通常情况下，使用最简单的`<bean>`单标签配置一个Bean，只需将`<bean>`标签的`class`属性指定为类的`全限定类名`，以及为该类提供一个构造函数即可。例如下面的配置，使用了`User`类的公共无参构造函数进行Bean实例化配置。

```java
package cc.chenzhihao;
public class User{
    // 省略属性信息
}
```

```xml
<bean id="user" class="cc.chenzhihao.User"/>
```
在Java类不指定构造函数的情况下，Java编译器在编译期间会自动为该类提供一个默认的构造函数，这里不用多说。而上面的Spring配置文件仅指定了该Bean的名称和类型，IoC容器在初始化并加载配置元数据进行Bean实例化时，会通过Java反射机制，调用该类的无参构造方法实例化Bean对象。当不改变上述Spring配置文件，仅对`User`类进行修改，添加私有（`private`）无参构造函数或添加带参构造函数时，IoC容器启动时，因无法调用到该类的公共无参构造函数，会导致IoC容器初始化失败，并抛出`NoSuchMethodException`，因为这是一个致命问题。类似的报错信息提示如下：

> Failed to instantiate [cc.chenzhihao.User]: No default constructor found; nested exception is java.lang.NoSuchMethodException: cc.chenzhihao.User.<init>()

那么如果当前需要配置的Bean没有无参构造方法，仅提供了自定义的含参构造函数（示例代码如下），那该怎么办呢？本篇后面关于`依赖注入（DI）`章节会有解释，请同学们继续往下看吧。

```java
package cc.chenzhihao;
public class User{
    private String name;
    
    public User(String name){
        this.name = name;
    }

    // 无公共无参构造函数
    // 省略setter/getter
}
```

### 基于静态工厂方法

定义使用静态工厂方法创建的bean时，可以使用class属性指定包含静态工厂方法的类，并使用名为factory-method的属性指定工厂方法本身的名称。您应该能够调用此方法（带有稍后描述的可选参数）并返回一个活动对象，该对象随后将被视为通过构造函数创建的。这种bean定义的一种用法是在旧版代码中调用静态工厂。

使用`静态工厂方法`创建Bean时，可以使用`<bean>`标签的`class`属性指定`工厂类`（即包含静态工厂方法的类），并且使用名为`factory-method`的参数指定`静态工厂方法`的名称。如此配置，IoC容器启动后，会调用该工厂类的静态工厂方法实例化类对象，并将其交由IoC容器管理，成为一个Bean。

> Note：此处`<bean>`标签的`class`属性指定的是`工厂类的全限定类名`，并不是调用静态工厂方法后所产生的Bean对象的类型。`id`属性依旧被用作实例化后的Bean的名称。

示例代码如下：

```java
package cc.chenzhihao;

public class AnimalFactory{
    private AnimalFactory(){}

    public static Cat newCat(){
        return new Cat();
    }

    public static Dog newDog(){
        return new Dog();
    }
}
```
Spring配置文件代码如下：
```xml
<bean id="cat" class="cc.chenzhihao.AnimalFactory" factory-method="newCat"/>
<bean id="dog" class="cc.chenzhihao.AnimalFactory" factory-method="newDog"/>
```
上述代码将使用`AnimalFactory`工厂类的`newCat`和`newDog`工厂方法分别创建名为`cat`和`dog`两个Bean实例，这个方式在某些场景下非常实用。但上述配置方式也会出现和`基于静态工厂方法的Bean实例化配置`一样的问题，那就是`静态工厂方法需要提供参数该怎么办？`，同样，在本篇后面关于`依赖注入（DI）`章节会有解释，请同学们继续往下看吧。


### 基于实例工厂方法

类似于通过静态工厂方法进行实例化，使用实例工厂方法进行实例化会从容器中调用现有bean的非静态方法来创建新bean。要使用此机制，请将class属性保留为空，并在factory-bean属性中，在当前（或父/祖先）容器中指定包含要创建该对象的实例方法的bean的名称。使用factory-method属性设置工厂方法本身的名称。

使用`基于实例工厂方法`的Bean实例化配置，类似于使用`静态工厂方法`的Bean实例化配置。使用该方式，IoC容器会从容器中调用给定Bean的非静态方法来创建新的Bean，在配置时，`<bean>`的`class`属性不要填写或留空，并且，在`factory-bean`属性中，指定当前容器（或父容器）中指定Bean名称的引用。Demo如下：

实例Java代码：

```java
package cc.chenzhihao;

public class FruitFactory{

    public Apple newApple(){
        return new Apple();
    }

    public Orange newOrange(String name){
        return new Orange(name);
    }

}
```

Spring配置文件：
```xml
<!-- Factory Bean，可以在当前容器，也可以在父容器或祖先容器进行配置 -->
<bean id="fruitFactory" class="cc.chenzhihao.FruitFactory"/>

<!-- 依托Factory Bean的实例工厂方法创建水果Bean对象（NOTE：不要指定class属性）. factory-bean指定实例工厂Bean名称，factory-method指定实力工厂Bean中的实例工厂方法 -->
<bean id="apple" factory-bean="fruitFactory" factory-method="newApple">

<!-- 为工厂方法提供参数 -->
<bean id="orange" factory-bean="fruitFactory" factory-method="newOrange">
    <constructor-arg value="橙子">
</bean>
```

以上代码，Spring会首先实例化`fruitFactory`，紧接着实例化`apple`。若工厂方法含有参数，则需要使用`<constructor-arg>`标签指定参数，使用方式同`构造方法实例化`。

## 总结

以上简单总结了使用Spring IoC容器`配置Bean实例化方式`的几种方法（是不是很饶舌~），最简单的是类似`new`的`基于构造函数的Bean实例化配置方式`，其次是`基于静态/实例工厂方法的Bean实例化配置`。

下面表格简单总结`构造函数`、`静态工厂Bean`和`实例工厂Bean`的异同。

\# |构造函数| 静态工厂 |  实例工厂 
:-: |:-: | :-: | :-:
id属性 | Bean名称 | Bean名称 | Bean名称 
class属性 |实际Bean的类型| 工厂Bean类型 | -
factory-bean | -| - | 实例工厂Bean名称 
factory-method| -| 静态工厂方法 | 实例工厂方法
constructor-arg标签 |提供构造函数参数| 提供工厂方法参数| 提供工厂方法参数


