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
#import "MediaItem.h"
#import "MediaCell.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (nonatomic, strong) NSArray <MediaItem *> * medaiItems;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self startHTTPServer];
    [self reloadData];
}

- (void)startHTTPServer
{
    NSError * error;
    [KTVHTTPCache proxyStart:&error];
    if (error) {
        NSLog(@"Proxy Start Failure, %@", error);
    } else {
        NSLog(@"Proxy Start Success");
    }
}

- (void)reloadData
{
    MediaItem * item1 = [[MediaItem alloc] initWithTitle:@"Lindsey Stirling - Boulevard of Broken Dreams"
                                               URLString:@"http://he.yinyuetai.com/uploads/videos/common/9A12015DCA9878CB8AE6EC60399EF29A.mp4"];
    MediaItem * item2 = [[MediaItem alloc] initWithTitle:@"Chris Brown - Sedated"
                                               URLString:@"http://hc.yinyuetai.com/uploads/videos/common/18AB015DCF2478E0102DC93B05179B49.mp4"];
    MediaItem * item3 = [[MediaItem alloc] initWithTitle:@"Eminem - Not Afraid"
                                               URLString:@"http://he.yinyuetai.com/uploads/videos/common/AC5B015C495FF0D0EE115D4E86452719.mp4"];
    MediaItem * item4 = [[MediaItem alloc] initWithTitle:@"Eminem & Dr. Dre - Video"
                                               URLString:@"http://hc.yinyuetai.com/uploads/videos/common/986E015D3B9151ED2BCE33A6B035D57A.mp4"];
    self.medaiItems = @[item1, item2, item3, item4];
    [self.tableView reloadData];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.medaiItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaCell * cell = [tableView dequeueReusableCellWithIdentifier:@"MediaCell"];
    [cell configureWithTitle:[self.medaiItems objectAtIndex:indexPath.row].title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * URLString = [self.medaiItems objectAtIndex:indexPath.row].URLString;
    
    if (URLString.length <= 0) {
        return;
    }
    
    NSString * proxyURLString = [KTVHTTPCache proxyURLStringWithOriginalURLString:URLString];
    
    AVPlayerViewController * viewController = [[AVPlayerViewController alloc] init];
    viewController.player = [AVPlayer playerWithURL:[NSURL URLWithString:proxyURLString]];
    [viewController.player play];
    
    [self presentViewController:viewController animated:YES completion:nil];
}


@end
