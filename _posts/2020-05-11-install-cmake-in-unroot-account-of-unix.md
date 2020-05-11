---
title: Install cmake in unroot account of unix
description: This is a tutorial about how to install softwares in your directory.
categories:
 - unix
tags:
- tutorial
- unix
- cmake
- server
---

> Under the unix sys, when you are unroot account, you cannot directly install camke or other softwares in root directory. This is a tutorial about how to install them in your directory.

## All Starting with Trinity installation

* After I used wget to download `trinity` and installed it, it reported that I needed `cmake` version higher than 3. The `cmake` in server is too old so I needed to re-install it.
Create new directory:

```sh
$ mkdir cmake
```

Download cmake latest version:
```sh
$ wget https://github.com/Kitware/CMake/releases/download/v3.17.2/cmake-3.17.2.tar.gz
```

Unzip the file:

```sh
$ tar -zvxf cmake-3.17.2.tar.gz
```

Start installation:

```sh
$ cd cmake-3.17.2
$ ./bootstrap
$ ./configure --prefix=/home/jia/local/cmake  
$ make
$ make install
```

* Configure the `bashrc` file. It's a very important step!

```sh
$ vim ~/.bashrc
```

Write the code into the file:

```sh
export PATH=/home/jia/local/cmake/bin:$PATH
```

Source it:

```sh
$ source ~/.bashrc
```

Check the version:

```sh
$ cmake -version
cmake version 3.17.2

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```
Done!
