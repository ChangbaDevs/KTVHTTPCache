//
//  KTVHCContentType.h
//  KTVHTTPCache
//
//  Created by Single on 2018/5/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCCommon.h"

KTVHTTPCACHE_EXTERN NSString * const KTVHCContentTypeVideo;
KTVHTTPCACHE_EXTERN NSString * const KTVHCContentTypeAudio;
KTVHTTPCACHE_EXTERN NSString * const KTVHCContentTypeApplicationMPEG4;
KTVHTTPCACHE_EXTERN NSString * const KTVHCContentTypeApplicationOctetStream;

@interface KTVHCContentType : NSObject

#pragma mark - Class

/**
 *  default vaules:
 *  KTVHCContentTypeVideo
 *  KTVHCContentTypeAudio
 *  KTVHCContentTypeApplicationMPEG4
 *  KTVHCContentTypeApplicationOctetStream
 *  KTVHCContentTypeBinaryOctetStream
 */
+ (void)setDefaultAcceptContextTypes:(NSArray <NSString *> *)defaultAcceptContextTypes;
+ (NSArray <NSString *> *)defaultAcceptContextTypes;

@end
