//
//  KTVHCHTTPURL.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCHTTPURL : NSObject

+ (KTVHCHTTPURL *)URLWithURIString:(NSString *)URIString;
+ (KTVHCHTTPURL *)URLWithOriginalURLString:(NSString *)originalURLString;

@property (nonatomic, copy, readonly) NSString * originalURLString;
@property (nonatomic, copy, readonly) NSString * proxyURLString;

@property (nonatomic, assign, readonly) NSInteger listeningPort;

@end
