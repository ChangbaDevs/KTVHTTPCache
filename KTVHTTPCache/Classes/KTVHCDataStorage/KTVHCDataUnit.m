//
//  KTVHCDataUnit.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnit.h"
#import "KTVHCURLTools.h"
#import "KTVHCDataCallback.h"

@interface KTVHCDataUnit ()

@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, copy) NSString * uniqueIdentifier;

@property (nonatomic, strong) NSDictionary * requestHeaderFields;
@property (nonatomic, strong) NSDictionary * responseHeaderFields;

@property (nonatomic, assign) NSInteger totalContentLength;
@property (nonatomic, assign) NSInteger totalCacheLength;

@property (nonatomic, strong) NSMutableArray <KTVHCDataUnitItem *> * unitItems;

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
        self.totalContentLength = [[aDecoder decodeObjectForKey:@"totalContentLength"] integerValue];
        self.totalCacheLength = [[aDecoder decodeObjectForKey:@"totalCacheLength"] integerValue];
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
    [aCoder encodeObject:@(self.totalCacheLength) forKey:@"totalCacheLength"];
    [aCoder encodeObject:self.unitItems forKey:@"unitItems"];
}

- (void)prepare
{
    if (!self.unitItems) {
        self.unitItems = [NSMutableArray array];
    }
    
    if (self.unitItems.count > 0)
    {
        NSMutableArray * removeArray = [NSMutableArray array];
        for (KTVHCDataUnitItem * obj in self.unitItems)
        {
            if (obj.size <= 0) {
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
    [self.unitItems sortUsingComparator:^NSComparisonResult(KTVHCDataUnitItem * obj1, KTVHCDataUnitItem * obj2) {
        if (obj1.offset < obj2.offset) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem
{
    [self.unitItems addObject:unitItem];
    [self sortUnitItems];
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
        self.totalContentLength = [contentRange substringFromIndex:range.location + range.length].integerValue;
    }
}

- (void)setTotalContentLength:(NSInteger)totalContentLength
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


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString
{
    return [KTVHCURLTools md5:URLString];
}

@end
