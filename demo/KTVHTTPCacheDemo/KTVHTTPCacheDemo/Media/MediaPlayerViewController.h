//
//  MediaPlayerViewController.h
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/14.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <AVKit/AVKit.h>

@interface MediaPlayerViewController : AVPlayerViewController

- (instancetype)initWithURLString:(NSString *)URLString;

@end
