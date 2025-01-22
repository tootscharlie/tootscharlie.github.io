---
published: false
title: Spring-浅谈依赖注入
date: 2019-12-06 15:22:19
categories: 技术
tags: Spring
---
Spring框架的核心技术是IoC，将对象的创建时机和创建过程交由IoC容器来管理，并且在容器实例化对象之后自动注入该对象所需的外部依赖，由于整个过程从根本上来说是反向的，所以称该过程为`控制反转`，也叫`依赖注入（DI）`。我在{% post_path /Users/didi/Documents/development/blog/source/_posts/Spring:白话一下IoC.md %}和{% post_link Spring-简单摆弄一下SpringIoC容器 %}两篇文章中简单描述了IoC是什么和Spring的IoC相关使用方式，本篇简单谈一下IoC的另一层意思——依赖注入（DI）

<!-- more -->

## 依赖是什么
说到`依赖`，可能会联想到`人对金钱的依赖`、`小孩子对父母的依赖`、`鱼儿对水的依赖`等，在这些依赖关系当中，有`强依赖`也有`弱依赖`，只要`事物A`在doSomething的时候需要另一个`事物B`参与其中，就称`事物A事物B`，也可以称`事物B是事物A的依赖项`。在软件系统中，`依赖性`体现的更为明显，因为任何一个系统都是由若干个系统模块组成，而每一个模块又由若干个类或函数组成。类与类之间会存在`关联`、`继承`和`实现`关系，而模块与模块之间也彼此耦合进行数据通信或行为交互。

在面向对象的软件系统中，`OrderService`（订单类）需要调用`ProductService`（产品类）获取产品价格信息。通常情况，我们会在`OrderService`中实例化`ProductService`的对象，然后调用`ProductService`对象的方法获取数据。样例代码如下
```java

public class OrderService{
    public Long getProcuctPrice(String productId){
        ProductService productService = new ProductService();
        return productService.getPrictByProductId(productId);
    }
}

public class ProductService{
    public Long getPrictByProductId(String productId){
        // do something
    }
}

```
上面代码虽然可以实现功能，但是违背了`依赖倒置原则`和`开闭原则`。前者比较好判断，因为在上述代码`getProcuctPrice`方法中使用`new`操作符创建了`ProductService`实例的对象，在`依赖倒置原则`设计原则的定义中明确指出`依赖于抽象，而不要依赖具体实现`。而后者`开闭原则`指的是`对扩展开放，对修改关闭`，即便采用接口来定义依赖的类型，如果有一天对于`ProductService`的依赖有变动，该方法仍然需要改动。那么面对上述这种情况，难道就无解了么？

## 依赖注入
`依赖注入`（Dependency Injection，简称DI）的思想，是将对象的实例化时机和实例化过程交由`容器`管理，并且对象所需的依赖，在`容器`实例化对象后会自动注入给对象。`依赖注入`只需引入一个所谓的`容器`，即可以降低代码耦合，提升代码的复用率，代码中几乎不用出现一行`new`对象的代码，而是去指定`我需要什么`，容器就会在启动时自动为你注入。而且，注入什么？什么之后注入？以什么方式注入？这些都是可配置的。是不是感觉爽了很多！

Spring框架已经为我们提供了`IoC容器`，并且为我们提供了`基于构造函数的依赖注入`和`基于属性Setter方法的起来注入`两种依赖注入方式，下面分别聊下这两种依赖注入方式各自的优势和不足。

### 基于构造函数的依赖注入

`基于构造函数的依赖注入`又称`构造注入`，若配置`ClassA`以构造注入的方式配置`ClassB`为其依赖项，则`容器`会在为`ClassA`注入依赖项之前，首先实例化`ClassB`对象，然后以`ClassB`对象为参数调用`ClassA`的某个合适的构造函数实例化`ClassA`对象，即以`ClassB`对象作为`ClassA`构造函数参数实例化`ClassA`对象。Java代码如下

