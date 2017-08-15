//
//  KTVHCDataNetworkSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataNetworkSource.h"
#import "KTVHCDataDownload.h"
#import "KTVHCPathTools.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataCallback.h"

@interface KTVHCDataNetworkSource () <KTVHCDataDownloadDelegate>


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataNetworkSourceDelegate> networkSourceDelegate;

@property (nonatomic, copy) NSString * URLString;

@property (nonatomic, strong) NSDictionary * requestHeaderFields;
@property (nonatomic, strong) NSDictionary * responseHeaderFields;

@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) BOOL errorCanceled;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishDownload;

@property (nonatomic, assign) long long totalContentLength;


#pragma mark - Download

@property (nonatomic, strong) NSURLSessionDataTask * downloadTask;
@property (nonatomic, strong) KTVHCDataUnitItem * unitItem;

@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, strong) NSFileHandle * writingHandle;

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, assign) long long downloadLength;
@property (nonatomic, assign) long long downloadReadOffset;
@property (nonatomic, assign) BOOL downloadDidStart;
@property (nonatomic, assign) BOOL downloadCompleteCalled;
@property (nonatomic, assign) BOOL needCallHasAvailableData;

@end

@implementation KTVHCDataNetworkSource

+ (instancetype)sourceWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                         URLString:(NSString *)URLString
                      headerFields:(NSDictionary *)headerFields
                            offset:(long long)offset
                            length:(long long)length
{
    return [[self alloc] initWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                                URLString:URLString
                             headerFields:headerFields
                                   offset:offset
                                   length:length];
}

- (instancetype)initWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                       URLString:(NSString *)URLString
                    headerFields:(NSDictionary *)headerFields
                          offset:(long long)offset
                          length:(long long)length
{
    if (self = [super init])
    {
        self.networkSourceDelegate = delegate;
        
        self.URLString = URLString;
        self.requestHeaderFields = headerFields;
        
        self.offset = offset;
        self.length = length;
        
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)prepare
{
    if (self.didClose) {
        return;
    }
    if (self.didCallPrepare) {
        return;
    }
    self.didCallPrepare = YES;
    
    NSURL * URL = [NSURL URLWithString:self.URLString];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
    
    if (self.length == KTVHCDataNetworkSourceLengthMaxVaule) {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-", self.offset] forHTTPHeaderField:@"Range"];
    } else {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", self.offset, self.offset + self.length - 1] forHTTPHeaderField:@"Range"];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    self.downloadDidStart = YES;
    self.downloadTask = [[KTVHCDataDownload download] downloadWithRequest:request delegate:self];
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    [self.lock lock];
    
    self.didClose = YES;
    
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    
    [self.downloadTask cancel];
    self.downloadTask = nil;
    
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    self.unitItem.writing = NO;
    
    [self.lock unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    if (self.errorCanceled) {
        return nil;
    }
    
    [self.lock lock];
    
    if ((self.didFinishDownload || self.downloadCompleteCalled) && self.downloadReadOffset >= self.downloadLength)
    {
        [self callbackForFinishRead];
        [self.lock unlock];
        return nil;
    }
    
    if (self.downloadLength <= self.downloadReadOffset) {
        self.needCallHasAvailableData = YES;
        [self.lock unlock];
        return nil;
    }
    
    NSData * data = [self.readingHandle readDataOfLength:MIN(self.downloadLength - self.downloadReadOffset, length)];
    self.downloadReadOffset += data.length;
    if (self.downloadReadOffset >= self.length)
    {
        [self callbackForFinishRead];
    }
    [self.lock unlock];
    return data;
}


#pragma mark - Callback

- (void)callbackForHasAvailableData
{
    if (!self.needCallHasAvailableData) {
        return;
    }
    
    self.needCallHasAvailableData = NO;
    if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceHasAvailableData:)]) {
        [KTVHCDataCallback callbackWithBlock:^{
            [self.networkSourceDelegate networkSourceHasAvailableData:self];
        }];
    }
}

- (void)callbackForFinishRead
{
    [self.readingHandle closeFile];
    self.readingHandle = nil;
 
    if (self.didClose) {
        return;
    }
    
    self.didFinishRead = YES;
    if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishRead:)]) {
        [KTVHCDataCallback callbackWithBlock:^{
            [self.networkSourceDelegate networkSourceDidFinishRead:self];
        }];
    }
}

- (void)callbackForFinishDownload
{
    if (self.didClose) {
        return;
    }
    
    if (self.downloadLength >= self.length)
    {
        self.didFinishDownload = YES;
        if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishDownload:)]) {
            [KTVHCDataCallback callbackWithBlock:^{
                [self.networkSourceDelegate networkSourceDidFinishDownload:self];
            }];
        }
    }
}


#pragma mark - KTVHCDataDownloadDelegate

- (void)download:(KTVHCDataDownload *)download didCompleteWithError:(NSError *)error
{
    [self.lock lock];
    
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    self.unitItem.writing = NO;
    
    if (error && !self.didClose)
    {
        self.error = error;
        if (self.error.code == NSURLErrorCancelled && !self.errorCanceled) {
            if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidCanceled:)]) {
                [KTVHCDataCallback callbackWithBlock:^{
                    [self.networkSourceDelegate networkSourceDidCanceled:self];
                }];
            }
        } else {
            if ([self.networkSourceDelegate respondsToSelector:@selector(networkSource:didFailure:)]) {
                [KTVHCDataCallback callbackWithBlock:^{
                    [self.networkSourceDelegate networkSource:self didFailure:error];
                }];
            }
        }
    }
    [self callbackForFinishDownload];
    self.downloadCompleteCalled = YES;
    
    [self.lock unlock];
}

- (BOOL)download:(KTVHCDataDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response
{
    [[KTVHCDataUnitPool unitPool] unit:self.URLString updateResponseHeaderFields:response.allHeaderFields];
    
    NSString * contentRange = [response.allHeaderFields objectForKey:@"Content-Range"];
    NSRange range = [contentRange rangeOfString:@"/"];
    if (contentRange.length > 0 && range.location != NSNotFound)
    {
        NSString * path = [KTVHCPathTools pathWithURLString:self.URLString offset:self.offset];
        self.unitItem = [KTVHCDataUnitItem unitItemWithOffset:self.offset path:path];
        self.unitItem.writing = YES;
        [[KTVHCDataUnitPool unitPool] unit:self.URLString insertUnitItem:self.unitItem];

        self.filePath = self.unitItem.filePath;
        self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
        
        self.totalContentLength = [contentRange substringFromIndex:range.location + range.length].longLongValue;
        self.responseHeaderFields = response.allHeaderFields;
        self.didFinishPrepare = YES;
        if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishPrepare:)]) {
            [KTVHCDataCallback callbackWithBlock:^{
                [self.networkSourceDelegate networkSourceDidFinishPrepare:self];
            }];
        }
        return YES;
    }
    
    self.errorCanceled = YES;
    return NO;
}

- (void)download:(KTVHCDataDownload *)download didReceiveData:(NSData *)data
{
    if (self.didClose) {
        return;
    }
    
    [self.lock lock];
    [self.writingHandle writeData:data];
    self.downloadLength += data.length;
    self.unitItem.length = self.downloadLength;
    [self callbackForHasAvailableData];
    [self.lock unlock];
}

@end
