//
//  KTVHCDataUnitQueue.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitQueue.h"

@interface KTVHCDataUnitQueue ()

@property (nonatomic, copy) NSString * archiverPath;
@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) NSMutableDictionary <NSString *, KTVHCDataUnit *> * unitDictionary;

@end

@implementation KTVHCDataUnitQueue

+ (instancetype)unitQueueWithArchiverPath:(NSString *)archiverPath
{
    return [[self alloc] initWithArchiverPath:archiverPath];
}

- (instancetype)initWithArchiverPath:(NSString *)archiverPath
{
    if (self = [super init])
    {
        self.archiverPath = archiverPath;
        self.lock = [[NSLock alloc] init];
        self.unitDictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archiverPath];
        if (!self.unitDictionary) {
            self.unitDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (KTVHCDataUnit *)unitWithUniqueIdentifier:(NSString *)uniqueIdentifier;
{
    if (uniqueIdentifier.length <= 0) {
        return nil;
    }
    
    KTVHCDataUnit * unit = nil;
    [self.lock lock];
    unit = [self.unitDictionary objectForKey:unit.uniqueIdentifier];
    [self.lock unlock];
    
    return unit;
}

- (void)putUnit:(KTVHCDataUnit *)unit
{
    if (!unit) {
        return;
    }
    
    [self.lock lock];
    if (![self.unitDictionary objectForKey:unit.uniqueIdentifier])
    {
        [self.unitDictionary setObject:unit forKey:unit.uniqueIdentifier];
    }
    [self.lock unlock];
}

- (void)popUnit:(KTVHCDataUnit *)unit
{
    if (!unit) {
        return;
    }
    
    [self.lock lock];
    if ([self.unitDictionary objectForKey:unit.uniqueIdentifier])
    {
        [self.unitDictionary removeObjectForKey:unit.uniqueIdentifier];
    }
    [self.lock unlock];
}

- (void)archive
{
    [self.lock lock];
    [NSKeyedArchiver archiveRootObject:self.unitDictionary toFile:self.archiverPath];
    [self.lock unlock];
}

@end
