//
//  KTVHCHTTPHLSResponse.m
//  KTVHTTPCache
//
//  Created by Gary Zhao on 2024/1/7.
//  Copyright © 2024 Single. All rights reserved.
//

#import "KTVHCHTTPHLSResponse.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataStorage.h"
#import "KTVHCDownload.h"
#import "KTVHCPathTool.h"
#import "KTVHCLog.h"


@interface KTVHCHTTPHLSResponse ()

@property (nonatomic, weak) KTVHCHTTPConnection *connection;

@property (nonatomic) UInt64 readedLength;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) KTVHCDataUnit *unit;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation KTVHCHTTPHLSResponse

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        KTVHCLogHTTPHLSResponse(@"%p, Create response\nrequest : %@", self, dataRequest);
        self.connection = connection;
        self.unit = [[KTVHCDataUnitPool pool] unitWithURL:dataRequest.URL];
        if (self.unit.totalLength == 0) {
            static NSURLSession *session = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                configuration.timeoutIntervalForRequest = 3;
                session = [NSURLSession sessionWithConfiguration:configuration];
            });
            __weak typeof(self) weakSelf = self;
            NSURLRequest *request = [[KTVHCDownload download] requestWithDataRequest:dataRequest];
            self.task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf handleResponeWithData:data response:response error:error];
            }];
            [self.task resume];
        } else {
            self.data = [NSData dataWithContentsOfURL:self.unit.completeURL];
        }
    }
    return self;
}

- (void)dealloc
{
    [self.unit workingRelease];
    [self.task cancel];
    KTVHCLogDealloc(self);
}

#pragma mark - HTTPResponse

- (void)handleResponeWithData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error
{
    if (error || data.length == 0 || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
        [self.connection responseDidAbort:self];
        KTVHCLogHTTPHLSResponse(@"%p, Handle response error: %@\nresponse : %@", self, error, response);
    } else {
        NSString *path = [KTVHCPathTool filePathWithURL:self.unit.URL offset:0];
        data = [self handleResponeWithData:data];
        if ([data writeToFile:path atomically:YES]) {
            self.data = data;
            KTVHCDataUnitItem *unitItem = [[KTVHCDataUnitItem alloc] initWithPath:path offset:0];
            [unitItem updateLength:data.length];
            [self.unit insertUnitItem:unitItem];
            [self.unit updateResponseHeaders:((NSHTTPURLResponse *)response).allHeaderFields totalLength:data.length];
            [self.connection responseHasAvailableData:self];
        } else {
            [self.connection responseDidAbort:self];
        }
    }
}

- (NSData *)handleResponeWithData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    KTVHCLogHTTPHLSResponse(@"%p, Handle response data : %@", self, string);
    if ([string containsString:@"\nhttp"]) {
        NSMutableArray *array = [string componentsSeparatedByString:@"\n"].mutableCopy;
        for (NSUInteger index = 0; index < array.count; index++) {
            NSString *line = array[index];
            if ([line hasPrefix:@"http"]) {
                line = [@"./" stringByAppendingString:line];
                [array replaceObjectAtIndex:index withObject:line];
            }
        }
        string = [array componentsJoinedByString:@"\n"];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        KTVHCLogHTTPHLSResponse(@"%p, Handle response data changed : %@", self, string);
    }
    return data;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    KTVHCLogHTTPHLSResponse(@"%p, Read data : %lld", self, (long long)self.data.length);
    self.readedLength = self.data.length;
    return self.data;
}

- (BOOL)delayResponseHeaders
{
    KTVHCLogHTTPHLSResponse(@"%p, Delay response : %d", self, self.self.data.length == 0);
    return self.data.length == 0;
}

- (UInt64)contentLength
{
    KTVHCLogHTTPHLSResponse(@"%p, Conetnt length : %lld", self, self.unit.totalLength);
    return self.data.length;
}

- (NSDictionary *)httpHeaders
{
    KTVHCLogHTTPHLSResponse(@"%p, Header\n%@", self, self.unit.responseHeaders);
    return self.unit.responseHeaders;
}

- (UInt64)offset
{
    KTVHCLogHTTPHLSResponse(@"%p, Offset : %lld", self, self.readedLength);
    return self.readedLength;
}

- (void)setOffset:(UInt64)offset
{
    KTVHCLogHTTPHLSResponse(@"%p, Set offset : %lld, %ld", self, offset, self.data.length);
}

- (BOOL)isDone
{
    KTVHCLogHTTPHLSResponse(@"%p, Check done : %lld", self, self.unit.totalLength);
    return self.readedLength > 0;
}

- (void)connectionDidClose
{
    KTVHCLogHTTPHLSResponse(@"%p, Connection did closed : %lld, %lld", self, self.unit.totalLength, self.unit.cacheLength);
    [self.task cancel];
}

@end
