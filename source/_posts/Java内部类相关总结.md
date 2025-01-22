---
published: false
title: Java内部类相关总结
date: 2020-03-30 11:08:51
categories: 技术
tags: 
    - java
    - 内部类
---
说起内部类这个词儿，感觉既熟悉又陌生。熟悉，是因为开发中经常会用到；陌生，是因为即使开发中经常用到，但对底层实现不是很了解。我在写这篇文章之前，对内部类的一些细节一直存在忙点，直至在面试中遇到内部类相关的问题才顿悟，是时候总结一下内部类相关的知识点了。
<!--more-->
Java是一门面向对象的语言，JVM以及大部分本地方法(native)均使用C++来实现，甚至也沿袭了一些C++的设计思想。但是对于C++支持的类多继承这一特性，JAVA选择了割舍，因为多继承会产生歧义，破坏JAVA的封装性。但是面试中我们往往会遇到“JAVA如何实现多继承？”这样的问题，这个问题主要考察面试者对JAVA语言特性的理解。这个问题并没有限制主体，即类的多继承还是接口的多继承，因为接口（Interface）是支持多继承的，单从这一方面来看，一些“聪明的”面试者会回答“JAVA支持多继承，但仅限于接口”。此刻面试者会觉得自己很高明，因为他们抓住了问题的漏洞。但面试官接下来的问题，可能会令面试者思考一番：

> “JAVA的类如何支持多继承？”

## 内部类
在Java中，可以将一个类定义在另一个类或一个方法里面，这样的类被称为内部类（Inner Class）。内部类一般包括这四种：
- 成员内部类
- 静态内部类
- 局部内部类
- 匿名内部类

### 成员内部类
“成员内部类”指的是内部类以类成员的方式出现在外部类之中，他可以拥有像成员属性和成员方法一样的访问权限（private、默认权限、protected和public），示例如下：
```java
public class Outter{
    private int a = 10;

    class Inner {
        public void fun(){
            System.out.println(a);
        }
    }
}
```
上面的示例中，`Inner`类看起来像`Outter`类的一个成员，所以称`Outer`为外部类，`Inner`为`Outter`的成员内部类，该内部类可以访问外部类所有`非静态`的`成员属性`及`成员方法`（包括private）。Java中允许`成员内部类`定义与`外部类或外部类父类`同名的`成员属性`或`成员方法`，此时若`内部类`想要调用`外部类或外部类父类`的`成员属性`或`成员方法`，需要借助以下方式来调用：
```java
外部类名.this.成员属性名; // 调用外部类成员属性
外部类名.this.成员方法名(); // 调用外部类成员方法
外部类名.supper.成员属性名; // 调用外部类父类的成员属性
外部类名.supper.成员方法名(); // 调用外部类父类的成员方法
```
而外部类OuterA若想访问某外部类OuterB的内部类Inner，却不能直接进行访问，需要先创建内部类对象，然后通过该对象的引用来访问内部类。示例如下：
```java
// 第一种
OuterA a = new OuterA();
Inner inner = a.new Inner();
// 第二种
OuterA a = new OuterA().new Inner();
```
以上两种方式均可，其中第二种写法可能不太常见，他是对第一种方是的一种简写。通过内部类的创建，可以看出`成员内部类对象的创建依赖外部类对象`。下面有个小例子，实操一下`成员内部类`的使用方法。

```java
public class Father {
    protected String name = "chenzhihao";
}

public class Outer extends Father {
    
    private int a = 1;
    private int b = 2;

    private class Inner {
        private int a = 3;

        public void fun() {
            System.out.println(a);
            System.out.println(this.a);
            System.out.println(b);
            System.out.println(Outer.this.a);
            System.out.println(Outer.this.b);
            System.out.println(Outer.super.name);
        }
    }

    public static void main(String[] args) {
        Inner inner = new Outer().new Inner();
        inner.fun();
    }
}
```
输出结果
```shell
3
3
2
1
2
chenzhihao
```
从上面例子的输出结果可以看出，成员内部类中`this`为当前`内部类对象`的引用，而`外部类.this`和`外部类.supper`分别对应`外部类`和`外部类父类`的引用。了解到这，我已经安耐不住“刨根问底”的心情想了解一下内部实现原理了，头两天研究Java字符串拼接时用到的Java反编译命令`javap`，是时候使用它一下来满足我的好奇心了。

> javap命令参数简述
> -c 对代码进行反汇编
> -l 输出行号和本地变量表
> -v 输出附加信息
> -p 显示所有类和成员
> -s 输出内部类型签名

常用的`javap`参数基本为以上几个，这里我们先对以上源码进行编译后，会生成`Outer.class`、`Outer$Inner.class`和`Father.class`三个文件，其中`Outer$Inner.class`为内部类编译后的字节码文件，其格式为`外部类名$内部类名.class`。这里我们先不管`Father.class`，他与我们这次讨论的话题无关。接下来在`class`字节码文件目录执行`javap -c -l -v -p -s Outer$Inner`命令，获取内部类反编译结果：
> 注：部分命令行无法反编译内部类，需要添加对$的转义，即：javap -c -l -v -p -s Outer\$Inner

