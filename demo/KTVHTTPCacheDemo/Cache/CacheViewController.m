//
//  CacheViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "CacheViewController.h"
#import <KTVHTTPCache/KTVHTTPCache.h>
#import "CacheItemZoneCell.h"
#import "CacheItemView.h"

@interface CacheViewController () <UITableViewDelegate, UITableViewDataSource, CacheItemViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<KTVHCDataCacheItem *> *items;

@end

@implementation CacheViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupItems];
}

- (void)setupItems
{
    self.items = [KTVHTTPCache cacheAllCacheItems];
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    KTVHCDataCacheItem *item = [self.items objectAtIndex:section];
    return item.zones.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KTVHCDataCacheItem *item = [self.items objectAtIndex:indexPath.section];
    KTVHCDataCacheItemZone *zone = [item.zones objectAtIndex:indexPath.row];
    CacheItemZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CacheItemZoneCell"];
    [cell configureWithOffset:zone.offset length:zone.length];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    KTVHCDataCacheItem *item = [self.items objectAtIndex:section];
    CacheItemView *view = [[CacheItemView alloc] initWithURLString:item.URL.absoluteString totalLength:item.totalLength cacheLength:item.cacheLength];
    view.delegate = self;
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 120;
}

#pragma mark - CacheItemViewDelegate

- (void)cacheItemView:(CacheItemView *)view deleteButtonDidClick:(NSString *)URLString
{
    [KTVHTTPCache cacheDeleteCacheWithURL:[NSURL URLWithString:URLString]];
    [self setupItems];
}

- (IBAction)deleteAllCache:(UIButton *)sender
{
    [KTVHTTPCache cacheDeleteAllCaches];
    [self setupItems];
}

@end
