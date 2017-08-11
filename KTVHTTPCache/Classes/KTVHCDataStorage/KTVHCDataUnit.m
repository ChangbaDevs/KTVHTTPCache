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

@property (nonatomic, strong) NSArray <KTVHCDataUnitItem *> * fileUnitItems;

@end

@implementation KTVHCDataUnit

+ (instancetype)unitWithURLString:(NSString *)URLString
{
    return [[self alloc] initWithURLString:URLString];
}

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString
{
    return [KTVHCURLTools md5:URLString];
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

@end