```java
Classfile Outer$Inner.class
  Last modified 2020-3-30; size 1306 bytes
  MD5 checksum 0b9c2a090315315b44b048c975d1e661
  Compiled from "Outer.java"
class Outer$Inner
  minor version: 0
  major version: 52
  flags: ACC_SUPER
Constant pool:
   #1 = Methodref          #11.#36        // Outer$Inner."<init>":(LOuter;)V
   #2 = Fieldref           #11.#37        // Outer$Inner.this$0:LOuter;
   #3 = Methodref          #12.#38        // java/lang/Object."<init>":()V
   #4 = Fieldref           #11.#39        // Outer$Inner.a:I
   #5 = Fieldref           #40.#41        // java/lang/System.out:Ljava/io/PrintStream;
   #6 = Methodref          #42.#43        // java/io/PrintStream.println:(I)V
   #7 = Methodref          #44.#45        // Outer.access$000:(LOuter;)I
   #8 = Methodref          #44.#46        // Outer.access$100:(LOuter;)I
   #9 = Methodref          #44.#47        // Outer.access$201:(LOuter;)Ljava/lang/String;
  #10 = Methodref          #42.#48        // java/io/PrintStream.println:(Ljava/lang/String;)V
  #11 = Class              #49            // Outer$Inner
  #12 = Class              #50            // java/lang/Object
  #13 = Utf8               a
  #14 = Utf8               I
  #15 = Utf8               this$0
  #16 = Utf8               LOuter;
  #17 = Utf8               <init>
  #18 = Utf8               (LOuter;)V
  #19 = Utf8               Code
  #20 = Utf8               LineNumberTable
  #21 = Utf8               LocalVariableTable
  #22 = Utf8               this
  #23 = Utf8               Inner
  #24 = Utf8               InnerClasses
  #25 = Utf8               LOuter$Inner;
  #26 = Utf8               MethodParameters
  #27 = Utf8               fun
  #28 = Utf8               ()V
  #29 = Class              #51            // Outer$1
  #30 = Utf8               (LOuter;LOuter$1;)V
  #31 = Utf8               x0
  #32 = Utf8               x1
  #33 = Utf8               LOuter$1;
  #34 = Utf8               SourceFile
  #35 = Utf8               Outer.java
  #36 = NameAndType        #17:#18        // "<init>":(LOuter;)V
  #37 = NameAndType        #15:#16        // this$0:LOuter;
  #38 = NameAndType        #17:#28        // "<init>":()V
  #39 = NameAndType        #13:#14        // a:I
  #40 = Class              #52            // java/lang/System
  #41 = NameAndType        #53:#54        // out:Ljava/io/PrintStream;
  #42 = Class              #55            // java/io/PrintStream
  #43 = NameAndType        #56:#57        // println:(I)V
  #44 = Class              #58            // Outer
  #45 = NameAndType        #59:#60        // access$000:(LOuter;)I
  #46 = NameAndType        #61:#60        // access$100:(LOuter;)I
  #47 = NameAndType        #62:#63        // access$201:(LOuter;)Ljava/lang/String;
  #48 = NameAndType        #56:#64        // println:(Ljava/lang/String;)V
  #49 = Utf8               Outer$Inner
  #50 = Utf8               java/lang/Object
  #51 = Utf8               Outer$1
  #52 = Utf8               java/lang/System
  #53 = Utf8               out
  #54 = Utf8               Ljava/io/PrintStream;
  #55 = Utf8               java/io/PrintStream
  #56 = Utf8               println
  #57 = Utf8               (I)V
  #58 = Utf8               Outer
  #59 = Utf8               access$000
  #60 = Utf8               (LOuter;)I
  #61 = Utf8               access$100
  #62 = Utf8               access$201
  #63 = Utf8               (LOuter;)Ljava/lang/String;
  #64 = Utf8               (Ljava/lang/String;)V
{
  private int a;
    descriptor: I
    flags: ACC_PRIVATE

  final Outer this$0;
    descriptor: LOuter;
    flags: ACC_FINAL, ACC_SYNTHETIC

  private Outer$Inner(Outer);
    descriptor: (LOuter;)V
    flags: ACC_PRIVATE
    Code:
      stack=2, locals=2, args_size=2
         0: aload_0
         1: aload_1
         2: putfield      #2                  // Field this$0:LOuter;
         5: aload_0
         6: invokespecial #3                  // Method java/lang/Object."<init>":()V
         9: aload_0
        10: iconst_3
        11: putfield      #4                  // Field a:I
        14: return
      LineNumberTable:
        line 15: 0
        line 16: 9
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      15     0  this   LOuter$Inner;
    MethodParameters:
      Name                           Flags
      this$0                         final synthetic

  public void fun();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: aload_0
         4: getfield      #4                  // Field a:I
         7: invokevirtual #6                  // Method java/io/PrintStream.println:(I)V
        10: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        13: aload_0
        14: getfield      #4                  // Field a:I
        17: invokevirtual #6                  // Method java/io/PrintStream.println:(I)V
        20: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        23: aload_0
        24: getfield      #2                  // Field this$0:LOuter;
        27: invokestatic  #7                  // Method Outer.access$000:(LOuter;)I
        30: invokevirtual #6                  // Method java/io/PrintStream.println:(I)V
        33: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        36: aload_0
        37: getfield      #2                  // Field this$0:LOuter;
        40: invokestatic  #8                  // Method Outer.access$100:(LOuter;)I
        43: invokevirtual #6                  // Method java/io/PrintStream.println:(I)V
        46: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        49: aload_0
        50: getfield      #2                  // Field this$0:LOuter;
        53: invokestatic  #7                  // Method Outer.access$000:(LOuter;)I
        56: invokevirtual #6                  // Method java/io/PrintStream.println:(I)V
        59: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        62: aload_0
        63: getfield      #2                  // Field this$0:LOuter;
        66: invokestatic  #9                  // Method Outer.access$201:(LOuter;)Ljava/lang/String;
        69: invokevirtual #10                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        72: return
      LineNumberTable:
        line 19: 0
        line 20: 10
        line 21: 20
        line 22: 33
        line 23: 46
        line 24: 59
        line 25: 72
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      73     0  this   LOuter$Inner;

  Outer$Inner(Outer, Outer$1);
    descriptor: (LOuter;LOuter$1;)V
    flags: ACC_SYNTHETIC
    Code:
      stack=2, locals=3, args_size=3
         0: aload_0
         1: aload_1
         2: invokespecial #1                  // Method "<init>":(LOuter;)V
         5: return
      LineNumberTable:
        line 15: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       6     0  this   LOuter$Inner;
            0       6     1    x0   LOuter;
            0       6     2    x1   LOuter$1;
}
SourceFile: "Outer.java"
InnerClasses:
     private #23= #11 of #44; //Inner=class Outer$Inner of class Outer
     static #29; //class Outer$1

```

