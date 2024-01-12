//
//  SGMediaItem.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGMediaItem.h"

@implementation SGMediaItem

-(instancetype)initWithURL:(NSURL *)URL title:(NSString *)title
{
    if (self = [super init]) {
        self.URL = URL;
        self.title = title;
    }
    return self;
}

@end
