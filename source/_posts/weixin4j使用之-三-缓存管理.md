---
published: true
title: weixin4j使用之(三) 缓存管理
date: 2018-05-26 12:07:30
categories: 技术
tags: 
    - 微信开发
    - weixin4j
---

在微信开发过程中，一些例如jsapi_token 和jsapi_ticket这些信息都有固定的生存时间，过了生存时间即失效，需要重新获取，然而微信方面对于这些信息的获取次数也加以限制。比如jsapi_token的有效时间为7200秒，日最大刷新次数为2000次。如果在每个业务周期内都获取一次的话，很有可能把接口刷爆掉，影响该公众号其他业务。

在传统开发中，上述那些敏感信息主要有以下几种存储形式：外部文件、内存、数据库、高速缓存等。介于一些信息都限制了有效时间，像是文件、内存、数据库这种形式存储的话每次获取前都需要判断一下token距上次获取的时间是否超过keytoken有效时间，若超过则调用token的刷新方法重新获取token。这个逻辑不难，但每次都要判断时间，这个很头疼。

当然，还有最后一种 高速缓存，比如redis，他可以很简单的在插入key的时候设置该key的生存时间，这样一来我们在读key的时候只需要判断有没有就行了，有就用没有就获取，是不是so easy。

好了，逻辑捋清楚了，再来看一下weixin4j给我们提供了哪些缓存的实现。

## weixin4j的Token缓存
在此之前，我对该项目的缓存没有任何一点了解，完全出于我个人判断，因为微信开发中必须要涉及到关键性token的缓存问题，那么该框架一定会提供缓存功能，这个方向是对的，那么具体在哪里？怎么用？怎么实现的？如何扩展？就需要翻文档或者查作者源码了。很遗憾，项目官网并没有提供缓存使用方面的文档或介绍，但我在该项目的github主页中找到了一篇介绍，实际上只是说了提供了和默认提供哪种缓存而已，并没有提供别的信息。开启自悟模式。

在基础组件的cache包中，我找到了一组关于缓存的API。

1. Cacheable
接口，定义可缓存对象一定是Cacheable的子类实现
2. CacheCreator
接口，定义缓存的创建
3. CacheStorager
接口，定义缓存的存储。如果要定义自己的缓存存储实现，直接实现该接口即可。但weixin4j已经给我们提供了五个可选择的实现，日常够用。
4. CacheManager
缓存管理器，构造时需要传入缓存的创建对象和存储对象。
5. 五个常用的缓存存储的实现

很巧，我的思路和作者一样，这里有五种缓存方式的具体实现，与我上面相比，多了一个redis集群配置和Memcache缓存配置，这个就不多说了。他们分别是

1. FileCacheStorager 文件方式，是weixin4j默认提供的
2. MemoryCacheStorager 内存方式，不推荐使用
3. MemcacheCacheStorager  Memcache的缓存方式，熟悉的童鞋可以用一下
4. RedisCacheStorager 基于单个Redis缓存的配置方式
5. RedisClusterCacheStorager  Redis集群方式

默认情况下，weixin4j使用文件方式，即使用FileCacheStorager来管理token缓存，默认缓存路径：java.io.tmpdir。

## Redis缓存token
五种方式都可以尝试，这里因为项目背景的原因，我使用单个Redis方式配置。

直接看RedisCacheStorager这个类的源码

```java
public class RedisCacheStorager<T extends Cacheable> implements
      CacheStorager<T> {
 
   private Pool<Jedis> jedisPool;
 
   private final static String HOST = "127.0.0.1";
   private final static int PORT = 6379;
   private final static int TIMEOUT = 5000;
   private final static int MAX_TOTAL = 50;
   private final static int MAX_IDLE = 5;
   private final static int MAX_WAIT_MILLIS = 5000;
   private final static boolean TEST_ON_BORROW = false;
   private final static boolean TEST_ON_RETURN = true;
 
   public RedisCacheStorager() {
      this(HOST, PORT, TIMEOUT);
   }
 
   public RedisCacheStorager(String host, int port, int timeout) {
      JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
      jedisPoolConfig.setMaxTotal(MAX_TOTAL);
      jedisPoolConfig.setMaxIdle(MAX_IDLE);
      jedisPoolConfig.setMaxWaitMillis(MAX_WAIT_MILLIS);
      jedisPoolConfig.setTestOnBorrow(TEST_ON_BORROW);
      jedisPoolConfig.setTestOnReturn(TEST_ON_RETURN);
      this.jedisPool = new JedisPool(jedisPoolConfig, host, port, timeout);
   }
 
   public RedisCacheStorager(JedisPoolConfig jedisPoolConfig) {
      this(new JedisPool(jedisPoolConfig, HOST, PORT, TIMEOUT));
   }
 
   public RedisCacheStorager(String host, int port, int timeout,
         JedisPoolConfig jedisPoolConfig) {
      this(new JedisPool(jedisPoolConfig, host, port, timeout));
   }
 
   public RedisCacheStorager(Pool<Jedis> jedisPool) {
      this.jedisPool = jedisPool;
   }
   
   //省略其他方法 ... 
}
```
在基于单个Redis的token缓存实现中，默认使用本地无密码认证的6379端口的Redis作为缓存介质，但也提供了四个构造方法去创建自己的token缓存。

第一种，直接使用默认的方式，不多说

第二种，使用主机地址、端口、超时时间配置

第三种，直接使用jedis连接池配置对象，但主机地址、端口和超时时间均使用默认

第四种，全部自定义

第五种，直接把jedis连接池对象传入

## 配置使用

在Weixin4jConfig对象中，加入RedisCacheStorager对象Bean配置。这里我的项目基于SpringBoot，配置如下
```java
@Autowired
private JedisConnectionFactory jedisConnectionFactory;
 
//配置基于Redis的token缓存管理器
@Bean
public RedisCacheStorager<Token> redisCacheStorager() {
    return new RedisCacheStorager<Token>(
            jedisConnectionFactory.getHostName(),
            jedisConnectionFactory.getPort(),
            jedisConnectionFactory.getTimeout(),
            jedisConnectionFactory.getPoolConfig()
    );
}
```

直接将Jedis的连接工厂拿到，配置RedisCacheStorager的时候注入四个信息即可。

在WeixinProxy对象中可以找到这样一个构造函数

```java
public WeixinProxy(CacheStorager<Token> cacheStorager) {
   this(Weixin4jConfigUtil.getWeixinAccount(), cacheStorager);
}
```
在构造该对象的时候传入一个Token对象的缓存存储管理器。这里直接在昨天的配置类中Weixin4jProxy的Bean配置处使用该构造函数初始化，并传入一个RedisCacheStorager对象。
```java
@Bean
public WeixinProxy mpWeixinProxy() {
    return new WeixinProxy(redisCacheStorager());
}
```

## 测试
调用分享接口，进入redis查看缓存信息
![缓存结果](/images/WX20170118-000011@2x.png)
