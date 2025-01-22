---
published: false
title: 'Spring:简单摆弄一下SpringIoC容器'
date: 2019-11-28 14:48:39
categories: 技术
tags: Spring
---

Spring框架本身实现了一套完整的IoC容器模型和依赖注入过程，在Spring框架的源码中`org.springframework.beans`和`org.springframework.context`包是Spring框架的基础，`BeanFactory`接口则是IoC的核心，它被描述为抽象的IoC容器，可以管理所以类型的Java对象，它定义了如何管理和配置IoC容器中的对象（例如：根据名称获取对象等）。我们常用的`ApplicationContext`是其子类，他完全实现了`BeanFactory`的所有功能，并且他还增加更多企业级特定的功能，例如：事件发布/监听机制、国际化等，在WEB应用程序生态中更是引入了`WebApplicationContext`提供全面的WEB应用程序开发支持。
<!--more-->

# Bean是个啥？

Bean由SpringIoC容器管理，是组成Spring应用程序的主干，任何被SpringIoC容器管理、实例化、组装的Java对象都可以统称为`Spring Bean对象`，简称`Bean`。`Bean`及`Bean`的依赖都是在`配置元数据`中配置，在Spring启动过程中通过读取配置元数据，根据配置信息对`Bean`及其外部依赖进行`实例化`、`组装`以及`类似生命周期管理`等操作。

# 配置元数据又是个啥？

Spring的IoC容器可以管理所有类型的Bean，但是总得告诉Spring要管理啥吧，就像去饭店点菜，你得告诉服务员你要吃啥（牛逼的可以喊一嗓子：菜单上的一样来一道）。对于Spring也是一样，需要提供一份清单，列出需要SpringIoC容器管理的Bean对象，以及对应Bean所需要的外部依赖及组装方式。

例如：
顾客：老板，给我来份麻辣拌
老板：得嘞，您有什么忌口的么？
顾客：不要麻也不要辣，多放香菇、金针菇、杏鲍菇
老板：得嘞，菌汤火锅一份~

Spring提供了多种配置元数据支持
- 基于XML
- 基于注解
- 基于Java编码

![SpringIoC容器示意图](/images/container-magic.png)
<center>SpringIoC容器示意图</center>

上图为Spring官方文档（V 4.3.25.RELEASE）中对SpringIoC容器的抽象描述示意图

# 一个Spring项目的诞生
## Spring 模块结构

Spring框架中，以核心模块为主的共有20多个模块参与并组成了Spring框架整体结构。下图为Spring官方文档提供的Spring各模块结构图

![Spring模块结构](/images/spring-overview.png)
<center>Spring模块结构</center>

## 创建Maven项目

首先，我们打开21世纪最牛逼的Java编译器`IntelliJ IDEA`，创建一个空的Maven项目，修改`pom.xml`文件，插入Spring为我们提供的Spring组件`物料清单`配置。

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-framework-bom</artifactId>
            <version>4.3.25.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```
> NOTE: `<dependencyManagement>`标签仅用于对Maven项目的依赖项进行定义，并不会真正的导入和下载依赖项，在使用时，需要在该Maven模块或其子模块的`pom.xml`文件中手动指定需要引入的依赖，填写在`<dependencies>`标签中，此时该依赖项才会进行导入或下载。

## 引入Spring

Spring包含许多模块，其中核心模块包括 `spring-core`, `spring-beans`, `spring-context`, `spring-context-support` 和 `spring-expression `，除此之外其余模块均建立在核心模块基础之上。此处我们暂时只使用`spring-context`模块即可使用Spring提供的开箱即用的IoC功能。该模块引入后将自动引入以下依赖模块：
- spring-aop
- spring-beans
- spring-core
- spring-expression

在`pom.xml`文件`<dependencies>`标签中添加下面的依赖项
```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>4.3.25.RELEASE</version>
    <scope>runtime</scope>
</dependency>
```

## 使用IoC容器管理Bean

这里描述基于XML配置元数据初始化IoC容器的例子

### 第一步：创建普通Java类

```java
package cc.chenzhihao.User;
public class User {
    private String name;
    // 省略getter and setter
}
```

### 第二步：创建配置元数据

SpringIoC容器在启动时需要为其注入`配置元数据`，`配置元数据`可以是`基于XML的配置元数据`、`基于注解的配置元数据`或`基于注解+Java编码的配置元数据`。

#### No.1 基于XML的配置元数据
在classpath目录下创建`applicationContext.xml`，该文件的框架结构如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- 在此处定义Bean的配置信息 -->

</beans>
```
然后，在XML配置文件中添加Bean相关配置。


这一步，将我们创建的普通Java类填写进Spring配置文件中。

Spring配置文件以`<beans>`为根节点，在标准命名空间下，其内部可使用的节点包括`<bean>`,`<import>`,`<alias>`和`<description>`标签（若引入AOP、事务配置，可能还会有`<tx>`标签）。其中`<bean>`标签用于定义`Bean`的配置；`<import>`标签用于引入其他`XML配置元数据`；`<alias>`标签用于为`Bean`定义别名；`<description>`标签不常用，一般用于对当前XML文档做描述。

此处使用`<bean>`标签配置一个Bean，`id`属性和`name`属性的作用相同，都是为Bean定义名称。相同之处在于，`id`和`name`都是为Bean起名，且该Bean名在同一SpringIoC容器中唯一。不同的是，`id`属性仅可以为Bean定义一个名称；而`name`属性可以定义多个名称，即`别名`（alias），可以使用`逗号（,）`或`分号（;）`分割的字符串定义多个别名.

