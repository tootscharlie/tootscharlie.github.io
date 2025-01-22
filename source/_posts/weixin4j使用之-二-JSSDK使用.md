---
published: true
title: weixin4j使用之(二) JSSDK使用
date: 2018-05-26 11:46:31
categories: 技术
tags: 
    - 微信开发
    - weixin4j
---
使用weixin4j第二天，今天搞一下JSSDK，也就是分享到朋友圈，分享到QQ之类的接口，官方称JS接口。废话不说，开干。

## 微信JS接口开发逻辑

在使用weixin4j进行微信JSSDK开发之前，先熟悉一下sdk的开发逻辑，这样在使用weixin4j的时候如果遇到问题，解决起来比较方便，逻辑也比较清楚。下面捋一下步骤

1. 绑定安全域名，没的说
2. 编写用于提供前端JSSDK配置信息的后端接口【参数：页面完整带参数url地址，去掉#后部分】
   1. 拿appid和secret换取access_token(公众号的全局唯一票据)。有效期7200秒，因此需要缓存起来，防治刷爆。此token非彼token，和我们上一篇文章中的token不一样，别混了。这个token是appid和secret加密后的结果，可以理解成该公众号的身份凭证，只不过该凭证每2小时(7200秒)需要刷新一次而已。接下来拿着我们的身份证去换票吧
   2. 用得到的access_token换取api_ticket。有效期也是7200秒，也需要做缓存。ticket相当于一张门票，在微信的一些接口调用中，都需要拿着这张票才使用。此时我们有了两样东西，一个是身份证（access_token）另一个是门票(api_ticket)，他们都有过期时间，我们需要定期去重新获取他们。
   3. 生成签名
   该签名是JSSDK接口的一个调用凭证，80%的错误都来自于签名的生成。
      1. 签名生成需要如下几个参数：
         1. 被分享页面的完整带参url地址,去掉#后部分，这里已经作为参数传递进来了
         2. 时间戳，10位字符串
         3. 随机字符串
         4. 门票（api_ticket）
      2. 签名算法，引用微信官方文档
        > 签名生成规则如下：参与签名的字段包括noncestr（随机字符串）, 有效的jsapi_ticket, timestamp（时间戳）, url（当前网页的URL，不包含#及其后面部分） 。对所有待签名参数按照字段名的ASCII 码从小到大排序（字典序）后，使用URL键值对的格式（即key1=value1&key2=value2…）拼接成字符串string1。这里需要注意的是所有参数名均为小写字符。对string1作sha1加密，字段名和字段值都采用原始值，不进行URL 转义。
   4. 将appid、时间戳、随机字符串、签名四个信息返回。到此后端接口就编写完了
3. 编写前端JS代码
   1. 通过后端接口获得配置信息
   2. 注入微信JSSDK配置函数中
   3. 在ready函数中配置要调用的JSSDK api信息

逻辑都知道了吧，建议用原生去写一下，一步步按照开发逻辑捋一遍再看这篇文章，就会更清晰一点。这里不再写原生了，直接使用weixin4j快速开发后端接口

## weixin4j开发思路
上一篇文章在获取用户信息的时候单独创建了一个配置类Weixin4jConfig，其中配置了开发代理类WeixinProxy，通过看这个Bean的源码，我们发现了如下的方法：

```java
/**
 * 获取JSSDK Ticket的tokenManager
 *
 * @param ticketType
 *            票据类型
 * @return
 */
public TokenManager getTicketManager(TicketType ticketType) {
   return new TokenManager(new WeixinTicketCreator(weixinAccount.getId(),
         ticketType, this.tokenManager), this.cacheStorager);
}
```
看到这个方法是关于JSSDK的，而且直接操作的是Ticket，我就乐坏了，哈哈。

不难发现该方法可以获取Ticket票据管理对象，需要传如一个参数TicketType，用我多年体育老师教的英语经验来看，这个参数名叫票据类型，让我们再看一下这个票据类型到底是啥
```java
public enum TicketType {
   /**
    * jsapi
    */
   jsapi,
   /**
    * 公众平台-卡券
    */
   wx_card,
   /**
    * 企业号-选取联系人
    */
   contact;
}
```
这是一个枚举类，发现jsapi，思路清晰了，需要根据票据类型获取票据管理对象。查阅票据管理对象的源代码发现并没有生成签名的算法。

接着沿着我们的思路，我们需要找到一个可以将四个参数生成签名的函数，或者如果weixin4j封装的更完善一点直接传入一个url得到组配置结果信息。

翻源码翻了好一会，发现在weixin4j-base组件com.foxinmy.weixin4j.jssdk包中有两个类，分别是JSSDKAPI和JSSDKConfigurator，真是踏破草鞋无觅处，得来全不费功夫呀

