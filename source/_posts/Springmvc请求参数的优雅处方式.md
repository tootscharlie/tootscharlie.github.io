---
published: false
title: Springmvc请求参数的优雅处方式
date: 2019-06-13 11:06:40
categories: 技术
tags: 
    - spring
    - 请求参数处理
---
当使用SpringMVC开发项目时，经常会出现对请求参数处理的困扰，例如：字符串前后端空格、前后端需要约定日期时间的传递方式、返回等。诸多问题我们的解决方式通常是前后端通过约定好统一的数据格式来保证系统暂时的稳定，或通过哪里出错改哪里的笨拙方式处理，这些都是不可取的。通过这篇文章，希望可以以优雅的方式彻底解决这个问题。

<!--more-->

&#160; &#160; &#160; &#160;当使用SpringMVC开发项目时，经常会出现对请求参数处理的困扰，例如：字符串前后端空格、前后端需要约定日期时间的传递方式、返回等。诸多问题我们的解决方式通常是前后端通过约定好统一的数据格式来保证系统暂时的稳定，或通过哪里出错改哪里的笨拙方式处理，这些都是不可取的。通过这篇文章，希望可以以优雅的方式彻底解决这个问题。
&#160; &#160; &#160; &#160;我的老东家办公楼的最顶层有一处独特的景观，从正面顺楼梯直上是一处悬挂在半层的独立空间，在半层入口的对面即是出口，而出口被设计为一道滑梯。设计师在设计之处说道：“当你遇到困难和瓶颈时，不妨跳出你所在的维度到更高的维度去思考，上去坐坐，当你想出答案了，再顺着滑梯滑下来”。而此景观的名字源于爱因斯坦的一句话 `问题往往在更高的维度可以得到解决`，所以它的名字叫作`高维之屋`。

![高维之屋](/images/高维之屋.jpg)
<center>高维之屋</center>


## 需求

> 去除请求参数中字符串两端空格。以该问题抛砖引玉

要去除请求参数中字符串两端的空格，涉及到两种情况：
- 1、URL参数
- 2、JSON请求体

对于第一种情况，通常在Get查询参数、PATH的路由参数中出现，在Controller的方法中以@RequestParam或@PathVariable注解变量完成参数绑定。对于第二种情况，通常在以Post请求的请求体中，在Controller的方法中以@RequestBody注解某实体完成参数绑定。

可以想到的解决方式如下：
- 方法一：接口调用方自行trim后传递。后端对接口调用方请求参数规范化程度不可控，所以不予考虑。
- 方法二：通过过滤器拦截请求参数，对字符串进行trim操作。在实现过滤器时，需要通过请求头content-type判断当前请求的内容格式，将请求对象中的参数取出trim后再塞回去，虽然可以实现需求，但编码实在太复杂，而且对于基于RESTful风格的URL中路由参数进行trim时处理起来更为复杂，且对于请求体中的JSON数据的值进行trim又涉及到递归的问题，所以仍不予考虑。
- 方法三：寻找Spring在Controller方法接收参数前的处理动作予以扩展。需要下点功夫看看官方文档啦~

## 解决方案

