//
//  KTVHCDataResponse.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/24.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KTVHCDataResponse : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy, readonly) NSString * contentType;

@property (nonatomic, assign, readonly) long long currentContentLength;
@property (nonatomic, assign, readonly) long long totalContentLength;

@property (nonatomic, copy, readonly) NSDictionary * headerFields;
@property (nonatomic, copy, readonly) NSDictionary * headerFieldsWithoutRangeAndLength;


@end
