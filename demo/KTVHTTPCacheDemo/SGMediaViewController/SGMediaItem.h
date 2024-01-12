//
//  SGMediaItem.h
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGMediaItem : NSObject

+ (NSArray<SGMediaItem *> *)items;

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSString *title;

@end
