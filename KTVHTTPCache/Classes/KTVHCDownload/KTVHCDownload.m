//
//  KTVHCDataDownload.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDownload.h"
#import "KTVHCLog.h"
#import <UIKit/UIKit.h>


@interface KTVHCDownload () <NSURLSessionDataDelegate>


@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSURLSessionConfiguration * sessionConfiguration;
@property (nonatomic, strong) NSOperationQueue * sessionDelegateQueue;

@property (nonatomic, strong) NSMutableDictionary <NSURLSessionTask *, id<KTVHCDownloadDelegate>> * delegateDictionary;
@property (nonatomic, strong) NSLock * lock;


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
        
        self.lock = [[NSLock alloc] init];
        self.delegateDictionary = [NSMutableDictionary dictionary];
        self.timeoutInterval = 30.0f;
        
        self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
        self.sessionDelegateQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionConfiguration.timeoutIntervalForRequest = self.timeoutInterval;
        self.sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
        
        
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.sessionDelegateQueue];
        
        // Notification
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


#pragma mark - Download

- (NSURLSessionDataTask *)downloadWithRequest:(NSMutableURLRequest *)request delegate:(id <KTVHCDownloadDelegate>)delegate
{
    [self.lock lock];
    
    KTVHCLogDownload(@"add download begin\n%@\n%@", request.URL.absoluteString, request.allHTTPHeaderFields);
    
    // mutable
    if (![request isKindOfClass:[NSMutableURLRequest class]]) {
        request = [request mutableCopy];
    }
    
    // config
    request.timeoutInterval = self.timeoutInterval;
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [self.commonHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    
    // setup
    NSURLSessionDataTask * task = [self.session dataTaskWithRequest:request];
    task.priority = 1.0;
    [self.delegateDictionary setObject:delegate forKey:task];
    [task resume];
    
    KTVHCLogDownload(@"add download end\n%@\n%@", request.URL.absoluteString, request.allHTTPHeaderFields);
    
    [self.lock unlock];
    return task;
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self.lock lock];
    
    KTVHCLogDownload(@"complete, %d, %@", (int)error.code, task.originalRequest.URL.absoluteString);
    
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:task];
    [delegate download:self didCompleteWithError:error];
    [self.delegateDictionary removeObjectForKey:task];
    if (self.delegateDictionary.count <= 0)
    {
        [self cleanBackgroundTaskAsync];
    }
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.lock lock];
    
    KTVHCLogDownload(@"receive response\n%@\n%@", response.URL.absoluteString, [(NSHTTPURLResponse *)response allHeaderFields]);
    
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    BOOL result = [delegate download:self didReceiveResponse:(NSHTTPURLResponse *)response];
    
    NSURLSessionResponseDisposition responseDisposition = result ? NSURLSessionResponseAllow : NSURLSessionResponseCancel;
    
    KTVHCLogDownload(@"response disposition, %d", (int)responseDisposition);
    
    completionHandler(responseDisposition);
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    [self.lock lock];
    
    KTVHCLogDownload(@"will perform HTTP redirection\n%@\n%@\n%@\n%@", response.URL.absoluteString, [(NSHTTPURLResponse *)response allHeaderFields], request.URL.absoluteString, request.allHTTPHeaderFields);

    completionHandler(request);
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.lock lock];
    
    KTVHCLogDownload(@"receive data begin, %lld, %@", (long long)data.length, dataTask.originalRequest.URL.absoluteString);
    
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    [delegate download:self didReceiveData:data];
    
    KTVHCLogDownload(@"receive data end, %lld, %@", (long long)data.length, dataTask.originalRequest.URL.absoluteString);
    
    [self.lock unlock];
}


#pragma mark - Notification

static UIBackgroundTaskIdentifier backgroundTaskIdentifier = -1;

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self cleanBackgroundTask];
    
    [self.lock lock];
    if (self.delegateDictionary.count > 0)
    {
        backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self cleanBackgroundTask];
        }];
        
        UIBackgroundTaskIdentifier blockIdentifier = backgroundTaskIdentifier;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (blockIdentifier == backgroundTaskIdentifier)
            {
                [self cleanBackgroundTask];
            }
        });
    }
    [self.lock unlock];
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
    
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void)cleanBackgroundTaskAsync
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.lock lock];
        if (self.delegateDictionary.count <= 0)
        {
            [self cleanBackgroundTask];
        }
        [self.lock unlock];
    });
}


@end
