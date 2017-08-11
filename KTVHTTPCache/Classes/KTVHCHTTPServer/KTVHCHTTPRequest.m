//
//  KTVHCHTTPRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPRequest.h"
#import "KTVHCDataRequest.h"

@interface KTVHCHTTPRequest ()

@property (nonatomic, copy) NSString * originalURLString;

@property (nonatomic, assign) NSInteger rangeMin;
@property (nonatomic, assign) NSInteger rangeMax;

@end

@implementation KTVHCHTTPRequest

+ (instancetype)requestWithOriginalURLString:(NSString *)originalURLString
{
    return [[self alloc] initWithOriginalURLString:originalURLString];
}

- (instancetype)initWithOriginalURLString:(NSString *)originalURLString
{
    if (self = [super init])
    {
        self.originalURLString = originalURLString;
        
        self.rangeMin = KTVHCDataRequestRangeMinVaule;
        self.rangeMax = KTVHCDataRequestRangeMaxVaule;
    }
    return self;
}

- (void)setAllHeaderFields:(NSDictionary *)allHeaderFields
{
    if (_allHeaderFields != allHeaderFields)
    {
        _allHeaderFields = allHeaderFields;
        
        NSString * rangeString = [allHeaderFields objectForKey:@"Range"];
        if (rangeString.length > 0 && [rangeString hasPrefix:@"bytes="])
        {
            rangeString = [rangeString stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
            NSArray <NSString *> * rangeArray = [rangeString componentsSeparatedByString:@"-"];
            
            if (rangeArray.count == 2)
            {
                if (rangeArray.firstObject.length > 0) {
                    self.rangeMin = rangeArray.firstObject.integerValue;
                }
                if (rangeArray.lastObject.length > 0) {
                    self.rangeMax = rangeArray.lastObject.integerValue;
                }
            }
        }
    }
}

- (KTVHCDataRequest *)dataRequest
{
    KTVHCDataRequest * dataRequest = [KTVHCDataRequest requestWithURLString:self.originalURLString];
    
    dataRequest.rangeMin = self.rangeMin;
    dataRequest.rangeMax = self.rangeMax;
    
    return dataRequest;
}

@end
