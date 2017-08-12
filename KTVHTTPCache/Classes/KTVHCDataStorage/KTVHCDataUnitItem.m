//
//  KTVHCDataUnitItem.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitItem.h"

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
    }
    return self;
}

@end
