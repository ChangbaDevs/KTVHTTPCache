//
//  KTVHCDataUnitItem.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitItem.h"
#import "KTVHCPathTools.h"

@interface KTVHCDataUnitItem ()

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, copy) NSString * filePath;

@end

@implementation KTVHCDataUnitItem

+ (instancetype)unitItemWithOffset:(NSInteger)offset filePath:(NSString *)filePath
{
    return [[self alloc] initWithOffset:offset filePath:filePath];
}

- (instancetype)initWithOffset:(NSInteger)offset filePath:(NSString *)filePath
{
    if (self = [super init])
    {
        self.offset = offset;
        self.filePath = filePath;
        [self prepare];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
        self.offset = [[aDecoder decodeObjectForKey:@"offset"] integerValue];
        [self prepare];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
    [aCoder encodeObject:@(self.offset) forKey:@"offset"];
}

- (void)prepare
{
    self.size = [KTVHCPathTools sizeOfItemAtFilePath:self.filePath];
}

@end
