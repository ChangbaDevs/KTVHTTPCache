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
    KTVHCDataNetworkSourceErrorReasonStatusCode,
    KTVHCDataNetworkSourceErrorReasonContentType,
    KTVHCDataNetworkSourceErrorReasonContentRange,
    KTVHCDataNetworkSourceErrorReasonCacheSpace,
};


@interface KTVHCDataNetworkSource () <KTVHCDownloadDelegate>


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;
@property (nonatomic, strong) NSMutableURLRequest * HTTPRequest;


#pragma mark - Setter

@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) BOOL errorCanceled;
@property (nonatomic, assign) KTVHCDataNetworkSourceErrorReason errorReason;
@property (nonatomic, copy) NSHTTPURLResponse * errorResponse;

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

- (instancetype)initWithRequest:(KTVHCDataRequest *)reqeust range:(KTVHCRange)range
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        _request = reqeust;
        _range = range;
        
        self.lock = [[NSLock alloc] init];
        
        KTVHCLogDataNetworkSource(@"did setup\n%@\n%@\n%@\n%@", self.request.URL, self.request.headers, self.request.acceptContentTypes, KTVHCStringFromRange(self.range));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)setDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    _delegate = delegate;
    _delegateQueue = delegateQueue;
}

- (void)prepare
{
    if (self.didClosed) {
        return;
    }
    if (self.didPrepared) {
        return;
    }
    [self.lock lock];
    KTVHCLogDataNetworkSource(@"call prepare");
    self.HTTPRequest = [NSMutableURLRequest requestWithURL:self.request.URL];
    static NSArray <NSString *> * availableHeaderKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableHeaderKeys = @[@"User-Agent",
                                @"Connection",
                                @"Accept",
                                @"Accept-Encoding",
                                @"Accept-Language",
                                @"Range"];
    });
    [self.request.headers enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * obj, BOOL * stop) {
        if ([availableHeaderKeys containsObject:key] && ![obj containsString:@"AppleCoreMedia/"])
        {
            [self.HTTPRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
    self.downloadTask = [[KTVHCDownload download] downloadWithRequest:self.HTTPRequest delegate:self];
    [self.lock unlock];
}

- (void)close
{
    if (self.didClosed) {
        return;
    }
    KTVHCLogDataNetworkSource(@"call close begin");
    [self.lock lock];
    _didClosed = YES;
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    if (!self.downloadCompleteCalled) {
        [self.downloadTask cancel];
    }
    self.downloadTask = nil;
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    KTVHCLogDataNetworkSource(@"call close end");
    [self.lock unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClosed) {
        return nil;
    }
    if (self.didFinished) {
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
            KTVHCLogDataNetworkSource(@"read data error : %lld, %lld, %lld", self.downloadReadedLength, self.downloadLength, KTVHCRangeGetLength(self.range));
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
    NSData * data = [self.readingHandle readDataOfLength:(NSUInteger)MIN(self.downloadLength - self.downloadReadedLength, length)];
    self.downloadReadedLength += data.length;
    KTVHCLogDataNetworkSource(@"read data : %lld, %lld, %lld, %lld", (long long)data.length, self.downloadReadedLength, self.downloadLength, KTVHCRangeGetLength(self.range));
    if (self.downloadReadedLength >= KTVHCRangeGetLength(self.range))
    {
        KTVHCLogDataNetworkSource(@"read data finished");
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        _didFinished = YES;
    }
    [self.lock unlock];
    return data;
}


#pragma mark - Callback

- (void)callbackForHasAvailableData
{
    if (self.didClosed) {
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
    if (self.didClosed) {
        return;
    }
    if (self.didPrepared) {
        return;
    }
    _didPrepared = YES;
    KTVHCLogDataNetworkSource(@"prepare finished");
    if ([self.delegate respondsToSelector:@selector(sourceDidPrepared:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourceDidPrepared:self];
        }];
    }
}


#pragma mark - Handle Response

- (BOOL)checkResponseStatusCode:(NSInteger)statusCode
{
    if (statusCode >= 400) {
        return NO;
    }
    return YES;
}

static BOOL (^globalContentTypeFilterBlock)(NSString *, NSString *, NSArray <NSString *> *) = nil;

+ (void)setContentTypeFilterBlock:(BOOL (^)(NSString *,
                                            NSString *,
                                            NSArray <NSString *> *))contentTypeFilterBlock
{
    globalContentTypeFilterBlock = contentTypeFilterBlock;
}

- (BOOL)checkResponeContentType:(NSHTTPURLResponse *)response
{
    NSString * contentType = [response.allHeaderFields objectForKey:@"Content-Type"];
    if (!contentType) {
        contentType = [response.allHeaderFields objectForKey:@"content-type"];
    }
    
    if (contentType.length > 0)
    {
        if (globalContentTypeFilterBlock) {
            return globalContentTypeFilterBlock(self.request.URL.absoluteString, contentType, self.request.acceptContentTypes);
        } else {
            for (NSString * obj in self.request.acceptContentTypes)
            {
                if ([[contentType lowercaseString] containsString:[obj lowercaseString]])
                {
                    return YES;
                }
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
        _range = KTVHCRangeWithEnsureLength(self.range, self.totalContentLength);
        if (self.currentContentLength > 0 && self.currentContentLength == KTVHCRangeGetLength(self.range)) {
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
    KTVHCLogDataNetworkSource(@"response error\n%@\n%@\n%@\n%@", self.request.URL, domain, response.URL.absoluteString, response.allHeaderFields);
    
    self.errorCanceled = YES;
    self.errorReason = reason;
    self.errorResponse = response;
}

- (void)handleResponse:(NSHTTPURLResponse *)response
{
    [[KTVHCDataUnitPool unitPool] unit:self.request.URL.absoluteString updateResponseHeaderFields:response.allHeaderFields];
    
    NSString * relativePath = [KTVHCPathTools relativePathForUnitItemFileWithURLString:self.request.URL.absoluteString
                                                                                offset:self.range.start];
    self.unitItem = [KTVHCDataUnitItem unitItemWithOffset:self.range.start relativePath:relativePath];
    
    [[KTVHCDataUnitPool unitPool] unit:self.request.URL.absoluteString insertUnitItem:self.unitItem];
    
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
    
    if (self.didClosed)
    {
        KTVHCLogDataNetworkSource(@"complete but did close, %@, %d", self.request.URL.absoluteString, (int)error.code);
    }
    else
    {
        if (error)
        {
            self.error = error;
            if (self.error.code != NSURLErrorCancelled || self.errorCanceled)
            {
                KTVHCLogDataNetworkSource(@"complete by error, %@, %d",  self.request.URL.absoluteString, (int)error.code);
                
                if (self.errorCanceled)
                {
                    NSError * resultError = nil;
                    switch (self.errorReason)
                    {
                        case KTVHCDataNetworkSourceErrorReasonStatusCode:
                        {
                            resultError = [KTVHCError errorForResponseUnavailable:self.request.URL.absoluteString
                                                                          request:self.HTTPRequest
                                                                         response:self.errorResponse];
                        }
                            break;
                        case KTVHCDataNetworkSourceErrorReasonContentType:
                        case KTVHCDataNetworkSourceErrorReasonContentRange:
                        {
                            resultError = [KTVHCError errorForUnsupportTheContent:self.request.URL.absoluteString
                                                                          request:self.HTTPRequest
                                                                         response:self.errorResponse];
                        }
                            break;
                        case KTVHCDataNetworkSourceErrorReasonCacheSpace:
                        {
                            resultError = [KTVHCError errorForNotEnoughDiskSpace:self.totalContentLength
                                                                         request:self.currentContentLength
                                                                totalCacheLength:[KTVHCDataStorage storage].totalCacheLength
                                                                  maxCacheLength:[KTVHCDataStorage storage].maxCacheLength];
                        }
                            break;
                        default:
                            break;
                    }
                    if (resultError) {
                        self.error = resultError;
                    }
                }
                
                if ([self.delegate respondsToSelector:@selector(networkSource:didFailed:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSource:self didFailed:self.error];
                    }];
                }
            }
            else
            {
                KTVHCLogDataNetworkSource(@"complete by cancel, %@, %d",  self.request.URL.absoluteString, (int)error.code);
            }
        }
        else
        {
            if (self.downloadLength >= KTVHCRangeGetLength(self.range))
            {
                KTVHCLogDataNetworkSource(@"complete by donwload finished, %@", self.request.URL.absoluteString);
                
                if ([self.delegate respondsToSelector:@selector(networkSourceDidFinishedDownload:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSourceDidFinishedDownload:self];
                    }];
                }
            }
            else
            {
                KTVHCLogDataNetworkSource(@"complete by unkonwn, %@", self.request.URL.absoluteString);
            }
        }
    }
    
    self.downloadCompleteCalled = YES;
    [self.lock unlock];
}

- (BOOL)download:(KTVHCDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response
{
    BOOL success = [self checkResponseStatusCode:response.statusCode];
    if (!success)
    {
        [self handleResponseDomain:@"status code error" reason:KTVHCDataNetworkSourceErrorReasonStatusCode response:response];
        return NO;
    }
    
    success = [self checkResponeContentType:response];
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
    if (self.didClosed) {
        return;
    }
    
    [self.lock lock];
    [self.writingHandle writeData:data];
    self.downloadLength += data.length;
    self.unitItem.length = self.downloadLength;
    
    KTVHCLogDataNetworkSource(@"receive data, %lld, %llu, %llu", (long long)data.length, self.downloadLength, self.unitItem.length);
    
    [self callbackForHasAvailableData];
    [self.lock unlock];
}


@end
