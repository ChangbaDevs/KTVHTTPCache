//
//  KTVHCURLTool.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCURLTool : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)tool;

@property (nonatomic, copy) NSURL * (^URLConverter)(NSURL *URL);

- (NSString *)keyWithURL:(NSURL *)URL;
- (NSString *)URLEncode:(NSString *)URLString;
- (NSString *)URLDecode:(NSString *)URLString;

@end
