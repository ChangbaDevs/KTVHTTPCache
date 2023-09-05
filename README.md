# KTVHTTPCache

KTVHTTPCache is a powerful media cache framework. It can cache HTTP request, and very suitable for media resources.
感谢开源 , 此版本兼容m3u8视频缓存
添加对m3u8的支持 请使用此方法
```
    __weak ViewController * weakself = self;
    [KTVHTTPCache proxyURLWithOriginalURL:item.URLString complete:^(NSURL *url) {
        
        NSLog(@"absoluteString === %@",url.absoluteString);
        MediaViewController *vc = [[MediaViewController alloc] initWithURLString:url.absoluteString];
        [weakself presentViewController:vc animated:YES completion:nil];
    }];
```

## 下载m3u8视频 的脚本
```
import datetime
import os
import re
import threading
import requests
from queue import Queue
# 预下载，获取m3u8文件，读出ts链接，并写入文档

rootPath = "/Users/yeqiu/Documents/downLoadM/cache/"

def down():
  # m3u8链接
  url = 'https://tophy.qoqkkhy.com/202308/30/14K5KmzgEq3/video/1000k_0X720_64k_25/hls/index.m3u8'
  # 当ts文件链接不完整时，需拼凑
  # 大部分网站可使用该方法拼接，部分特殊网站需单独拼接
  base_url = re.split(r"[a-zA-Z0-9-_\.]+\.m3u8", url)[0]
  # print(base_url)
  resp = requests.get(url)
  m3u8_text = resp.text
  # print(m3u8_text)
  # 按行拆分m3u8文档
  ts_queue = Queue(10000)
  lines = m3u8_text.split('\n')
  # 找到文档中含有ts字段的行
  concatfile = rootPath + "s" + '.txt'
  m3u8File = rootPath + "index" + '.m3u8'
  with open(m3u8File, 'w') as f:
        f.write('')
  for line in lines:
    if '.ts' in line:
      if 'http' in line:
        # print("ts>>", line)
        ts_queue.put(line)
      else:
        line = base_url + line
        ts_queue.put(line)
        # print('ts>>',line)
      filename = re.search('([a-zA-Z0-9-]+.ts)', line).group(1).strip()
      # 一定要先写文件，因为线程的下载是无序的，文件无法按照
      # 123456。。。去顺序排序，而文件中的命名也无法保证是按顺序的
      # 这会导致下载的ts文件无序，合并时，就会顺序错误，导致视频有问题。
      with open(m3u8File, 'a+') as f:
        f.write(filename + "\n")
      with open(concatfile, 'a+') as f:
        f.write("file %s\n" % filename)
    else:
      #   open(concatfile, 'a+').write("file %s\n" % filename)
      with open(m3u8File, 'a+') as f:
        f.write(line + "\n")

    
    
  return ts_queue,m3u8File
# 线程模式，执行线程下载
def run(ts_queue):
  tt_name = threading.current_thread().getName()
  while not ts_queue.empty():
    url = ts_queue.get()
    r = requests.get(url, stream=True)
    filename = re.search('([a-zA-Z0-9-]+.ts)', url).group(1).strip()
    with open(rootPath + filename, 'wb') as fp:
      for chunk in r.iter_content(5242):
        if chunk:
          fp.write(chunk)
    print(tt_name + " " + filename + ' 下载成功')
# 视频合并方法，使用ffmpeg
def merge(concatfile, name):
  try:
    path = rootPath + name + '.mp4'
    # ffmpeg -i index.m3u8 -vcodec copy -acodec copy out.mp4
    command = 'ffmpeg -i %s -vcodec copy -acodec copy %s' % (concatfile, path)
    os.system(command)
    print('视频合并完成')
  except:
    print('合并失败')
if __name__ == '__main__':
  name = input('请输入视频名称：')
  start = datetime.datetime.now().replace(microsecond=0)
  s,concatfile = down()
  print(s,concatfile)
  threads = []
  for i in range(15):
    t = threading.Thread(target=run, name='th-'+str(i), kwargs={'ts_queue': s})
    threads.append(t)
  for t in threads:
    t.start()
  for t in threads:
    t.join()
  end = datetime.datetime.now().replace(microsecond=0)
  print('下载耗时：' + str(end - start))
  merge(concatfile,name)
  over = datetime.datetime.now().replace(microsecond=0)
  print('合并耗时：' + str(over - end))
```

## Flow Chart

![KTVHTTPCache Flow Chart](http://libobjc-libs.oss-cn-beijing.aliyuncs.com/Resource/KTVHTTPCache-flow-chart-thin.jpeg)


## Features

- Thread safety.
- Logging system, Support for console and file output.
- Accurate view caching information.
- Provide different levels of interface.
- Adjust the download configuration.
- Compatible with M3U8 format video

## Installation

#### Installation with CocoaPods

To integrate KTVHTTPCache into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
pod 'KTVHTTPCache',:git => 'https://github.com/QiuYeHong90/KTVHTTPCache.git',:tag=>'3.0.8'
```

Run `pod install`

#### Installation with Carthage

To integrate KTVHTTPCache into your Xcode project using Carthage, specify it in your Cartfile:

```ogdl
github "ChangbaDevs/KTVHTTPCache" ~> 2.0.0
```

Run `carthage update` to build the framework and drag the built `KTVHTTPCache.framework` and `KTVCocoaHTTPServer.framework` into your Xcode project.


## Usage

- Start proxy.

```objc
[KTVHTTPCache proxyStart:&error];
```

- Generated proxy URL.

```objc
NSURL *proxyURL = [KTVHTTPCache proxyURLWithOriginalURL:originalURL];
AVPlayer *player = [AVPlayer playerWithURL:proxyURL];
```

- Get the complete cache file URL if existed.

```objc
NSURL *completeCacheFileURL= [KTVHTTPCache cacheCompleteFileURLWithURL:originalURL];
```

- Set the URL filter processing mapping relationship.

```objc
[KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
    return URL;
}];
```

- Download Configuration

```objc
// Timeout interval.
[KTVHTTPCache downloadSetTimeoutInterval:30];

// Accept Content-Type.
[KTVHTTPCache downloadSetAcceptableContentTypes:contentTypes];

// Set unsupport Content-Type filter.
[KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
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
NSString *logFilePath = [KTVHTTPCache logRecordLogFilePath];
```


## License

KTVHTTPCache is released under the MIT license.


## Feedback

- GitHub : [Single](https://github.com/QiuYeHong90)
- Email : libobjc@gmail.com
- Email : 793983383@gmail.com

## Developed by Single

- [SGPlayer](https://github.com/libobjc/SGPlayer) - A powerful media player framework for iOS, macOS, and tvOS.
- [KTVVideoProcess](https://github.com/ChangbaDevs/KTVVideoProcess) - A High-Performance video effects processing framework.

