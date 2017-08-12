//
//  KTVHCDataManager.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataManager.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataPrivate.h"

@interface KTVHCDataManager ()

@property (nonatomic, strong) NSMutableArray <KTVHCDataUnit *> * workingUnits;

@end

@implementation KTVHCDataManager

+ (instancetype)manager
{
    static KTVHCDataManager * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.workingUnits = [NSMutableArray array];
    }
    return self;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request error:(NSError **)error;
{
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool unitPool] unitWithURLString:request.URLString];
    /*
    if ([self.workingUnits containsObject:unit])
    {
        * error = [NSError errorWithDomain:@"At the same time there is only one reader at work." code:-1 userInfo:nil];
        return nil;
    }
     */
    [[KTVHCDataUnitPool unitPool] unit:request.URLString updateRequestHeaderFields:request.headerFields];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit request:request];
    return reader;
}

@end
