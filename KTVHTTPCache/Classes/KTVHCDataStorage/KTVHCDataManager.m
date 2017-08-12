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

@interface KTVHCDataManager () <KTVHCDataReaderWorkingDelegate>

@property (nonatomic, strong) NSCondition * condition;
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
        self.condition = [[NSCondition alloc] init];
        self.workingUnits = [NSMutableArray array];
    }
    return self;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request;
{
    if (!request || request.URLString.length <= 0) {
        return nil;
    }
    
    [self.condition lock];
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool unitPool] unitWithURLString:request.URLString];
    while ([self.workingUnits containsObject:unit]) {
        [self.condition wait];
    }
    [self.workingUnits addObject:unit];
    [[KTVHCDataUnitPool unitPool] unit:request.URLString updateRequestHeaderFields:request.headerFields];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit
                                                       request:request
                                               workingDelegate:self];
    [self.condition unlock];
    return reader;
}


#pragma mark - KTVHCDataReaderWorkingDelegate

- (void)readerDidStopWorking:(KTVHCDataReader *)reader
{
    [self.condition lock];
    if ([self.workingUnits containsObject:reader.unit]) {
        [self.workingUnits removeObject:reader.unit];
        [self.condition signal];
    }
    [self.condition unlock];
}

@end
