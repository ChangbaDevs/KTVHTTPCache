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

@end

@implementation KTVHCDataUnitItem

- (id)copyWithZone:(NSZone *)zone
{
    [self lock];
    KTVHCDataUnitItem * obj = [[KTVHCDataUnitItem alloc] initForCopy];
    obj->_relativePath = self.relativePath;
    obj->_absolutePath = self.absolutePath;
    obj->_createTimeInterval = self.createTimeInterval;
    obj->_offset = self.offset;
    obj->_length = self.length;
    [self unlock];
    return obj;
}

- (instancetype)initForCopy
{
    if (self = [super init]) {
        
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _createTimeInterval = [NSDate date].timeIntervalSince1970;
        if ([KTVHCPathTools isRelativePath:_relativePath]) {
            _relativePath = path;
        } else {
            _relativePath = [KTVHCPathTools convertAbsoultePathToRelativePath:path];
        }
        _offset = 0;
        [self prepare];
    }
    return self;
}

- (instancetype)initWithRequest:(KTVHCDataRequest *)request
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _createTimeInterval = [NSDate date].timeIntervalSince1970;
        _relativePath = [KTVHCPathTools relativePathForUnitItemFileWithURL:request.URL offset:request.range.start];
        _offset = request.range.start;
        [self prepare];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _createTimeInterval = [[aDecoder decodeObjectForKey:@"createTimeInterval"] doubleValue];
        _relativePath = [aDecoder decodeObjectForKey:@"relativePath"];
        _offset = [[aDecoder decodeObjectForKey:@"offset"] longLongValue];
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
    _absolutePath = [KTVHCPathTools absolutePathWithRelativePath:self.relativePath];
    self.length = [KTVHCPathTools sizeOfItemAtFilePath:self.absolutePath];
}

- (void)setLength:(long long)length
{
    [self lock];
    _length = length;
    KTVHCLogDataUnitItem(@"set length, %lld", length);
    [self unlock];
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
