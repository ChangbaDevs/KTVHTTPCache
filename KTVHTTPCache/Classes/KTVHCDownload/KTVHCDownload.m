//
//  KTVHCDataDownload.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDownload.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataStorage.h"
#import "KTVHCError.h"
#import "KTVHCLog.h"

#import <UIKit/UIKit.h>

NSString * const KTVHCContentTypeVideo                  = @"video/";
NSString * const KTVHCContentTypeAudio                  = @"audio/";
NSString * const KTVHCContentTypeApplicationMPEG4       = @"application/mp4";
NSString * const KTVHCContentTypeApplicationOctetStream = @"application/octet-stream";
NSString * const KTVHCContentTypeBinaryOctetStream      = @"binary/octet-stream";

@interface KTVHCDownload () <NSURLSessionDataDelegate, NSLocking>

@property (nonatomic, strong) NSLock *coreLock;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, NSError *> *errorDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, KTVHCDataRequest *> *requestDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, id<KTVHCDownloadDelegate>> *delegateDictionary;

@end

@implementation KTVHCDownload

+ (instancetype)download
{
    static KTVHCDownload *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
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
        self.acceptContentTypes = @[KTVHCContentTypeVideo,
                                    KTVHCContentTypeAudio,
                                    KTVHCContentTypeApplicationMPEG4,
                                    KTVHCContentTypeApplicationOctetStream,
                                    KTVHCContentTypeBinaryOctetStream];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)availableHeaderKeys
{
    static NSArray<NSString *> *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = @[@"User-Agent",
                @"Connection",
                @"Accept",
                @"Accept-Encoding",
                @"Accept-Language",
                @"Range"];
    });
    return obj;
}

- (NSURLSessionTask *)downloadWithRequest:(KTVHCDataRequest *)request delegate:(id<KTVHCDownloadDelegate>)delegate
{
    [self lock];
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:request.URL];
    mRequest.timeoutInterval = self.timeoutInterval;
    mRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [request.headerFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        if ([self.availableHeaderKeys containsObject:key] ||
            [self.whitelistHeaderKeys containsObject:key]) {
            [mRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
    [self.additionalHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [mRequest setValue:obj forHTTPHeaderField:key];
    }];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:mRequest];
    [self.requestDictionary setObject:request forKey:task];
    [self.delegateDictionary setObject:delegate forKey:task];
    task.priority = 1.0;
    [task resume];
    KTVHCLogDownload(@"%p, Add Request\nrequest : %@\nURL : %@\nheaders : %@\nHTTPRequest headers : %@\nCount : %d", self, request, request.URL, request.headerFields, mRequest.allHTTPHeaderFields, (int)self.delegateDictionary.count);
    [self unlock];
    return task;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self lock];
    KTVHCLogDownload(@"%p, Complete\nError : %@", self, error);
    if ([self.errorDictionary objectForKey:task]) {
        error = [self.errorDictionary objectForKey:task];
    }
    id<KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:task];
    [delegate download:self didCompleteWithError:error];
    [self.delegateDictionary removeObjectForKey:task];
    [self.requestDictionary removeObjectForKey:task];
    [self.errorDictionary removeObjectForKey:task];
    if (self.delegateDictionary.count <= 0) {
        [self cleanBackgroundTaskAsync];
    }
    [self unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self lock];
    KTVHCDataRequest *dataRequest = [self.requestDictionary objectForKey:task];
    KTVHCDataResponse *dataResponse = [[KTVHCDataResponse alloc] initWithURL:dataRequest.URL headerFields:response.allHeaderFields];
    KTVHCLogDownload(@"%p, Receive response\nrequest : %@\nresponse : %@\nHTTPResponse : %@", self, dataRequest, dataResponse, response.allHeaderFields);
    NSError *error = nil;
    if (!error) {
        if (response.statusCode > 400) {
            error = [KTVHCError errorForResponseUnavailable:task.currentRequest.URL
                                                    request:task.currentRequest
                                                   response:task.response];
        }
    }
    if (!error) {
        BOOL vaild = NO;
        if (dataResponse.contentType.length > 0) {
            for (NSString *obj in self.acceptContentTypes) {
                if ([[dataResponse.contentType lowercaseString] containsString:[obj lowercaseString]]) {
                    vaild = YES;
                }
            }
            if (!vaild && self.unsupportContentTypeFilter) {
                vaild = self.unsupportContentTypeFilter(dataRequest.URL, dataResponse.contentType);
            }
        }
        if (!vaild) {
            error = [KTVHCError errorForUnsupportContentType:task.currentRequest.URL
                                                     request:task.currentRequest
                                                    response:task.response];
        }
    }
    if (!error) {
        if (dataResponse.currentLength <= 0 ||
            (!KTVHCRangeIsFull(dataRequest.range) &&
             (dataResponse.currentLength != KTVHCRangeGetLength(dataRequest.range)))) {
                error = [KTVHCError errorForUnsupportContentType:task.currentRequest.URL
                                                         request:task.currentRequest
                                                        response:task.response];
            }
    }
    if (!error) {
        long long (^getDeletionLength)(long long) = ^(long long desireLength){
            return desireLength + [KTVHCDataStorage storage].totalCacheLength - [KTVHCDataStorage storage].maxCacheLength;
        };
        long long length = getDeletionLength(dataResponse.currentLength);
        if (length > 0) {
            [[KTVHCDataUnitPool pool] deleteUnitsWithLength:length];
            length = getDeletionLength(dataResponse.currentLength);
            if (length > 0) {
                error = [KTVHCError errorForNotEnoughDiskSpace:dataResponse.totalLength
                                                       request:dataResponse.currentLength
                                              totalCacheLength:[KTVHCDataStorage storage].totalCacheLength
                                                maxCacheLength:[KTVHCDataStorage storage].maxCacheLength];
            }
        }
    }
    if (error) {
        KTVHCLogDownload(@"%p, Invaild response\nError : %@", self, error);
        [self.errorDictionary setObject:error forKey:task];
        completionHandler(NSURLSessionResponseCancel);
    } else {
        id<KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:task];
        [delegate download:self didReceiveResponse:dataResponse];
        completionHandler(NSURLSessionResponseAllow);
    }
    [self unlock];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    [self lock];
    KTVHCLogDownload(@"%p, Perform HTTP redirection\nresponse : %@\nrequest : %@", self, response, request);
    completionHandler(request);
    [self unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self lock];
    KTVHCLogDownload(@"%p, Receive data - Begin\nLength : %lld\nURL : %@", self, (long long)data.length, dataTask.originalRequest.URL.absoluteString);
    id<KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    [delegate download:self didReceiveData:data];
    KTVHCLogDownload(@"%p, Receive data - End\nLength : %lld\nURL : %@", self, (long long)data.length, dataTask.originalRequest.URL.absoluteString);
    [self unlock];
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSLock alloc] init];
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
    if (self.delegateDictionary.count > 0) {
        backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self cleanBackgroundTask];
        }];
        UIBackgroundTaskIdentifier identifier = backgroundTaskIdentifier;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (identifier == backgroundTaskIdentifier) {
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
