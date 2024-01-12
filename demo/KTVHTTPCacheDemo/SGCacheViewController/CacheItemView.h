//
//  SGCacheItemView.h
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SGCacheItemView;

@protocol  SGCacheItemViewDelegate <NSObject>

- (void)cacheItemView:(SGCacheItemView *)view deleteButtonDidClick:(NSString *)URLString;

@end

@interface SGCacheItemView : UIView

- (instancetype)initWithURLString:(NSString *)URLString totalLength:(long long)totalLength cacheLength:(long long)cacheLength;

@property (nonatomic, weak) id<SGCacheItemViewDelegate> delegate;

@end
