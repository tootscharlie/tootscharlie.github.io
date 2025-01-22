---
published: false
title: Spring-属性注入那点事儿
date: 2019-12-09 10:26:41
categories: 技术
tags: Spring
---
依赖注入（DI）是Spring容器的核心，其为容器中的Bean管理外部依赖的配置、实例化和组装，在适当的时候将Bean的外部依赖注入进Bean对象内部。本篇总结一下Bean属性（或依赖）注入配置的其他方式，例如：如何配置`java.lang.List`、`java.lang.Map`、`java.lang.Set`或`java.lang.Properties`等集合元素的注入方式。

<!--more-->

## 唠叨唠叨
上一篇{% post_link Spring-浅谈依赖注入 %}简单总结了一下使用Spring IoC容器提供的`构造注入`与`Setter注入`配置Bean的依赖注入，其中有涉及到`<property>`和`<ref>`等标签的时候留了个坑，本篇总结一下`字面值`或`依赖项`的依赖配置细节。

## 注入字面值
字面值是指在配置中使用字符串将语义化的信息直接填写到配置文件中，在IoC容器启动并执行Bean的DI过程时，自动将该值设置仅Bean对应的属性中，大多数使用场景是`调用属性的Setter方法`进行值的设置。样例代码如下：
创建一个`Person`类，指定`name`属性抽象描述人的姓名，并添加该属性的访问器方法。
```java
package cc.chenzhihao;
public class Person {
    
    private String name;
    
    public Person(){
        System.out.println("构造函数被调用");
    }

    public void setName(String name){
        System.out.println("Setter方法被调用。name=" + name);
        this.name = name;
    }

    public String getName(){
        return this.name;
    }

    // 省略toString方法
}
```
接下来，在Spring配置文件中，配置该`Person`类的配置元数据，指定`id`属性为`chenzhihao`作为Bean的名称，`class`属性指定Bean的类型，并使用子标签`<property>`为`name`属性赋值。
```xml
<bean id="chenzhihao" class="cc.chenzhihao.Person">
    <property name="name" value="陈志昊">
</bean>
```
创建IoC容器，指定配置元数据。

```java
ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("application-context.xml");
Person chenzhihao = context.getBean("chenzhihao", Person.class);
System.out.println(chenzhihao);
```

以下为启动日志，分析一下属性的设置过程。PS：`<!--注释内容-->`非日志打印，而是为解释该注释的下一行日志所用。
```log
1. 10:56:08,958 DEBUG main xml.DefaultBeanDefinitionDocumentReader:92 - Loading bean definitions
2. 10:56:08,999 DEBUG main xml.XmlBeanDefinitionReader:224 - Loaded 1 bean definitions from location pattern [application-context.xml]
<!-- 由于名为chenzhihao的Bean默认被配置为Singleton（单例）scope，在容器加载完Bean定义之后，会以同步加锁的方式（synchronized）预先实例化所有单例所用于的Bean，并将其放入高速缓存当中。Bean作用于以后再说 -->
3. 10:56:09,314 DEBUG main support.DefaultListableBeanFactory:725 - Pre-instantiating singletons in org.springframework.beans.factory.support.DefaultListableBeanFactory@2145b572: defining beans [chenzhihao]; root of factory hierarchy
<!-- 尝试以单例作用于方式创建该Bean。若已创建则直接从单例Bean高速缓存获取，否则创建新的实例（第5行）并放入单例Bean高速缓存 -->
4. 10:56:09,316 DEBUG main support.DefaultListableBeanFactory:221 - Creating shared instance of singleton bean 'chenzhihao'
<!-- 由于初始化时，单例Bean高速缓存没有名为chenzhihao的Bean，所以以反射的方式调用默认无参构造函数实例化对象 -->
5. 10:56:09,316 DEBUG main support.DefaultListableBeanFactory:447 - Creating instance of bean 'chenzhihao'
<!-- 输出日志信息，表示构造函数被IoC容器调用 -->
6. 构造函数被调用
<!-- 创建完Bean之后，将其放入缓存中。此举可以解决潜在的循环依赖问题。 -->
7. 10:56:09,475 DEBUG main support.DefaultListableBeanFactory:537 - Eagerly caching bean 'chenzhihao' to allow for resolving potential circular references
<!-- 容器调用Bean对象的'name'属性的Setter方法，赋值 -->
8. setter方法被调用。name=陈志昊
9. 10:56:09,567 DEBUG main support.DefaultListableBeanFactory:483 - Finished creating instance of bean 'chenzhihao'
<!-- 以下为客户端获取Bean的日志打印 -->
10. 10:56:09,571 DEBUG main support.DefaultListableBeanFactory:251 - Returning cached instance of singleton bean 'lifecycleProcessor'
11. 10:56:09,582 DEBUG main support.DefaultListableBeanFactory:251 - Returning cached instance of singleton bean 'chenzhihao'
<!-- toString方法 -->
12. Person(name=陈志昊)
```