#### 成员内部类编译结果分析
##### 外部类对象引用
- 第79行（`final Outer this$0;`），编译器在对成员内部类编译时，自动插入了一个常量`this$0`，且该变量时Outer对象的引用。咿？成员内部类持有外部类的引用，有猫腻！该常量既然出现，肯定需要在初始化时赋值，接下来看内部类的构造函数反编译后的内容。
- 第83~105行是内部类的构造函数反编译结果。这里的方法签名很奇怪，编译器自动为内部类的构造函数添加了一个Outer类型的形参，接收一个外部类对象。在代码区（`code`）第90行，通过JVM的`putfield`命令将`Outer`对象赋值给`this$0`常量。

通过以上分析，得知编译器会为内部类构造函数添加一个类型为外部类类型的形参，接收一个外部类对象，并在内部类对象初始化时持有该外部类对象，且该对象的引用还是一个不可变的常量。这为成员内部类与外部类的数据访问奠定了基础。

##### 内部类的成员访问
第113~116行和第117~120行，分别为`System.out.println(a);`与`System.out.println(this.a);`的编译结果，可见两种方式的编译结果实际上是相同的，源码编译后`this`参数被去除。证明单独对成员的访问和通过this关键字对成员进行访问本质上无差别，都是访问当前类对象的成员。

##### 外部类的成员访问
- 第122~125行和第131~135行，分别为`System.out.println(b);`与`System.out.println(Outer.this.b);`的编译结果，这两种方式都是在成员内部类中访问外部类成员，可见两种方式编译结果也是相同的，源码编译后，均调用了外部类相同的方法——`access$000`，该方法稍后再说
- 第126~130行为`System.out.println(Outer.this.a);`的编译结果，与`System.out.println(a);`编译结果有所不同，此处他也是访问父类的成员，调用了父类的`access$100`方法，该方法稍后再说
##### 外部类父类的成员访问
第136~139行为`System.out.println(Outer.super.name);`的编译结果，编译结果显示，其调用了外部类的`access$201`方法，该方法稍后再说

通过对内部类编译结果的分析可知，编译器对内部类编译后的结果进行了处理，为其添加了一个外部类对象的常量引用，并通过编译期修改内部类构造函数，传入外部类对象引用的方式为该常量赋值，达到内部类持有外部类对象引用的目的，为成员内部类访问外部类成员奠定了基础。访问外部类以及外部类父类成员，均调用了外部类的一簇方法，这些方法的命名格式统一为`access$iii`（iii为编译器分配的数字）。至此，成员内部类的编译结果已经不足以说明问题了，接下来，看一下编译器对外部类都干了些什么。

