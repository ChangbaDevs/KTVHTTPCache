//
//  SGMediaItem.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGMediaItem.h"

@implementation SGMediaItem

+ (NSArray<SGMediaItem *> *)items
{
    return @[
        [[SGMediaItem alloc] initWithURL:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4"]
                                   title:@"萧亚轩 - 冲动"],
        [[SGMediaItem alloc] initWithURL:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/3B1DDE764577E0529C33DC5901307461.mp4"]
                                   title:@"张惠妹 - 你是爱我的 & AirPlay"],
    ];
}

-(instancetype)initWithURL:(NSURL *)URL title:(NSString *)title
{
    if (self = [super init]) {
        self.URL = URL;
        self.title = title;
    }
    return self;
}

@end
