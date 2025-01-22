---
published: false
title: 【Git爬坡】创建第一个版本库
date: 2019-05-26 13:05:47
categories: 技术
tags: git
---

创建并进入Git仓库本地根目录
```bash
chenzhihao-mac:Study chenzhihao$ mkdir gitlearning
```

在目录内初始化Git版本库
```bash
chenzhihao-mac:gitlearning chenzhihao$ git init
Initialized empty Git repository in /Users/chenzhihao/Documents/Study/gitlearning/.git/
```
执行完`git init`命令后会得到提示`Initialized empty Git repository in /Users/chenzhihao/Documents/Study/gitlearning/.git/`，即在对应目录初始化了一个空的Git仓库。
我们使用如下命令，即可看到在我们的Git仓库本地根目录下存在一个隐藏的`.git`文件夹

```bash
chenzhihao-mac:gitlearning chenzhihao$ ls -a
. .. .git
```
接下来在仓库目录下创建一个文件，并写入一些内容后使用`cat`命令查看文件内容

```bash
chenzhihao-mac:gitlearning chenzhihao$ touch readme.md
chenzhihao-mac:gitlearning chenzhihao$ vi readme.md
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
```

文件已经被创建，但此时该文件还没有被Git管理。使用git add 文件名命令将文件交由Git管理，即将改文件提交到Git暂存区中，此命令可以针对不同文件执行多次。

```bash
chenzhihao-mac:gitlearning chenzhihao$ git add readme.md
```
此时文件仅仅提交到了Git的暂存区中，可以理解为Git刚刚看见了该文件，还没有提交到版本库。接下来使用git commit命令将整个暂存区的所有更改全部提交到Git本地仓库中。
```bash
chenzhihao-mac:gitlearning chenzhihao$ git commit -m "create file readme.md"
[master (root-commit) 3a2897a] create file readme.md
1 file changed, 2 insertions(+)
create mode 100644 readme.md
```
执行完上述代码后，`3a2897a`是本次`commit`的版本号，在日后需要对本次提交做相关操作时，版本号是一次`commit`的唯一识别码。-m参数后接本次提交的注释，最好使用一段有意义的话标注被提交做了什么

经过上述过程之后我们第一个采用Git管理的工程就结束了。

## 总结
- `git init` 初始化本地Git仓库，在该操作目录下生成一个名为`.git`的隐藏文件
- `git add `将更新提交到Git暂存区。这里的更新可以使创建、删除、修改、添加等，可以理解为让Git获取到更改，但还没有被提交
- `git commit` 将暂存区的所有更改一并提交到工作区，即将更改写入本地版本库。其中`-m`参数可以添加一段描述，描述本次提交做了些什么
