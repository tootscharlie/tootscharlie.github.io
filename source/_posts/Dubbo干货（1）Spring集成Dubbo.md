---
published: false
title: Dubbo干货（1）Spring集成Dubbo
date: 2019-05-26 13:25:28
categories: 技术
tags: dubbo
---

![dubbo](/images/TB1lrnCkXzqK1RjSZFCXXbbxVXa-1340-328-1024x251.png)

<!--more-->

## 前置条件

熟悉Spring开发和配置。

Dubbo官网学习地址：[点击学习](https://dubbo.apache.org/zh-cn/)

## 环境准备

开发软件：IDEA 2019

JDK：1.8

Spring全家桶：4.3.24.RELEAS

Dubbo：2.5.7（[阿里巴巴](https://mvnrepository.com/artifact/com.alibaba/dubbo)）

Zookeeper：3.4.14

zkclient：0.11

slf4j-log4j12

## 安装&启动Zookeeper
下载Zookeeper（[点击进入清华Zookeeper镜像站](https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/)），解压到本地目录，进入`解压目录/bin`，双击`zkServer.cmd`（通过cmd命令行界面执行）。Unix系统同学请执行 `zkServer.sh` 脚本文件。执行后，命令行界面如下则表示启动成功。
![zookeeper](/images/zookeeper.png)

## 创建learnDemo项目

创建learnDemo项目，new project如图，填写artifactId、groupId、moduleName和项目地址，完成父项目创建。
![1](/images/新建项目.png)

![2](/images/2.png)

![3](/images/3.png)

新建项目后，修改pom文件，添加相关依赖的配置，供子Module使用，避免重复配置。

## 创建provider-api

因为服务提供者（Provider）需要暴露服务API接口给服务消费者（Consumer），生产环境需要将Provider项目中包含暴露服务API的jar包发布（例如：Maven仓库）供消费者使用。这里将生产者和消费者做在一个项目内，使用不同的Module拆分，将Provider的API单独创建一个Module，由Provider和Consumer分别引用。

新建Module，如图创建provider-api模块：
![1](/images/api1.png)

![2](/images/api2.png)

![3](/images/api3.png)

在provider-api模块中新建`server`包，在包下创建接口 `ITestService`，用于定义Provider服务提供的功能定义。

```java
package server;
 
public interface ITestService {
 
    String hello(String data);
 
}
```
## 创建provider

### 第一步，新建模块

创建生产者。新建Module，如图创建provider模块：

注：这里创建的是web项目，建议选择`maven-archetype-webapp` 模板，会自动生成 `web`目录。如果不选择， 也可以创建Maven项目，手动创建相关目录并进行配置。

![4](/images/4.png)

![5](/images/5.png)

![6](/images/6.png)

![7](/images/7.png)

### 第二步，添加api模块依赖

修改provider项目pom文件，添加对`provider-api`模块的引用。

### 第三步，添加日志配置，web容器配置
修改web.xml，添加Spring IoC容器配置和DispatcherServlet相关配置，此处省略，不会的我只能理解你不了解Spring，请先自行百度。

在Resources目录下创建 `log4j.properties` 文件，用于打印日志，文件内容如下：

```conf
log4j.rootLogger=DEBUG,A1
log4j.appender.A1=org.apache.log4j.ConsoleAppender
log4j.appender.A1.layout=org.apache.log4j.PatternLayout
log4j.appender.A1.layout.ConversionPattern=%-d{yyyy-MM-dd  HH:mm:ss,SSS} [%t] [%c]-[%p] %m%n
```

### 第四步，创建服务实现类
新建server包，在包下新建服务实现类 `TestServerImpl`，实现 `TestService` 接口并实现其中的接口方法
```java
package cc.chenzhihao.provider.server;
 
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import server.ITestService;
 
/**
 * 服务业务实现类
 *
 * @author chenzhihao
 * Email: s_chenzh@jiedaibao.com
 * Date; 2019/5/11 23:16
 */
public class TestServiceImpl implements ITestService {
 
    private final Logger logger = LoggerFactory.getLogger(this.getClass());
 
    @Override
    public String hello(String data) {
        logger.info("invoke server, data = {}", data);
        return String.format("Provider say \" hello %s \"", data);
    }
}
```
### 第五步，添加dubbo配置
在`Resources`目录下新建 `application-context.xml`，添加如下配置
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:dubbo="http://code.alibabatech.com/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans-3.2.xsd
        http://www.springframework.org/schema/context
        http://www.springframework.org/schema/context/spring-context-3.2.xsd
        http://code.alibabatech.com/schema/dubbo
         http://code.alibabatech.com/schema/dubbo/dubbo.xsd">
 
    <context:component-scan base-package="cc.chenzhihao.provider.*"/>
 
    <!-- 提供方应用信息，用于计算依赖关系 -->
    <dubbo:application name="provider"/>
 
    <!-- 使用zookeeper注册中心暴露服务地址 -->
    <dubbo:registry address="zookeeper://localhost:2181"/>
 
    <!-- 用dubbo协议在20880端口暴露服务 -->
    <dubbo:protocol name="dubbo" port="20880"/>
 
    <!-- 声明需要暴露的服务接口 -->
    <dubbo:service interface="server.ITestService" ref="testService"/>
 
    <!-- 和本地bean一样实现服务 -->
    <bean id="testService" class="cc.chenzhihao.provider.server.TestServiceImpl"/>
 
</beans>
```

## 创建consumer
### 第一步~第三步
同Provider，此处省略。

### 第四步，添加dubbo配置
在`Resources`目录下新建 `application-context.xml`，添加如下配置
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:dubbo="http://code.alibabatech.com/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans-3.2.xsd
        http://www.springframework.org/schema/context
        http://www.springframework.org/schema/context/spring-context-3.2.xsd
        http://code.alibabatech.com/schema/dubbo
         http://code.alibabatech.com/schema/dubbo/dubbo.xsd">
 
    <context:component-scan base-package="cc.chenzhihao.consumer.*"/>
 
    <!-- 消费方应用信息，用于计算依赖关系 -->
    <dubbo:application name="consumer"/>
 
    <!-- 使用zookeeper注册中心暴露服务地址 -->
    <dubbo:registry address="zookeeper://localhost:2181"/>
 
    <!-- 用dubbo协议在20880端口暴露服务 -->
    <dubbo:protocol name="dubbo" port="20880"/>
 
    <!-- 声明需要引用的服务接口 -->
    <dubbo:reference interface="server.ITestService" id="testService"/>
 
</beans>
```
### 第五步，实现服务调用逻辑
新建 `TestController`，注入并调用服务接口业务方法。
```java
package cc.chenzhihao.consumer.controller;
 
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import server.ITestService;
 
/**
 * @author chenzhihao
 * Email: s_chenzh@jiedaibao.com
 * Date; 2019/5/11 23:40
 */
@Controller
public class TestController {
 
    @Autowired
    ITestService testService;
 
    @RequestMapping(value = "/hello", method = RequestMethod.GET)
    @ResponseBody
    public String hello(String name) {
        return testService.hello(name);
    }
}
```

## 运行前Tomcat配置

添加两个Tomcat启动配置，以Provider为例，Consumer类似。

注：两个Tomcat启动配置，各自HTTP端口和JMX端口不能一致，可以修改为8080和8081

![tomcat1](/images/tomcat1.png)

![tomcat2](/images/tomcat2.png)

## 启动服务并调用Consumer服务
先后启动Provider和Consumer，启动时系统会自动向注册中心注册或订阅服务，会有日志打印，如图表示启动成功：
![a](/images/a.png)

使用浏览器访问Consumer接口，测试服务是否正常调用

## 一些坑
- Dubbo的版本选择要慎重，有一些报错原因并不是代码书写问题，而是版本不兼容导致，详细请查看Dubbo相关Q&A
- 启动前，注意本地回环地址配置，服务在注册时获取的注册中心地址有时默认会获取为为局域网地址，此时可以尝试关闭本机防火墙，配置局域网内端口转发等
- Zookeeper，zkclient包一定要引，否则启动或接口调用时会报错
- 提示 No Provider *** 90%的原因时因为Provider没有注册到注册中心，可以尝试查看。剩下10%是因为本地回环地址的原因，我踩地雷了….

## 总结
半小时就可以搞定，结果我搞了一天半，原因在于对于Dubbo一些坑的摸索，其中因本地回环地址导致服务注册无法调用服务，提示服务未注册或无法启动等情况层出不穷，相信很多同学也像我一样遇到了问题。

通过这篇文章，总结了一下Dubbo和Spring整合的过程，希望能引领大家初尝Dubbo的味道。Dubbo系列将持续更新，不会很系统，接下来会列一些采坑集锦。
