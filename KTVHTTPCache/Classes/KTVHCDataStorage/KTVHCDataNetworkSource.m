//
//  KTVHCDataNetworkSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataNetworkSource.h"
#import "KTVHCDataStorage.h"
#import "KTVHCPathTools.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataCallback.h"
#import "KTVHCDownload.h"
#import "KTVHCError.h"
#import "KTVHCLog.h"


typedef NS_ENUM(NSUInteger, KTVHCDataNetworkSourceErrorReason)
{
    KTVHCDataNetworkSourceErrorReasonNone,
    KTVHCDataNetworkSourceErrorReasonContentType,
    KTVHCDataNetworkSourceErrorReasonContentRange,
    KTVHCDataNetworkSourceErrorReasonCacheSpace,
};


@interface KTVHCDataNetworkSource () <KTVHCDownloadDelegate>


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataNetworkSourceDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, copy) NSArray <NSString *> * acceptContentTypePrefixs;

@property (nonatomic, strong) NSMutableURLRequest * request;

@property (nonatomic, copy) NSDictionary * requestHeaderFields;
@property (nonatomic, copy) NSDictionary * responseHeaderFields;

@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) BOOL errorCanceled;
@property (nonatomic, assign) KTVHCDataNetworkSourceErrorReason errorReason;
@property (nonatomic, copy) NSHTTPURLResponse * errorResponse;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishDownload;

@property (nonatomic, assign) long long totalContentLength;
@property (nonatomic, assign) long long currentContentLength;


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
           acceptContentTypePrefixs:(NSArray <NSString *> *)acceptContentTypePrefixs
                             offset:(long long)offset
                             length:(long long)length
{
    return [[self alloc] initWithURLString:URLString
                              headerFields:headerFields
                  acceptContentTypePrefixs:acceptContentTypePrefixs
                                    offset:offset
                                    length:length];
}

- (instancetype)initWithURLString:(NSString *)URLString
                     headerFields:(NSDictionary *)headerFields
         acceptContentTypePrefixs:(NSArray <NSString *> *)acceptContentTypePrefixs
                           offset:(long long)offset
                           length:(long long)length
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        self.URLString = URLString;
        self.requestHeaderFields = headerFields;
        self.acceptContentTypePrefixs = acceptContentTypePrefixs;
        
        self.offset = offset;
        self.length = length;
        
        self.lock = [[NSLock alloc] init];
        
        KTVHCLogDataNetworkSource(@"did setup\n%@\n%@\n%@\noffset, %lld, length, %lld", self.URLString, self.requestHeaderFields, self.acceptContentTypePrefixs, self.offset, self.length);
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
    self.request = [NSMutableURLRequest requestWithURL:URL];
    
    static NSArray <NSString *> * availableHeaderKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableHeaderKeys = @[@"User-Agent",
                                @"Connection",
                                @"Accept",
                                @"Accept-Encoding",
                                @"Accept-Language"];
    });
    
    [self.requestHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * obj, BOOL * stop) {
        if ([availableHeaderKeys containsObject:key] && ![obj containsString:@"AppleCoreMedia/"])
        {
            [self.request setValue:obj forHTTPHeaderField:key];
        }
    }];
    
    if (self.length == KTVHCDataNetworkSourceLengthMaxVaule) {
        [self.request setValue:[NSString stringWithFormat:@"bytes=%lld-", self.offset] forHTTPHeaderField:@"Range"];
    } else {
        [self.request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", self.offset, self.offset + self.length - 1] forHTTPHeaderField:@"Range"];
    }
    
    self.downloadTask = [[KTVHCDownload download] downloadWithRequest:self.request delegate:self];
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    KTVHCLogDataNetworkSource(@"call close begin");
    
    [self.lock lock];
    
    self.didClose = YES;
    
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    
    if (!self.downloadCompleteCalled) {
        [self.downloadTask cancel];
    }
    self.downloadTask = nil;
    
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    self.unitItem.writing = NO;
    
    KTVHCLogDataNetworkSource(@"call close end");
    
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

- (void)callbackForFinishPrepare
{
    if (self.didClose) {
        return;
    }
    
    if (self.didFinishPrepare) {
        return;
    }
    self.didFinishPrepare = YES;
    
    KTVHCLogDataNetworkSource(@"prepare finished");
    
    if ([self.delegate respondsToSelector:@selector(networkSourceDidFinishPrepare:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate networkSourceDidFinishPrepare:self];
        }];
    }
}


#pragma mark - Handle Response

