//
//  KTVHCHTTPConnection.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPRequest.h"
#import "KTVHCHTTPResponse.h"
#import "KTVHCHTTPResponsePing.h"
#import "KTVHCHTTPURL.h"
#import "KTVHCDataRequest.h"
#import "KTVHCLog.h"

static NSInteger const KTVHC_TIMEOUT_WRITE_ERROR = 30;
static NSInteger const KTVHC_HTTP_RESPONSE = 90;

@implementation KTVHCHTTPConnection


+ (NSString *)responsePingTokenString
{
    return KTVHCHTTPResponsePingTokenString;
}

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    if (self = [super initWithAsyncSocket:newSocket configuration:aConfig])
    {
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
    KTVHCLogHTTPConnection(@"receive request, %@, %@", method, path);
    
    KTVHCHTTPURL * URL = [KTVHCHTTPURL URLWithServerURIString:path];
    
    switch (URL.type)
    {
        case KTVHCHTTPURLTypePing:
        {
            KTVHCHTTPResponsePing * currentResponse = [KTVHCHTTPResponsePing responseWithConnection:self];
            
            return currentResponse;
        }
        case KTVHCHTTPURLTypeContent:
        {
            KTVHCHTTPRequest * currentRequest = [KTVHCHTTPRequest requestWithOriginalURLString:URL.originalURLString];
            
            currentRequest.isHeaderComplete = request.isHeaderComplete;
            currentRequest.allHTTPHeaderFields = request.allHeaderFields;
            currentRequest.URL = request.url;
            currentRequest.method = request.method;
            currentRequest.statusCode = request.statusCode;
            currentRequest.version = request.version;
            
            KTVHCDataRequest * dataRequest = [currentRequest dataRequest];
            KTVHCHTTPResponse * currentResponse = [KTVHCHTTPResponse responseWithConnection:self dataRequest:dataRequest];
            
            return currentResponse;
        }
    }
    return nil;
}

#pragma mark - handle error
- (void)handleErrorWithFailingResponse:(NSHTTPURLResponse *)response
{
    HTTPMessage *customResponse = [[HTTPMessage alloc] initResponseWithStatusCode:response.statusCode description:nil version:HTTPVersion1_1];
    [response.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [customResponse setHeaderField:key value:obj];
    }];
    [customResponse setHeaderField:@"Content-Length" value:@"0"];
    NSData *responseData = [self preprocessErrorResponse:customResponse];
    [asyncSocket writeData:responseData withTimeout:KTVHC_TIMEOUT_WRITE_ERROR tag:KTVHC_HTTP_RESPONSE];
    
}


@end
