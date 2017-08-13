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
#import "KTVHCHTTPURL.h"
#import "KTVHCDataRequest.h"

@interface KTVHCHTTPConnection ()

@property (nonatomic, strong) KTVHCHTTPRequest * currentRequest;
@property (nonatomic, strong) KTVHCHTTPResponse * currentResponse;

@end

@implementation KTVHCHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithURIString:path];
    
    self.currentRequest = [KTVHCHTTPRequest requestWithOriginalURLString:url.originalURLString];

    self.currentRequest.isHeaderComplete = request.isHeaderComplete;
    self.currentRequest.headerFields = request.allHeaderFields;
    self.currentRequest.URL = request.url;
    self.currentRequest.method = request.method;
    self.currentRequest.statusCode = request.statusCode;
    self.currentRequest.version = request.version;
    
    KTVHCDataRequest * dataRequest = [self.currentRequest dataRequest];
    self.currentResponse = [KTVHCHTTPResponse responseWithConnection:self dataRequest:dataRequest];
    
    return self.currentResponse;
}

@end