## 注入依赖项

前几篇文章在提到依赖注入的时候，使用了`<ref>`标签，该标签会引用当前容器或其父容器中指定的Bean。例如：若要为某个Bean的`target`属性指定另一个名为`sourceTarget`Bean的引用，则只需按如下配置：
```xml
<property name="target">
    <ref bean="sourceTarget">
</property>
```
`ref`标签的`bean`属性表示对一个Bean名称的指定，他可以是某个Bean的`id`属性，也可以是某个Bean`name`属性中的一个。当然，如果你指向引用当前容器父容器或祖先容器中的Bean，则必须为`ref`标签指`parent`属性，并将其值设置为父容器Bean的名称。

## 注入集合
Spring支持对Bean的集合类型的属性注入元素内容，并且支持`父子Bean`同一类型、同一名称集合属性的自动`合并`操作。在JDK7.0版本之后，Java集合框架引入了`泛型`特性，Spring可以自动识别基于八大基本数据类型包装器类型的泛型集合类型属性，并尝试通过Spring框架默认的`属性编辑器`对配置元数据中提供的字面值做响应的类型转换并赋值。Spring目前支持以`<list/>`、`<set/>`、`<map/>`和 `<props/>`标签分别对`List`、`Set`、`Map`和`Properties`类型对象进行属性注入。

### 注入List
若类`User`有一个类型为`List<String>`的属性`tags`，该属性被定义为用户的标签，在Bean实例化是需要通过配置元数据注入默认的用户标签`A`、`B`和`C`。代码如下：
创建`User`类
```java
public class User {

    private List<String> tag;

    // 省略Getter、Setter和toString方法
}
```
在Spring配置文件中提供`User`类Bean的配置元数据
```xml
<bean id="user" class="cc.chenzhihao.User">
    <property name="tag">
        <list>
            <value>A</value>
            <value>B</value>
            <value>C</value>
        </list>
    </property>
</bean>
```
通过为`<property>`标签指定`<list>-<value>`子标签，即可对`List`类型的属性进行赋值。Spring默认会实例化一个`java.Util.ArrayList`对象包装提供的值，并将其赋给Bean属性。

- `<list>`标签属性
  - `value-type`: 指定所有集合元素的类型，属性值为类型全限定类名字符串。eg：java.lang.String
  - `merge`: 如果当前Bean被配置为`父子Bean`，若merge属性被配置为`true`，则会进行属性合并。
- `<value>`标签属性
  - `type`: 指定该元素的类型，属性值同`<list>`标签`value-type`属性。