#### 外部类编译结果分析
执行`javap -c -l -v -p -s Outer`命令，获取外部类反编译结果：
```java
Classfile Outer.class
  Last modified 2020-3-30; size 1294 bytes
  MD5 checksum cd4a64a47cae124234a2c8704d4cb140
  Compiled from "Outer.java"
public class Outer extends Father
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Fieldref           #11.#40        // Father.name:Ljava/lang/String;
   #2 = Fieldref           #6.#41         // Outer.a:I
   #3 = Fieldref           #6.#42         // Outer.b:I
   #4 = Methodref          #11.#43        // Father."<init>":()V
   #5 = Class              #44            // Outer$Inner
   #6 = Class              #45            // Outer
   #7 = Methodref          #6.#43         // Outer."<init>":()V
   #8 = Methodref          #46.#47        // java/lang/Object.getClass:()Ljava/lang/Class;
   #9 = Methodref          #5.#48         // Outer$Inner."<init>":(LOuter;LOuter$1;)V
  #10 = Methodref          #5.#49         // Outer$Inner.fun:()V
  #11 = Class              #50            // Father
  #12 = Class              #51            // Outer$1
  #13 = Utf8               InnerClasses
  #14 = Utf8               Inner
  #15 = Utf8               a
  #16 = Utf8               I
  #17 = Utf8               b
  #18 = Utf8               <init>
  #19 = Utf8               ()V
  #20 = Utf8               Code
  #21 = Utf8               LineNumberTable
  #22 = Utf8               LocalVariableTable
  #23 = Utf8               this
  #24 = Utf8               LOuter;
  #25 = Utf8               main
  #26 = Utf8               ([Ljava/lang/String;)V
  #27 = Utf8               args
  #28 = Utf8               [Ljava/lang/String;
  #29 = Utf8               inner
  #30 = Utf8               LOuter$Inner;
  #31 = Utf8               MethodParameters
  #32 = Utf8               access$000
  #33 = Utf8               (LOuter;)I
  #34 = Utf8               x0
  #35 = Utf8               access$100
  #36 = Utf8               access$201
  #37 = Utf8               (LOuter;)Ljava/lang/String;
  #38 = Utf8               SourceFile
  #39 = Utf8               Outer.java
  #40 = NameAndType        #52:#53        // name:Ljava/lang/String;
  #41 = NameAndType        #15:#16        // a:I
  #42 = NameAndType        #17:#16        // b:I
  #43 = NameAndType        #18:#19        // "<init>":()V
  #44 = Utf8               Outer$Inner
  #45 = Utf8               Outer
  #46 = Class              #54            // java/lang/Object
  #47 = NameAndType        #55:#56        // getClass:()Ljava/lang/Class;
  #48 = NameAndType        #18:#57        // "<init>":(LOuter;LOuter$1;)V
  #49 = NameAndType        #58:#19        // fun:()V
  #50 = Utf8               Father
  #51 = Utf8               Outer$1
  #52 = Utf8               name
  #53 = Utf8               Ljava/lang/String;
  #54 = Utf8               java/lang/Object
  #55 = Utf8               getClass
  #56 = Utf8               ()Ljava/lang/Class;
  #57 = Utf8               (LOuter;LOuter$1;)V
  #58 = Utf8               fun
{
  private int a;
    descriptor: I
    flags: ACC_PRIVATE

  private int b;
    descriptor: I
    flags: ACC_PRIVATE

  public Outer();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: aload_0
         1: invokespecial #4                  // Method Father."<init>":()V
         4: aload_0
         5: iconst_1
         6: putfield      #2                  // Field a:I
         9: aload_0
        10: iconst_2
        11: putfield      #3                  // Field b:I
        14: return
      LineNumberTable:
        line 10: 0
        line 12: 4
        line 13: 9
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      15     0  this   LOuter;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=4, locals=2, args_size=1
         0: new           #5                  // class Outer$Inner
         3: dup
         4: new           #6                  // class Outer
         7: dup
         8: invokespecial #7                  // Method "<init>":()V
        11: dup
        12: invokevirtual #8                  // Method java/lang/Object.getClass:()Ljava/lang/Class;
        15: pop
        16: aconst_null
        17: invokespecial #9                  // Method Outer$Inner."<init>":(LOuter;LOuter$1;)V
        20: astore_1
        21: aload_1
        22: invokevirtual #10                 // Method Outer$Inner.fun:()V
        25: return
      LineNumberTable:
        line 29: 0
        line 30: 21
        line 31: 25
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      26     0  args   [Ljava/lang/String;
           21       5     1 inner   LOuter$Inner;
    MethodParameters:
      Name                           Flags
      args

  static int access$000(Outer);
    descriptor: (LOuter;)I
    flags: ACC_STATIC, ACC_SYNTHETIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: getfield      #3                  // Field b:I
         4: ireturn
      LineNumberTable:
        line 10: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0    x0   LOuter;

  static int access$100(Outer);
    descriptor: (LOuter;)I
    flags: ACC_STATIC, ACC_SYNTHETIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: getfield      #2                  // Field a:I
         4: ireturn
      LineNumberTable:
        line 10: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0    x0   LOuter;

  static java.lang.String access$201(Outer);
    descriptor: (LOuter;)Ljava/lang/String;
    flags: ACC_STATIC, ACC_SYNTHETIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: getfield      #1                  // Field Father.name:Ljava/lang/String;
         4: areturn
      LineNumberTable:
        line 10: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0    x0   LOuter;
}
SourceFile: "Outer.java"
InnerClasses:
     static #12; //class Outer$1
     private #14= #5 of #6; //Inner=class Outer$Inner of class Outer

```
在外部类的反编译结果中发现了`access$iii`方法，他们的方法签名分别为：
- `static int access$000(Outer);`
- `static int access$100(Outer);`
- `static java.lang.String access$201(Outer);`

这三个方法并非我们源码中添加的，而是编译器为内部类自动生成的，这些方法是编译器为解决内部类访问外部类成员时提供的一种策略。他们实现方式基本无差别，通过传入外部类对象，并使用该对象进行操作。其中对于属性的访问，使用`getfield` JVM命令实现。

有些同学可能会说，这样会安全吗？当然，我看到这的时候也去尝试调用该方法，但是编译时就出错了，我尝试通过反射调用该方法，同样出现异常。因为该方法是禁止在程序中调用的，而是编译器未解决内部类访问外部类属性提供的一种手段，在编译期和运行期禁止程序对这些方法的调用。