JSSDKConfigurator是真正的JSSDK配置信息的操作对象，而JSSDKAPI对象则是API信息的对象，后续才会用到它，先不着急。来看一下这个对象的结构：

![方法截图](/images/QQ20170116-132928@2x-300x187.png)

1. 该对象有一个构造方法，需要传入一个TokenManager，咦，这个构造函数的注释中说可以通过调用WeixinProxy#getTicketManager获取，兴奋不已。
2. debugMode()方法是开启JSSDKdebug模式，该方法只是向返回信息中添加了一个debug为true的参数，很显然，该参数的信息会在前端被使用，我们只需要接受就好
3. appid()，其实并没什么卵用，如果在weixin4j配置了开发者账号在初始化的时候直接回从配置文件中获得，这里不管他
4. apis(),可以传入一个或一组API数据
5. toJSONConfig，这个方法传入一个String类型的url，返回一组信息。这个方法就是我们需要的构造签名的方法，代码找到了，那就开干

## 配置Bean

根据思路我们知道，使用weixin4j开发JSSDK需要三个组件，一个是TokenManager另一个是JSSDKConfigurator，还有上一篇的WeixinProxy代理类

```java
@Bean
public WeixinProxy mpWeixinProxy() {
    return new WeixinProxy();
}
 
@Bean
public TokenManager ticketTokenManager() {
    //通过WeixinProxy对象获取Jsapi的票据管理对象
    return mpWeixinProxy().getTicketManager(TicketType.jsapi);
}
 
@Bean
public JSSDKConfigurator jssdkConfigurator() {
    //new一个JSSDK配置工具，该工具需要传入票据管理对象，这里传入的同时直接开启JSSDK的debug模式
    return new JSSDKConfigurator(ticketTokenManager()).debugMode();
}
```
到此我们的配置工作就结束了， 接着来搞一下api接口

## API接口
首先注入刚刚配置的两个Bean
```java
@Autowired
private JSSDKConfigurator jssdkConfigurator;
@Autowired
private TokenManager ticketTokenManager;
```
接着 编写web接口
```java
@GetMapping(value = "jssdk_jsonconfig")
public APIResult getJssdkJsonConfig(@RequestParam("url") String url) {
    try {
        //将公众号开发中所有的api全部添加进去。
        jssdkConfigurator.apis(JSSDKAPI.MP_ALL_APIS);
        //生成配置信息
        String jsonConfig = jssdkConfigurator.toJSONConfig(url);
        //weixin4j在生成签名的时候没有提供ticket打印功能，如果想使用微信官方的签名校验的童鞋，请使用票据管理器获取ticket票据
        logger.info("jssdk ticket:{}", ticketTokenManager.getAccessToken());
        return asSuccess(jsonConfig);
    } catch (WeixinException e) {
        e.printStackTrace();
        return asError(e.getMessage());
    }
}
```
后端的接口代码就是这样。关键代码就两行，是不是特别一贼

## 前端JS代码

根据我们的原生开发逻辑，直接上代码，不啰嗦

```javascript
<!-- js -->
<script src='http://img.neusoft.edu.cn/templates/neusoft.edu.cn/js/jquery.min.js'></script>
<script src="http://res.wx.qq.com/open/js/jweixin-1.0.0.js"></script>
<script>
    $(function () {
        var config = {
            debug: '', // 开启调试模式
            appId: '', // 必填，公众号的唯一标识
            timestamp: '', // 必填，生成签名的时间戳
            nonceStr: '', // 必填，生成签名的随机串
            signature: '',// 必填，签名，见附录1
            jsApiList: [] // 必填，需要使用的JS接口列表，所有JS接口列表见附录2
        };
        $.ajax({
            url: '接口请求地址',
            type: 'GET',
            dataType: 'json',
            async:false,
            data: {url: window.location.href}
        }).success(function(date){
            var json = JSON.parse(date.result);
            config.debug = json.debug;
            config.appId = json.appId;
            config.timestamp = json.timestamp;
            config.nonceStr = json.nonceStr;
            config.signature = json.signature;
            config.jsApiList = json.jsApiList;
        });
        wx.config(config);
        wx.ready(function(){
            //分享接口
            wx.onMenuShareTimeline({
                title: '这里是分享标题', // 分享标题
                link: window.location.href, // 分享链接
                imgUrl: '分享图标地址.没有,先这么放着吧', // 分享图标
                success: function () {
                    // 用户确认分享后执行的回调函数
                    alert("分享成功");
                },
                cancel: function () {
                    // 用户取消分享后执行的回调函数
                    alert("不分享拉倒");
                }
            });
        });
        wx.error(function(res){
            console.log("error:" + res);
        });
    });
</script>
```
## 测试结果
![1](/images/QQ20170116-135016.png)
![2](/images/QQ20170116-135047.png)
