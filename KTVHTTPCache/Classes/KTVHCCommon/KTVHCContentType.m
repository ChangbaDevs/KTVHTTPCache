//
//  KTVHCContentType.m
//  KTVHTTPCache
//
//  Created by Single on 2018/5/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVHCContentType.h"

NSString * const KTVHCContentTypeVideo = @"video/";
NSString * const KTVHCContentTypeAudio = @"audio/";
NSString * const KTVHCContentTypeApplicationMPEG4 = @"application/mp4";
NSString * const KTVHCContentTypeApplicationOctetStream = @"application/octet-stream";
NSString * const KTVHCContentTypeBinaryOctetStream = @"binary/octet-stream";

@implementation KTVHCContentType

#pragma mark - Class

static NSArray <NSString *> * defaultAcceptContextTypes = nil;

+ (void)setDefaultAcceptContextTypes:(NSArray <NSString *> *)defaultAcceptContextTypes
{
    defaultAcceptContextTypes = defaultAcceptContextTypes;
}

+ (NSArray <NSString *> *)defaultAcceptContextTypes
{
    if (!defaultAcceptContextTypes)
    {
        defaultAcceptContextTypes = @[KTVHCContentTypeVideo,
                                      KTVHCContentTypeAudio,
                                      KTVHCContentTypeApplicationMPEG4,
                                      KTVHCContentTypeApplicationOctetStream,
                                      KTVHCContentTypeBinaryOctetStream];
    }
    return defaultAcceptContextTypes;
}

@end
