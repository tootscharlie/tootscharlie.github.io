---
published: false
title: 解决Springboot使用Redis反序列化遇到的类型转换异常
date: 2019-05-26 13:17:36
updated: 2019-05-26 13:17:36
categories: 技术
tags: redis
---
## 异常现象
在使用Springboot 配合 Redis做缓存处理的时候，单元测试中对象的序列化和反序列化操作均正常，但是项目Runing后，接口操作出现类型转换异常，最可笑的是同一类型转换出了错😄。
> java.lang.ClassCastException: OauthCodeRedisCacheEntity cannot be cast to OauthCodeRedisCacheEntity

![image](/images/WX20180119-211451@2x.png)

## 解决思路

第一、我排查了一下单元测试和实际API接口的代码逻辑是否相同，然而是相同的。

第二、通过Debug模式检查了一下单元测试和实际API接口对本系统下Redis反序列化方法入参的参数值，发现也均值一样的

第三、先后执行单元测试和实际API，查看Redis缓存中的数据是否相同，经检验也是相同的。

第四、我考虑到是否是因多线程引起的，所以对调用该序列化方法的Service层进行了并发控制，这里仅加了可重入锁。然而并没有成功

第五、MDZZ，心态爆炸，歇了一会，和媳妇做做饭、收拾收拾家，开心

第六、Google 搜索关键词“Springboot Redis 反序列化类型转换失败” ….  未果，看来中文search不行

第七、Google 直接粘贴报错信息。 果然，SF大法好

## 刨根问底

> When you use DevTools with caching, you need to be aware of [this limitation](http://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#using-boot-devtools-known-restart-limitations).
> When the object is serialized into the cache, the application class loader is C1. Then after you change some code/configuration, devtools automatically restart the context and creates a new classloader (C2). When you hit that cache method, the cache abstraction finds an entry in the cache and it deserializes it from the store. If the cache library doesn’t take the context classloader into account, that object will have the wrong classloader attached to it (which explains that weird exception `A cannot be cast to A`).

上面这段话是Stack Overflow社区一大佬就此问题的回答，大意是说，当使用SpringBoot 的 DevTools时，其实该工具是具有缓存效果的，这点需要注意，而且该大佬也提供的注意事项的连接地址 [this limitation](http://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#using-boot-devtools-known-restart-limitations).

当对象被序列化到缓存里时，当前应用的类加载器是C1，当你改变了一些代码或者配置文件的时候，DevTools 工具将会自动重新启动这个容器，并且创建一个新的类加载器 C2. 这时候调用这个具有缓存的方法时，缓存管理将会从缓存里找到该条缓存记录并进行反序列化操作。如果缓存库不考虑上下文的话，也就是没注意到类加载器的变化时，该对象将会有错误的类加载器(这解释了奇怪的异常)。

其实就是因上下文类加载器不同而产生这样的错误，那么归根结底就是因SpringBoot DevTools工具搞的鬼。

果然，在项目配置初期，为了实现所谓的热部署和热加载使用了该工具库，果断删掉。

Perfect！！

## 总结
但凡遇到报错信息，切记不要慌不要乱，有因才有果，可以吓你根据自己的分析按照自己的想法进行错误排查，针对出现的类型转换出现的异常，首先应该想到是不是自己代码的问题，因为此次错误我在单元测试中是可用的，所以业务代码层面不会出现问题。

尽量把自己能想到 的解决方式全都用一遍，因为此时你对这个报错已经有了大题的了解，这个了解仅仅是利用排除法了解到的，即  他不是因为什么什么而发生。所以在接下来使用搜索引擎的时候，可以避免走一些弯路。

自己能想到的解决方法都用了之后，建议直接Google 报错信息，简单粗暴。逐条查看，按照说明处理。

当然最重要的还是心态，我在掏空自己的想法之后，果断选择去和小迷妹聊会天，解放一下思路，放松一下紧绷的神经。当然，在放松之余，我也在想这个问题，只是会更放松。

总而言之，言而总之，所有的程序员们，当你写代码遇到问题遇到Bug，起立，做点别的事情去
