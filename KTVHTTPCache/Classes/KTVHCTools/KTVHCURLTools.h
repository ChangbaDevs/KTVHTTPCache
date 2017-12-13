//
//  KTVHCURLTools.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *(^KTVHCURLFilterBlock)(NSString *);

@interface KTVHCURLTools : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)URLTools;

@property (nonatomic, copy) KTVHCURLFilterBlock archiveURLFilterBlock;


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString;

+ (NSString *)URLEncode:(NSString *)URLString;
+ (NSString *)URLDecode:(NSString *)URLString;


@end
