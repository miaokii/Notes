# URLSession

URLSession是iOS7之后用以和服务器交互数据的集合类和协议的统称，它可以实现数据请求，后台上传，下载等功能，可以通过闭包实现回调事件，也可以通过代理实现重定向和任务完成的事件等

每个程序可以创建多个URLSession实例，每个实例用以组织相关的数据传输任务

URLSession由三部分构成：

- URLSessionConfiguration：会话的初始化配置，可以设置会话的可用网络类型，与主机的最大连接数，缓存策略，安全证书等

- URLSession：负责请求/响应数据交互的会话对象
- URLSessionTask：会话任务的基类，通过调用会话的创建不同类型任务的方法来创建任务

## URLSessionConfiguration



## URLSession

URLSession本身不负责数据的请求，而是通过创建Task任务，Task来请求的方式处理会话

### 创建

URLSession有三种创建方式

#### shared

使用系统提供的共享单例对象

```swift
let sessionShared = URLSession.shared
```

共享单例对象使用的默认配置选项，所以有很多的使用限制

- 不能从服务器获取增量数据
- 不能更改默认的连接行为
- 身份验证受限
- 当app没有运行时，不能使用后台上传和下载功能

#### init(configuration:)

使用URLSessionConfiguration初始化URLSession

```swift
let sessionConfiguration = URLSessionConfiguration.default
let session = URLSession.init(configuration: sessionConfiguration)
```

URLSessionConfiguration可以配置请求的超时时间、请求头、cookie和鉴权等信息

#### init(configuration:delegate:delegateQueue:)

```swift
let session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: .current)
```

此方法可以设置会话的初始化信息，委托对象，委托回调队列等

- URLSessionDelegate：通知代理对象会话的生命周期，处理身份验证
- delegateQueue：回调队列用于调度委托调用和完成处理程序的操作队列，该队列应该是一个串行队列，以确保回调的正确顺序，如果为nil，则会话将创建一个串行操作队列

### 使用

```swift
let session = URLSession.shared
let dataTask = session.dataTask(with: URL.init(string: "https://www.baidu.com")!) { data, response, error in
    print(String.init(data: data!, encoding: .utf8))
}
dataTask.resume()
```



https://www.jianshu.com/p/26c49255c898