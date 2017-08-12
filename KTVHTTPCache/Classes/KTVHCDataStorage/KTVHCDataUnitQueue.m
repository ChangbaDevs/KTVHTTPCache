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
@property (nonatomic, strong) NSMutableArray <KTVHCDataUnit *> * unitArray;

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
        self.unitArray = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archiverPath];
        if (!self.unitArray) {
            self.unitArray = [NSMutableArray array];
        }
    }
    return self;
}

- (KTVHCDataUnit *)unitWithUniqueIdentifier:(NSString *)uniqueIdentifier;
{
    if (uniqueIdentifier.length <= 0) {
        return nil;
    }
    
    [self.lock lock];
    KTVHCDataUnit * unit = nil;
    for (KTVHCDataUnit * obj in self.unitArray)
    {
        if ([obj.uniqueIdentifier isEqualToString:uniqueIdentifier]) {
            unit = obj;
            break;
        }
    }
    [self.lock unlock];
    return unit;
}

- (void)putUnit:(KTVHCDataUnit *)unit
{
    if (!unit) {
        return;
    }
    
    [self.lock lock];
    if (![self.unitArray containsObject:unit]) {
        [self.unitArray addObject:unit];
    }
    [self.lock unlock];
}

- (void)popUnit:(KTVHCDataUnit *)unit
{
    if (!unit) {
        return;
    }
    
    [self.lock lock];
    if ([self.unitArray containsObject:unit]) {
        [self.unitArray removeObject:unit];
    }
    [self.lock unlock];
}

- (void)archive
{
    [self.lock lock];
    [NSKeyedArchiver archiveRootObject:self.unitArray toFile:self.archiverPath];
    [self.lock unlock];
}

@end