```java
public class ClassA{
    private ClassB b;
    private String name;

    public ClassA(ClassB b){
        this.b = b;
        this.name = "";
    }

    public ClassA(ClassB b, String name){
        this.b = b;
        this.name = name;
    }
}

public class ClassB{
    // do something
}
```

容器在使用构造注入，为对象注入外部依赖时，是根据构造函数的参数类型进行自动匹配的，这也不难理解，在Java中区分方法的方式为`方法名称、方法参数列表的个数、类型和顺序不同`。
在Spring配置元数据中，在`<bean>`元素内部使用`<constructor-arg>`标签指定该Bean的构造函数参数，例如：
```xml
<beans>
    <bean id="classA" class="cc.chenzhihao.ClassA">
        <constructor-arg ref="classB">
        <constructor-arg value="理想">
    </bean>

    <bean id="classB" class="cc.chenzhihao.ClassB"/>
</beans>
```
- `ref` 指定依赖Bean实例的名称，该Bean实例可以当前容器定义，也可以是父容器或其祖先容器中的某个Bean。
- `value` 提供字面值，如果参数对应的类型为`基本数据类型`或`基本数据类型的包装类型`，Spring会自动注入

按以上Java代码和配置，容器会自动识别并调用`ClassA`中签名为`public ClassA(ClassB b, String name)`的构造函数，`<constructor-arg>`标签还提供了更多参数来更准确的完成参数配置

- `type` 指定参数类型，值为全限定类型名称，按类型匹配。eg：`<constructor-arg type="java.lang.String" value="chenzhihao">`
- `name` 指定参数名称。eg: `<constructor-arg name="age" value="25">`
- `index` 指定参数位置，从0开始。eg: `<constructor-arg index="0" value="25">`

### 基于Setter方法的依赖注入
`基于Setter的构造注入`简称`setter注入`，是Bean对象在通过`基于构造函数构造函数`或`基于静态/实例工厂`实例化后，以依赖项对象作为参数，调用属性的Setter方法，将依赖项注入进Bean对象的过程。代码如下
Java代码
```java
public class ClassA{
    private String name;
    private ClassB b;

    public void setB(ClassB b){
        this.b = b;
    }
    public void setName(String name){
        this.name = name;
    }
}
public class ClassB{
    // do something
}
```
Spring配置
```xml
<beans>
    <bean id="classA" class="cc.chenzhihao.ClassA">
        <property name="name" value="理想">
        <property name="b" ref="classB">
    </bean>

    <bean id="classB" class="cc.chenzhihao.ClassB"/>
</beans>
```
通过为`<bean>`提供`<property>`标签，指定参数。IoC容器在执行依赖项注入时，会通过属性名识别Setter方法名。`ref`和`value`参数同`constructor-arg`标签。

### 构造注入 vs Setter注入

| #          | 构造注入            | Setter注入     |
| ---------- | ------------------- | -------------- |
| 推荐性     | 官方推荐            | 官方不推荐     |
| 注入时机   | Bean实例化之前      | Bean实例化之后 |
| 属性完整性 | 完整                | 不完整         |
| 配置方式   | `<constructor-arg>` | `<property>`   |

