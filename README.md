# KTVHTTPCache

KTVHTTPCache is a smart media cache framework. It can cache HTTP request, very suitable for media resources.


## Flow Chart

![KTVHTTPCache Flow Chart](http://oxl6mxy2t.bkt.clouddn.com/changba/KTVHTTPCache-flow-chart.jpeg)


## Features

- Thread safety.
- Logging system, Support for console and file output.
- Accurate view caching information.
- Provide different levels of interface.
- Adjust the download configuration.


## Installation

#### Installation with CocoaPods

To integrate KTVHTTPCache into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
pod 'KTVHTTPCache', '~> 1.1.7'
```

Run `pod install`

#### Installation with Carthage

To integrate KTVHTTPCache into your Xcode project using Carthage, specify it in your Cartfile:

```ogdl
github "ChangbaDevs/KTVHTTPCache" ~> 1.1.7
```

Run `carthage update` to build the framework and drag the built `KTVHTTPCache.framework` and `KTVCocoaHTTPServer.framework` into your Xcode project.


## Usage

- Start proxy.

```objc
[KTVHTTPCache proxyStart:&error];
```

- Generated proxy URL.

```objc
NSURL * proxyURL = [KTVHTTPCache proxyURLWithOriginalURL:originalURL];
AVPlayer * player = [AVPlayer playerWithURL:proxyURL];
```

- Get the complete cache file URL if existed.

```objc
NSURL * completeCacheFileURL= [KTVHTTPCache cacheCompleteFileURLIfExistedWithURL:originalURL];
```

- Set the URL filter processing mapping relationship.

```objc
[KTVHTTPCache tokenSetURLFilter:^NSURL *(NSURL *URL) {
    return URL;
}];
```

- Download Configuration

```objc
// Timeout interval.
[KTVHTTPCache downloadSetTimeoutInterval:30];

// Accept Content-Type.
[KTVHTTPCache downloadSetAcceptContentTypes:contentTypes];

// Set unsupport Content-Type filter.
[KTVHTTPCache downloadSetUnsupportContentTypeFilter:^BOOL(NSURL * URL, NSString * contentType) {
    return NO;
}];

// Additional headers.
[KTVHTTPCache downloadSetAdditionalHeaders:headers];

// Whitelist headers.
[KTVHTTPCache downloadSetWhitelistHeaderKeys:headers];
```

- Log.

```objc
// Console.
[KTVHTTPCache logSetConsoleLogEnable:YES];

// File.
[KTVHTTPCache logSetRecordLogEnable:YES];
NSString * logFilePath = [KTVHTTPCache logRecordLogFilePath];
```


## License

KTVHTTPCache is released under the MIT license.


## Feedback

- GitHub : [Single](https://github.com/libobjc)
- Email : libobjc@gmail.com
- Twitter : CoderSingle
- Weibo : 程序员Single


## Developed by Single

- [SGPlayer](https://github.com/libobjc/SGPlayer) - A powerful media player framework for iOS, macOS, and tvOS.
- [KTVVideoProcess](https://github.com/ChangbaDevs/KTVVideoProcess) - A High-Performance video effects processing framework.