### 静态内部类
静态内部类是以外部类静态属性的方式存在的，静态内部类不需要依赖外部类，即在没有外部类对象的情况下即可创建内部类对象。可以把他理解为静态变量或静态方法。静态内部类只能访问外部类或外部类父类的静态成员和方法，不能访问非静态成员和方法。因为类的成员是依赖于类实例对象存在而存在的，在没有外部类对象的情况下，静态内部类对象仍然可以创建，但是外部类的成员属性还没被初始化，所以不允许调用。
静态内部类的写法大致如下：
```java
public class Outer{
    public static int a = 10;
    public int b = 2;

    private static class Inner {
        private int a = 3;

        public void fun() {
            System.out.println(a);
            System.out.println(Outer.a);
            //System.out.println(b);  // 编译报错
        }
    }

    public static void main(String[] args) {
        Inner inner = new Outer.Inner();
        inner.fun();
    }
}
```
上述代码执行后输出：
```java
3
10
```
#### 静态内部类反编译结果
直接通过`javap -c -l -v -p -s Outer$Inner`命令查看内部类反编译结果如下：
```java
Classfile Outer$Inner.class
  Last modified 2020-3-30; size 843 bytes
  MD5 checksum fb1cafed1018f46f3c57fc23c3be5480
  Compiled from "Outer.java"
class Outer$Inner
  minor version: 0
  major version: 52
  flags: ACC_SUPER
Constant pool:
   #1 = Methodref          #7.#27         // Outer$Inner."<init>":()V
   #2 = Methodref          #8.#27         // java/lang/Object."<init>":()V
   #3 = Fieldref           #7.#28         // Outer$Inner.a:I
   #4 = Fieldref           #29.#30        // java/lang/System.out:Ljava/io/PrintStream;
   #5 = Methodref          #31.#32        // java/io/PrintStream.println:(I)V
   #6 = Fieldref           #33.#28        // Outer.a:I
   #7 = Class              #34            // Outer$Inner
   #8 = Class              #35            // java/lang/Object
   #9 = Utf8               a
  #10 = Utf8               I
  #11 = Utf8               <init>
  #12 = Utf8               ()V
  #13 = Utf8               Code
  #14 = Utf8               LineNumberTable
  #15 = Utf8               LocalVariableTable
  #16 = Utf8               this
  #17 = Utf8               Inner
  #18 = Utf8               InnerClasses
  #19 = Utf8               LOuter$Inner;
  #20 = Utf8               fun
  #21 = Class              #36            // Outer$1
  #22 = Utf8               (LOuter$1;)V
  #23 = Utf8               x0
  #24 = Utf8               LOuter$1;
  #25 = Utf8               SourceFile
  #26 = Utf8               Outer.java
  #27 = NameAndType        #11:#12        // "<init>":()V
  #28 = NameAndType        #9:#10         // a:I
  #29 = Class              #37            // java/lang/System
  #30 = NameAndType        #38:#39        // out:Ljava/io/PrintStream;
  #31 = Class              #40            // java/io/PrintStream
  #32 = NameAndType        #41:#42        // println:(I)V
  #33 = Class              #43            // Outer
  #34 = Utf8               Outer$Inner
  #35 = Utf8               java/lang/Object
  #36 = Utf8               Outer$1
  #37 = Utf8               java/lang/System
  #38 = Utf8               out
  #39 = Utf8               Ljava/io/PrintStream;
  #40 = Utf8               java/io/PrintStream
  #41 = Utf8               println
  #42 = Utf8               (I)V
  #43 = Utf8               Outer
{
  private int a;
    descriptor: I
    flags: ACC_PRIVATE

  private Outer$Inner();
    descriptor: ()V
    flags: ACC_PRIVATE
    Code:
      stack=2, locals=1, args_size=1
         0: aload_0
         1: invokespecial #2                  // Method java/lang/Object."<init>":()V
         4: aload_0
         5: iconst_3
         6: putfield      #3                  // Field a:I
         9: return
      LineNumberTable:
        line 15: 0
        line 16: 4
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      10     0  this   LOuter$Inner;

  public void fun();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: aload_0
         4: getfield      #3                  // Field a:I
         7: invokevirtual #5                  // Method java/io/PrintStream.println:(I)V
        10: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
        13: getstatic     #6                  // Field Outer.a:I
        16: invokevirtual #5                  // Method java/io/PrintStream.println:(I)V
        19: return
      LineNumberTable:
        line 19: 0
        line 20: 10
        line 22: 19
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      20     0  this   LOuter$Inner;

  Outer$Inner(Outer$1);
    descriptor: (LOuter$1;)V
    flags: ACC_SYNTHETIC
    Code:
      stack=1, locals=2, args_size=2
         0: aload_0
         1: invokespecial #1                  // Method "<init>":()V
         4: return
      LineNumberTable:
        line 15: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   LOuter$Inner;
            0       5     1    x0   LOuter$1;
}
SourceFile: "Outer.java"
InnerClasses:
     private static #17= #7 of #33; //Inner=class Outer$Inner of class Outer
     static #21; //class Outer$1

```
第76~95行为fun方法调用处理方式，其中请注意第86行，通过JVM`getstatic`指令，获取外部类Outer的`a`属性。这个属性什么时候被赋值的呢？篇幅原因，不列举外部类反编译的全部内容，仅列举关键内容如下：
```java
  static {};
    descriptor: ()V
    flags: ACC_STATIC
    Code:
      stack=1, locals=0, args_size=0
         0: bipush        10
         2: putstatic     #6                  // Field a:I
         5: return
      LineNumberTable:
        line 12: 0
```
上述内容为Outer反编译后的部分内容，这组静态代码中，通过`bipush`以及`putstatic`两个JVM指令，分别进行了常量10的入栈以及对静态变量`a`的赋值动作。对此仍然好奇的同学，可以自己尝试并深入研究一下。