上面的小例子中，集合元素的类型为`String`，Spring会自动识别该类型。当然也可以通过指定`<list>`标签的`value-type`属性，提供以全限定类名的方式指定集合元素值的类型；或也可以通过指定`<value>`元素`type`属性指定集合中单个元素的类型。`List`标签的`value-type`属性和`<value>`标签的`type`属性所指定的类型必须满足对应Bean属性的泛型类型约束，若将其指定为`java.lang.StringBuffer`，否则将会抛出`IllegalStateException`异常，并提示开发者正在尝试转换不兼容的类型，并且Spring会友好的提示开发者在这种情况下，可以尝试提供`属性编辑器`（PropertyEditor）。属性编辑器以后再说。
```
java.lang.IllegalStateException: Cannot convert value of type 'java.lang.String' to required type 'java.lang.StringBuffer': no matching editors or conversion strategy found
```

### 注入Set
若将上述`User`类中`tag`属性的类型改为`Set<String>`，依据Java`Set`对象的元素唯一性要求，该类型属性中不会出现重复值。
将上述`User`类中`tag`属性的类型改为`Set<String>`，并修改相关代码：
User类
```java
public class User {

    private Set<String> tag;

    // 省略Getter、Setter和toString方法
}
```
配置文件：
```xml
<bean id="user" class="cc.chenzhihao.User">
    <property name="tag">
        <set>
            <value>A</value>
            <value>B</value>
            <value>C</value>
        </set>
    </property>
</bean>
```
当使用`<set>`标签为`Set`类型属性注入元素时，通过`<value>`标签填充元素。Spring会默认实例化一个`LinkedHashSet`集合对象封装元素信息。因为Set不允许出现重复值，当配置的元素中有重复元素时，将会被过滤。
- `<set>`标签属性
  - `value-type`: 指定所有集合元素的类型，属性值为类型全限定类名字符串。eg：java.lang.String
  - `merge`: 如果当前Bean被配置为`父子Bean`，若merge属性被配置为`true`，则会进行属性合并。
- `<value>`标签属性
  - `type`: 指定该元素的类型，属性值同`<set>`标签`value-type`属性。

对于`<set>`标签`value-type`属性和`<value>`标签`type`，若没有满足对应Bean集合类型属性泛型约束时，同`注入List`一样会抛出`IllegalStateException`异常。

### 注入Map
当需要为Bean对象`Map`类型的属性注入元素时，例如如下代码：
```java
public class User{
    private Map<String, Object> infoMap;
    
    //省略Getter和Setter方法
}
```
`User`类中有一个`Map<String, Object>`类型的属性`infoMap`，其内部元素key类型为`String`，value类型为`Object`，即可以接收任意类型的值。通过配置文件，指定`name`和`age`属性，分别为`陈志昊`和`20`
```xml
<bean id="user" class="cc.chenzhihao.User">
    <property name="infoMap">
        <map>
            <entry key="name" value="陈志昊"/>
            <entry key="age" value="20"/>
        </map>
    </property>
</bean>
```
通过为`<property>`标签指定`<map>-<entry>`子标签配置Map类型属性注入。在默认情况下，Spring会为`infoMap`属性注入一个`java.util.LinkedHashMap`对象，并将要注入的元素包裹在其中。以下是相关标签的属性介绍

- `<map>`标签
  - `key-type`: 键的类型
  - `value-type`: 值的类型
  - `merge`: 如果当前Bean被配置为`父子Bean`，若merge属性被配置为`true`，则会进行属性合并。
- `<entry>`标签
  - `key`：指定键的字面值
  - `value`：指定值的字面值
  - `value-type`：指定`value`值的时实际类型，值为类型的全限定类名
  - `key-ref`：通过指定一个Bean名称（Bean的id或name属性），引用一个Bean对象，作为元素的键
  - `value-ref`：通过指定一个Bean名称（Bean的id或name属性），引用一个Bean对象，作为元素的值

对于`<map>`标签的`value-type`、`<entry>`标签的`value-type`若类型不符合对应Bean属性的集合泛型类型约束时，将会抛出`IllegalStateException`异常。并且可以通过`key-ref`和`value-ref`标签指定Bean对象作为键和值的实际对象，若对应Bean定义不存在，则会抛异常。

