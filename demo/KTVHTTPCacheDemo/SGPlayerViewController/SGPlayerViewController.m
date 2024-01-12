//
//  SGPlayerViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/14.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface SGPlayerViewController ()

@property (nonatomic, copy) NSURL *URL;

@end

@implementation SGPlayerViewController

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.URL = URL;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.player = [AVPlayer playerWithURL:self.URL];
        [self.player play];
    });
}

- (void)dealloc
{
    [self.player.currentItem.asset cancelLoading];
    [self.player.currentItem cancelPendingSeeks];
    [self.player cancelPendingPrerolls];
}

@end
