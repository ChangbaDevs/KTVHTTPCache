//
//  KTVHCDataDownload.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataDownload.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"


@interface KTVHCDataDownload () <NSURLSessionDataDelegate>


@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSURLSessionConfiguration * sessionConfiguration;
@property (nonatomic, strong) NSOperationQueue * sessionDelegateQueue;

@property (nonatomic, strong) NSMutableDictionary <NSURLSessionTask *, id<KTVHCDataDownloadDelegate>> * delegateDictionary;
@property (nonatomic, strong) NSLock * lock;


@end


@implementation KTVHCDataDownload


+ (instancetype)download
{
    static KTVHCDataDownload * obj = nil;
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
        self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration
                                                     delegate:self
                                                delegateQueue:self.sessionDelegateQueue];
    }
    return self;
}


- (NSURLSessionDataTask *)downloadWithRequest:(NSURLRequest *)request delegate:(id<KTVHCDataDownloadDelegate>)delegate
{
    [self.lock lock];
    KTVHCLogDataDownload(@"add download\n%@\n%@", request.URL.absoluteString, request.allHTTPHeaderFields);
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
    KTVHCLogDataDownload(@"complete : %@, %ld", task.originalRequest.URL.absoluteString, error.code);
    id <KTVHCDataDownloadDelegate> delegate = [self.delegateDictionary objectForKey:task];
    [delegate download:self didCompleteWithError:error];
    [self.delegateDictionary removeObjectForKey:task];
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.lock lock];
    KTVHCLogDataDownload(@"receive response\n%@\n%@", response.URL.absoluteString, [(NSHTTPURLResponse *)response allHeaderFields]);
    id <KTVHCDataDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    BOOL result = [delegate download:self didReceiveResponse:(NSHTTPURLResponse *)response];
    completionHandler(result ? NSURLSessionResponseAllow : NSURLSessionResponseCancel);
    [self.lock unlock];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.lock lock];
    KTVHCLogDataDownload(@"receive data : %@, %lu", dataTask.originalRequest.URL.absoluteString, data.length);
    id <KTVHCDataDownloadDelegate> delegate = [self.delegateDictionary objectForKey:dataTask];
    [delegate download:self didReceiveData:data];
    [self.lock unlock];
}


@end