> NOTE
> 若对应属性的类型为`Map<String, Object>`，像上述例子中`infoMap`属性，值的类型约束为`Object`，即任意类型。若在Bean的实际定义中未指定值的实际类型，则Spring IoC容器在对值进行处理的时候，会默认将字面值（`<value>`）转换为`String`类型进行赋值。通过调用值的`getClass()`方法即可得知。

### 注入Properties
当向Bean对象中类型为`java.util.Properties`的属性注入元素时，可以在`<property>`标签中指定`<props>-<prop>`组合标签为该类型的属性进行赋值，在Spring IoC容器初始化时，会默认为属性注入`java.util.Properties`对象实例，并将元素信息包裹在其中。样例代码如下：
Java代码：

```java
public class User{
    private Properties infoProps;
    // 省略Getter和Setter方法
}
```
Spring配置文件
```xml
 <bean id="user" class="cc.chenzhihao.User">
    <property name="infoProps">
        <props>
            <prop key="name">陈志昊</prop>
            <prop key="age">25</prop>
        </props>
    </property>
</bean>
```
以下分别对`<props>`和`<prop>`标签的属性描述

- `<props>`标签
  - `value-type`：指定`value`值的时实际类型，值为类型的全限定类名
  - `merge`: 如果当前Bean被配置为`父子Bean`，若merge属性被配置为`true`，则会进行属性合并。
- `<prop>`标签
  - `key`: 属性名，字符串类型，在配置中以字面值作为实际配置值

### 集合合并（merge）
Spring提供了对以上四种常见集合类型元素注入的配置，并且以上四种配置中都提到了`merge`属性，该属性名直译为“合并”，实际功能也指的是集合属性元素的合并，`默认不合并`。但此合并并非集合属性本身进行元素合并，而是在基于`父-子Bean`模型中，若`父Bean`和`子Bean`都定义了同名属性，并且在子Bean中开启了`merge`属性，即`merge=true`，Spring IoC容器就会尝试使用子Bean中该属性与父Bean同名属性做覆盖操作，当然此操作可以正常执行的前提是`父子Bean`中该属性是同一类型，换句话说，不能将`父子Bean`中同名不同类型的属性进行merge操作，此举会引发异常。默认情况下，在合并的过程中，都是`子Bean`对`父Bean`的属性进行覆盖或元素的追加。
先创建一个父类`Father`和子类`Sun`，`Sun`继承`Father`。
```java
public class Futher {
    // 定义父类属性信息
}

public class Sun extends Futher{
    // 定义子类属性信息
}
```

#### Merge List
修改`Futher`和`Sun`类，将`List<String> tags`属性分别添加进上述两个类中。
```java
public class Futher {
    private List<String> tags;
    // 省略访问器和toStrig方法
}

public class Sun extends Futher{
    private List<String> tags;
    // 省略访问器和toStrig方法
}
```
修改Spring配置文件，添加`Futher`和`Sun`类Bean配置元数据。通过指定子类Bean`<bean>`标签`parent`属性来指定该Bean的父类Bean（该属性的值可以是父类Bean的`id`属性，也可以是`name`属性中的一个，总之能唯一确定一个Bean就行。`父子Bean`相关，后续再说）。在子类Bean要执行覆盖的属性的标签上指定`merge="true"`，开启覆盖模式。对于`List`，Spring在处理的时候会将`子Bean`的元素追加到`父Bean`元素的后边。
```xml
<!-- 父类 -->
<bean id="father" class="cc.chenzhihao.pandora.bean.Father">
    <property name="tags">
        <list>
            <value>A</value>
            <value>B</value>
            <value>C</value>
        </list>
    </property>
</bean>

<!-- 子类 -->
<bean id="sun" class="cc.chenzhihao.pandora.bean.Sun" parent="father">
    <property name="tags">
        <list merge="true">
            <value>A</value>
            <value>D</value>
            <value>E</value>
        </list>
    </property>
</bean>
```
默认情况下，对于List的merge操作，子类最终的元素内容，将会是取子类追加到父类之后的结果，即`父类元素的顺序优先于子类元素的顺序`，默认情况下，Spring保持了List元素的顺序——子类元素在父类元素之后，父类和子类集合各自属性中的元素顺序保持不变。
上述例子中，子类中`tags`属性最终值为：[A, B, C, A, D, E]

