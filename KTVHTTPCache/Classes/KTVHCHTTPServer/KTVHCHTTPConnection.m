//
//  KTVHCHTTPConnection.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPResponse.h"
#import "KTVHCDataStorage.h"
#import "KTVHCURLTool.h"
#import "KTVHCLog.h"

@class  HTTPFileResponse;
@implementation KTVHCHTTPConnection

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
        KTVHCLogAlloc(self);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    KTVHCLogHTTPConnection(@"%p, Receive request\nmethod : %@\npath : %@\nURL : %@", self, method, path, request.url);
    NSDictionary<NSString *,NSString *> *parameters = [[KTVHCURLTool tool] parseQuery:request.url.query];
    NSURL *URL = [NSURL URLWithString:[parameters objectForKey:@"url"]];
    NSString *fileUrlStr = [parameters objectForKey:@"fileUrl"];
    NSString *m3u8urlStr = [parameters objectForKey:@"m3u8url"];
    if (fileUrlStr != nil) {
        NSURL * fileUrl = [[NSURL alloc] initWithString:fileUrlStr];
        NSLog(@"fileUrlStr === %@ = %@",fileUrlStr,fileUrl);
        if (fileUrl.isFileURL) {
            HTTPFileResponse * response = [[HTTPFileResponse  alloc] init];
            response.fileUrl = fileUrl;
            return  response;
        }
    }
    
    if (m3u8urlStr != nil) {
        NSURL * m3u8url = [[NSURL alloc] initWithString:m3u8urlStr];
        NSLog(@"m3u8urlStr === %@ = %@",m3u8urlStr,m3u8url);
        KTVHCDataRequest *dataRequest = [[KTVHCDataRequest alloc] initWithURL:URL headers:request.allHeaderFields];
        KTVHCHTTPResponse *response = [[KTVHCHTTPResponse alloc] initWithConnection:self dataRequest:dataRequest];
        response.isM3u8 = YES;
        
        return response;
    }
    
    
    KTVHCDataRequest *dataRequest = [[KTVHCDataRequest alloc] initWithURL:URL headers:request.allHeaderFields];
    KTVHCHTTPResponse *response = [[KTVHCHTTPResponse alloc] initWithConnection:self dataRequest:dataRequest];
    return response;
}


@end

@interface HTTPFileResponse ()



@end


@implementation HTTPFileResponse



- (UInt64)contentLength {
    NSData * dataF = [[NSData alloc] initWithContentsOfURL:self.fileUrl];
    return  [dataF length];
}

- (BOOL)isDone {
    return  YES;
}

- (UInt64)offset {
    return 1024 * 1024 *1024;
}

- (NSData *)readDataOfLength:(NSUInteger)length {
    
    NSData * dataF = [[NSData alloc] initWithContentsOfURL:self.fileUrl];

    NSString * str = [[NSString alloc] initWithData: dataF encoding:NSUTF8StringEncoding];
    NSLog(@"str_+-===== %@",str);
    return dataF;
}

- (void)setOffset:(UInt64)offset {
    NSLog(@"str_+-===== %d",offset);
}

@end
