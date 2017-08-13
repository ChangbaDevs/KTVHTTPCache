//
//  CacheItemView.h
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CacheItemView : UIView

- (instancetype)initWithURLString:(NSString *)URLString
                      totalLength:(long long)totalLength
                      cacheLength:(long long)cacheLength;

@end