#### Merge Set
由于`Set`的元素唯一性语义所致，无论是在Bean初始化配置时还是父子Bean属性合并时，最终集合内不会出现重复的元素。具体配置如下
修改`Futher`和`Sun`类，将`Set<String> tags`属性分别添加进上述两个类中。
```java
public class Futher {
    private Set<String> tags;
    // 省略访问器和toStrig方法
}

public class Sun extends Futher{
    private Set<String> tags;
    // 省略访问器和toStrig方法
}
```
修改Spring配置文件
```xml
<!-- 父类 -->
<bean id="father" class="cc.chenzhihao.pandora.bean.Father">
    <property name="tags">
        <set>
            <value>A</value>
            <value>B</value>
            <value>C</value>
        </set>
    </property>
</bean>

<!-- 子类 -->
<bean id="sun" class="cc.chenzhihao.pandora.bean.Sun" parent="father">
    <property name="tags">
        <set merge="true">
            <value>A</value>
            <value>D</value>
            <value>E</value>
        </set>
    </property>
</bean>
```
在SpringIoC处理的过程中，使用子类的元素填充或覆盖父类的元素，在`Set`类型属性的赋值中，若子类出现了与父类相同的元素，则会忽略子类中同名的元素，保留父类的，并且顺序与`List`相同。最终子Bean中的`tags`属性元素为：[A, B, C, D, E]

#### Merge Map
修改`Futher`和`Sun`类，将`Map<String, Object> info`属性分别添加进上述两个类中。
```java
public class Futher {
    private Map<String, Object> info;
    // 省略访问器和toStrig方法
}

public class Sun extends Futher{
    private Map<String, Object> info;
    // 省略访问器和toStrig方法
}
```
修改Spring配置文件
```xml
<!-- 父类 -->
<bean id="father" class="cc.chenzhihao.Father">
    <property name="info">
        <map>
            <entry key="name" value="陈志昊"/>
            <entry key="age" value="18"/>
        </map>
    </property>
</bean>

<!-- 子类 -->
<bean id="sun" class="cc.chenzhihao.Sun" parent="father">
    <property name="info">
        <map merge="true">
            <entry key="age" value="20"/>
            <entry key="city" value="辽宁-丹东"/>
        </map>
    </property>
</bean>
```
对于Map来说，子类将会覆盖父类Map中的属性值，若没有，则会进行追加操作。Map本身为Hash结构，Hash结构的元素顺序取决于元素经过Hash之后落在的Bucket的位置，但是Spring对于Map属性的注入时，为了最大程度保证配置顺序和运行顺序一致，使用`java.util.LinkedHashMap`对象包装属性，由于`LinkedHashMap`本身维护了遍历`按插入顺序遍历`和按`访问顺序遍历`两种模式，使得`LinkedHashMap`元素本身可以实现有序化，在Spring中，采用的`LinkedHashMap`的`按插入顺序遍历`。以下是Spring源码`org.springframework.beans.factory.config.MapFactoryBean#createInstance`方法中，对于Map类型属性的注入操作的代码：
```java
protected Map<Object, Object> createInstance() {
    if (this.sourceMap == null) {
        throw new IllegalArgumentException("'sourceMap' is required");
    }
    // 以下为获取Bean对应属性Map的类型，若类型不是`java.util.Map`（即手动指定Map的类型，eg：HashMap），则直接实例化。
    // 否则，默认实例化一个`LinkedHashMap`对象，并且accessOrder参数已默认形式初始化，即遍历顺序=插入顺序
    Map<Object, Object> result = null;
    if (this.targetMapClass != null) {
        result = BeanUtils.instantiateClass(this.targetMapClass);
    }
    else {
        result = new LinkedHashMap<Object, Object>(this.sourceMap.size());
    }
    // 省略其他代码~
}
```

