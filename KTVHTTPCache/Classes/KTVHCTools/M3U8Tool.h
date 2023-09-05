//
//  M3U8Tool.h
//  KTVHTTPCacheDemo
//
//  Created by Ray on 2023/9/4.
//  Copyright © 2023 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface M3U8Tool : NSObject
+(NSString *)saveM3u8WithUrl: (NSString *)url;
+(void)proxyURLWithOriginalURL: (NSString *)urlStr complete: (void(^)(NSURL * url))complete;

+ (NSError *)deleteAll;
@end

NS_ASSUME_NONNULL_END
