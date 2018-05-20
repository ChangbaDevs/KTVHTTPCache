//
//  KTVHCDataDownload.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDownload.h"
#import <UIKit/UIKit.h>
#import "KTVHCLog.h"
#import "KTVHCError.h"
#import "KTVHCDataStorage.h"
#import "KTVHCDataUnitPool.h"

@interface KTVHCDownload () <NSURLSessionDataDelegate, NSLocking>

@property (nonatomic, strong) NSRecursiveLock * coreLock;
@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSOperationQueue * sessionDelegateQueue;
@property (nonatomic, strong) NSURLSessionConfiguration * sessionConfiguration;
@property (nonatomic, strong) NSMutableDictionary <NSURLSessionTask *, NSError *> * errorDictionary;
@property (nonatomic, strong) NSMutableDictionary <NSURLSessionTask *, KTVHCDataRequest *> * requestDictionary;
@property (nonatomic, strong) NSMutableDictionary <NSURLSessionTask *, id<KTVHCDownloadDelegate>> * delegateDictionary;

@end

@implementation KTVHCDownload

+ (instancetype)download
{
    static KTVHCDownload * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.timeoutInterval = 30.0f;
        self.errorDictionary = [NSMutableDictionary dictionary];
        self.requestDictionary = [NSMutableDictionary dictionary];
        self.delegateDictionary = [NSMutableDictionary dictionary];
        self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
        self.sessionDelegateQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionConfiguration.timeoutIntervalForRequest = self.timeoutInterval;
        self.sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.sessionDelegateQueue];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:[UIApplication sharedApplication]];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSURLSessionTask *)downloadWithRequest:(KTVHCDataRequest *)request delegate:(id<KTVHCDownloadDelegate>)delegate
{
    [self lock];
    KTVHCLogDownload(@"add download begin\n%@\n%@", request.URL, request.headers);
    NSMutableURLRequest * HTTPRequest = [NSMutableURLRequest requestWithURL:request.URL];
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
    [request.headers enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * obj, BOOL * stop) {
        if ([availableHeaderKeys containsObject:key] && ![obj containsString:@"AppleCoreMedia/"]) {
            [HTTPRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
    HTTPRequest.timeoutInterval = self.timeoutInterval;
    HTTPRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [self.commonHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [HTTPRequest setValue:obj forHTTPHeaderField:key];
    }];
    NSURLSessionDataTask * task = [self.session dataTaskWithRequest:HTTPRequest];
    task.priority = 1.0;
    [self.requestDictionary setObject:request forKey:task];
    [self.delegateDictionary setObject:delegate forKey:task];
    [task resume];
    KTVHCLogDownload(@"add download end\n%@\n%@", request.URL.absoluteString, request.headers);
    [self unlock];
    return task;
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self lock];
    KTVHCLogDownload(@"complete, %d, %@", (int)error.code, task.originalRequest.URL.absoluteString);
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:task];
    NSError * cancelError = [self.errorDictionary objectForKey:task];
    if (cancelError) {
        error = cancelError;
    }
    [delegate download:self didCompleteWithError:error];
    [self.delegateDictionary removeObjectForKey:task];
    [self.requestDictionary removeObjectForKey:task];
    [self.errorDictionary removeObjectForKey:task];
    if (self.delegateDictionary.count <= 0) {
        [self cleanBackgroundTaskAsync];
    }
    [self unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self lock];
    KTVHCLogDownload(@"receive response\n%@\n%@", response.URL.absoluteString, [(NSHTTPURLResponse *)response allHeaderFields]);
    NSHTTPURLResponse * HTTPResponse = (NSHTTPURLResponse *)response;
    KTVHCDataRequest * dataRequest = [self.requestDictionary objectForKey:dataTask];
    KTVHCDataResponse * dataResponse = [[KTVHCDataResponse alloc] initWithURL:dataRequest.URL headers:HTTPResponse.allHeaderFields];
    NSError * error = nil;
    if (!error) {
        if (HTTPResponse.statusCode > 400) {
            error = [KTVHCError errorForResponseUnavailable:dataTask.currentRequest.URL request:dataTask.currentRequest response:dataTask.response];
        }
        if (!error) {
            BOOL contentTypeVaild = NO;
            if (dataResponse.contentType.length > 0) {
                if (self.contentTypeFilter) {
                    contentTypeVaild = self.contentTypeFilter(dataRequest.URL.absoluteString, dataResponse.contentType, dataRequest.acceptContentTypes);
                } else {
                    for (NSString * obj in dataRequest.acceptContentTypes) {
                        if ([[dataResponse.contentType lowercaseString] containsString:[obj lowercaseString]]) {
                            contentTypeVaild = YES;
                        }
                    }
                }
            }
            if (!contentTypeVaild) {
                error = [KTVHCError errorForUnsupportContentType:dataTask.currentRequest.URL request:dataTask.currentRequest response:dataTask.response];
            }
            if (!error) {
                if (dataResponse.currentLength != KTVHCRangeGetLength(dataRequest.range)) {
                    error = [KTVHCError errorForUnsupportContentType:dataTask.currentRequest.URL request:dataTask.currentRequest response:dataTask.response];
                }
                if (!error) {
                    long long delta = dataResponse.currentLength + [KTVHCDataStorage storage].totalCacheLength - [KTVHCDataStorage storage].maxCacheLength;
                    if (delta > 0) {
                        [[KTVHCDataUnitPool pool] deleteUnitsWithMinSize:delta];
                        delta = dataResponse.currentLength + [KTVHCDataStorage storage].totalCacheLength - [KTVHCDataStorage storage].maxCacheLength;
                        if (delta > 0) {
                            error = [KTVHCError errorForNotEnoughDiskSpace:dataResponse.totalLength request:dataResponse.currentLength totalCacheLength:[KTVHCDataStorage storage].totalCacheLength maxCacheLength:[KTVHCDataStorage storage].maxCacheLength];
                        }
                    }
                }
            }
        }
    }
    if (error) {
        [self.errorDictionary setObject:error forKey:dataTask];
        completionHandler(NSURLSessionResponseCancel);
    } else {
        id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
        [delegate download:self didReceiveResponse:dataResponse];
        completionHandler(NSURLSessionResponseAllow);
    }
    [self unlock];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    [self lock];
    KTVHCLogDownload(@"will perform HTTP redirection\n%@\n%@\n%@\n%@", response.URL.absoluteString, [(NSHTTPURLResponse *)response allHeaderFields], request.URL.absoluteString, request.allHTTPHeaderFields);
    completionHandler(request);
    [self unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self lock];
    KTVHCLogDownload(@"receive data begin, %lld, %@", (long long)data.length, dataTask.originalRequest.URL.absoluteString);
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    [delegate download:self didReceiveData:data];
    KTVHCLogDownload(@"receive data end, %lld, %@", (long long)data.length, dataTask.originalRequest.URL.absoluteString);
    [self unlock];
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}


#pragma mark - Background Task

static UIBackgroundTaskIdentifier backgroundTaskIdentifier = -1;

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self cleanBackgroundTask];
    [self lock];
    if (self.delegateDictionary.count > 0)
    {
        backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self cleanBackgroundTask];
        }];
        UIBackgroundTaskIdentifier blockIdentifier = backgroundTaskIdentifier;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (blockIdentifier == backgroundTaskIdentifier) {
                [self cleanBackgroundTask];
            }
        });
    }
    [self unlock];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self cleanBackgroundTask];
}

- (void)cleanBackgroundTask
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void)cleanBackgroundTaskAsync
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self lock];
        if (self.delegateDictionary.count <= 0) {
            [self cleanBackgroundTask];
        }
        [self unlock];
    });
}


@end
