//
//  KTVHCDataDownload.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDownload.h"
#import "KTVHCLog.h"


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
        self.lock = [[NSLock alloc] init];
        self.delegateDictionary = [NSMutableDictionary dictionary];
        self.timeoutInterval = 30.0f;
        self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.sessionDelegateQueue];
    }
    return self;
}


- (NSURLSessionDataTask *)downloadWithRequest:(NSMutableURLRequest *)request delegate:(id <KTVHCDownloadDelegate>)delegate
{
    [self.lock lock];
    
    KTVHCLogDownload(@"add download\n%@\n%@", request.URL.absoluteString, request.allHTTPHeaderFields);
    
    if (![request isKindOfClass:[NSMutableURLRequest class]]) {
        request = [request mutableCopy];
    }
    
    request.timeoutInterval = self.timeoutInterval;
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    
    NSURLSessionDataTask * task = [self.session dataTaskWithRequest:request];
    [self.delegateDictionary setObject:delegate forKey:task];
    [task resume];
    
    [self.lock unlock];
    return task;
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self.lock lock];
    
    KTVHCLogDownload(@"complete, %ld, %@", error.code, task.originalRequest.URL.absoluteString);
    
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:task];
    [delegate download:self didCompleteWithError:error];
    [self.delegateDictionary removeObjectForKey:task];
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.lock lock];
    
    KTVHCLogDownload(@"receive response\n%@\n%@", response.URL.absoluteString, [(NSHTTPURLResponse *)response allHeaderFields]);
    
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    BOOL result = [delegate download:self didReceiveResponse:(NSHTTPURLResponse *)response];
    completionHandler(result ? NSURLSessionResponseAllow : NSURLSessionResponseCancel);
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.lock lock];
    
    KTVHCLogDownload(@"receive data, %lu, %@", data.length, dataTask.originalRequest.URL.absoluteString);
    
    id <KTVHCDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    [delegate download:self didReceiveData:data];
    [self.lock unlock];
}


@end
