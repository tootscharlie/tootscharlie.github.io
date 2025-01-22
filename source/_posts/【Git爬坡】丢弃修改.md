---
published: false
title: 【Git爬坡】丢弃修改
date: 2019-05-26 13:13:52
categories: 技术
tags: git
---

某天，你修改了一大堆文件，这时候Leader告诉你部分功能舍弃，恰好你写的这些文件就是丢弃功能中的文件，这时候该怎么办呢？这就要看看当时的状态，分为四种情况。

1. 工作区的修改未被添加到暂存区
2. 工作区的修改以被添加到暂存区后，再次修改改文件，但此次修改未添加到暂存区
3. 基于第一种情况下，暂存区的修改已经全部被提交到本地版本库
4. 基于第二种情况下，本地版本库已经被推送到远程仓库
下面是对以上三种情况的详细介绍

## 第一种：修改未添加到暂存区
对某个文件进行修改后，但未将修改的文件添加到暂存区，这时想要恢复该文件到原始状态。需要使用`git checkout -- 文件名`命令
```bash
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
chenzhihao-mac:gitlearning chenzhihao$ vi readme.md
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
 
Test test test test
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
Changes not staged for commit:
(use "git add <file>..." to update what will be committed)
(use "git checkout -- <file>..." to discard changes in working directory)
 
modified: readme.md
 
no changes added to commit (use "git add" and/or "git commit -a")
chenzhihao-mac:gitlearning chenzhihao$ git checkout -- readme.md
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
nothing to commit, working tree clean
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
```

## 第二种：修改暂存区内已有的文件，但本次修改未提交

当我们已经将修改的文件添加到了暂存区，或对已提交到暂存区中的文件进行二次修改时，这时，如果感觉该文件的不应该进行此修改，需要撤销修改。那该怎么做呢？
首先，使用`git reset`命令，将某个文件恢复到某个版本，此时文件的修改已经从暂存区删除，但工作区中的文件还是处于修改的状态，这时就回到了第一种情况，可以使用`git checkout -- 文件名`命令将文件恢复到修改前的状态

```bash
chenzhihao-mac:gitlearning chenzhihao$ vi readme.md
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
 
Test
chenzhihao-mac:gitlearning chenzhihao$ git add readme.md
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
Changes to be committed:
(use "git reset HEAD <file>..." to unstage)
 
modified: readme.md
 
chenzhihao-mac:gitlearning chenzhihao$ git reset head readme.md
Unstaged changes after reset:
M readme.md
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
Changes not staged for commit:
(use "git add <file>..." to update what will be committed)
(use "git checkout -- <file>..." to discard changes in working directory)
 
modified: readme.md
 
no changes added to commit (use "git add" and/or "git commit -a")
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
 
Test
chenzhihao-mac:gitlearning chenzhihao$ git checkout -- readme.md
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
nothing to commit, working tree clean
```

## 暂存区已被提交到本地版本库
对于修改已经被提交到本地代码库，直接使用上一篇[【Git爬坡】后悔药之版本回退](/2019/05/26/【Git爬坡】后悔药之版本回退/) 文章讲过的内容进行版本回退。

## 第四种：本地版本库已被推送到远程仓库
恭喜你，出门右拐，财务领工资

## 总结
针对丢弃修改这个问题的四种情况：

- 工作区的修改未被添加到暂存区。使用 `git checkout -- 文件名` 命令
- 工作区的修改以被添加到暂存区后，再次修改改文件，但此次修改未添加到暂存区。使用 `git reset` 命令，先丢弃暂存区，然后使用1中的命令撤销对文件的修改
- 基于第一种情况下，暂存区的修改已经全部被提交到本地版本库。使用版本回退即可解决，详情查看[【Git爬坡】后悔药之版本回退](/2019/05/26/【Git爬坡】后悔药之版本回退/)
- 基于第二种情况下，本地版本库已经被推送到远程仓库。哎，祝你好运