则上述例子中，子类Bean`sun`的`info`属性为：{name=陈志昊, age=20, city=辽宁-丹东}
#### Merge Properties
由于`Properties`与`Map`的结构与配置方式大致相同，因此这块只粘贴源码和结果。
修改`Futher`和`Sun`类，将`Map<String, Object> info`属性分别添加进上述两个类中。
```java
public class Futher {
    private Properties info;
    // 省略访问器和toStrig方法
}

public class Sun extends Futher{
    private Properties info;
    // 省略访问器和toStrig方法
}
```
修改Spring配置文件
```xml
<!-- 父类 -->
<bean id="father" class="cc.chenzhihao.Father">
    <property name="info">
        <props>
            <prop key="name">陈志昊</prop>
            <prop key="age">18</prop>
        </props>
    </property>
</bean>

<!-- 子类 -->
<bean id="sun" class="cc.chenzhihao.Sun" parent="father">
    <property name="info">
        <props merge="true">
            <prop key="age">20</prop>
            <prop key="city">辽宁-丹东</prop>
        </props>
    </property>
</bean>
```
则上述例子中，子类Bean`sun`的`info`属性为：{age=20, name=陈志昊, city=辽宁-丹东}

## 注入内部Bean

Spring提供一个比较方便的方式，允许在Spring配置文件中，为一个Bean的属性值赋予一个`匿名内部Bean`，这个操作相当于Java中的匿名内部类一样。配置样例代码如下：
```xml
<bean id="outer" class="...">
    <property name="target">
        <bean class="cc.chenzhihao.Person">
            <property name="name" value="陈志昊"/>
            <property name="age" value="20"/>
        </bean>
    </property>
</bean>
```
以上配置文件，为`outer`Bean的`target`属性提供了一个类型为`cc.chenzhihao.Person`的Bean实例，该内部Bean在配置时同其他Bean一样配置，只不过对于内部Bean来说，没有Bean命名一说，如果指定了`id`或`name`属性，Spring IoC容器在初始化该Bean时也不会为其指定名字。容器也会忽略内部Bean的作用域，因为内部Bean始终是匿名的，并且始终与外部Bean一起创建。 

## 注入空字符串和NULL

当要对字符串属性注入空串（`""`）时，或对属性本身设置为`null`，则可以对属性进行如下配置。

### 设置空串
以下配置，将对Bean的`email`属性设置为空字符串，而并非`null`。 
```xml
<property name="email" value=""/>
```

### 设置NULL
以下配置，将对Bean的`email`属性设置为`null`。 
```xml
<property name="email">
    <null/>
</property>
```

## 总结
本篇总结了一下Spring支持的Bean属性注入类型，以及对应类型的注入配置方式，其中用到的最多的是`注入字面值`、`注入依赖项`和`注入集合`。在企业引用中，`注入字面值`的配置方式往往不常用，而是在IoC容器配置文件中提供`PreferencesPlaceholderConfigurer`对象配置，注入外部配置属性文件，通过对Spring配置文件中应用字面值注入的地方提供属性名称占位符的方式，注入外部属性配置信息。这样的好处是，可以通过运行环境的不同，自动打包装配对应环境的配置信息（例如：数据库配置、加密秘钥等）。
而需要注意的是，对属性值注入`空串`和注入`NULL`值，Spring采取的是`""`表示空串，`<null/>`表示null值，而`"null"`只表示字面值null。
