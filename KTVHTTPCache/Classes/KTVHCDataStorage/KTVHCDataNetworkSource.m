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

@interface KTVHCDataNetworkSource () <KTVHCDataDownloadDelegate>


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger size;

@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataNetworkSourceDelegate> networkSourceDelegate;

@property (nonatomic, copy) NSString * URLString;

@property (nonatomic, strong) NSDictionary * requestHeaderFields;
@property (nonatomic, strong) NSDictionary * responseHeaderFields;

@property (nonatomic, strong) NSError * error;
@property (nonatomic, assign) BOOL errorCanceled;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didFinishClose;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishDownload;

@property (nonatomic, assign) NSInteger totalContentLength;


#pragma mark - Download

@property (nonatomic, strong) NSURLSessionDataTask * downloadTask;
@property (nonatomic, strong) KTVHCDataUnitItem * unitItem;

@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, strong) NSFileHandle * writingHandle;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, assign) NSInteger downloadSize;
@property (nonatomic, assign) NSInteger downloadReadOffset;
@property (nonatomic, assign) BOOL downloadCompleteCalled;

@end

@implementation KTVHCDataNetworkSource

+ (instancetype)sourceWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                         URLString:(NSString *)URLString
                      headerFields:(NSDictionary *)headerFields
                            offset:(NSInteger)offset
                              size:(NSInteger)size
{
    return [[self alloc] initWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                                URLString:URLString
                             headerFields:headerFields
                                   offset:offset
                                     size:size];
}

- (instancetype)initWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                       URLString:(NSString *)URLString
                    headerFields:(NSDictionary *)headerFields
                          offset:(NSInteger)offset
                            size:(NSInteger)size
{
    if (self = [super init])
    {
        self.networkSourceDelegate = delegate;
        
        self.URLString = URLString;
        self.requestHeaderFields = headerFields;
        
        self.offset = offset;
        self.size = size;
        
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)prepare
{
    if (self.didClose) {
        return;
    }
    
    NSURL * URL = [NSURL URLWithString:self.URLString];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
    
    if (self.size == KTVHCDataNetworkSourceSizeMaxVaule) {
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-", self.offset] forHTTPHeaderField:@"Range"];
    } else {
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.offset, self.offset + self.size - 1] forHTTPHeaderField:@"Range"];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    self.downloadTask = [[KTVHCDataDownload download] downloadWithRequest:request delegate:self];
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    [self.condition lock];
    
    self.didClose = YES;
    
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    
    [self.downloadTask cancel];
    self.downloadTask = nil;
    if (self.downloadCompleteCalled) {
        [self callbackForFinishClose];
    }
    
    [self.condition unlock];
}

- (NSData *)syncReadDataOfLength:(NSInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    [self.condition lock];
    while (!self.didFinishDownload && ((self.downloadSize - self.downloadReadOffset) < length))
    {
        [self.condition wait];
    }
    if (self.didFinishDownload && self.downloadReadOffset >= self.downloadSize)
    {
        [self callbackForFinishRead];
        [self.condition unlock];
        return nil;
    }
    NSData * data = [self.readingHandle readDataOfLength:length];
    self.downloadReadOffset += data.length;
    if (self.downloadReadOffset >= self.size)
    {
        [self callbackForFinishRead];
    }
    [self.condition unlock];
    return data;
}


#pragma mark - Callback

- (void)callbackForFinishRead
{
    [self.readingHandle closeFile];
    self.readingHandle = nil;
 
    if (self.didClose) {
        return;
    }
    
    self.didFinishRead = YES;
    if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishRead:)]) {
        [self.networkSourceDelegate networkSourceDidFinishRead:self];
    }
}

- (void)callbackForFinishDownload
{
    if (self.didClose) {
        return;
    }
    
    if (self.downloadSize >= self.size)
    {
        self.didFinishDownload = YES;
        if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishDownload:)]) {
            [self.networkSourceDelegate networkSourceDidFinishDownload:self];
        }
    }
}

- (void)callbackForFinishClose
{
    if (!self.didClose) {
        return;
    }
    if (self.didFinishClose) {
        return;
    }
    
    self.didFinishClose = YES;
    if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishClose:)]) {
        [self.networkSourceDelegate networkSourceDidFinishClose:self];
    }
}


#pragma mark - KTVHCDataDownloadDelegate

- (void)download:(KTVHCDataDownload *)download didCompleteWithError:(NSError *)error
{
    [self.condition lock];
    
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    
    if (error && !self.didClose)
    {
        self.error = error;
        if (self.error.code == NSURLErrorCancelled && !self.errorCanceled) {
            if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidCanceled:)]) {
                [self.networkSourceDelegate networkSourceDidCanceled:self];
            }
        } else {
            if ([self.networkSourceDelegate respondsToSelector:@selector(networkSource:didFailure:)]) {
                [self.networkSourceDelegate networkSource:self didFailure:error];
            }
        }
    }
    [self callbackForFinishDownload];
    self.downloadCompleteCalled = YES;
    [self callbackForFinishClose];
    
    [self.condition signal];
    [self.condition unlock];
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
        [[KTVHCDataUnitPool unitPool] unit:self.URLString insertUnitItem:self.unitItem];

        self.filePath = self.unitItem.filePath;
        self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
        
        self.totalContentLength = [contentRange substringFromIndex:range.location + range.length].integerValue;
        self.responseHeaderFields = response.allHeaderFields;
        self.didFinishPrepare = YES;
        if ([self.networkSourceDelegate respondsToSelector:@selector(networkSourceDidFinishPrepare:)]) {
            [self.networkSourceDelegate networkSourceDidFinishPrepare:self];
        }
        return YES;
    }
    self.errorCanceled = YES;
    return NO;
}

- (void)download:(KTVHCDataDownload *)download didReceiveData:(NSData *)data
{
    [self.condition lock];
    [self.writingHandle writeData:data];
    self.downloadSize += data.length;
    self.unitItem.size = self.downloadSize;
    [self.condition signal];
    [self.condition unlock];
}


@end
