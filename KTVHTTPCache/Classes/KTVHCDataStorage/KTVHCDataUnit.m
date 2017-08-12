//
//  KTVHCDataUnit.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnit.h"
#import "KTVHCURLTools.h"

@interface KTVHCDataUnit ()

@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, copy) NSString * uniqueIdentifier;

@property (nonatomic, strong) NSDictionary * requestHeaderFields;
@property (nonatomic, strong) NSDictionary * responseHeaderFields;

@property (nonatomic, assign) NSInteger totalContentLength;
@property (nonatomic, assign) NSInteger totalCacheLength;

@property (nonatomic, strong) NSMutableArray <KTVHCDataUnitItem *> * fileUnitItems;

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
    }
    return self;
}

- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem
{
    [self.fileUnitItems addObject:unitItem];
    [self.fileUnitItems sortUsingComparator:^NSComparisonResult(KTVHCDataUnitItem * obj1, KTVHCDataUnitItem * obj2) {
        if (obj1.offset < obj2.offset) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
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
            [self.delegate unitDidUpdateTotalContentLength:self];
        }
    }
}


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString
{
    return [KTVHCURLTools md5:URLString];
}

@end
