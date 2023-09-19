//
//  MediaViewModel.m
//  KTVHTTPCacheDemo
//
//  Created by Ray on 2023/9/19.
//  Copyright © 2023 Single. All rights reserved.
//

#import "MediaViewModel.h"

@implementation MediaViewModel
-(void)playerViewController:(AVPlayerViewController *)playerViewController willBeginFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
//    self.player = http://lzaiuw.changba.com/userdata/video/940071102.mp4
//    NSURL * oldUrl = [[NSURL alloc] initWithString:@"http://lzaiuw.changba.com/userdata/video/940071102.mp4"];
//    AVPlayerItem * oldItem = [[AVPlayerItem alloc] initWithURL: oldUrl];
//    [self.player replaceCurrentItemWithPlayerItem: oldItem];
    NSLog(@"=======start");
}
-(void)playerViewController:(AVPlayerViewController *)playerViewController willEndFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
//    NSURL * oldUrl = [[NSURL alloc] initWithString: self.URLString];
//    AVPlayerItem * oldItem = [[AVPlayerItem alloc] initWithURL: oldUrl];
//    [self.player replaceCurrentItemWithPlayerItem: oldItem];
    NSLog(@"=======end");
}

@end
