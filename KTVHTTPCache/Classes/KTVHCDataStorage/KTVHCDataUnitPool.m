//
//  KTVHCDataUnitPool.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitPool.h"
#import "KTVHCDataUnitQueue.h"

@interface KTVHCDataUnitPool ()

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) KTVHCDataUnitQueue * unitQueue;

@end

@implementation KTVHCDataUnitPool

+ (instancetype)unitPool
{
    static KTVHCDataUnitPool * obj = nil;
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
        self.lock = [[NSLock alloc] init];
        self.unitQueue = [KTVHCDataUnitQueue unitQueueWithArchiverPath:@""];
    }
    return self;
}

- (KTVHCDataUnit *)unitWithURLString:(NSString *)URLString
{
    [self.lock lock];
    
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    if (!unit)
    {
        unit = [KTVHCDataUnit unitWithURLString:URLString];
        [self.unitQueue putUnit:unit];
    }
    
    [self.lock unlock];
    return unit;
}

@end