### 局部内部类
局部内部类被定义在方法、代码块或某些作用域的内部，与局部变量的性质类似，他不可以被访问修饰符所修饰，且该内部类的范围仅限于该作用域之中，正常情况下，作用域结束，其中的局部变量以及局部内部类都会随之释放。写法大致如下：
```java
public class Outer {

    public int a = 10;

    public void fun() {
        class Inner {
            private int a = 3;

            public void fun() {
                System.out.println(this.a);
                System.out.println(Outer.this.a);
            }
        }
        new Inner().fun();
    }

    //public void error(){
    //    new Inner().fun(); // 编译失败
    //}

    public static void main(String[] args) {
        new Outer().fun();
    }
}
```
#### 局部内部类编译结果
对以上代码编译后，发现输出目录中有`Outer.class`和`Outer$1Inner.class`，其中`Outer$1Inner.class`为fun()方法中的内部类，因为该内部类有名称（Inner），但是作用域仅限fun()方法，为了避免歧义，编译生成的文件格式就没规定成了这个样子。通过`javap -c -l -v -p -s Outer$Inner`命令反编译，查看该内部类的编译结果：
```java
Classfile Outer$1Inner.class
  Last modified 2020-3-30; size 820 bytes
  MD5 checksum 9fd67259394c8412da7670e8d762469a
  Compiled from "Outer.java"
class Outer$1Inner
  minor version: 0
  major version: 52
  flags: ACC_SUPER
Constant pool:
   #1 = Fieldref           #7.#30         // Outer$1Inner.this$0:LOuter;
   #2 = Methodref          #8.#31         // java/lang/Object."<init>":()V
   #3 = Fieldref           #7.#32         // Outer$1Inner.a:I
   #4 = Fieldref           #33.#34        // java/lang/System.out:Ljava/io/PrintStream;
   #5 = Methodref          #35.#36        // java/io/PrintStream.println:(I)V
   #6 = Fieldref           #28.#32        // Outer.a:I
   #7 = Class              #37            // Outer$1Inner
   #8 = Class              #38            // java/lang/Object
   #9 = Utf8               a
  #10 = Utf8               I
  #11 = Utf8               this$0
  #12 = Utf8               LOuter;
  #13 = Utf8               <init>
  #14 = Utf8               (LOuter;)V
  #15 = Utf8               Code
  #16 = Utf8               LineNumberTable
  #17 = Utf8               LocalVariableTable
  #18 = Utf8               this
  #19 = Utf8               Inner
  #20 = Utf8               InnerClasses
  #21 = Utf8               LOuter$1Inner;
  #22 = Utf8               MethodParameters
  #23 = Utf8               fun
  #24 = Utf8               ()V
  #25 = Utf8               SourceFile
  #26 = Utf8               Outer.java
  #27 = Utf8               EnclosingMethod
  #28 = Class              #39            // Outer
  #29 = NameAndType        #23:#24        // fun:()V
  #30 = NameAndType        #11:#12        // this$0:LOuter;
  #31 = NameAndType        #13:#24        // "<init>":()V
  #32 = NameAndType        #9:#10         // a:I
  #33 = Class              #40            // java/lang/System
  #34 = NameAndType        #41:#42        // out:Ljava/io/PrintStream;
  #35 = Class              #43            // java/io/PrintStream
  #36 = NameAndType        #44:#45        // println:(I)V
  #37 = Utf8               Outer$1Inner
  #38 = Utf8               java/lang/Object
  #39 = Utf8               Outer
  #40 = Utf8               java/lang/System
  #41 = Utf8               out
  #42 = Utf8               Ljava/io/PrintStream;
  #43 = Utf8               java/io/PrintStream
  #44 = Utf8               println
  #45 = Utf8               (I)V
{
  private int a;
    descriptor: I
    flags: ACC_PRIVATE

  final Outer this$0;
    descriptor: LOuter;
    flags: ACC_FINAL, ACC_SYNTHETIC

  Outer$1Inner(Outer);
    descriptor: (LOuter;)V
    flags:
    Code:
      stack=2, locals=2, args_size=2
         0: aload_0
         1: aload_1
         2: putfield      #1                  // Field this$0:LOuter;
         5: aload_0
         6: invokespecial #2                  // Method java/lang/Object."<init>":()V
         9: aload_0
        10: iconst_3
        11: putfield      #3                  // Field a:I
        14: return
      LineNumberTable:
        line 15: 0
        line 16: 9
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      15     0  this   LOuter$1Inner;
            0      15     1 this$0   LOuter;
    MethodParameters:
      Name                           Flags
      this$0                         final mandated

  public void fun();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: aload_0
         4: getfield      #3                  // Field a:I
         7: invokevirtual #5                  // Method java/io/PrintStream.println:(I)V
        10: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
        13: aload_0
        14: getfield      #1                  // Field this$0:LOuter;
        17: getfield      #6                  // Field Outer.a:I
        20: invokevirtual #5                  // Method java/io/PrintStream.println:(I)V
        23: return
      LineNumberTable:
        line 19: 0
        line 20: 10
        line 21: 23
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      24     0  this   LOuter$1Inner;
}
SourceFile: "Outer.java"
EnclosingMethod: #28.#29                // Outer.fun
InnerClasses:
     #19= #7; //Inner=class Outer$1Inner

```
- 第60行，是不是很熟悉？这与成员内部类的编译结果一致，都是让内部类对象持有一个外部类对象的引用。并且该内部类的构造函数通过传入外部类对象的方式，为该参数绑定值。
- 第99~102行，通过`getfield`JVM命令先获得持有的外部类对象，接着通过外部类对象访问外部类成员。

而外部类反编译后的内容与成员内部类的基本一致，有兴趣的同学自己尝试研究吧，这里不再多说

