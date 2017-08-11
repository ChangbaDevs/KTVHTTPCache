//
//  KTVHCDataRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataRequest.h"

@interface KTVHCDataRequest ()

@property (nonatomic, copy) NSString * URLString;

@end

@implementation KTVHCDataRequest

+ (instancetype)requestWithURLString:(NSString *)URLString
{
    return [[self alloc] initWithURLString:URLString];
}

- (instancetype)initWithURLString:(NSString *)URLString
{
    if (self = [super init])
    {
        self.URLString = URLString;
        self.rangeMin = KTVHCDataRequestRangeVaule;
        self.rangeMax = KTVHCDataRequestRangeVaule;
    }
    return self;
}

@end
