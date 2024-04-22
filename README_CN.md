# KTVHTTPCache

![Cocoapods Version](https://img.shields.io/cocoapods/v/KTVHTTPCache) ![Cocoapods License](https://img.shields.io/cocoapods/l/KTVHTTPCache?color=red) ![Cocoapods platforms](https://img.shields.io/cocoapods/p/KTVHTTPCache?color=green)

KTVHTTPCache 是一个强大的 HTTP 缓存框架，非常适合用于多媒体资源的缓存。

- [English](https://github.com/ChangbaDevs/KTVHTTPCache/blob/master/README.md)


## Flow Chart

![KTVHTTPCache Flow Chart](https://github.com/ChangbaDevs/KTVHTTPCache/blob/master/documents/flow-chart.jpg?raw=true)


## Features

- 边播放、边下载、边缓存
- 支持预加载
- 支持 HLS
- 支持 AirPlay
- 支持 URL 映射
- 多并发、线程安全
- 强大的日志系统
- 缓存文件管理
- 低耦合、高拓展性


## Requirements

- iOS 12.0 or later
- Xcode 11.0 or later


## Supported Formats

支持全部基于 HTTP 协议传输的资源：

- 视频格式：MP4，TS，MOV，MXF，MPG，FLV，WMV，AVI，M4V，F4V，MPEG，3GP，ASF，MKV 等
- 音频格式：MP3，OGG，WAV，WMA，APE，FLAC，AAC，AC3，MMF，AMR，M4A，M4R，WV，MP2 等
- Support Apple HTTP Live Streaming (HLS) m3uu8 index files.


## Installation

#### Installation with CocoaPods

To integrate KTVHTTPCache into your Xcode project using CocoaPods, specify it in your Podfile:

```objc
pod 'KTVHTTPCache', '~> 3.0.0'
```

Run `pod install`

#### Installation with Carthage

To integrate KTVHTTPCache into your Xcode project using Carthage, specify it in your Cartfile:

```objc
github "ChangbaDevs/KTVHTTPCache" ~> 3.0.0
```

Run `carthage update` to build the framework and drag the built `KTVHTTPCache.framework` and `KTVCocoaHTTPServer.framework` into your Xcode project.


## 设计原则

KTVHTTPCache 最初是为了实现多媒体资源在线播放过程中边播放边下载边缓存的功能，设计之初便严格遵守如下原则：

- 简洁高效的 API，与业务侧无耦合
- 网络使用最小化，切片存储，已加载过的数据片段不再请求网络
- 播放过程中可随意 Seek，且已播放过的部分不再请求网络
- 缓存全局共享，同一 URL 已观播放的部分下载时不再请求网络
- 与播放器无相关性，支持 AVPlayer 或其他基于 FFmpeg 的播放器
- 完备的日志系统，问题全程可排查、可追溯

该框架本质是对 HTTP 请求进行缓存，对传输内容并没有限制，因此应用场景不限于音视频在线播放，也可以用于文件下载、图片加载、普通网络请求等场景。

## 缓存策略

以网络使用最小化为原则，采用分片加载数据的方式。有 Network Source 和 File Source 两种数据源，分别用于下载网络数据和读取本地数据。通过对比 Request Header 中 Range 和本地缓存状态动态生成数据加载策略。
例如 Request Header 中 Range 为 0-1000，本地缓存中已有 200-500 和 700-800 两段数据。那么会对应生成 5 个 Source，分别是：

- Network Source: 0-199
- File Source   : 200-500
- Network Source: 501-699
- File Source   : 700-800
- Network Source: 801-1000

它们由 Source Manager 进行管理，对外仅提供一个简洁的读取接口。


## 使用

#### 搭配 AVPlayer 使用

- 以下为搭配 AVPlayer 的使用示例。实际项目中不限于 AVPlayer，同样可与其他基于 FFmpeg 的播放器搭配使用

```objc
// 1.启动本地代理服务器
[KTVHTTPCache proxyStart:&error];

// 2.生成代理 URL
NSURL *proxyURL = [KTVHTTPCache proxyURLWithOriginalURL:originalURL];

// 3.通过代理 URL 创建 AVPlayer
AVPlayer *player = [AVPlayer playerWithURL:proxyURL];
```

#### 预加载

- 使用 Data Loader 并通过其 delegate 实时获取预加载状态

```objc
// 可通过 Request Header 中 Range 参数控制预加载范围
KTVHCDataRequest *request= [[KTVHCDataRequest alloc] initWithURL:URL headers:headers];
KTVHCDataLoader *loader = [KTVHTTPCache cacheLoaderWithRequest:request];
loader.delegate = self;
[loader prepare];
```

#### 激活 AirPlay

- 出于稳定性的考虑，Local Server 默认仅接受来自 localhost 的请求，这导致 AirPlay 默认未激活，使用如下 API 可进行更改

```objc
// 将 bindToLocalhost 设置为 NO 以激活 AirPlay
NSURL *proxyURL = [KTVHTTPCache proxyURLWithOriginalURL:originalURL bindToLocalhost:NO];
```

#### URL 映射

- 如果指向同一资源的 URL 为动态变化的，可使用如下 API 进行映射

```objc
/**
 *  例如：
 *  http://www.xxxx.com/video.mp4?token=1 
 *  和
 *  http://www.xxxx.com/video.mp4?token=2 
 *  虽 URL 不同，但都指向同一文件，即可在 block 中返回
 *  http://www.xxxx.com/video.mp4
 *  以映射到同一块缓存
 */ 
[KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
    return URL;
}];
```

#### 网络配置

```objc
// 设置超时时间
[KTVHTTPCache downloadSetTimeoutInterval:30];

/**
 * 出于安全性/稳定性的考虑，默认仅开放 Content-Type 为如下类型的响应
 * - text/x
 * - video/x
 * - audio/x
 * - application/x-mpegURL
 * - vnd.apple.mpegURL
 * - application/mp4
 * - application/octet-stream
 * - binary/octet-stream
 * 如需开放更多类型，使用此 API 设置
 */
[KTVHTTPCache downloadSetAcceptableContentTypes:contentTypes];

// 遇到默认未接受的 Content-Type 类型时触发该处置器，可自行判断是否接受
[KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
    return NO;
}];
```

#### 管理缓存数据

- 默认缓存空间为 500m，用完后启用淘汰机制，逐步淘汰最早的缓存数据

```objc
// 如果该 URL 已被完整缓存，则该 URL 被本地服务器释放后，会自动合并为一个完整的文件
NSURL *fileURL= [KTVHTTPCache cacheCompleteFileURLWithURL:originalURL];
```

#### 日志系统

```objc
// 获取指定 URL 的错误信息
NSError *error = [KTVHTTPCache logErrorForURL:URL];

// 开启控制台输出日志
[KTVHTTPCache logSetConsoleLogEnable:YES];

// 写入日志信息到文件
[KTVHTTPCache logSetRecordLogEnable:YES];
NSString *logFilePath = [KTVHTTPCache logRecordLogFilePath];
```


## License

KTVHTTPCache is released under the MIT license.


## Author

- GitHub : [Single](https://github.com/libobjc)
- Email : libobjc@gmail.com


## Developed by Author

- [SGPlayer](https://github.com/libobjc/SGPlayer) - A powerful media player framework for iOS, macOS, and tvOS.
- [KTVVideoProcess](https://github.com/ChangbaDevs/KTVVideoProcess) - A High-Performance video effects processing framework.

