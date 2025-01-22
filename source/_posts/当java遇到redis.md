---
published: false
title: 当java遇到redis
date: 2019-05-25 23:45:01
tags: 
    - java
    - redis
categories: 技术
---
redis以高并发、速度快被广泛的运用在缓存领域中。通过分析之前写过的微信摇一摇抽奖活动发现，直接对mysql数据库读写资源开销非常大，而mysql的并发数也相对较小，通过redis做缓存可以很好的解决此类问题。

<!--more-->

## 环境
- redis server 3.0.6
- jedis 2.9.0
- jdk 1.8
- spring 4.2.1
- maven 3

## 基础命令
- redis-server [redis.conf path] 启动redis
- redis-cli [-a password] [-p port] [-h host] 连接redis客户端

## 普通键值操作
- SET key value  添加键值
- GET key  通过键获取值
- DEL key 删除键值
- EXISTS key 判断key是否存在

## jedis测试
jedis 2.9.0 jar包。至于为毛叫jedis，想想log4j就清楚了。

这里使用maven管理jar包依赖，想了解maven基础的朋友，出门右拐谷歌

```xml
<dependency>
     <groupId>redis.clients</groupId>
     <artifactId>jedis</artifactId>
     <version>2.9.0</version>
</dependency>
```

新建测试类，添加测试方法

```java
@Test
public void testJedis() throws Exception {
    Jedis jedis = new Jedis("localhost");
    //jedis.auth("password"); // 认证秘钥，认证失败会抛出redis.clients.jedis.exceptions.JedisDataException: ERR invalid password异常
    jedis.set("name","chen");
    String name = jedis.get("name");
    jedis.close();
    Assert.assertEquals("chen",name);
}
```

此时没有任何提示及异常，证明测试成功，前往redis使用命令查看自定义键值是否添加成功
```bash
127.0.0.1:6379> GET name
"chen"

127.0.0.1:6379> GET name
"chen"
```
## spring整合
通过spring配置redis连接池拿到redis连接对象，使用后关闭即可。Jedis提供了redis连接池对象JedisPool和连接池配置对象JedisPoolConfig

配置JedisPoolConfig

```xml
<bean id="jedisPoolConfig" class="redis.clients.jedis.JedisPoolConfig">
    // 最大空闲时间，超过此时间连接自动释放 0 默认不限制
    <property name="maxIdle" value="{redis.pool.maxIdle}"/>
    // 最大连接数 0 默认不限制
    <property name="maxTotal" value="${redis.pool.maxActive}"/>
    // 最大连接等待时间 -1 默认无限制
    <property name="maxWaitMillis" value="${redis.pool.maxWait}"/>
</bean>
```

Jedis连接池对象的几个构造函数

```java
JedisPool(String host); // 使用默认JedisPoolConfig配置，和默认端口
JedisPool(String host, int port); 指定端口，使用默认配置

//使用自定义JedisPoolConfig配置，切指定端口，超时时间，密码和数据库编号
JedisPool(GenericObjectPoolConfig poolConfig, String host, int port, int timeout, String password, int database)
```
```xml
<bean id="jedisPool" class="redis.clients.jedis.JedisPool">
    <constructor-arg index="0" ref="jedisPoolConfig"/>
    <constructor-arg index="1" value="{redis.hostname}"/>
    <constructor-arg index="2" value="${redis.port}"/>
    <constructor-arg index="3" value="60000" type="int"/>
    <constructor-arg index="4" value="${redis.password}"/>
    <constructor-arg index="5" value="0"/>
</bean>
```
测试

```java
@Autowired
private JedisPool jedisPool;

@Test
public void testJedisPool() throws Exception {
    // 获取redis连接对象
    Jedis jedis = jedisPool.getResource();
    jedis.set("name","jedis");
    String name = jedis.get("name");
    jedis.close();// 关闭连接
    Assert.assertEquals("jedis",name);
}
```
