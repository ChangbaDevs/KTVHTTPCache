//
//  MediaViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/14.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "MediaViewModel.h"
#import "MediaViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MediaViewController ()

@property (nonatomic,strong) MediaViewModel * viewModel;
@property (nonatomic, strong) NSString *URLString;

@end

@implementation MediaViewController

- (instancetype)initWithURLString:(NSString *)URLString
{
    if (self = [super init]) {
        self.URLString = URLString;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.player = [AVPlayer playerWithURL:[NSURL URLWithString:self.URLString]];
    [self.player play];
    _viewModel = [MediaViewModel new];
    self.delegate = _viewModel;
    
    
//    var timeObserver = avPlayerVC.player?.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: CMTimeScale(NSEC_PER_SEC)), queue: nil, using: {(cmtime) in
//                    let progress = cmtime.seconds / CMTimeGetSeconds(self.avPlayerVC.player!.currentItem!.duration)
//                    if (progress == 1.0) {
//                        //播放百分比为1表示已经播放完毕
//                        print("播放完成")
//                        //处理播放完成之后的操作
//                        clickblock()
//                    }
//                })
    
}

- (void)dealloc
{
    [self.player.currentItem.asset cancelLoading];
    [self.player.currentItem cancelPendingSeeks];
    [self.player cancelPendingPrerolls];
}



@end


