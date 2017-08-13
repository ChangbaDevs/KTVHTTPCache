//
//  KTVHCDataRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataRequest.h"
#import "KTVHCDataPrivate.h"

@interface KTVHCDataRequest ()

@property (nonatomic, copy) NSString * URLString;

@property (nonatomic, assign) long long rangeMin;
@property (nonatomic, assign) long long rangeMax;

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
        self.rangeMin = KTVHCDataRequestRangeMinVaule;
        self.rangeMax = KTVHCDataRequestRangeMaxVaule;
    }
    return self;
}

- (void)setHeaderFields:(NSDictionary *)headerFields
{
    if (_headerFields != headerFields)
    {
        _headerFields = headerFields;
        
        NSString * rangeString = [headerFields objectForKey:@"Range"];
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
}

@end
