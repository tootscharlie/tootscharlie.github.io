---
published: false
title: JDK8之Lambda表达式与函数式接口简述
date: 2019-09-27 17:17:55
categories: 技术
tags: JDK8
---
java8最大的特性就是引入Lambda表达式，即函数式编程，可以将行为进行传递。总结就是：使用不可变值与函数，函数对不可变值进行处理，映射成另一个值。
<!--more-->

## Lambda表达式
### 啰里啰嗦
Java中万事万物皆对象，在JDK8以前，方法只能传递基本数据类型或引用数据类型，然而方法是不可以作为参数传递的。在其他语言中（例如：JavaScript）都已支持Lambda表达式实现函数式编程。当然在JDK8以前版本中也可以使用`带有单一方法的匿名内部类`的方式“伪实现”函数式编程。

### 语法

```java
(/*args list*/) -> {/*function body*/}
// eg
(age, name) -> {System.out.println("姓名:"+name+"，年龄:"+age)}
```

### 使用Lambda创建线程
JDK8以前，使用匿名内部类方式创建线程
```java
Thread thread = new Thread(new Runnable(){
    public void run(){
    @Override
        System.out.println("hello world");
    }
}));
```
使用Lambda表达式实现
```java
Thread thread = new Thread(()->{
    System.out.println("hello world");
})
// 或
Thread thread = new Thread(()->System.out.println("hello world"))
```

## 函数式接口
> 官方定义
> 函数式接口(Functional Interface)就是一个有且仅有一个抽象方法，但是可以有多个非抽象方法的接口。
> 函数式接口可以被隐式转换为 lambda 表达式。

可以将函数式接口理解为对方法（函数）的约定，是对方法的抽象，包括参数列表的个数、类型和顺序，以及有无返回值和返回值的类型，符合条件的方法就可以使用用函数式接口引用类型变量接收

### 自定义函数式接口
#### @FunctionInterface
JDK8新增`@FunctionInterface`注解，用于标注一个接口为函数式接口.
创建一个输入类型为`Integer`输出类型为`String`的函数式接口，用于将数字转换为字符串。

```java
@FunctionInterface
public interface CustomFunction{
    public String apply(Integer number);
}
```
测试类

```java
public class Test{
    public static void main(String[] args){
        // 数字转字符串。
        // ClassName::FunctionName 方法引用
        CustomFunction function1 = String::valueOf;
        // 数字+1转字符串
        CustomFunction function2 = number -> {return String.valueOf(number+1)};

        System.out.println(toString(1, function1)); // 1
        System.out.println(toString(1, function2)); // 2
    }

    public static String toString(int number, CustomFunction function){
        return function.apply(number);
    }
}
```
#### 旧版本兼容
仅有一个抽象方法的接口，也可以作为函数式接口使用。目的是兼容旧版本

### Java自带函数式接口

|  类型  |   函数接口    |     抽象方法      |     功能     | 入参类型 | 返回类型 |               示例                |
| :----: | :-----------: | :---------------: | :----------: | :------: | :------: | :-------------------------------: |
| 功能型 | Function<T,R> |   R apply(T t)    | 输入T，输出R |    T     |    R     | 获取学生（Student）的名字（name） |
| 生产型 |  Supplier<T>  |      T get()      |   生产对象   |    无    |    T     |             工厂方法              |
| 消费型 |  Consumer<T>  | void accept(T t)  |   消费对象   |    T     |    无    |            输出一个值             |
| 断言型 | Predicate<T>  | Boolean test(T t) |   断言真假   |    T     | Boolean  | 该学生（Student）成绩为100分吗？  |

此处使用学生对象Amy为例

```java
public class Test{
    private Student amy;

    @Before
    public void setUp(){
        this.amy = new Student("Amy", 18, 98.0);
    }

    /**
     * 静态内部类：学生
     */
    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    private static class Student{
        private String name;
        private Double score;
    }

    // has more test~
}
```

#### 功能型函数式接口
> 表示输入一个参数，返回一个结果的函数
使用场景：接受一个值，
eg：获取学生对象（amy）的姓名（name）

```java
@Test
public void testFunction() {
    Function<Student, String> getNameFun = Student::getName;
    System.out.println(getNameFun.apply(amy));
}
```

#### 生产型函数式接口
> 表示无入参，返回一个结果的函数

eg：创建一个学生对象
```java
@Test
public void testSupplier() {
    Supplier<Student> newStudentFun = Student::new;
    Student student = newStudentFun.get();
}
```

#### 消费型函数式接口
> 表示一个接收单个输入参数且无返回结果的函数。该函数在一定程度上会对输入参数进行操作，故该操作会有副作用。

eg：修改学生成绩除以2并打印学生信息
```java
@Test
public void testConsumer() {
    Consumer<Student> updStudentNameFun = student -> student.setScore(student.getScore() / 2);
    Consumer<Student> printStudentFun = System.out::println;
    updStudentNameFun.andThen(printStudentFun).accept(amy);
}
```

#### 断言型函数式接口
> 表示一个接收单个参数，并返回Boolean类型结果的函数。该函数用于根据入参进行条件判断，并返回判断结果（true，false）
> 也可以通过`and`和`or`添加多个组合条件

eg：判断学生成绩是否及格（大于60分）
```java
@Test
public void testPredicate() {
    Predicate<Student> isPassedExam = student -> student.getScore() > 60;
    System.out.println(isPassedExam.test(amy));
}
```
