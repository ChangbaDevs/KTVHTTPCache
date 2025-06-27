//
//  KTVHCHLSTool.h
//  KTVHTTPCache
//
//  Created by Single on 2025/6/27.
//  Copyright © 2025年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCHLSTool : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)tool;

@property (nonatomic, copy) NSString * (^contentHandler)(NSString *content);

- (NSString *)handleContent:(NSString *)content;

- (NSArray<NSURL *> *)makeURLsForContent:(NSString *)content sourceURL:(NSURL *)sourceURL;

- (NSURLSessionDataTask *)taskWithURL:(NSURL *)URL completionHandler:(void (^)(NSData *, NSError *))completionHandler;

@end
