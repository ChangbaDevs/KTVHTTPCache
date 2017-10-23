//
//  KTVHCHTTPURL.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, KTVHCHTTPURLType)
{
    KTVHCHTTPURLTypePing,
    KTVHCHTTPURLTypeContent,
};


@interface KTVHCHTTPURL : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (KTVHCHTTPURL *)URLForPing;
+ (KTVHCHTTPURL *)URLWithServerURIString:(NSString *)serverURIString;
+ (KTVHCHTTPURL *)URLWithOriginalURLString:(NSString *)originalURLString;

@property (nonatomic, assign, readonly) KTVHCHTTPURLType type;
@property (nonatomic, copy, readonly) NSString * originalURLString;

- (NSURL *)proxyURLWithServerPort:(NSInteger)serverPort;
- (NSString *)proxyURLStringWithServerPort:(NSInteger)serverPort;


@end
