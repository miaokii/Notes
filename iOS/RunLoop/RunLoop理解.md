# RunLoop

## RunLoop简介

https://juejin.cn/post/6844903588712415239#heading-4

https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html#//apple_ref/doc/uid/10000057i-CH16-SW23

### 理解

Run：运行，Loop：循环，RunLoop就是程序运行的循环（事件循环），可以理解为程序在运行时不断的进行一个循环。RunLoop用于处理窗口事件（鼠标滑动、屏幕滑动、屏幕点击、屏幕刷新等），端口事件（插入键盘、插入鼠标、耳机或其他外设），Timer事件

### 和线程的关系

每个线程都拥有一个RunLoop对象，不能手动创建和显示管理RunLoop对象，如果需要访问当前RunLoop对象，使用`RunLoop.current`方法获取

主线程的RunLoop是自动启动的，手动创建的线程需要显式地运行其RunLoop

当RunLoop没有事件处理时，会使线程进入睡眠状态，节省CPU资源

RunLoop不是线程安全的，通常只能在当前线程的上下文中调用其方法，不能在另一个线程中运行其他线程的RunLoop对象的方法

### 主线程中的RunLoop

在App启动时，首先调用`main`方法，main方法中创建应用程序和对应程序的代理，并设置了主事件循环RunLoop

```objective-c
int main(int argc, char * argv[]) {
    @autoreleasepool {
        int value = UIApplicationMain(argc, argv, nil,NSStringFromClass([AppDelegate class]));
        return value;
    }
}
```

查看`UIApplicationMain`的定义

```objective-c
/// 创建程序对象和程序代理并设置设置主线程RunLoop
/// @param argc 参数计数，通常传入main函数argc
/// @param argv 可变的参数列表， 这通传入main函数argv
/// @param principalClassName UIApplication类或子类名称，如果指定nil，就默认为UIApplication
/// @param delegateClassName UIApplication代理名称
int UIApplicationMain(int argc, char * _Nullable *argv, NSString *principalClassName, NSString *delegateClassName);
```

他的返回值是一个整形，但即使指定了函数的返回类型，这个函数也不会返回。可以在main函数中添加验证：

```objective-c
int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSLog(@"application start", nil);
        int value = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        NSLog(@"application end", nil);
        return value;
    }
}
```

运行程序时，发现只打印了`application start`，结合官方文档中`UIApplicationMain`的说明，UIApplicationMain设置了主事件循环（包括应用程序的运行循环），并开始处理事件，所以UIApplicationMain不会返回，以此保证程序一直运行

![runloop](../../Assets/runloop/runloop.jpg)

上图是Apple官方的RunLoop运行模型，由模型可知，RunLoop就是一个事件循环，再循环过程中不断检测输入源和定时器源来接收这些源的事件，然后通知线程进行事件处理，当没有源输入事件时，线程就休息等待，避免占用cpu资源

## CFRunLoop

RunLoop定义在Foundation框架，CFRunLoop定义在CoreFoundation框架，是纯C函数，RunLoop是CFRunLoop面向对象的封装，此外并没有其他功能

CoreFundation是开源的，所以可以分析[源码](https://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c.auto.html)