- (BOOL)checkResponeContentType:(NSHTTPURLResponse *)response
{
    NSString * contentType = [response.allHeaderFields objectForKey:@"Content-Type"];
    if (!contentType) {
        contentType = [response.allHeaderFields objectForKey:@"content-type"];
    }
    
    if (contentType.length > 0)
    {
        for (NSString * obj in self.acceptContentTypePrefixs)
        {
            if ([[contentType lowercaseString] hasPrefix:[obj lowercaseString]])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)checkResponseContentRangeAndConfigProperty:(NSHTTPURLResponse *)response
{
    NSString * contentLength = [response.allHeaderFields objectForKey:@"Content-Length"];
    NSString * contentRange = [response.allHeaderFields objectForKey:@"Content-Range"];
    NSRange range = [contentRange rangeOfString:@"/"];
    
    if (!contentLength) {
        contentLength = [response.allHeaderFields objectForKey:@"content-length"];
    }
    if (!contentRange) {
        contentRange = [response.allHeaderFields objectForKey:@"content-range"];
    }
    
    if (contentRange.length > 0 && range.location != NSNotFound)
    {
        self.totalContentLength = [contentRange substringFromIndex:range.location + range.length].longLongValue;
        self.currentContentLength = [contentLength longLongValue];
        
        if (self.length == KTVHCDataNetworkSourceLengthMaxVaule) {
            self.length = self.totalContentLength - self.offset;
        }
        
        if (self.currentContentLength > 0 && self.currentContentLength == self.length) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)checkCacheSpace
{
    long long delta = [KTVHCDataStorage storage].totalCacheLength + self.currentContentLength - [KTVHCDataStorage storage].maxCacheLength;
    if (delta > 0)
    {
        [[KTVHCDataUnitPool unitPool] deleteUnitsWithMinSize:delta];
        
        delta = [KTVHCDataStorage storage].totalCacheLength + self.currentContentLength - [KTVHCDataStorage storage].maxCacheLength;
        if (delta > 0)
        {
            return NO;
        }
    }
    return YES;
}

- (void)handleResponseDomain:(NSString *)domain reason:(KTVHCDataNetworkSourceErrorReason)reason response:(NSHTTPURLResponse *)response
{
    KTVHCLogDataNetworkSource(@"response error\n%@\n%@\n%@\n%@", self.URLString, domain, response.URL.absoluteString, response.allHeaderFields);
    
    self.errorCanceled = YES;
    self.errorReason = reason;
    self.errorResponse = response;
}

- (void)handleResponse:(NSHTTPURLResponse *)response
{
    self.responseHeaderFields = response.allHeaderFields;
    
    [[KTVHCDataUnitPool unitPool] unit:self.URLString updateResponseHeaderFields:response.allHeaderFields];
    
    NSString * relativePath = [KTVHCPathTools relativePathForFileWithURLString:self.URLString offset:self.offset];
    self.unitItem = [KTVHCDataUnitItem unitItemWithOffset:self.offset relativePath:relativePath];
    self.unitItem.writing = YES;
    
    [[KTVHCDataUnitPool unitPool] unit:self.URLString insertUnitItem:self.unitItem];
    
    self.filePath = self.unitItem.absolutePath;
    self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
}


#pragma mark - KTVHCDownloadDelegate

- (void)download:(KTVHCDownload *)download didCompleteWithError:(NSError *)error
{
    [self.lock lock];
    
    [self.writingHandle synchronizeFile];
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
                
                if (self.errorCanceled)
                {
                    switch (self.errorReason) {
                        case KTVHCDataNetworkSourceErrorReasonNone:
                        {
                            
                        }
                            break;
                        case KTVHCDataNetworkSourceErrorReasonContentType:
                        case KTVHCDataNetworkSourceErrorReasonContentRange:
                        {
                            NSError * obj = [KTVHCError errorForResponseUnavailable:self.URLString request:self.request response:self.errorResponse];
                            if (obj) {
                                self.error = obj;
                            }
                        }
                            break;
                        case KTVHCDataNetworkSourceErrorReasonCacheSpace:
                        {
                            NSError * obj = [KTVHCError errorForNotEnoughDiskSpace:self.totalContentLength
                                                                           request:self.currentContentLength
                                                                  totalCacheLength:[KTVHCDataStorage storage].totalCacheLength
                                                                    maxCacheLength:[KTVHCDataStorage storage].maxCacheLength];
                            if (obj) {
                                self.error = obj;
                            }
                        }
                            break;
                    }
                }
                
                if ([self.delegate respondsToSelector:@selector(networkSource:didFailure:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSource:self didFailure:self.error];
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

- (BOOL)download:(KTVHCDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response
{
    BOOL success = [self checkResponeContentType:response];
    if (!success)
    {
        [self handleResponseDomain:@"content type error" reason:KTVHCDataNetworkSourceErrorReasonContentType response:response];
        return NO;
    }
    
    success = [self checkResponseContentRangeAndConfigProperty:response];
    if (!success)
    {
        [self handleResponseDomain:@"content range error" reason:KTVHCDataNetworkSourceErrorReasonContentRange response:response];
        return NO;
    }
    
    success = [self checkCacheSpace];
    if (!success)
    {
        [self handleResponseDomain:@"cache space error" reason:KTVHCDataNetworkSourceErrorReasonCacheSpace response:response];
        return NO;
    }
    
    [self handleResponse:response];
    [self callbackForFinishPrepare];
    
    return YES;
}

- (void)download:(KTVHCDownload *)download didReceiveData:(NSData *)data
{
    if (self.didClose) {
        return;
    }
    
    [self.lock lock];
    [self.writingHandle writeData:data];
    self.downloadLength += data.length;
    self.unitItem.length = self.downloadLength;
    
    KTVHCLogDataNetworkSource(@"receive data, %lu, %llu, %llu", data.length, self.downloadLength, self.unitItem.length);
    
    [self callbackForHasAvailableData];
    [self.lock unlock];
}


@end