Spring框架做的足够优雅，以至于可以让`构造注入`和`Setter注入`混用。官方推荐将构造注入用于Bean的强依赖项注入，将Setter注入用作Bean的可选依赖项注入，虽然Setter注入是在Bean实例化之后进行，但是也可以使用`@Required`注解标注某个属性为`必填项`。但是尽管如此，Spring官方团队还是建议开发者使用`构造注入`，因为它可以使开发者将应用程序的组件定义为`不可变对象`，并且确保Bean所需的所有外部依赖均不为null，此外，Bean的依赖项在注入Bean对象之前，总是会被IoC容器预先实例化，这使得Bean被返回给客户端的时候总是以`完全初始化的方式返回`。如果某些情况下，Bean的依赖项很多，此时选用`构造注入`，将会给构造函数添加许多局部变量，导致构造函数参数列表爆炸，但这种情况也表示当前这个类承担了太多的责任，应当视情况进行类的职责拆分，以满足设计原则中的`单一职责`原则。由于Setter注入主要是对Bean的可选依赖项进行注入，建议在开发的过程中为属性预先提供默认值，不然，在使用Bean的时候，一定要对Bean的依赖项进行非空检查，因为我没办法知道Bean的依赖项是否已经被IoC容器在初始化的时候注入到Bean。但是Setter注入的一个好处就是，属性的Setter方法可以使该Bean的对象在初始化以后，使用新的依赖项替换现有依赖项。
具体`构造注入`和`Setter注入`哪个更好，浏览一下Spring社区，各持己见，褒贬不一。我觉得还得从实际使用场景来选择，例如在使用一个为开源的工具包时，工具包仅说明某工具类提供了某个构造方法进行对象实例化，并未提供Setter方法，那这种情况就只能使用构造注入。

### 循环依赖问题
`循环依赖`问题一般发生在使用`构造注入`的场景。如下配置：
Java代码
```java
public class ClassA {
    private ClassB classB;

    public ClassA(ClassB classB) {
        this.classB = classB;
    }
}
public class ClassB {
    private ClassA classA;

    public ClassB(ClassA classA) {
        this.classA = classA;
    }
}

```

Spring配置
```xml
    <bean id="classA" class="cc.chenzhihao.pandora.bean.ClassA">
        <constructor-arg ref="classB"/>
    </bean>

    <bean id="classB" class="cc.chenzhihao.pandora.bean.ClassB">
        <constructor-arg ref="classA"/>
    </bean>
```

在Spring容器启动阶段，通过读取提供的配置元数据进行Spring容器初始化，在初始化过程中，对SpringIoC容器维护的Bean清单进行自检，检测该清单上的依赖项，如果发现`ClassA`和`ClassB`相互依赖，并且使用的是构造注入，就会抛出`BeanCurrentlyInCreationException`异常，并且会提示如下信息
> Error creating bean with name 'classA': Requested bean is currently in creation: Is there an unresolvable circular reference?

Spring检测到`ClassA`和`ClassB`相互依赖关系，并且由于都是强依赖，SpringIoC懵逼了，咋搞嘞？搞不定，算了，抛异常吧。这是个典型的`先有鸡还是先有蛋的问题`。因为这是致命问题，所以必须在SpringIoC容器启动时进行检测。那如果真实的使用场景必须实现`ClassA`和`ClassB`的相互依赖关系该怎么办呢？其实这和Java并发模型中的死锁模型很相似，死锁产生的原因就是两个线程各自持有一个锁不肯放，还依赖对方手里的锁进行解锁，这时候就掐架了。一种解决方案就是，修改其中一个类的代码，将`构造注入变为Setter注入`，并将另一个使用构造注入的Bean设置为`懒加载`（lazy-init），虽然官方不推荐这么做，但是使用这个方式确实可以解决循环依赖的问题，原因就是Setter注入是在Bean实例化后进行，而懒加载配置又使得Bean不在IoC容器初始化时实例化，尽在首次被调用时才实例化。如下配置：

Java代码
```java
public class ClassA {
    private ClassB classB;

    public ClassA(ClassB classB) {
        this.classB = classB;
    }
}
public class ClassB {
    private ClassA classA;

    public void setClassA(ClassA classA) {
        this.classA = classA;
    }
}

```

