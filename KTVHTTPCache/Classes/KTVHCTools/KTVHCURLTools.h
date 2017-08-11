//
//  KTVHCURLTools.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCURLTools : NSObject

+ (NSString *)URLEncode:(NSString *)URLString;
+ (NSString *)URLDecode:(NSString *)URLString;

@end
