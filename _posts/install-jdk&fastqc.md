---
title: Install jdk and fastqc without root 
description: I solved some problems when installing jdk and fastqc.
categories:
 - unix
tags:
- tutorial
- unix
- jdk
- fastqc
- server
---

简单描述，我遇到了两个问题：
1. 不能通过yum或者wget直接下载jdk；
2. fastqc安装后
```sh
$ fastqc: command not found...
```

解决方案：
1.因为HTML是不能够解压的，虽然他的名字也是*.tar,gz，下载速度还特别快。
正确姿势：wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" + 右键复制的链接，我的是：http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz  注意接收他的协议，不然你不能复制。

原因：这个网址并不可以直接下载，貌似还经过了两次重定向，所以你直接wget是不行的。

参数含义：

 --no-check-certificate表示不校验SSL证书，因为中间的两个302会访问https，会涉及到证书的问题，不校验能快一点，影响不大，

--no-cookies表示不使用cookies,当然首次在header里指定的会带上，后面重定向的就不带了，这个影响也不大，可以不加
————————————————
版权声明：本文为CSDN博主「lwgkzl」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/lwgkzl/java/article/details/79889983

2. 
