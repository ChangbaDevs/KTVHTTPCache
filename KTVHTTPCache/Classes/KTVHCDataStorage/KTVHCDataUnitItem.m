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
@property (nonatomic, copy) NSString * path;
@property (nonatomic, copy) NSString * filePath;

@end

@implementation KTVHCDataUnitItem

+ (instancetype)unitItemWithOffset:(NSInteger)offset path:(NSString *)path
{
    return [[self alloc] initWithOffset:offset path:(NSString *)path];
}

- (instancetype)initWithOffset:(NSInteger)offset path:(NSString *)path
{
    if (self = [super init])
    {
        self.offset = offset;
        self.path = path;
        [self prepare];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.path = [aDecoder decodeObjectForKey:@"path"];
        self.offset = [[aDecoder decodeObjectForKey:@"offset"] integerValue];
        [self prepare];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:@(self.offset) forKey:@"offset"];
}

- (void)prepare
{
    self.filePath = [KTVHCPathTools pathForInsertBasePath:self.path];
    self.size = [KTVHCPathTools sizeOfItemAtFilePath:self.filePath];
}

@end
