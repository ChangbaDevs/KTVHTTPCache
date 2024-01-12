//
//  SGMediaViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGMediaViewController.h"
#import "SGPlayerViewController.h"
#import "SGMediaItemCell.h"
#import "SGMediaItem.h"

#import <KTVHTTPCache/KTVHTTPCache.h>

@interface SGMediaViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<SGMediaItem *> *items;

@end

@implementation SGMediaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupHTTPCache];
    });
    [self setupItems];
}

- (void)setupHTTPCache
{
    [KTVHTTPCache logSetConsoleLogEnable:YES];
    NSError *error = nil;
    [KTVHTTPCache proxyStart:&error];
    if (error) {
        NSLog(@"Proxy Start Failure, %@", error);
    } else {
        NSLog(@"Proxy Start Success");
    }
    [KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
        NSLog(@"URL Filter reviced URL : %@", URL);
        return URL;
    }];
    [KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
        NSLog(@"Unsupport Content-Type Filter reviced URL : %@, %@", URL, contentType);
        return NO;
    }];
}

- (void)setupItems
{
    self.items = @[
        [[SGMediaItem alloc] initWithURL:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4"]
                                   title:@"萧亚轩 - 冲动"],
        [[SGMediaItem alloc] initWithURL:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/3B1DDE764577E0529C33DC5901307461.mp4"]
                                   title:@"张惠妹 - 你是爱我的"],
    ];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SGMediaItem *item = [self.items objectAtIndex:indexPath.row];
    SGMediaItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SGMediaItemCell"];
    [cell configureWithTitle:item.title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SGMediaItem *item = [self.items objectAtIndex:indexPath.row];
    NSURL *URL = [KTVHTTPCache proxyURLWithOriginalURL:item.URL];
    SGPlayerViewController *vc = [[SGPlayerViewController alloc] initWithURL:URL];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
