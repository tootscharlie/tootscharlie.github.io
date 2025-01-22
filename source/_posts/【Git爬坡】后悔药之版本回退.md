---
published: false
title: 【Git爬坡】后悔药之版本回退
date: 2019-05-26 13:09:23
categories: 技术
tags: git
---
从小我们就知道，如果做了错事儿是没有后悔药吃的，只能承担相应的责任。但是在代码的世界里，这种不可能将变为可能，也就是说，当你在Git中误操作时，Git将为你提供”后悔药“。

首先查看readme.md文件原始内容
```bash
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
```

修改该文件，添加一个单词`very`
```bash
chenzhihao-mac:gitlearning chenzhihao$ vi readme.md
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very very important Code Management System!
```

将修改提交到暂存区
```bash
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
Changes not staged for commit:
(use "git add <file>..." to update what will be committed)
(use "git checkout -- <file>..." to discard changes in working directory)
 
modified: readme.md
 
no changes added to commit (use "git add" and/or "git commit -a")
chenzhihao-mac:gitlearning chenzhihao$ git add readme.md
chenzhihao-mac:gitlearning chenzhihao$ git status
On branch master
Changes to be committed:
(use "git reset HEAD <file>..." to unstage)
 
modified: readme.md
```

将暂存区全部提交到本地Git仓库
```bash
chenzhihao-mac:gitlearning chenzhihao$ git commit -m "update readme.md add very"
[master b98de68] update readme.md add very
1 file changed, 1 insertion(+), 1 deletion(-)
```
这时候突然发现，不应该这么更改，但是已经将修改提交到本地仓库了，怎么办？
使用`git log`查看当前版本库的操作记录，可以看到列出了两条commit记录，第一条为`HEAD-master`，即当前版本在`master`分支上。

```bash
chenzhihao-mac:gitlearning chenzhihao$ git log
commit b98de68ec923f7521535a9b36ffc1f62e6c38a77 (HEAD -> master)
Author: Chen <admin@chenzhihao.cc>
Date: Mon Dec 11 16:12:03 2017 +0800
 
update readme.md add very
 
commit 3a2897a6fcd90a32249d706a04d67b3f8c7cff45
Author: Chen <admin@chenzhihao.cc>
Date: Mon Dec 11 08:26:30 2017 +0800
 
create file readme.md
```
接下来就可以使用`git reset`命令将当前版本恢复到其他版本，这里可以直接使用版本号，来选择会退到哪一个版本
```bash
chenzhihao-mac:gitlearning chenzhihao$ git reset --hard 3a2897a6fcd90a32249d706a04d67b3f8c7cff45
HEAD is now at 3a2897a create file readme.md
chenzhihao-mac:gitlearning chenzhihao$ git log
commit 3a2897a6fcd90a32249d706a04d67b3f8c7cff45 (HEAD -> master)
Author: Chen <admin@chenzhihao.cc>
Date: Mon Dec 11 08:26:30 2017 +0800
 
create file readme.md
chenzhihao-mac:gitlearning chenzhihao$ cat readme.md
Hello world!
Git is a very important Code Management System!
```

或者使用`head^`恢复前一个版本，`head^^`恢复前两个版本，当然只要你愿意写，可以写100个`^`，恢复到前一百个版本，因为实在太长，可以使用`head~100`

```bash
HEAD is now at 3a2897a create file readme.md
chenzhihao-mac:gitlearning chenzhihao$ git log
commit 3a2897a6fcd90a32249d706a04d67b3f8c7cff45 (HEAD -> master)
Author: Chen <admin@chenzhihao.cc>
Date: Mon Dec 11 08:26:30 2017 +0800
 
create file readme.md
```
但是可以使用`git reflog`查看历史操作，根据操作日志进行恢复

```bash
chenzhihao-mac:gitlearning chenzhihao$ git reflog
3a2897a (HEAD -> master) HEAD@{0}: reset: moving to 3a2897a6fcd90a32249d706a04d67b3f8c7cff45
b98de68 HEAD@{1}: commit: update readme.md add very
3a2897a (HEAD -> master) HEAD@{2}: reset: moving to 3a2897a
3a2897a (HEAD -> master) HEAD@{3}: reset: moving to 3a2897a6fcd
2b9f78a HEAD@{4}: reset: moving to 2b9f78a903ac2cf91b7b30712dbabd264a834701
3a2897a (HEAD -> master) HEAD@{5}: reset: moving to 3a2897a6fcd
2b9f78a HEAD@{6}: reset: moving to 2b9f78a903ac2cf91b7b30712dbabd264a834701
3a2897a (HEAD -> master) HEAD@{7}: reset: moving to head^
2b9f78a HEAD@{8}: commit: update readme.md add very
3a2897a (HEAD -> master) HEAD@{9}: commit (initial): create file readme.md
chenzhihao-mac:gitlearning chenzhihao$ git reset --hard b98de68
HEAD is now at b98de68 update readme.md add very
```
## 总结

- `git status`  查看当前暂存区状态
- `git reset` 将工作区恢复到某一个版本
- `git log`  查看版本记录
- `git reflog`  查看历史操作记录