Spring配置
```xml
    <bean id="classA" class="cc.chenzhihao.pandora.bean.ClassA" lazy-init="true">
        <constructor-arg ref="classB"/>
    </bean>

    <bean id="classB" class="cc.chenzhihao.pandora.bean.ClassB">
        <property name="classA" ref="classA"/>
    </bean>
```
Spring启动日志
```log
1. 17:58:16,066 DEBUG main xml.XmlBeanDefinitionReader:224 - Loaded 2 bean definitions from location pattern [application-context.xml]
2. 17:58:16,227 DEBUG main support.DefaultListableBeanFactory:725 - Pre-instantiating singletons in org.springframework.beans.factory.support.DefaultListableBeanFactory@481a996b: defining beans [classA,classB]; root of factory hierarchy
3. 17:58:16,229 DEBUG main support.DefaultListableBeanFactory:221 - Creating shared instance of singleton bean 'classB'
4. 17:58:16,229 DEBUG main support.DefaultListableBeanFactory:447 - Creating instance of bean 'classB'
5. 17:58:16,254 DEBUG main support.DefaultListableBeanFactory:537 - Eagerly caching bean 'classB' to allow for resolving potential circular references
6. 17:58:16,257 DEBUG main support.DefaultListableBeanFactory:221 - Creating shared instance of singleton bean 'classA'
7. 17:58:16,257 DEBUG main support.DefaultListableBeanFactory:447 - Creating instance of bean 'classA'
8. 17:58:16,261 DEBUG main support.DefaultListableBeanFactory:247 - Returning eagerly cached instance of singleton bean 'classB' that is not fully initialized yet - a consequence of a circular reference
9. 17:58:16,290 DEBUG main support.DefaultListableBeanFactory:537 - Eagerly caching bean 'classA' to allow for resolving potential circular references
10. 17:58:16,316 DEBUG main support.DefaultListableBeanFactory:483 - Finished creating instance of bean 'classA'
11. 17:58:16,409 DEBUG main support.DefaultListableBeanFactory:483 - Finished creating instance of bean 'classB'
12. 17:58:16,412 DEBUG main support.DefaultListableBeanFactory:251 - Returning cached instance of singleton bean 'lifecycleProcessor'
13. 17:58:16,418 DEBUG main support.DefaultListableBeanFactory:251 - Returning cached instance of singleton bean 'classA'
14. 17:58:16,419 DEBUG main support.DefaultListableBeanFactory:251 - Returning cached instance of singleton bean 'classB'
```
分析Spring容器启动日志发现，在IoC容器启动时，先以单例作用域创建名为`classB`的Bean,因在`classB`中`classA`属性为可选依赖，则可以预先实例化，实例化后将其放入高速缓存当中，此时`classB`的实例化并未完成，暂时停止。由于`classB`中有对`classA`的依赖，此时对`classA`进行实例化，而因`classA`中对`classB`的依赖，早在实例化`classA`之前实例化好了，所以直接从高速缓存中取`classB`对象，注意第8行，Spring已经打印出了日志，告知因为发现了循环引用，所以此时的`classB`从高速缓存中返回。最后在`classA`以单例作用于实例化完成后，`classA`与`classB`全部完成实例化。而第12，13，14是客户端操作IoC容器获取Bean对象的日志信息。以上涉及到的`Bean作用域`、`懒加载`等，以后再写几篇慢慢补充

## 总结
本篇简单总结了一下Spring依赖注入的两种配置方式——`构造注入`和`Setter注入`，以及两中方式的优缺点对比。
`构造注入`
- 为强依赖项提供依赖注入配置
- 优点：可以实现Bean为不可变对象、且客户端拿到的Bean是完整的、官方推荐
- 缺点：可能产生循环依赖问题、依赖过多导致构造函数参数个数增加

`Setter注入`
- 为可选依赖项提供注入配置
- 优点：在Bean实例化后进行可提供依赖的替换、不会出现循环依赖问题
- 缺点：客户端拿到的对象可能是不完整的，需要进行依赖项判空检查

无论是`构造注入`还是`Setter注入`，都各有利弊。任何事情都需要从两方面看，工程师可以利用技术和工具完成项目需求，但技术和工具往往都是`双刃剑`，在使用的过程中一定要根据使用场景进行技术选型，有些技术在某些特定的业务场景下就不适用，而有的虽然不是主流，但仍可以在某些场景解决某些实际问题。
