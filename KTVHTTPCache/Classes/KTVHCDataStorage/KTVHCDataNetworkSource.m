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
#import "KTVHCLog.h"


@interface KTVHCDataNetworkSource () <KTVHCDataDownloadDelegate>


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataNetworkSourceDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

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
@property (nonatomic, assign) long long downloadReadedLength;
@property (nonatomic, assign) BOOL downloadCompleteCalled;
@property (nonatomic, assign) BOOL needCallHasAvailableData;


@end


@implementation KTVHCDataNetworkSource


+ (instancetype)sourceWithURLString:(NSString *)URLString
                       headerFields:(NSDictionary *)headerFields
                             offset:(long long)offset
                             length:(long long)length
{
    return [[self alloc] initWithURLString:URLString
                              headerFields:headerFields
                                    offset:offset
                                    length:length];
}

- (instancetype)initWithURLString:(NSString *)URLString
                     headerFields:(NSDictionary *)headerFields
                           offset:(long long)offset
                           length:(long long)length
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.URLString = URLString;
        self.requestHeaderFields = headerFields;
        
        self.offset = offset;
        self.length = length;
        
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)setDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    self.delegate = delegate;
    self.delegateQueue = delegateQueue;
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
    
    KTVHCLogDataNetworkSource(@"call prepare");
    
    NSURL * URL = [NSURL URLWithString:self.URLString];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
    
    if (self.length == KTVHCDataNetworkSourceLengthMaxVaule) {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-", self.offset] forHTTPHeaderField:@"Range"];
    } else {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", self.offset, self.offset + self.length - 1] forHTTPHeaderField:@"Range"];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    self.downloadTask = [[KTVHCDataDownload download] downloadWithRequest:request delegate:self];
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    KTVHCLogDataNetworkSource(@"call close");
    
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
    
    if (self.downloadReadedLength >= self.downloadLength)
    {
        if (self.downloadCompleteCalled)
        {
            KTVHCLogDataNetworkSource(@"read data error : %lld, %lld, %lld", self.downloadReadedLength, self.downloadLength, self.length);
            
            [self.readingHandle closeFile];
            self.readingHandle = nil;
        }
        else
        {
            KTVHCLogDataNetworkSource(@"read data set need call");
            
            self.needCallHasAvailableData = YES;
        }
        
        [self.lock unlock];
        return nil;
    }
    
    NSData * data = [self.readingHandle readDataOfLength:MIN(self.downloadLength - self.downloadReadedLength, length)];
    self.downloadReadedLength += data.length;
    
    KTVHCLogDataNetworkSource(@"read data : %lu, %lld, %lld, %lld", data.length, self.downloadReadedLength, self.downloadLength, self.length);
    
    if (self.downloadReadedLength >= self.length)
    {
        KTVHCLogDataNetworkSource(@"read data finished");
        
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        
        self.didFinishRead = YES;
    }
    
    [self.lock unlock];
    return data;
}


#pragma mark - Callback

- (void)callbackForHasAvailableData
{
    if (self.didClose) {
        return;
    }
    if (!self.needCallHasAvailableData) {
        return;
    }
    
    KTVHCLogDataNetworkSource(@"has available data");
    
    self.needCallHasAvailableData = NO;
    if ([self.delegate respondsToSelector:@selector(networkSourceHasAvailableData:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate networkSourceHasAvailableData:self];
        }];
    }
}


#pragma mark - KTVHCDataDownloadDelegate

- (void)download:(KTVHCDataDownload *)download didCompleteWithError:(NSError *)error
{
    [self.lock lock];
    
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    self.unitItem.writing = NO;
    
    if (self.didClose)
    {
        KTVHCLogDataNetworkSource(@"complete but did close, %@, %ld", self.URLString, error.code);
    }
    else
    {
        if (error)
        {
            self.error = error;
            if (self.error.code != NSURLErrorCancelled || self.errorCanceled)
            {
                KTVHCLogDataNetworkSource(@"complete by error, %@, %ld",  self.URLString, error.code);
                
                if ([self.delegate respondsToSelector:@selector(networkSource:didFailure:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSource:self didFailure:error];
                    }];
                }
            }
            else
            {
                KTVHCLogDataNetworkSource(@"complete by cancel, %@, %ld",  self.URLString, error.code);
            }
        }
        else
        {
            if (self.downloadLength >= self.length)
            {
                KTVHCLogDataNetworkSource(@"complete by donwload finished, %@", self.URLString);
                
                self.didFinishDownload = YES;
                if ([self.delegate respondsToSelector:@selector(networkSourceDidFinishDownload:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSourceDidFinishDownload:self];
                    }];
                }
            }
            else
            {
                KTVHCLogDataNetworkSource(@"complete by unkonwn, %@", self.URLString);
            }
        }
    }
    
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
        KTVHCLogDataNetworkSource(@"receive response\n%@\n%@", self.URLString, response.URL.absoluteString);
        
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
        if ([self.delegate respondsToSelector:@selector(networkSourceDidFinishPrepare:)]) {
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                [self.delegate networkSourceDidFinishPrepare:self];
            }];
        }
        return YES;
    }
    
    KTVHCLogDataNetworkSource(@"receive response without Content-Range\n%@\n%@\n%@", self.URLString, response.URL.absoluteString, response.allHeaderFields);
    
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
    
    KTVHCLogDataNetworkSource(@"receive data, %llu, %llu", self.downloadLength, self.unitItem.length);
    
    [self callbackForHasAvailableData];
    [self.lock unlock];
}


@end
