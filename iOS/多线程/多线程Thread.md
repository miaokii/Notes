# Thread

Thread时Apple提供的一种面向对象的多线程解决方案，可以直接操作线程对象，需要手动管理线程的生命周期

## 创建

创建Thread有三种方式

```swift
// 创建线程，不会自动启动
let thread = Thread.init(target: self, selector: #selector(threadFunc), object: nil)
// 启动线程
thread.start()
```

创建并自动启动线程

```swift
Thread.detachNewThreadSelector(#selector(threadFunc), toTarget: self, with: nil)
```

隐式创建并启动线程

```swift
performSelector(inBackground: #selector(threadFunc), with: nil)
```

## 线程之间通信

在某些情况下，任务是在其他线程中执行的，任务执行完成需要刷新UI，就需要在不同线程之间通信

```swift
// 在主线程上执行
performSelector(onMainThread: #selector(threadFunc), with: nil, waitUntilDone: false)        
// 在指定线程上操作
Thread.current.perform(#selector(threadFunc), on: .main, with: nil, waitUntilDone: true)
// 在当前线程上操作
perform(#selector(threadFunc))
```

例如，请求图片并显示在UI上

```swift
func downloadImage() {
    let downloadThread = Thread.init {
        let url = URL.init(string: "https://cf.bstatic.com/images/hotel/max1280x900/262/262672564.jpg")!
        guard let data = try? Data.init(contentsOf: url),
              let image = UIImage.init(data: data) else {
            return
        }
	      // 在主线程上显示
        self.performSelector(onMainThread: #selector(self.refresh(image:)), with: image, waitUntilDone: false)
    }
    downloadThread.name = "download Image Thread"
    downloadThread.start()
}

@objc private func refresh(image: UIImage) {
    imageView.image = image
}
```

## 其他方法

Thread的其他相关方法

```swift
// 命名
thread.name = "new thread"
// 优先级 0-1，默认0.5，越大优先级越高
thread.threadPriority = 0
// 启动线程
thread.start()
// 线程休眠10s
Thread.sleep(forTimeInterval: 10)
// 休眠到指定时间
Thread.sleep(until: Date.distantFuture)
// 线程取消
thread.cancel()
// 是否正在执行
thread.isExecuting
// 是否取消
thread.isCancelled
// 是否结束
thread.isFinished
// 强制停止，进入死亡状态
Thread.exit()
```

## 线程同步

当一个程序对一个线程安全的方法或者语句进行访问的时候，其他的不能再对他进行操作了，必须等到这次访问结束以后才能对这个线程安全的方法进行访问

## 线程安全

在多线程程序中，多个线程可能会同时运行，也就可能会同时运行一段代码，如果每次运行的结果和蛋线程运行的结果是一样的，而且其他变量值和预期也是一样的，就是线程安全的

若每个线程中对全局变量、静态变量只有读操作，而无写操作，一般来说，这个全局变量是线程安全的；若有多个线程同时执行写操作（更改变量），一般都需要考虑线程同步，否则的话就可能影响线程安全。

### 线程安全方案

给存在数据竞争的操作加锁，不允许其他线程进行操作。加锁的方式有多种：objc_sync_enter/objc_sync_exit、 NSLock、NSCondition、NSConditionLock、DispatchSemaphore等
