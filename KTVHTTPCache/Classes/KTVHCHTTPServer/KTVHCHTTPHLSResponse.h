//
//  KTVHCHTTPHLSResponse.h
//  KTVHTTPCache
//
//  Created by Gary Zhao on 2024/1/7.
//  Copyright © 2024 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCHTTPHeader.h"

@class KTVHCHTTPConnection;
@class KTVHCDataRequest;

@interface KTVHCHTTPHLSResponse : NSObject <HTTPResponse>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest NS_DESIGNATED_INITIALIZER;

@end
