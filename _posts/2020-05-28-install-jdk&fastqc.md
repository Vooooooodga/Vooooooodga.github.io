---
title: Install jdk and fastqc without root 
description: I solved some problems when installing jdk and fastqc. But finally, I decided to use bioconda to install al softwares, which is pretty convenient!
categories:
 - unix
tags:
- unix
- jdk
- fastqc
- server
- conda
---

简单描述，我遇到了两个问题：
1. 不能通过yum或者wget直接下载jdk，而jdk是使用fastqc的必要软件；
2. fastqc安装后不能使用
```sh
fastqc: command not found...
```

Solution:
1. 因为HTML是不能够解压的，虽然他的名字也是*.tar,gz，下载速度还特别快。
正确姿势：wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" + 右键复制的链接，我的是：http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz  注意接收他的协议，不然不能复制。

问题原因：这个网址并不可以直接下载，貌似还经过了两次重定向，所以直接wget是不行的。

参数意义：

 --no-check-certificate表示不校验SSL证书，因为中间的两个302会访问https，会涉及到证书的问题，不校验能快一点，影响不大

--no-cookies表示不使用cookies,当然首次在header里指定的会带上，后面重定向的就不带了，这个影响也不大


2. 改用fastx_toolkit完美代替fastqc



后续：
安装了miniconda后基本解决了安装软件的所有问题,只有在使用samtools的时候出现了意外，有个libcrypto动态库找不到
```sh
samtools: error while loading shared libraries: libcrypto.so.1.0.0: cannot open shared object file: No such file or directory
```
使用ldd查看：
```sh
$ which samtools
~/local/miniconda3/bin/samtools
$ ldd ~/local/miniconda3/bin/samtools
libcrypto.so.1.0.0 => not found

```
查了一下发现是openssl库位置不对造成的。

解决办法：先查看服务器有哪些库：
```sh
$ ls /usr/lib64/libssl*
/usr/lib64/libssl.so.1.0.2k
```
确定只有这一个， 接下来改变samtools中的openssl库指向地址：
```sh
ln -s /home/Jia /usr/lib64/libssl.so.1.0.2k
```
