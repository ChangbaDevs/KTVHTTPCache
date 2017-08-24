//
//  KTVHCHTTPRequest.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataRequest;


@interface KTVHCHTTPRequest : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)requestWithOriginalURLString:(NSString *)originalURLString;

@property (nonatomic, copy, readonly) NSString * originalURLString;

@property (nonatomic, assign) BOOL isHeaderComplete;
@property (nonatomic, copy) NSDictionary * allHTTPHeaderFields;

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, copy) NSString * method;
@property (nonatomic, assign) NSInteger statusCode;

@property (nonatomic, copy) NSString * version;


- (KTVHCDataRequest *)dataRequest;


@end
