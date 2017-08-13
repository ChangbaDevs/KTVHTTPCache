//
//  ViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "ViewController.h"
#import <KTVHTTPCache/KTVHTTPCache.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSError * error;
    [KTVHTTPCache proxyStart:&error];
    if (error) {
        NSLog(@"Proxy Start Failure, %@", error);
    } else {
        NSLog(@"Proxy Start Success");
    }
}

/**
 *  Test Media URL
 **/
static NSString * URLString = ;

- (IBAction)play:(UIButton *)sender
{
    NSString * proxyURLString = [KTVHTTPCache proxyURLStringWithOriginalURLString:URLString];
    
    AVPlayerViewController * viewController = [[AVPlayerViewController alloc] init];
    viewController.player = [AVPlayer playerWithURL:[NSURL URLWithString:proxyURLString]];
    [viewController.player play];
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)cleanCurrentURLCache:(UIButton *)sender
{
    [KTVHTTPCache cacheCleanCacheItemWithURLString:URLString];
}

- (IBAction)cleanAllCache:(UIButton *)sender
{
    [KTVHTTPCache cacheCleanAllCacheItem];
}


@end
