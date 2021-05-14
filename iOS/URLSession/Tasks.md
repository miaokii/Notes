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

**multipart/form-data**规范定义在[rfc2388](https://www.ietf.org/rfc/rfc2388.txt)，请求体的格式固定如下：

```text
--boundary
Content-Disposition: form-data; name="参数1"
参数1值
--boundary
Content-Disposition: form-data; name="参数2"
参数2值
--boundary
Content-Disposition: form-data; name="参数n"
参数n值
--boundary
Content-Disposition: form-data; name="表单参数名"; filename="文件名"
Content-Type: MIMEType
要上传的文件二进制数据
--boundary--
```

请求体大概分为三部分：上传参数、上传信息、上传文件二进制信息，通过`utf-8`编码格式上传。请求体内每一行用`\r\n(回车+换行)`来分隔，参数和参数值之间由两个`\r\n`分割，`Content-Type`需要根据具体的文件格式定。

**请求体的格式是固定的格式，不能随意更改**

- 定义分段内容

```swift
// 分段边界
private let boundary = "upload.boundary"
// 回车换行
private let crlf = "\r\n"
// --
private let line = "--"
```

- 构造请求

```swift
guard let imgData = UIImage.init(named: "head")?.jpegData(compressionQuality: 1) else {
    return
}

let url = URL.init(string: "http://example.com/user/api/update")!
var request = URLRequest.init(url: url)
request.httpMethod = "POST"

// 请求头格式
let header = [
    "Content-Type": "multipart/form-data; charset=utf-8; boundary=\(boundary)",
    "token": kyToken
]
request.allHTTPHeaderFields = header

// 参数
let param = ["id":"123xxx",
             "nickName": "uzi"]

// 构建请求体
let taskData = buildHeadImage(data: imgData, param: param)

let uploadTask = session.uploadTask(with: request, from: taskData) { data, response, error in
    guard let data = data else {
        print(error.debugDescription )
        return
    }
    print(String.init(data: data, encoding: .utf8) ?? "")
}
uploadTask.resume()
```

- 构建请求体

``` swift
func buildHeadImage(data: Data, param: [String: Any]) -> Data {
    
    // 保存请求体数据
    var formData = Data()
    var formString = ""
    
    // 上传参数
    for (key, value) in param {
        guard let valueData = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed),
              let valueString = String.init(data: valueData, encoding: .utf8) else {
            continue
        }
        
        formString += line+boundary+crlf
        formString += "Content-Disposition: form-data; name=\"\(key)\""+crlf+crlf
        formString += valueString+crlf
    }
    
    // 上传数据信息
    formString += line+boundary+crlf
    formString += "Content-Disposition: form-data; name=\"file\""+crlf+crlf
    formString += "Content-Type: image/*"+crlf
    
    // 拼接参数和上传数据信息
    formData.append(formString.data(using: .utf8)!)
    // 拼接上传数据
    formData.append(data)
    
    // 结束行
    let end = crlf+line+boundary+line+crlf
    formData.append(end.data(using: .utf8)!)
    return formData
}
```

#### 文件上传

对于大文件的上传，一次性读入内存可能造成内存耗尽，所以不适合使用表单格式。一种处理方法是将大文件切割成若干个小文件，逐个上传。当使用文件形式上传，如果需要监听上传进度或使用后台上传的功能，就不能使用共享的会话，自定义会话实现会话协议来监听进度是最合适的选择

