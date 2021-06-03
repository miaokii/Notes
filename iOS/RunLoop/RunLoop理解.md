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

![runloop](../../.Assets/runloop/runloop.jpg)

上图是Apple官方的RunLoop运行模型，由模型可知，RunLoop就是一个事件循环，再循环过程中不断检测输入源和定时器源来接收这些源的事件，然后通知线程进行事件处理，当没有源输入事件时，线程就休息等待，避免占用cpu资源

## CFRunLoop

RunLoop定义在Foundation框架，CFRunLoop定义在CoreFoundation框架，是纯C函数，RunLoop是CFRunLoop面向对象的封装，此外并没有其他功能

CoreFundation是开源的，所以可以分析[源码](https://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c.auto.html)

## Run Loop Modes

运行循环模式是要监视的输入源和计时器的集合，以及要通知的运行循环观察者集合。每次RunLoop循环中，可以设置特定的模式，设置后RunLoop循环中，只监听与该模式相关联的源，并允许其传递事件给线程，如果设置了监听，观察者也只监听与该模式相关的的RunLoop进度。此时其他模式的源发出新事件将会被保留，直到之后以适当的模式来处理事件。设置循环模式可以通过Fundation或CoreFoundation框架`RunLoop.Mode`和`CFRunLoopMode`来指定，本质上模式都是用字符串来定义的

运行模式可以从运行循环中过滤掉不需要的源事件，多数情况下，循环模式是`default`类型。`modal`模式用于处理模态面板（MacOS程序的关于视图等）事件，此种模式下，只有模态面板的事件会传给线程

下表列举所有的循环模式：

| Mode           | Name                                                         | Description                                                  |
| :------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Default        | `RunLoop.Mode.default` (Cocoa)<br />`kCFRunLoopDefaultMode` (CF) | 用的最多的模式，使用该模式开始运行循环并配置数据源           |
| Connection     | `NSConnectionReplyMode` (Cocoa)                              | Cocoa框架用该模式监听NSConnection对象回调，开发几乎不使用    |
| Modal          | `RunLoop.Mode.modalPanel` (Cocoa)                            | 标识模态面板事件                                             |
| Event tracking | `RunLoop.Mode.eventTracking` (Cocoa)                         | 用于跟踪事件，如鼠标滑动，屏幕滑动                           |
| Common modes   | `RunLoop.Mode.common` (Cocoa)<br />`kCFRunLoopCommonModes` (Core Foundation) | 最常用的模式，是default、modal和eventTracking模式的集合，可以处理大部分的事件 |

## Input Sources

输入源将事件异步传递到线程，不同的输入源会产生不同的事件，通常有两个类别：

- 基于端口的输入源监听程序的Mach端口 Source1
- 自定义输入源监听事件的自定义源 Source0

在运行循环中，输入源不区分基于端口还是基于自定义。系统通常实现两种类型的输入源，区别在于他们信号的发送方式。基于端口的源由内核自动发出信号，自定义的源必须从另一个线程手动发出信号

以下列举了系统定义的几种源

### 基于端口的源

基于端口相关功能的输入源。在Cocoa中，不需要直接创建输入源，只要创建一个端口对象，将端口对象添加到RunLoop中即可。在CoreFoundation中，需手动创建端口及输入源，使用`CFMachPortRef`，`CFMessagePortRef`或`CFSocketRef`来创建适当的对象

#### MachPort

MachPort用于进程之间、线程之间的相互通信

### 自定义输入源

自定义输入源，使用CoreFoundation框架下CFRunLoopSourceRef类型来创建。可以使用多个回调函数配置自自定义输入源。当要从RunLoop中删除源时，CoreFoundation会在不同点调用这些函数以配置源，处理所有传入事件，最后移除源

除了定义事件到达时自定义源的行为外，还必须定义事件传递机制。这部分的代码需在单独的线程上运行，负责为输入源提供其数据，并在准备好处理数据时向其发出信号

### Cocoa Perform Selector Sources

在Cocoa中，NSObject类定义了一个自定义的输入源，该源允许再任何线程上执行一个方法，在线程间通信时，这种方法减轻了在一个线程上运行多种方法时的同步问题

执行方法选择器源在执行了方法后，就将自身从RunLoop中删除

在另一个线程上执行方法选择器时，目标线程必须有正在运行的RunLoop。如果目标线程时手动创建的线程，就需要手动启动该线程的RunLoop

下面列举了NSObject中定义的在其他线程执行任务的方法：

- 在当前线程的下一个RunLoop循环中，在程序的主线程执行指定方法

  > 这两个方法可以阻塞当前线程，直到执行指定方法为止

```swift
func performSelector(onMainThread aSelector: Selector, with arg: Any?, waitUntilDone wait: Bool, modes array: [String]?)

func performSelector(onMainThread aSelector: Selector, with arg: Any?, waitUntilDone wait: Bool)
```

- 在指定线程上执行指定方法

  > 这两个方法可以阻塞当前线程，直到执行指定方法为止

```swift
func perform(_ aSelector: Selector, on thr: Thread, with arg: Any?, waitUntilDone wait: Bool)

func perform(_ aSelector: Selector, on thr: Thread, with arg: Any?, waitUntilDone wait: Bool, modes array: [String]?)
```

- 在当前线程的下一个RunLoop循环中，可以延迟执行指定方法

  > 因为当前线程要一直等到下一个RunLoop周期执行指定方法，所以下面这两个方法提供了一个与当前正在执行的代码相比最小的自动延迟
  >
  > 当有多个排队方法时，按照排队的顺序依次执行

```swift
func perform(_ aSelector: Selector, with anArgument: Any?, afterDelay delay: TimeInterval, inModes modes: [RunLoop.Mode])

func perform(_ aSelector: Selector, with anArgument: Any?, afterDelay delay: TimeInterval)
```

- 取消上面两个等待在下一个RunLoop周期运行的方法执行

```swift
class func cancelPreviousPerformRequests(withTarget aTarget: Any, selector aSelector: Selector, object anArgument: Any?)

class func cancelPreviousPerformRequests(withTarget aTarget: Any)
```

### Timer Sources

计时器源用于在将来预定的时间将事件同步传递到线程执行。计时器是线程通知自己执行某个操作的方式

计时器不是实时的，且计时器必须在RunLoop的特定模式下才能运行。如果RunLoop没有运行，计时器也不会触发

计时器可以配置为仅一次或重复生成事件。重复计时器会根据计划的触发时间（而不是实际的触发时间）自动重新计划自己的时间。例如，如果计划将计时器在特定时间触发，并且此后每5秒钟触发一次，则即使实际触发时间被延迟，计划的触发时间也将始终落在原始的5秒时间间隔上。如果触发时间延迟得太多，以致错过了一个或多个计划的触发时间，则计时器将在错过的时间段内仅触发一次。在错过了一段时间后触发后，计时器将重新安排为下一个计划的触发时间

### RunLoop Sequence Events

在每一次的RunLoop循环中，线程都会处理一些待处理的事件，并向已经添加的观察者发出通知，通知的顺序如下：

1. 通知观察者进入RunLoop循环
2. 通知观察者准备就绪的计时器即将触发
3. 通知观察者非基于端口的输入源即将触发
4. 触发所有准备触发的非基于端口的输入源
5. 如果一个基于端口的输入源已经准备好且等待启动，就需要立即启动，转到步骤9
6. 通知观察者线程即将进入睡眠状态
7. 线程进入睡眠状态，直到发生下列事件之一：
   - 接收到基于端口的输入源事件
   - 定时器启动
   - 为RunLoop设置的超时时间到期
   - RunLoop被显示唤醒
8. 通知观察者线程刚刚醒来
9. 处理已经添加的事件：
   - 如果触发了用户定义的定时器，处理定时器事件并重新启动循环，转到步骤2
   - 如果触发了输入源，传递事件
   - 如果RunLoop被显示唤醒且还没有到超时时间，重新启动循环，转到步骤2
10. 通知观察者RunLoop循环结束

计时器和输入源的观察者通知是在事件实际发生之前传递的，因此通知时间和事件实际事件可能会有差距，一种好的处理方法是：使用睡眠和从睡眠中唤醒通知来关联实际事件之间的事件间隔

可以显式唤醒RunLoop循环。其他事件也可能导致运行循环被唤醒。例如，添加另一个非基于端口的输入源会唤醒运行循环，以便可以立即处理输入源，而不是等到发生其他事件为止

## 何时使用RunLoop

在主线程中，RunLoop是随程序一同启动的，不需要显示调用

对于辅助线程，需要判断是否需要RunLoop，如果需要，手动启动。不需要在所有情况下都启动辅助线程的RunLoop，通常，当希望与线程进行更多交互时，可以启动RunLoop

使用端口或自定义输入源与其他线程进行通信时，需要启动RunLoop。如：

- 使用定时器
- 保持线程执行周期性任务
- performSelector方法等

当开启辅助线程RunLoop时，在适当的情况下，应该退出RunLoop

## 使用RunLoop

RunLoop对象提供了用于将输入源，计时器和RunLoop观察器添加到运行循环然后运行它的接口。 每个线程都有一个与之关联的RunLoop对象。 在 Cocoa 中，这个对象是 NSRunLoop 类的一个实例。 在底层中，它是一个指向 CFRunLoopRef类型的指针

### 获取RunLoop对象

```swift
// cocoa
let runLoop = RunLoop.current
// cf
let cfRunLoop = CFRunLoopGetCurrent()
// RunLoop->CFRunLoop
// runLoop和cfRunLoop都引用同一个运行循环
runLoop.getCFRunLoop()
```

### RunLoop配置

在辅助线程上开启RunLoop时，必须向其添加至少一个输入源或定时器，否则RunLoop没有监控到任务源，它会在尝试开启时立刻退出

除了添加输入源，还可以添加RunLoop观察者来监控RunLoop的不同执行阶段，在Cocoa程序中，也必须使用CoreFoundation框架来添加RunLoop监控

```swift
let runLoop = RunLoop.current
let cfRunLoop = runLoop.getCFRunLoop()
let runLoopObserverHandle:(CFRunLoopObserver?, CFRunLoopActivity)->Void = { (cf, ac) in
    if ac == .entry {
        print("进入 runloop")
    }
    else if ac == .beforeTimers {
        print("即将处理timer事件")
    }
    else if ac == .beforeWaiting {
        print("runloop即将休眠")
    }
    else if ac == .afterWaiting {
        print("runloop被唤醒")
    }
    else if ac == .exit {
        print("退出runloop")
    }
}
let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,CFRunLoopActivity.allActivities.rawValue, true, 0, runLoopObserverHandle)
CFRunLoopAddObserver(cfRunLoop, observer, .defaultMode)
let timer = Timer.scheduledTimer(timeInterval: 1, target: WeakProxy.init(target: self), selector: #selector(fireTimer), userInfo: nil, repeats: true)
```

### 开始RunLoop

辅助线程才需要手动启动RunLoop，包括以下几种方式：

- 无条件：此方式下，线程将置于永久循环，无法控制RunLoop本身。可以添加和删除输入源和计时器，但停止循环的唯一方法就是终止它，也不能在自定义模式下运行RunLoop

```swift
func run()
```

- 有时间限制：使用超时配置，RunLoop直到事件到达和超时时间到期之前都会一直运行。如果事件到达，则将该事件分配给线程进行处理，然后RunLoop退出，此后代码可以重新启动一个循环来处理下一个事件。如果超时时间到期，可以重新启动RunLoop。

```swift
// 运行RunLoop直到指定日期，在此期间它处理来自所有附加输入源的事件
func run(until limitDate: Date)
```

- 特定模式：可以使用特定模式运行RunLoop。模式和超时时间不是互斥的，特定模式可以在启动RunLoop是使用。特定模式限定了RunLoop中事件传递的源类型

```swift
// 运行一次循环，阻止在指定模式下输入源直到指定日期
// 如果RunLoop运行并处理了输入源或达到了指定的超时值，则为 true
// 否则，如果无法启动运行循环，则为 false。
func run(mode: RunLoop.Mode, before limitDate: Date) -> Bool
func perform(inModes modes: [RunLoop.Mode], block: @escaping () -> Void)
```

### 退出RunLoop

有两种方法可以在线程处理事件之前退出RunLoop：

- 使用超时时间：在RunLoop推出之前完成所有正常处理，包括向观察者发送通知

```swift
// 运行RunLoop直到指定日期，在此期间它处理来自所有附加输入源的事件
func run(until limitDate: Date)
```

- 手动停止：手动停止RunLoop会产生类似超时的效果，不同在于可以在无条件启动的RunLoop上使用此命令

```swift
func CFRunLoopStop(_ rl: CFRunLoop!)
```

> 移除输入源和Timer也可能退出RunLoop，但应该避免使用这种方式，因为系统可能会添加其他源处理所需事件，导致不能退出

### 线程安全

线程安全取决于用于操作运行循环的 API

Core Foundation中的函数通常是线程安全的，可以从任何线程调用。 但是，如果正在执行更改RunLoop配置的操作，尽可能从拥有RunLoop的线程，然后执行配置操作

Cocoa RunLoop类在本质上不如Core Foundation类线程安全。如果要修改某个线程的RunLoop，就应该先持有这个线程。并且将输入源或计时器添加到属于不同线程的RunLoop可能会发生异常