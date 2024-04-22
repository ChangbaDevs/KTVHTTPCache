# KTVHTTPCache

![Cocoapods Version](https://img.shields.io/cocoapods/v/KTVHTTPCache) ![Cocoapods License](https://img.shields.io/cocoapods/l/KTVHTTPCache?color=red) ![Cocoapods platforms](https://img.shields.io/cocoapods/p/KTVHTTPCache?color=green)

KTVHTTPCache is a powerful HTTP caching framework, very suitable for caching multimedia resources.

- [中文版](https://github.com/ChangbaDevs/KTVHTTPCache/blob/master/README_CN.md)


## Flow Chart

![KTVHTTPCache Flow Chart](https://github.com/ChangbaDevs/KTVHTTPCache/blob/master/documents/flow-chart.jpg?raw=true)


## Features

- Play, download and cache while playing
- Support preloading
- Support HLS
- Support AirPlay
- Support URL mapping
- Multiple concurrency, thread safety
- Powerful logging system
- Cache file management
- Low coupling and high expandability


## Requirements

- iOS 12.0 or later
- Xcode 11.0 or later


## Supported Formats

Supports all resources transmitted based on HTTP protocol:

- Video: MP4, TS, MOV, MXF, MPG, FLV, WMV, AVI, M4V, F4V, MPEG, 3GP, ASF, MKV, etc.
- Audio: MP3, OGG, WAV, WMA, APE, FLAC, AAC, AC3, MMF, AMR, M4A, M4R, WV, MP2, etc.
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


## Design Principles

KTVHTTPCache was originally designed to realize the function of playing, downloading and caching multimedia resources during online playback. From the beginning of the design, the following principles were strictly followed:

- Simple and efficient API, no coupling with the business side
- Minimize network usage, slice storage, loaded data fragments no longer request the network
- Seek during playback, and the parts that have been played will no longer request the network.
- The cache is shared globally, and the network will no longer be requested when downloading parts of the same URL that have already been played.
- No dependence on the player, supports AVPlayer or other FFmpeg-based players
- Complete logging system, problems can be found and traced throughout the process

The essence of this framework is to cache HTTP requests, and there is no restriction on the transmission content. Therefore, the application scenarios are not limited to online audio and video playback, but can also be used for file downloads, image loading, ordinary network requests and other scenarios.

## Caching Strategy

Based on the principle of minimizing network usage, data is loaded in slices. There are two data sources: Network Source and File Source, which are used to download network data and read local data respectively. Dynamically generate data loading strategies by comparing the Range in the Request Header with the local cache status.
For example, the Range in the Request Header is 0-1000, and there are already two pieces of data 200-500 and 700-800 in the local cache. Then 5 Sources will be generated correspondingly, which are:

- Network Source: 0-199
- File Source   : 200-500
- Network Source: 501-699
- File Source   : 700-800
- Network Source: 801-1000

They are managed by Source Manager and only provide a simple reading API to the outside world.


## Usage

#### Use with AVPlayer

- The following is an example of usage with AVPlayer. In actual projects, it is not limited to AVPlayer, but can also be used with other FFmpeg-based players.

```objc
// 1.Start local proxy server.
[KTVHTTPCache proxyStart:&error];

// 2.Generate proxy URL.
NSURL *proxyURL = [KTVHTTPCache proxyURLWithOriginalURL:originalURL];

// 3.Create AVPlayer with proxy URL.
AVPlayer *player = [AVPlayer playerWithURL:proxyURL];
```

#### Preloading

- Use KTVHCDataLoader and get the preload status in real time through its delegate

```objc
// The preloading range can be controlled through the Range parameter in the Request Header.
KTVHCDataRequest *request= [[KTVHCDataRequest alloc] initWithURL:URL headers:headers];
KTVHCDataLoader *loader = [KTVHTTPCache cacheLoaderWithRequest:request];
loader.delegate = self;
[loader prepare];
```

#### Activate AirPlay

- For stability reasons, Local Server only accepts requests from localhost by default, which causes AirPlay to be inactive by default. This can be changed using the following API.

```objc
// Set bindToLocalhost to NO to activate AirPlay.
NSURL *proxyURL = [KTVHTTPCache proxyURLWithOriginalURL:originalURL bindToLocalhost:NO];
```

#### URL Mapping

- If the URL pointing to the same resource changes dynamically, you can use the following API for mapping.

```objc
/**
  *  For example:
  *  http://www.xxxx.com/video.mp4?token=1
  *  and
  *  http://www.xxxx.com/video.mp4?token=2
  *  Although the URLs are different, they all point to the same file and can be returned in the block
  *  http://www.xxxx.com/video.mp4
  *  to map to the same cache
  */ 
[KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
    return URL;
}];
```

#### Network Configuration

```objc
// Set timeout interval.
[KTVHTTPCache downloadSetTimeoutInterval:30];

/**
  * For security/stability considerations, only responses with the following Content-Type are enabled by default:
  * - text/x
  * - video/x
  * - audio/x
  * - application/x-mpegURL
  * - vnd.apple.mpegURL
  * - application/mp4
  * - application/octet-stream
  * - binary/octet-stream
  * To open more types, use this API setting
  */
[KTVHTTPCache downloadSetAcceptableContentTypes:contentTypes];

// This handler is triggered when a Content-Type type is not accepted by default. You can decide whether to accept it by yourself.
[KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
    return NO;
}];
```

#### Manage Cached Data

- The default cache space is 500m. After it is used up, the elimination mechanism is enabled to gradually eliminate the oldest cached data.

```objc
// If the URL has been fully cached, it will be automatically merged into a complete file after it is released by the local server.
NSURL *fileURL= [KTVHTTPCache cacheCompleteFileURLWithURL:originalURL];
```

#### Logging system

```objc
// Get error information for a specified URL.
NSError *error = [KTVHTTPCache logErrorForURL:URL];

// Enable console output logs.
[KTVHTTPCache logSetConsoleLogEnable:YES];

// Write logs to file.
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

