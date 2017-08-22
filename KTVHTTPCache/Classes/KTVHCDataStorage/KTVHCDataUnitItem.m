//
//  KTVHCDataUnitItem.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitItem.h"
#import "KTVHCPathTools.h"
#import "KTVHCLog.h"


@interface KTVHCDataUnitItem ()


@property (nonatomic, strong) NSLock * coreLock;

@property (nonatomic, assign) NSTimeInterval createTimeInterval;

@property (nonatomic, assign) long long offset;
@property (nonatomic, copy) NSString * path;
@property (nonatomic, copy) NSString * filePath;


@end


@implementation KTVHCDataUnitItem


+ (instancetype)unitItemWithOffset:(long long)offset path:(NSString *)path
{
    return [[self alloc] initWithOffset:offset path:(NSString *)path];
}

- (instancetype)initWithOffset:(long long)offset path:(NSString *)path
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.createTimeInterval = [NSDate date].timeIntervalSince1970;
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
        self.createTimeInterval = [[aDecoder decodeObjectForKey:@"createTimeInterval"] doubleValue];
        self.path = [aDecoder decodeObjectForKey:@"path"];
        self.offset = [[aDecoder decodeObjectForKey:@"offset"] longLongValue];
        [self prepare];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.createTimeInterval) forKey:@"createTimeInterval"];
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:@(self.offset) forKey:@"offset"];
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)prepare
{
    self.coreLock = [[NSLock alloc] init];
    self.filePath = [KTVHCPathTools absolutePathWithRelativePath:self.path];
    self.length = [KTVHCPathTools sizeOfItemAtFilePath:self.filePath];
}


#pragma mark - Setter

- (void)setLength:(long long)length
{
    [self lock];
    _length = length;
    
    KTVHCLogDataUnitItem(@"set length, %lld", length);
    
    [self unlock];
}

- (void)reloadFileLength
{
    [self lock];
    _length = [KTVHCPathTools sizeOfItemAtFilePath:self.filePath];
    [self unlock];
}


#pragma mark - NSLocking

- (void)lock
{
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}


@end
