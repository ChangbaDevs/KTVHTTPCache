//
//  KTVHCDataUnit.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnit.h"
#import "KTVHCURLTools.h"
#import "KTVHCPathTools.h"
#import "KTVHCDataCallback.h"

@interface KTVHCDataUnit ()

@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, copy) NSString * uniqueIdentifier;

@property (nonatomic, strong) NSDictionary * requestHeaderFields;
@property (nonatomic, strong) NSDictionary * responseHeaderFields;

@property (nonatomic, assign) long long totalContentLength;
@property (nonatomic, assign) long long totalCacheLength;

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSMutableArray <KTVHCDataUnitItem *> * unitItems;

@property (nonatomic, assign) NSInteger workingCount;

@end

@implementation KTVHCDataUnit

+ (instancetype)unitWithURLString:(NSString *)URLString
{
    return [[self alloc] initWithURLString:URLString];
}

- (instancetype)initWithURLString:(NSString *)URLString
{
    if (self = [super init])
    {
        self.URLString = URLString;
        self.uniqueIdentifier = [[self class] uniqueIdentifierWithURLString:self.URLString];
        [self prepare];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.URLString = [aDecoder decodeObjectForKey:@"URLString"];
        self.uniqueIdentifier = [aDecoder decodeObjectForKey:@"uniqueIdentifier"];
        self.requestHeaderFields = [aDecoder decodeObjectForKey:@"requestHeaderFields"];
        self.responseHeaderFields = [aDecoder decodeObjectForKey:@"responseHeaderFields"];
        self.totalContentLength = [[aDecoder decodeObjectForKey:@"totalContentLength"] longLongValue];
        self.unitItems = [aDecoder decodeObjectForKey:@"unitItems"];
        [self prepare];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.URLString forKey:@"URLString"];
    [aCoder encodeObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];
    [aCoder encodeObject:self.requestHeaderFields forKey:@"requestHeaderFields"];
    [aCoder encodeObject:self.responseHeaderFields forKey:@"responseHeaderFields"];
    [aCoder encodeObject:@(self.totalContentLength) forKey:@"totalContentLength"];
    [aCoder encodeObject:self.unitItems forKey:@"unitItems"];
}

- (void)prepare
{
    self.coreLock = [[NSLock alloc] init];
    if (!self.unitItems) {
        self.unitItems = [NSMutableArray array];
    }
    
    if (self.unitItems.count > 0)
    {
        NSMutableArray * removeArray = [NSMutableArray array];
        for (KTVHCDataUnitItem * obj in self.unitItems)
        {
            if (obj.length <= 0) {
                [removeArray addObject:obj];
            }
        }
        [self.unitItems removeObjectsInArray:removeArray];
        [removeArray removeAllObjects];
        [self sortUnitItems];
    }
}

- (void)sortUnitItems
{
    for (KTVHCDataUnitItem * obj in self.unitItems) {
        [obj lock];
    }
    [self.unitItems sortUsingComparator:^NSComparisonResult(KTVHCDataUnitItem * obj1, KTVHCDataUnitItem * obj2) {
        NSComparisonResult result = NSOrderedDescending;
        if (obj1.offset < obj2.offset) {
            result = NSOrderedAscending;
        } else if ((obj1.offset == obj2.offset) && (obj1.length > obj2.length)) {
            result = NSOrderedAscending;
        }
        return result;
    }];
    for (KTVHCDataUnitItem * obj in self.unitItems) {
        [obj unlock];
    }
}

- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem
{
    [self lock];
    [self.unitItems addObject:unitItem];
    [self sortUnitItems];
    [self unlock];
}

- (void)updateRequestHeaderFields:(NSDictionary *)requestHeaderFields
{
    self.requestHeaderFields = requestHeaderFields;
}

- (void)updateResponseHeaderFields:(NSDictionary *)responseHeaderFields
{
    self.responseHeaderFields = responseHeaderFields;
    
    NSString * contentRange = [self.responseHeaderFields objectForKey:@"Content-Range"];
    NSRange range = [contentRange rangeOfString:@"/"];
    if (contentRange.length > 0 && range.location != NSNotFound) {
        self.totalContentLength = [contentRange substringFromIndex:range.location + range.length].longLongValue;
    }
}


#pragma mark - Setter/Getter

- (void)setTotalContentLength:(long long)totalContentLength
{
    if (_totalContentLength != totalContentLength)
    {
        _totalContentLength = totalContentLength;
        if ([self.delegate respondsToSelector:@selector(unitDidUpdateTotalContentLength:)]) {
            [KTVHCDataCallback callbackWithBlock:^{
                [self.delegate unitDidUpdateTotalContentLength:self];
            }];
        }
    }
}

- (long long)totalCacheLength
{
    long long length = 0;
    [self lock];
    for (KTVHCDataUnitItem * obj in self.unitItems)
    {
        length += obj.length;
    }
    [self unlock];
    return length;
}

- (NSDictionary *)requestHeaderFieldsWithoutRange
{
    if ([self.requestHeaderFields objectForKey:@"Range"]) {
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:self.requestHeaderFields];
        [headers removeObjectForKey:@"Range"];
        return headers;
    }
    return self.requestHeaderFields;
}

- (NSDictionary *)responseHeaderFieldsWithoutRangeAndLength
{
    if ([self.responseHeaderFields objectForKey:@"Content-Range"]
        || [self.responseHeaderFields objectForKey:@"Content-Length"])
    {
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:self.responseHeaderFields];
        [headers removeObjectForKey:@"Content-Range"];
        [headers removeObjectForKey:@"Content-Length"];
        return headers;
    }
    return self.responseHeaderFields;
}


#pragma mark - Working State

- (BOOL)working
{
    [self lock];
    BOOL working = self.workingCount > 0;
    [self unlock];
    return working;
}

- (void)workingRetain
{
    [self lock];
    self.workingCount++;
    [self unlock];
}

- (void)workingRelease
{
    [self lock];
    self.workingCount--;
    [self unlock];
}


#pragma mark - File

- (NSString *)fileFolderPath
{
    return [KTVHCPathTools folderPathWithURLString:self.URLString];
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


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString
{
    return [KTVHCURLTools md5:URLString];
}

@end
