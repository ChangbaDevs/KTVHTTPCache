//
//  KTVHCDataUnitQueue.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitQueue.h"
#import "KTVHCLog.h"


@interface KTVHCDataUnitQueue ()


@property (nonatomic, copy) NSString * archiverPath;
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
        self.unitArray = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archiverPath];
        if (!self.unitArray) {
            self.unitArray = [NSMutableArray array];
        }
        KTVHCLogDataUnitQueue(@"init unit count, %ld", (long)self.unitArray.count);
    }
    return self;
}


- (NSArray <KTVHCDataUnit *> *)allUnits
{
    if (self.unitArray.count <= 0) {
        return nil;
    }
    
    NSArray <KTVHCDataUnit *> * units = [self.unitArray copy];
    return units;
}

- (KTVHCDataUnit *)unitWithUniqueIdentifier:(NSString *)uniqueIdentifier;
{
    if (uniqueIdentifier.length <= 0) {
        return nil;
    }
    
    KTVHCDataUnit * unit = nil;
    for (KTVHCDataUnit * obj in self.unitArray)
    {
        if ([obj.uniqueIdentifier isEqualToString:uniqueIdentifier]) {
            unit = obj;
            break;
        }
    }
    return unit;
}

- (void)putUnit:(KTVHCDataUnit *)unit
{
    if (!unit) {
        return;
    }
    
    if (![self.unitArray containsObject:unit]) {
        [self.unitArray addObject:unit];
    }
}

- (void)popUnit:(KTVHCDataUnit *)unit
{
    if (!unit) {
        return;
    }
    
    if ([self.unitArray containsObject:unit]) {
        [self.unitArray removeObject:unit];
    }
}

- (void)archive
{
    KTVHCLogDataUnitQueue(@"archive begin, %ld", (long)self.unitArray.count);
    
    [NSKeyedArchiver archiveRootObject:self.unitArray toFile:self.archiverPath];
    
    KTVHCLogDataUnitQueue(@"archive end, %ld", (long)self.unitArray.count);
}


@end
