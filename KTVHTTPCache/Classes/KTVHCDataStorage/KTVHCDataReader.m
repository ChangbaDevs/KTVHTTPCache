//
//  KTVHCDataReader.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"
#import "KTVHCDataUnit.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataSourcer.h"

@interface KTVHCDataReader ()

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataRequest * request;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@end

@implementation KTVHCDataReader

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit request:(KTVHCDataRequest *)request
{
    return [[self alloc] initWithUnit:unit request:request];
}

- (instancetype)initWithUnit:(KTVHCDataUnit *)unit request:(KTVHCDataRequest *)request
{
    if (self = [super init])
    {
        self.unit = unit;
        self.request = request;
        [self setupSourcer];
    }
    return self;
}

- (void)setupSourcer
{
    
}

@end