`<<property>`作为`<bean>`的子标签，用于对Bean的属性赋值，此处为该Bean对象的`name`属性赋值，属性值为`value`属性对应的值本身.

```xml
<bean id="chen" name="zhihao" class="cc.chenzhihao.User">
     <property name="name" value="陈志昊"/>
</bean>
<bean id="zhao" name="benshan" class="cc.chenzhihao.User">
     <property name="name" value="赵本山"/>
</bean>
```

也可以使用`<alias>`标签在配置文件中为Bean单独定义别名，例如：

```xml
<alias name="chen" alias="chenzhihao"/>
<alias name="zhao" alias="zhaobenshan"/>
```

#### No.2 基于注解的配置元数据

- 第一步：在类路径下，创建以`org.springframework.context.annotation.Configuration`注解标注的Java类`BeanConfiguration`(该类名称不限)
- 第二步：添加使用`org.springframework.context.annotation.Bean`注解标注的方法，配置Bean

```java
package cc.chenzhihao;
@Configuration
public class BeanConfiguration {

    @Bean(name = {"ma","mayun"})
    public User ma() {
        User user = new User();
        user.setName("马云");
        return user;
    }

}
```

- 使用`@Configuration`注解的类被定义为`基于注解的配置元数据`，仅可用于类
- `@Bean`注解仅可用于带有注解`@Configuration`类的方法上，作用同基于XML配置元数据的`<bean>`标签。默认无参，方法名对应`<bean>`标签`id`属性，返回值类型对应`<bean>`标签`class`属性。若要定义别名，可以指定`@Bean`注解的`name`属性。（NOTE：指定`name`属性后，方法名不在作为Bean的名称定义）


### 第三步：创建IoC容器

最前面讲到，Spring框架中，`BeanFactory`接口为IoC容器的抽象描述，也可以直接把它理解为IoC容器。针对不同的场景，Spring提供了基于`BeanFactory`不同的实现。例如：

- FileSystemXmlApplicationContext 在系统文件路径下查找XML配置元数据初始化IoC容器
- ClassPathXmlApplicationContext 在Classpath路径加查找XML配置元数据初始化IoC容器
- AnnotationConfigApplicationContext 基于注解配置元数据初始化IoC容器
- and so on~

#### 使用基于XML的配置元数据初始化IoC容器

此处我们创建`ClassPathXmlApplicationContext`的对象，并在构造函数参数中指定`classpath`路径下的XML配置元数据文件名称创建SpringIoC。`FileSystemXmlApplicationContext`与之类似，区别在于构造函数参数传递的参数为系统文件路径。

```java
ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("applicationContext.xml");
```
> NOTE: 一定要保证在classpath根目录下有名为`applicationContext.xml`的Spring配置文件

#### 使用基于注解的配置元数据初始化IoC容器

```java
// 指定基于注解的配置元数据类的Class对象
// NOTE: 此处不要指定注解的Class对象，该参数旨在指定配置元数据是什么
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(BeanConfiguration.class);

// 或指定类路径，AnnotationConfigApplicationContext在初始化时会自动扫描该包路径下包含`@Configuration`注解的Java类作为配置元数据
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext("cc.chenzhihao");
```

### 第四步：从IoC容器中获取Bean

因`ClassPathXmlApplicationContext`为`BeanFactory`接口的子类，实现了`BeanFactory`接口的所有功能，因此可以使用`BeanFactory`接口中获取Bean的方法。

#### 根据名称获取Bean
使用容器`Object getBean(String name)`方法

```java
Object user = (User)context.getBean("chen"); 
System.out.println(user.getName()); 
```

- 若名为`chen`的Bean不存在，则会抛出`NoSuchBeanDefinitionException`异常
- IoC容器无法在编译期间得知Bean的类型，需要在运行是才能知道，所以方法的返回值被定义为`Object`类型，如要使用原始对象的功能，则需要强制类型转换。
- 此处进行强制类型转换是有风险的，因为如果对于不了解Spring配置文件的开发者，单纯通过名称获取Bean就进行强转，有可能会抛出Java类型转换异常（`ClassCastException`）。

因此不建议使用该方法。

#### 根据类型获取Bean

使用容器`<T> T getBean(Class<T> requiredType)`方法

```java
User user = context.getBean(User.class); // throw NoUniqueBeanDefinitionException
System.out.println(user.getName()); 
```

- 若名为`chen`的Bean不存在，则会抛出`NoSuchBeanDefinitionException`异常
- 该方法查找IoC容器中T类型的Bean，若IoC容器中存在多个T类型的Bean，则会抛出`NoUniqueBeanDefinitionException`异常。

因此不建议使用该方法。

#### 根据名称+类型获取Bean

使用`<T> T getBean(String name, Class<T> requiredType)`方法

```java
User user = context.getBean("chen", User.class); 
System.out.println(user.getName()); // 陈志昊
```

- 若名为`chen`的Bean不存在，则会抛出`NoSuchBeanDefinitionException`异常

#### 根据类型获取多个Bean

使用`<T> Map<String, T> getBeansOfType(Class<T> type)`方法

```java
Map<String, User> users = context.getBeansOfType(User.class); 
for(Map.Entry<String, User> userEntry: users){
    System.out.println(userEntry.getValue().getName());
}

// print：
// 陈志昊
// 赵本山
```

该方法用于获取某类型所有Bean，通常在基于Spring框架构建系统内模块时，通过扩展基类创建子类模块的方式对业务扩展进行解耦，是面向对象软件设计中的原则——开闭原则（对扩展开放，对修改关闭），通常根据基类类型在SpringIoC容器中查找Bean集合，对齐遍历或筛选后调用Bean方法进行业务处理。