### 匿名内部类
匿名内部类，顾名思义，就是没有名字的内部类，也是平时我们用到最多的一种内部类。例如：为Thread对象提供一个Runnable接口的实例、Android开发添加一个监听器等、JDK8的Lambda表达式底层实现等，均用到的匿名内部类。以创建一个线程为例，匿名内部类的写法大致如下：
```java
public class Outer {

    public int a = 10;

    public void fun() throws InterruptedException {
        int a = 1;
        Thread thread = new Thread(new Runnable() {

            @Override
            public void run() {
                System.out.println(a);
                System.out.println(Outer.this.a);
            }
        });
        thread.start();
        thread.join();
    }

    public static void main(String[] args) throws InterruptedException {
        new Outer().fun();
    }
}

```
本例输出为：
```
1
10
```
编译后，发现输出目录存在`Outer$1.class`和`Outer.class`两个类，其中`Outer$1.class`为本例中的匿名内部类，因为他没有名字，所以编译器自动为该内部类提供了序号。

#### 外部类反编译结果
通过`javap -c -l -v -p -s  Outer`命令得到一下输出内容：

```java
 public void fun() throws java.lang.InterruptedException;
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=6, locals=3, args_size=1
         0: sipush        999
         3: istore_1
         4: new           #2                  // class java/lang/Thread
         7: dup
         8: new           #3                  // class com/flexible/personal/utils/Outer$1
        11: dup
        12: aload_0
        13: iload_1
        14: invokespecial #4                  // Method com/flexible/personal/utils/Outer$1."<init>":(Lcom/flexible/personal/utils/Outer;I)V
        17: invokespecial #5                  // Method java/lang/Thread."<init>":(Ljava/lang/Runnable;)V
        20: astore_2
        21: aload_2
        22: invokevirtual #6                  // Method java/lang/Thread.start:()V
        25: aload_2
        26: invokevirtual #7                  // Method java/lang/Thread.join:()V
        29: return
      LineNumberTable:
        line 13: 0
        line 14: 4
        line 21: 21
        line 22: 25
        line 23: 29
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      30     0  this   Lcom/flexible/personal/utils/Outer;
            4      26     1     a   I
           21       9     2 thread   Ljava/lang/Thread;
    Exceptions:
      throws java.lang.InterruptedException
```
- 第6，7两行通过`sipush`将数字999入栈，接着将该数值写入变量a中。
- 第14行，调用匿名内部类`Outer$1`的构造函数，将外部类对象以及一个int值传入构造函数中。通过查看该方法的本地变量表（LocalVariableTable）我们可以看到符号`I`即是变量a的值，所以此处将变量a的值传入内部类。注意，此处是值传递，并非引用传递。

#### 匿名内部类反编译结果
通过`javap -c -l -v -p -s  Outer$1`命令得到一下输出内容：
```java
Classfile Outer$1.class
  Last modified 2020-3-30; size 817 bytes
  MD5 checksum cef9401fb86313f60b67f99096ce90d6
  Compiled from "Outer.java"
class Outer$1 implements java.lang.Runnable
  minor version: 0
  major version: 52
  flags: ACC_SUPER
Constant pool:
   #1 = Fieldref           #6.#29         // Outer$1.this$0:LOuter;
   #2 = Fieldref           #6.#30         // Outer$1.val$a:I
   #3 = Methodref          #7.#31         // java/lang/Object."<init>":()V
   #4 = Fieldref           #32.#33        // java/lang/System.out:Ljava/io/PrintStream;
   #5 = Methodref          #34.#35        // java/io/PrintStream.println:(I)V
   #6 = Class              #36            // Outer$1
   #7 = Class              #37            // java/lang/Object
   #8 = Class              #38            // java/lang/Runnable
   #9 = Utf8               val$a
  #10 = Utf8               I
  #11 = Utf8               this$0
  #12 = Utf8               LOuter;
  #13 = Utf8               <init>
  #14 = Utf8               (LOuter;I)V
  #15 = Utf8               Code
  #16 = Utf8               LineNumberTable
  #17 = Utf8               LocalVariableTable
  #18 = Utf8               this
  #19 = Utf8               InnerClasses
  #20 = Utf8               LOuter$1;
  #21 = Utf8               MethodParameters
  #22 = Utf8               run
  #23 = Utf8               ()V
  #24 = Utf8               SourceFile
  #25 = Utf8               Outer.java
  #26 = Utf8               EnclosingMethod
  #27 = Class              #39            // Outer
  #28 = NameAndType        #40:#23        // fun:()V
  #29 = NameAndType        #11:#12        // this$0:LOuter;
  #30 = NameAndType        #9:#10         // val$a:I
  #31 = NameAndType        #13:#23        // "<init>":()V
  #32 = Class              #41            // java/lang/System
  #33 = NameAndType        #42:#43        // out:Ljava/io/PrintStream;
  #34 = Class              #44            // java/io/PrintStream
  #35 = NameAndType        #45:#46        // println:(I)V
  #36 = Utf8               Outer$1
  #37 = Utf8               java/lang/Object
  #38 = Utf8               java/lang/Runnable
  #39 = Utf8               Outer
  #40 = Utf8               fun
  #41 = Utf8               java/lang/System
  #42 = Utf8               out
  #43 = Utf8               Ljava/io/PrintStream;
  #44 = Utf8               java/io/PrintStream
  #45 = Utf8               println
  #46 = Utf8               (I)V
{
  final int val$a;
    descriptor: I
    flags: ACC_FINAL, ACC_SYNTHETIC

  final Outer this$0;
    descriptor: LOuter;
    flags: ACC_FINAL, ACC_SYNTHETIC

  Outer$1(Outer, int);
    descriptor: (LOuter;I)V
    flags:
    Code:
      stack=2, locals=3, args_size=3
         0: aload_0
         1: aload_1
         2: putfield      #1                  // Field this$0:LOuter;
         5: aload_0
         6: iload_2
         7: putfield      #2                  // Field val$a:I
        10: aload_0
        11: invokespecial #3                  // Method java/lang/Object."<init>":()V
        14: return
      LineNumberTable:
        line 14: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      15     0  this   LOuter$1;
            0      15     1 this$0   LOuter;
    MethodParameters:
      Name                           Flags
      this$0                         final mandated
      val$a                          final synthetic

  public void run();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: aload_0
         4: getfield      #2                  // Field val$a:I
         7: invokevirtual #5                  // Method java/io/PrintStream.println:(I)V
        10: return
      LineNumberTable:
        line 18: 0
        line 19: 10
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      11     0  this   LOuter$1;
}
SourceFile: "Outer.java"
EnclosingMethod: #27.#28                // Outer.fun
InnerClasses:
     #6; //class Outer$1

```
- 第65行，编译器修改的内部类的构造函数，接收两个参数，分别是外部类对象以及一个int类型的值。上文的外部类反编译结果中初始化内部类即是调用了这个方法。且在第72行和第75行，分别将这两个参数赋值给了常量`this$0`和`val$a`。请注意，这里做的是值传递操作，即`val$a`是对匿名内部类外部的局部变量`a`的一份值拷贝。
- 第97行，是`System.out.println(a);`语句的反编译核心内容，从反编译结果来看，Java并没有真的去获取局部变量的值，而是使用了`拷贝值`，且该拷贝值是无法修改的。
  

