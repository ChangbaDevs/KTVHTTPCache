//
//  KTVHCDataNetworkSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataNetworkSource.h"

@interface KTVHCDataNetworkSource ()

@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, strong) NSDictionary * headrFields;

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger size;

@end

@implementation KTVHCDataNetworkSource

+ (instancetype)sourceWithURLString:(NSString *)URLString headerFields:(NSDictionary *)headerFields offset:(NSInteger)offset size:(NSInteger)size
{
    return [[self alloc] initWithURLString:URLString
                              headerFields:headerFields
                                    offset:offset
                                      size:size];
}

- (instancetype)initWithURLString:(NSString *)URLString
                     headerFields:(NSDictionary *)headerFields
                           offset:(NSInteger)offset
                             size:(NSInteger)size
{
    if (self = [super init])
    {
        self.URLString = URLString;
        self.headrFields = headerFields;
        
        self.offset = offset;
        self.size = size;
    }
    return self;
}

@end