通过阅读[Spring官方文档](https://docs.spring.io/spring/docs/4.3.24.RELEASE/spring-framework-reference/)（4.3.24.RELEASE版本，有单页html和pdf版可供选择，以下简称官方文档）得知，SpringMVC在处理Controller方法参数时使用了Spring的参数绑定和类型转换机制，且对于处理以JSON数据格式的请求和响应（@RequestBody和@ResponseBody）采用Jackson来进行序列化和反序列化操作。从而可以得出一个推断，我只需要实现自定义参数绑定、自定义Jackson序列化和反序列化即可实现该需求，并且很优雅~ 
> 画外音：“哪有那么简单，想改你就改啊？”
> 画内音：“对于Spring这种级别的框架，一定是支持开发者进行自定义扩展的，况且我遇到的问题，社区内一定会有人比我遇到的早。”
> 画外音：“so？”
> 画内音：“so你个大头鬼，对任何问题一定要抱有乐观的态度，你特么就是一'锁'。”
> 画外音：“什么锁？”
> 画内音：“悲观锁！！！”

### 前50%：请求参数中字符串trim

#### 1、啥是自定义数据绑定

官方文档的[Method Parameters And Type Conversion](https://docs.spring.io/spring/docs/4.3.24.RELEASE/spring-framework-reference/htmlsingle/#mvc-ann-typeconversion)小节介绍道：

> String-based values extracted from the request including request parameters, path variables, request headers, and cookie values may need to be converted to the target type of the method parameter or field (e.g., binding a request parameter to a field in an @ModelAttribute parameter) they’re bound to. If the target type is not String, Spring automatically converts to the appropriate type. All simple types such as int, long, Date, etc. are supported. You can further customize the conversion process through a WebDataBinder (see the section called “Customizing WebDataBinder initialization”) or by registering Formatters with the FormattingConversionService (see Section 9.6, “Spring Field Formatting”).

大概意思是，在进行参数绑定的时候，若对应的绑定参数类型不是字符串（String），则Spring会自动将值转换为对应的类型，这个操作支持所有基础类型，例如：int、long、Date等。并且Spring提供了`WebDataBinder`作为自定义数据类型转换的扩展点。那么如何去扩展WebDataBinder呢？

官方文档的[Customizing data binding with @InitBinder](https://docs.spring.io/spring/docs/4.3.24.RELEASE/spring-framework-reference/htmlsingle/#mvc-ann-webdatabinder)小节介绍道：
> To customize request parameter binding with PropertyEditors through Spring’s WebDataBinder, you can use @InitBinder-annotated methods within your controller, @InitBinder methods within an @ControllerAdvice class, or provide a custom WebBindingInitializer. See the the section called “Advising controllers with @ControllerAdvice and @RestControllerAdvice” section for more details.

#### 2、三种实现方法

Spring提供了三种方法来完成这件事儿：
1. 可以在@Controller注解的类中使用`@InitBinder`注解方法
2. 在@ControllerAdvice注解的类中使用`@InitBinder`注解方法
3. 提供自定义`org.springframework.web.bind.support.WebBindingInitializer`扩展

可以在@Controller或@ControllerAdvice注解的类中创建由@InitBinder注解的方法，或创建接口`org.springframework.web.bind.support.WebBindingInitializer`的实现类提供扩展。当时用@InitBinder注解方法时，该方法不可以有返回值，且参数可以是`org.springframework.web.bind.WebDataBinder`、`org.springframework.web.context.request.WebRequest`和`java.util.Locale`的组合。就像下面这样：

```java
@Controller
public class MyFormController {

    /**
     * 自定义参数绑定
     * @param webDataBinder 必选。用于从Web请求参数到JavaBean对象的数据绑定
     * @param webRequest    表示当前的一次请求，可以从请求对象中拿到一些数据
     * @param locale        一个java.util.Locale对象，用于国际化
     */
    @InitBinder
    protected void initBinder(WebDataBinder binder, WebRequest webRequest, Locale locale) {
        // do something~
    }

    // ...
}
```
但是，对于第一种方法，@InitBinder注解方法仅在当前@Controller中有效。（什么，那岂不是每个@Controller都得写一遍，我特么才不！）但`提供自定义WebBindingInitializer扩展`和`在@ControllerAdvice注解的类中使用@InitBinder注解方法`，则是全局配置（舒服~）

#### 3、WebBindingInitializer接口
先看一下`WebBindingInitializer`接口是个啥
```java
public interface WebBindingInitializer {
	void initBinder(WebDataBinder binder, WebRequest request);
}
```
该接口已经为咱们定义好了初始化绑定器的方法，和使用`@InitBinder`注解方法从参数上来看只差`Locale`对象，可能是该对象用处不多吧。
来看看`WebDataBinder`对象，该对象内部有一个`void registerCustomEditor(Class<?> requiredType, PropertyEditor propertyEditor)`方法，其内部调用了`PropertyEditorRegistry`接口对象的`void registerCustomEditor(Class<?> requiredType, PropertyEditor propertyEditor)`方法，该方法的作用是为给定类型的所有属性注册给定的自定义属性编辑器，即我们可以为所有`String`、`Date`等类型的参数注册特定于该类型的属性编辑器。方法第一个参数为`Class`对象，我们可以提供任意类型，是任意类型哟~，第二个参数为`java.beans.PropertyEditor`属性编辑器对象，咿~ 这特么居然是Java类库自带的接口，通过IDEA找到该接口的子类，卧槽~
![propertyEditor子类](/images/propertyEditor子类.png)
<center>propertyEditor子类列表</center>
高亮处那是什么？`org.springframework.beans.propertyeditors.StringTrimmerEditor` ，对没有看错，从他的名字上一眼就能看出他的才华。此时应该想起歌声：`是谁~送你来到我身边~`

#### 4、扩展WebBindingInitializer
二话不说，先来创建一个类，起一个一眼就能看出来和`WebBindingInitializer`有血缘关系的名字，并实现该接口重写`initBinder`方法，在该方法中使用`WebDataBinder`对象的`registerCustomEditor`方法为`String`类型的对象注册`StringTrimmerEditor`编辑器。

```java
public class CustomWebBindingInitializer implements WebBindingInitializer {

    @Override
    public void initBinder(WebDataBinder webDataBinder, WebRequest webRequest) {
        /*
            注册对于String类型参数对象的属性进行trim操作的编辑器,
            构造参数代表空串是否转为null，false，则将null转为空串。hie hie ~ 前端就不用了处理null啦
        */
        webDataBinder.registerCustomEditor(String.class, new StringTrimmerEditor(false));
        // 这里我还添加了其他类型的属性编辑器
        webDataBinder.registerCustomEditor(Short.class, new CustomNumberEditor(Short.class, true));
        webDataBinder.registerCustomEditor(Integer.class, new CustomNumberEditor(Integer.class, true));
        webDataBinder.registerCustomEditor(Long.class, new CustomNumberEditor(Long.class, true));
        webDataBinder.registerCustomEditor(Float.class, new CustomNumberEditor(Float.class, true));
        webDataBinder.registerCustomEditor(Double.class, new CustomNumberEditor(Double.class, true));
        webDataBinder.registerCustomEditor(BigDecimal.class, new CustomNumberEditor(BigDecimal.class, true));
        webDataBinder.registerCustomEditor(BigInteger.class, new CustomNumberEditor(BigInteger.class, true));
        // 可以在此继续扩展~
    }

}
```
#### 5、配置WebBindingInitializer
定义好了扩展，该如何配置呢？官方文档[Configuring a custom WebBindingInitializer](https://docs.spring.io/spring/docs/4.3.24.RELEASE/spring-framework-reference/htmlsingle/#mvc-ann-webbindinginitializer) 小节给出了方法，配置`RequestMappingHandlerAdapter`Bean，将`WebBindingInitializer`对象配置到该Bean的`webBindingInitializer`属性。具体实现如下：

```xml
<bean class="org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter">
    <property name="cacheSeconds" value="0"/>
    <!--添加自定义参数绑定器-->
    <property name="webBindingInitializer">
        <bean class="cc.chenzhihao.study.springmvc.config.CustomWebBindingInitializer"/>
    </property>
</bean>
```
此处有个坑，上述Bean的配置，要在启用SpringMVC注解配置`<mvc:annotation-driven/>`之前，否则不会生效。

#### 6、测试字符串参数Trim效果
编写控制器，代码如下：
```java
@Controller
public class BinderTestController {

    /**
     * 对请求参数中String类型参数进行trim测试
     */
    @RequestMapping("/param")
    @ResponseBody
    public String testTrimRequestParam(@RequestParam(value = "p1", required = false) String p1,
                                       @RequestParam(value = "p2", required = false) Integer p2,
                                       @RequestParam(value = "p3", required = false) Double p3,
                                       @RequestParam(value = "p4", required = false) BigInteger p4,
                                       @RequestParam(value = "p5", required = false) BigDecimal p5) {
        StringBuilder sb = new StringBuilder();
        Optional.ofNullable(p1).ifPresent((e) -> sb.append(String.format("String param is [%s]", e)).append("\n"));
        Optional.ofNullable(p2).ifPresent((e) -> sb.append(String.format("Integer param is [%s]", e)).append("\n"));
        Optional.ofNullable(p3).ifPresent((e) -> sb.append(String.format("Double param is [%s]", e)).append("\n"));
        Optional.ofNullable(p4).ifPresent((e) -> sb.append(String.format("BigInteger param is [%s]", e.toString())).append("\n"));
        Optional.ofNullable(p5).ifPresent((e) -> sb.append(String.format("BigDecimal param is [%s]", e.toString())).append("\n"));
        System.out.println(sb.toString());
        return sb.toString();
    }
}
```

测试请求 
`http://localhost:8080/tirm/param?p1=%20trim%20&p2=%2001%2000%201&p3=1.0%200020202002020202&p4=9999999999999999999999999999999999999999999999&p5=1.1111111111999000111111111111222222222222220200202020202020020202020202222`

打印结果：
```
String param is [trim]
Integer param is [1001]
Double param is [1.000202020020202]
BigInteger param is [9999999999999999999999999999999999999999999999]
BigDecimal param is [1.1111111111999000111111111111222222222222220200202020202020020202020202222]
```
由打印结果可以看到，对于两端带空格的字符串，在进行参数绑定后，已经自动trim。
这仅仅实现了50%的工作量，另一部分，则是JSON中字符串值的trim。

### 后50%：请求体JSON中字符串trim

SpringMVC通过`@RequestBody`来处理`application/json`的HTTP请求，将json数据反序列化为某对象，已完成在Controller方法中使用对象接收请求体，常见使用场景如：新增实体、更新实体等。使用`@ResponseBody`将数据以Json形式发送给响应HTTP响应对象。我们从日常开发中得知，并且通过官方文档进一步证实SpringMVC使用Jackson处理以上的请求和响应。对于请求的json中数据的处理，必定要采用扩展Jackson的反序列化操作才可以优雅的实现，那么如何操作呢？在Spring项目开发当中，没有什么是文档和社区提供不了的。

#### 1、Spring对请求响应的处理过程
首先看一下java中请求和响应的处理过程。Http请求和响应的报文其实都是字符串，请求和响应报文在java程序会被封装为`ServletInputStream`和`ServletOutputStream`流对象，从`ServletInputStream`中读取请求报文，从`ServletOutputStream`中输出响应报文。从流对象中只能读取到原始的字符串报文，同样输出流也是。那么在报文到达SpringMVC和从SpringMVC出去，都存在一个字符串到java对象的转化问题。这一过程，在SpringMVC中，是通过`HttpMessageConverter`这个对象来解决的。大概的处理过程如下：
![Spring的请求响应过程](/images/请求响应.png)

#### 2、HttpMessageConverter
官方文档[Enabling the MVC Java Config or the MVC XML Namespace](https://docs.spring.io/spring/docs/4.3.24.RELEASE/spring-framework-reference/htmlsingle/#mvc-config-enable) 小节中提及到，使用`<mvc:annotation-driven/>`注解在`DispatchServlet`上下文中定义并弃用MVC的Java配置。开启该配置，会自动注册`RequestMappingHandlerMapping`，`RequestMappingHandlerAdapter`和`ExceptionHandlerExceptionResolver`（以及其他），以支持使用带注释的控制器方法处理请求。
> 注意，此处添加该配置会自动注册`RequestMappingHandlerAdapter`，这就是为什么在上一节配置`webBindingInitializer`时`RequestMappingHandlerAdapter`Bean对象要在`<mvc:annotation-driven/>`配置前书写的原因，因为后面的配置会不生效。
该配置还支持许多功能，详见官方文档该小节中列出的支持的功能列表。其中，`HttpMessageConverter`映入眼帘，正是刚刚所提及到的。


官方给出如下说明：
> HttpMessageConverter support for @RequestBody method parameters and @ResponseBody method return values from @RequestMapping or @ExceptionHandler methods.
大意是`HttpMessageConverter`支持对`@RequestBody`注解的方法的参数以及`@ResponseBody`注解的方法的返回值进行处理。
`<mvc:annotation-driven/>`配置默认启用了一下几种消息转换器：
1. ByteArrayHttpMessageConverter converts byte arrays.
2. StringHttpMessageConverter converts strings.
3. ResourceHttpMessageConverter converts to/from org.springframework.core.io.Resource for all media types.
4. SourceHttpMessageConverter converts to/from a javax.xml.transform.Source.
5. FormHttpMessageConverter converts form data to/from a MultiValueMap<String, String>.
6. Jaxb2RootElementHttpMessageConverter converts Java objects to/from XML — added if JAXB2 is present and Jackson 2 
7. XML extension is not present on the classpath.
8. MappingJackson2HttpMessageConverter converts to/from JSON — added if Jackson 2 is present on the classpath.
9. MappingJackson2XmlHttpMessageConverter converts to/from XML — added if Jackson 2 XML extension is present on the classpath.
10. AtomFeedHttpMessageConverter converts Atom feeds — added if Rome is present on the classpath.
11. RssChannelHttpMessageConverter converts RSS feeds — added if Rome is present on the classpath.

通过该列表可以看到，对于JSON的处理，Spring提供了`org.springframework.http.converter.json.MappingJackson2HttpMessageConverter`转换器，看一下这是个什么玩儿楞~

#### 3、MappingJackson2

该类的全限定类名为`org.springframework.http.converter.json.MappingJackson2HttpMessageConverter`，通过获取源码查看注释了解到，该转换器使用`Jackson 2.x`的`ObjectMapper`读写JSON，此转换器可用于反序列化为某类型的Java类或无类型的HashMap实例。 默认情况下，此转换器支持带有UTF-8字符集的`application/json`和`application/*+json`。可以通过设置该对象的`supportedMediaTypes`属性覆盖支持的`media-type`列表。下图是该转换器的UML图

![继承关系](/images/mappingJackson2继承关系.png)

其直接父类`org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter`内部实现如下：
```java
public abstract class AbstractJackson2HttpMessageConverter extends AbstractGenericHttpMessageConverter<Object> {

	protected ObjectMapper objectMapper;

	public void setObjectMapper(ObjectMapper objectMapper) {
		Assert.notNull(objectMapper, "ObjectMapper must not be null");
		this.objectMapper = objectMapper;
		configurePrettyPrint();
	}
    
    // ~ 省略部分代码
}
```
看到在父类中有一个访问权限为`protected`的`ObjectMapper`类型对象，在刚刚了解到`MappingJackson2HttpMessageConverter`转换器使用`com.fasterxml.jackson.databind.ObjectMapper`对象对JSON进行读写，并且其父类还有对该对象的Setter方法，hie ~ hie ~ 又可以进行扩展啦
#### 4、ObjectMapper是啥
来自官方的解释
> ObjectMapper provides functionality for reading and writing JSON, either to and from basic POJOs (Plain Old Java Objects), or to and from a general-purpose JSON Tree Model (JsonNode), as well as related functionality for performing conversions.
> ObjectMapper提供了从基本POJO（普通Java对象）或从通用JSON树模型（JsonNode）读取和写入JSON的功能，以及用于执行转换的相关功能。
这是个牛逼的角色，在Spring对JSON进行反序列化的时候，会使用消息转换器进行转换，那么内部实现就是通过该对象对JSON进行读取操作。通过阅读源码了解到，该类内部有一个`<T> T readValue(JsonParser jp, Class<T> valueType)`方法，该方法的作用是将JSON内容反序列化为Java对象、数组或包装类型。官方给出提示：

> Note: this method should NOT be used if the result type is a container ({@link java.util.Collection} or {@link java.util.Map}. The reason is that due to type erasure, key and value types can not be introspected when using this method.
大意是，由于由于类型擦除的影响，对于java.util.Collection或java.util.Map类型，则不应使用此方法。

#### 5、JsonParser是啥
`ObjectMapper`对象`<T> T readValue(JsonParser jp, Class<T> valueType)`方法第一个参数为`com.fasterxml.jackson.core.JsonParser`对象，他是用于读取JSON内容的公共API的基类，找到如下方法`ObjectMapper registerModule(Module module);`，该方法用于注册可以扩展由该映射器提供的功能，例如，通过添加自定义序列化和反序列化器，哎哟~ 小火鸡~~
该方法的参数为`com.fasterxml.jackson.databind.Module`接口对象，通过查找其子类发现就特么一个`com.fasterxml.jackson.databind.module.SimpleModule`类~看一下这个类都提供什么扩展点
- <T> SimpleModule addSerializer(Class<? extends T> type, JsonSerializer<T> ser); // 为某类型添加序列化器
- <T> SimpleModule addDeserializer(Class<T> type, JsonDeserializer<? extends T> deser); // 为某类型添加反序列化器

在添加反序列化器方法中，第二个参数为`com.fasterxml.jackson.databind.JsonDeserializer`接口类型对象，阅读该接口源码文档发现该类的类注释写着大大的：

> Custom deserializers should usually not directly extend this class, but instead extend {@link com.fasterxml.jackson.databind.deser.std.StdDeserializer} (or its subtypes like {@link com.fasterxml.jackson.databind.deser.std.StdScalarDeserializer}).
大意是自定义反序列化器通常不应直接扩展此类，而是扩展`com.fasterxml.jackson.databind.deser.std.StdDeserializer`（或其子类）

Ok~ 大致了解结构了吧，开干

#### 6、扩展ObjectMapper

创建一个类，取一个一眼就能看出来和`ObjectMapper`有血缘关系的名字，并继承该抽象类，在该类初始化时注册扩展点。
```java
public class CustomObjectMapper extends ObjectMapper {
    public CustomObjectMapper() {
        /*
            调用ObjectMapper的registerModule方法添加扩展点
            此处使用匿名对象直接new SimpleModul添加扩展功能
        */
        registerModule(new SimpleModule() {
            {
                /*
                    注册对于String类型值对象的反序列化器
                    对于反序列化器直接new StdDeserializer的子类StdScalarDeserializer完成
                */
                addDeserializer(String.class, new StdScalarDeserializer<String>(String.class) {
                    @Override
                    public String deserialize(JsonParser jp, DeserializationContext context) throws IOException {
                        return StringUtils.trim(jp.getValueAsString());
                    }
                });
                // ... 也可自定义其他类型序列化和反序列化器，例如：蛋疼的日期类型...
            }
        });
    }
}
```

通过`org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter`对象的`messageConverters`属性可以配置消息转换器，还记得前面我们讲的Spring提供的`MappingJackson2HttpMessageConverter`JSON消息转换器吗，就是他，他父类中的`objectMapper`参数可以配置`ObjectMapper`对象的扩展点，Perfect~ 配置如下

```xml
<!--手动配置RequestMappingHandlerAdapter实现自定义扩展-->
<bean class="org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter">
    <property name="cacheSeconds" value="0"/>
    <!--添加自定义参数绑定-->
    <property name="webBindingInitializer">
        <bean class="cc.chenzhihao.study.springmvc.config.CustomWebBindingInitializer"/>
    </property>
    <!--实现自定义Jackson消息转换，已完成以json形式对对象进行序列化和反序列化以及配置支持的media-type-->
    <property name="messageConverters">
        <bean class="org.springframework.http.converter.json.MappingJackson2HttpMessageConverter">
            <property name="objectMapper">
                <bean class="cc.chenzhihao.study.springmvc.config.CustomObjectMapper"/>
            </property>
            <property name="supportedMediaTypes">
                <list>
                    <value>text/plain;charset=UTF-8</value>
                    <value>application/json;charset=UTF-8</value>
                </list>
            </property>
        </bean>
    </property>
</bean>
```

#### 8、测试JSON的trim效果

```java
/**
 * json请求体重Strng类型参数进行trim测试
 *
 * @param user 请求体对象
 * @return 响应
 */
@RequestMapping(value = "/body", method = RequestMethod.POST)
@ResponseBody
public User testTrimRequestBody(@RequestBody User user) {
    System.out.println(String.format("body is %s", user.toString()));
    return user;
}
```
请求json：
```json
{
	"name":"               chenzhihao    ",
	"phone":"                     12     "
}
```
后端解析后：
```json
{"name":"chenzhihao","phone":"12"}
```

## 源码
[点击查看](https://github.com/24tt/spring-learning/tree/master/springmvc-trim)
