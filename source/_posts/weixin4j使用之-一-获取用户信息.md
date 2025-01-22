---
published: true
title: weixin4j使用之(一) 获取用户信息
date: 2018-05-26 11:39:00
categories: 技术
tags: 
    - 微信开发
    - weixin4j
---
因为最近的项目需要做微信方面的开发，之前也有过微信开发的经验，但每逢项目中遇到跟微信沾边的东西就得从头写起，一直也没单独把微信开发方面的代码单独独立出来。

首先到微信开放平台申请一个测试号，绑定安全域名

## weixin4j环境配置

这是一个封装了相当完善的Java微信开发工具，项目主页：[weixin4j](https://github.com/foxinmy/weixin4j)

建议先了解微信传统Oauth2.0开发流程再使用该工具

#### 引入Maven配置
```xml
//这里引入weixin4j公众号开发Api，还有企业号和服务器的这里不引入
<dependency>
    <groupId>com.foxinmy</groupId>
    <artifactId>weixin4j-mp</artifactId>
    <version>1.7.4</version>
</dependency>
```
weixin4j相关依赖还有fastjson和HttpClient

## 配置开发代理Bean

将com.foxinmy.weixin4j.mp.WeixinProxy类注入Spring容器管理
```java
@Bean
public WeixinProxy mpWeixinProxy() {
    return new WeixinProxy();
}
```

获取用户信息需要使用的几个对象

- com.foxinmy.weixin4j.mp.api.OauthApi
公众号Oauth开发流程API
- com.foxinmy.weixin4j.mp.model.OauthToken
Token实体
- com.foxinmy.weixin4j.mp.model.User
微信用户信息封装实体

## 配置开发者账号
在classpath下创建weixin4j.properties配置文件，配置Appid和secret
```conf
weixin4j.account={"id":appid,"secret":secret}
```
## 用户信息获取接口
贴上获取用户信息的代码，按照微信逻辑走即可

1. snapi_userinfo 授权，需用户手动确认授权，因此无需关注或与公众号产生消息交互

```java
@GetMapping(value = "/user_authenticator")
public APIResult userAuthenticator(@RequestParam(name = "code") String code) {
    OauthApi oauthApi = weixinProxy.getOauthApi();
    OauthToken oauthToken = oauthApi.getAuthorizationToken(code);
    logger.info("{}", oauthToken.toString());
    User user = oauthApi.getAuthorizationUser(oauthToken);
    return asSuccess(user);
}
```
2. snapi_base 授权，获取用户openid，并通过openid获取用户信息。用户信息中带有用户是否关注公众号的状态字段。用此字段来判断用户是否已关注公众号，达到强制关注的效果
```java
@GetMapping(value = "/user_authenticator")
public APIResult userAuthenticator(@RequestParam(name = "code") String code) {
    OauthApi oauthApi = weixinProxy.getOauthApi();
    OauthToken oauthToken = oauthApi.getAuthorizationToken(code);
    return weixinProxy.getUser(oauthToken.getOpenId());
}
```

## 创建授权连接

weixin4j提供了构造授权连接的Api，传入回调地址、state、scope即可

com.foxinmy.weixin4j.mp.api.OauthApi#getUserAuthorizationURL(redirectUri, state, scope)

scope分为两种snsapi_base和snsapi_userinfo，具体请查阅微信开发文档

通过微信访问授权连接，应该会得到用户信息的输出。

## 总结
使用weixin4j大大简化了java微信开发的时间，而且weixin4j还提供了一套非常灵活的token缓存机制。这篇先到这里，下一篇会分享通过weixin4j开发分享到朋友圈的功能。
