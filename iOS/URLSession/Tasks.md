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

### GET请求

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

### POST请求

使用URLRequest创建任务，可以指定请求方法，默认是`GET`请求，`POST`请求如下

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

## URLSessionUploadTask

上传任务，是URLSessionDataTask的子类，用于向服务器上传文件或数据。创建上传任务时，需提供一个URLRequest实例，其中包含可能需要在上传时发送的标头，例如内容类型`Content-Type`，内容处理等。当在后台会话中为文件创建上传任务时，系统会将文件复制到临时存储区并从那里获取流数据。在上传过程中，任务会定期回调代理的`urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)`方法提供任务的状态信息

文件上传有两种形式，表单上传和后台文件上传。表单上传会直接在内存中读取上传数据，当上传内容很大时，可能会耗尽内存。文件上传专门为较大的数据集设计，它使用适当的分段模式从文件中读取数据，分段上传，例如上传视频内容时

#### 表单上传

表单形式上传对请求头、请求体有一些特殊要求

```swift
header = ["Content-Type": "multipart/form-data; charset=utf-8; boundary=customboundary"] 
```

**multipart/form-data**表示使用表单上传，**charset=utf-8**表示二进制数据的编码格式，**boundary**表示上传内容的分割符，用于分割请求体，区分不同的参数部分，接收方根据该字段解析和还原上传的数据

