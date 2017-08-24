//
//  KTVHCDataRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataRequest.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCLog.h"


@interface KTVHCDataRequest ()


@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, copy) NSDictionary * allHTTPHeaderFields;

@property (nonatomic, assign) long long rangeMin;
@property (nonatomic, assign) long long rangeMax;


@end


@implementation KTVHCDataRequest


+ (instancetype)requestWithURLString:(NSString *)URLString allHTTPHeaderFields:(NSDictionary *)allHTTPHeaderFields
{
    return [[self alloc] initWithURLString:URLString allHTTPHeaderFields:allHTTPHeaderFields];
}

- (instancetype)initWithURLString:(NSString *)URLString allHTTPHeaderFields:(NSDictionary *)allHTTPHeaderFields
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.rangeMin = KTVHCDataRequestRangeMinVaule;
        self.rangeMax = KTVHCDataRequestRangeMaxVaule;
        self.URLString = URLString;
        self.allHTTPHeaderFields = allHTTPHeaderFields;
        [self setupRange];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)setupRange
{
    NSString * rangeString = [self.allHTTPHeaderFields objectForKey:@"Range"];
    if (rangeString.length > 0 && [rangeString hasPrefix:@"bytes="])
    {
        rangeString = [rangeString stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
        NSArray <NSString *> * rangeArray = [rangeString componentsSeparatedByString:@"-"];
        
        if (rangeArray.count == 2)
        {
            if (rangeArray.firstObject.length > 0) {
                self.rangeMin = rangeArray.firstObject.longLongValue;
            }
            if (rangeArray.lastObject.length > 0) {
                self.rangeMax = rangeArray.lastObject.longLongValue;
            }
        }
    }
}


@end