#### 匿名内部类访问外部局部变量
我们都知道Java语法中要求，匿名内部类在访问他所在作用域中的局部变量时，该变量必须为常量（这里的常量不仅仅指被final关键字修饰。还包括可以不使用final修饰，但已经初始化就不可以在被执行写操作）。 上面的例子中，在方法`fun()`中的匿名内部类想要访问该方法的局部变量`a`，实际上Java编译器偷偷的修改了执行过程，通过修改内部类构造函数并在调用他的过程中传入局部变量的`拷贝值`达到优化执行效率的目的，并且该`拷贝值`一经传入内部类，就永远不可以被更改，因为编译器为该值生成了一个常量。为什么Java会这样设计呢？为什么匿名内部类在使用外部局部变量时要求变量为常量呢？

请思考一个场景，当`方法A`中创建了一个线程后，`方法A`执行结束，栈针被释放，`方法A`中的局部变量表也被释放，但是此时线程可能还在执行，即线程的生命周期还没有结束，与之对应的匿名内部类（Runnable对象）的生命周期也没有结束，那么如果该内部类通过引用的方式指向一个变量，那么此时该变量已经变得不可用（已经被释放）。

而Java如此设计有两个好处
1. 通过`值拷贝`的方式将局部变量的值传递给内部类，可以避免因外部作用域生命周期结束使得局部变量失效的问题。
2. `值拷贝`之后，若内部类的内外部均对自己持有的值进行修改操作，会导致该局部变量所对应的语义失效，因此系统数据错乱，所以为了保险起见，内部类访问了局部变量，那么该变量在内部类的内外部均不允许进行写操作，目的是为了保证语法的语义以及防止数据错乱。


## 总结
- 内部类分为`成员内部类`、`静态内部类`、`局部内部类`和`匿名内部类`四种
- `成员内部类`可以理解为外部类的一个非静态成员，其实例化需要依赖外部类的实例对象。简单理解，成员的实例化是在类初始化阶段才会进行内存空间分配，并随类的实例存在于堆内存中，所以`成员内部类`也可以这样理解。
- `静态内部类`可以理解为外部类的一个静态成员，期实例化以来的是外部类Class对象本身，并不是外部类的实例对象本身。简单理解，类成员（static修饰的静态成员）在类准备阶段在方法区进行内存分配，在静态成员进行内存分配之前，类的Class对象早已在方法区实例化完毕，并且暴露了访问类静态成员的全部入口。所以`静态内部类`也可以理解为类的静态成员。
- `局部内部类`可以理解为局部变量，局部变量的生命周期依赖于其所在的作用于，不同作用域内的数据不能互访，且离开该作用域后，局部变量被释放。所以`局部内部类`也可以这样理解。
- `匿名内部类`即没有名字的内部类，仅被用于实例化后提供回调。因为匿名内部类的生命周期不确定，所以在内部类中使用一切外部变量，这些变量必须为常量。
- 所有内部类想要访问自身的成员属性时，可以直接通过`属性名`或`this.属性名`的方式访问。所以`this`在内部类中，指向当前类对象的引用。
- 所有内部类想要访问外部类的成员属性时，可以通过`属性名`或`外部类.this.属性名`或`外部类.supper.属性名`方式访问。
- 内部类的使用场景
  - 通过Thread类对象创建线程时，为该对象提供Runnable实例
  - JDK8的函数式编程、Lambda表达式等底层实现
  - Android开发当中的监听器
  - LinkedList的链表节点类、HashMap的Entry节点、ReentrantLock内部同步器的实现（AQS实例）、以及AQS的Condition实例等。
  - 懒汉式单例模式的一种实现方式，通过访问私有静态内部类持有的静态实例实现单例模式。该方式思路是通过JAVA类加载过程中的初始化锁，达到在JVM层级保证实例在同一类加载器上的唯一性。


本篇通过Java编译结果对内部类进行了简单的总结，本人才疏学浅，如果纰漏或错误，请指正。
