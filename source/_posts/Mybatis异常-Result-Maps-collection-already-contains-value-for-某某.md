---
published: false
title: Mybatis异常 Result Maps collection already contains value for 某某
date: 2019-05-26 11:08:00
categories: 技术
tags: 
    - mybatis
---

开发时最痛恨的是灯下黑的bug，bug就在眼皮子地下被自己的“自作聪明”忽略掉。就在刚刚，我花了近十分钟去解决一个Mybatis报的异常： Result Maps collection already contains value for #￥%。先解释一下该异常信息的意思：Result Maps集合已经存在于#￥%。总之通过异常信息可以确定的是 该文件中有相同的某某某，即有同名的东西存在于一个文件中。着手解决一下吧

<!--more-->

开发时最痛恨的是灯下黑的bug，bug就在眼皮子地下被自己的“自作聪明”忽略掉。就在刚刚，我花了近十分钟去解决一个Mybatis报的异常： Result Maps collection already contains value for #￥%。先解释一下该异常信息的意思：Result Maps集合已经存在于#￥%。总之通过异常信息可以确定的是 该文件中有相同的某某某，即有同名的东西存在于一个文件中。着手解决一下吧

```java
org.apache.ibatis.builder.BuilderException: Error parsing Mapper XML. Cause: java.lang.IllegalArgumentException: Result Maps collection already contains value for cc.chenzhihao.projectName.mapper.custom.QuestionnaireAnswerMapperCustom.BaseResultMap
```

剖析了一遍Mapper文件后发现如下尴（sha）尬（bi）的代码

```xml
<sql id="Base_Column_List" >
    questionnaire_answer_id, question_id, questionnaire_id
</sql>
<sql id="Base_Column_List" >
    questionnaire_answer_id, question_id, questionnaire_id
</sql>
```

发现了同名代码，该知道如何处理了吧
