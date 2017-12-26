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


@property (nonatomic, strong) NSRecursiveLock * coreLock;

@property (nonatomic, assign) NSTimeInterval createTimeInterval;

@property (nonatomic, assign) long long offset;
@property (nonatomic, copy) NSString * relativePath;
@property (nonatomic, copy) NSString * absolutePath;


@end


@implementation KTVHCDataUnitItem


+ (instancetype)unitItemWithOffset:(long long)offset relativePath:(NSString *)relativePath
{
    return [[self alloc] initWithOffset:offset relativePath:relativePath];
}

- (instancetype)initWithOffset:(long long)offset relativePath:(NSString *)relativePath
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.createTimeInterval = [NSDate date].timeIntervalSince1970;
        self.offset = offset;
        self.relativePath = relativePath;
        [self prepare];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.createTimeInterval = [[aDecoder decodeObjectForKey:@"createTimeInterval"] doubleValue];
        self.relativePath = [aDecoder decodeObjectForKey:@"relativePath"];
        self.offset = [[aDecoder decodeObjectForKey:@"offset"] longLongValue];
        [self prepare];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.createTimeInterval) forKey:@"createTimeInterval"];
    [aCoder encodeObject:self.relativePath forKey:@"relativePath"];
    [aCoder encodeObject:@(self.offset) forKey:@"offset"];
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)prepare
{
    self.coreLock = [[NSRecursiveLock alloc] init];
    self.absolutePath = [KTVHCPathTools absolutePathWithRelativePath:self.relativePath];
    self.length = [KTVHCPathTools sizeOfItemAtFilePath:self.absolutePath];
}


#pragma mark - Setter

- (void)setLength:(long long)length
{
    [self lock];
    _length = length;
    
    KTVHCLogDataUnitItem(@"set length, %lld", length);
    
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
