---
published: false
title: HttpClient发起请求中文数据乱码问题解决
date: 2019-05-26 11:29:21
categories: java
tags: httpClient
---

## 问题现象

在调用php程序员的接口时，我们约定对参数进行字典排序并encode后按照约定的逻辑加密生成签名，加到请求头一同传输，php端对提交的参数执行同样的逻辑并且与请求头中的签名对比，起到防止数据在传输过程中被篡改。当然了，使用ssl的自然不用这么麻烦。我的问题出现在java方面给php接口方面post时中文乱码的问题。

![数据乱码截图](/images/C48211E7-9D3B-4834-B590-197DA0A0B95B.jpg)

## 初步想法

谈到中文乱码问题，我首先想到肯定是字符集在某个环节出现不匹配的情况。在使用HttpClient进行Http请求操作时，涉及到编码的无非在请求头处，但这里我们按照接口定义，对参数生成签名时使用了encode（UTF-8）编码，经过与接口方面的校验签名生成正确，也就说明是请求头出了问题。看一下post代码

```java
public static StringBuilder post(String url, Map<String, String> headers, Map<String, String> params) throws IOException {
    CloseableHttpClient httpClient = HttpClients.createDefault();
    HttpPost httpPost = new HttpPost(url);
    if (params != null && !params.isEmpty()) {
        List<NameValuePair> nvps = new ArrayList<NameValuePair>();
        for (Map.Entry<String, String> param : params.entrySet()) {
            nvps.add(new BasicNameValuePair(param.getKey(), param.getValue()));
        }
        httpPost.setEntity(new UrlEncodedFormEntity(nvps,"utf-8"));
    }
    if (headers != null && !headers.isEmpty()) {
        for (Map.Entry<String, String> header : headers.entrySet()) {
            httpPost.setHeader(header.getKey(), header.getValue());
        }
    }
    try (CloseableHttpResponse response = httpClient.execute(httpPost)) {
        return getContent(response.getEntity());
    }
}
```
第九行位置，可以看到我在发起post请求时使用的是默认UrlEncodedFormEntity，该对象会对参数进行自动encode操作，但问题来了，编码呢？
看一下这个对象的构造函数

```java
/**
 * Constructs a new {@link UrlEncodedFormEntity} with the list
 * of parameters with the default encoding of {@link HTTP#DEFAULT_CONTENT_CHARSET}
 *
 * @param parameters list of name/value pairs
 * @throws UnsupportedEncodingException if the default encoding isn't supported
 */
public UrlEncodedFormEntity (
    final List <? extends NameValuePair> parameters) throws UnsupportedEncodingException {
    this(parameters, (Charset) null);
}
```
可以看到在单参数构造函数中还使用了一个第二个参数是字符编码的构造函数，看注释可以看到，在不指定字符编码的时候默认使用的是DEFAULT_CONTENT_CHARSET字符编码（ISO-8859-1）
好了，现在已经定位到问题了。问题出现在这里，现在可以使用第二个参数为字符编码的构造函数构造该对象。使用utf-8构造该对象即可解决问题。
