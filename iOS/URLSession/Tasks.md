# URLSessionTask

`URLSessionTask`是所有会话任务的父类，其中定义了操作任务的基本方法，包括开始、暂停获取任务进度等

## URLSessionDataTask

数据会话任务，将下载的数据直接返回到内存中，返回数据格式为`Data`，通常可以解析为`JSON`格式。与`URLSessionDataTask`对应的代理是`URLSessionDataDelegate`，其中定义了处理数据和上传任务的方法，包括：

- 从服务器收到任务响应：*completionHandler*用于指定收到服务器响应后，如何继续进行会话，有四种选择：
  - cancel：取消任务
  - allow：继续执行
  - becomeDownload：转换为URLSessionDownloadTask下载任务
  - becomeStream：转换为URLSessionStreamTask任务

```swift
func urlSession(URLSession, dataTask: URLSessionDataTask, didReceive: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void)
```

- 转换为下载任务

```swift
func urlSession(URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionDownloadTask)
```

- 转换为流任务

```swift
func urlSession(URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionStreamTask)
```

- 接收数据：当返回数据较大时，可能会分片接收

```swift
func urlSession(URLSession, dataTask: URLSessionDataTask, didReceive: Data)
```

- 是否缓存响应

```swift
func urlSession(URLSession, dataTask: URLSessionDataTask, willCacheResponse: CachedURLResponse, completionHandler: (CachedURLResponse?) -> Void)
```

### 使用

创建会话任务时，允许使用闭包来接收会话数据，此时如果设置了代理，将不会执行代理回调，因为闭包的优先级更高，但是在闭包中无法控制请求过程，比如请求转换

这种方法创建的会话任务处于`suspend`状态，需要手动调用`resume`方法开始任务

```swift
let sessionConfiguration = URLSessionConfiguration.default
let session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: .current)
let dataTask = session.dataTask(with: URL.init(string: "https://www.baidu.com")!) { data, response, error in
    guard let data = data else {
        print(error?.localizedDescription ?? "")
        return
    }
    print(String.init(data: data, encoding: .utf8)!)
}
dataTask.resume()
```

如果使用delegate接收数据时

```swift
let session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: .current)
let dataTask = session.dataTask(with: URL.init(string: "https://www.baidu.com")!)
dataTask.resume()

// 实现URLSessionDataDelegate代理
// 接收到数据
func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
  responseData.append(data)
}

// 任务结束
func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let err = error {
        print(err.localizedDescription)
        return
    }
    print(String.init(data: responseData, encoding: .utf8)!)
}
```

使用URLRequest创建任务，可以指定请求方法，默认时`GET`请求

```swift
let session = URLSession.shared
var request = URLRequest.init(url: .init(string: "http://www.example.com")!)
request.httpMethod = "POST"
request.allHTTPHeaderFields = ["Content-Type": "application/json"]
let bodyDic = ["type":"1","username":"didi","password":"123456"]
request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDic, options: .fragmentsAllowed)
let postTask = session.dataTask(with: request) { data, response, error in
    guard let data = data else {
        print(error?.localizedDescription ?? "")
        return
    }
    print(String.init(data: data, encoding: .utf8)!)
}
postTask.resume()
```

