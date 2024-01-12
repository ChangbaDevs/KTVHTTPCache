//
//  SGCacheViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGCacheViewController.h"
#import "SGCacheItemZoneCell.h"
#import "SGCacheItemView.h"

#import <KTVHTTPCache/KTVHTTPCache.h>

@interface SGCacheViewController () <UITableViewDelegate, UITableViewDataSource, SGCacheItemViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<KTVHCDataCacheItem *> *items;

@end

@implementation SGCacheViewController

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
    return [self.items objectAtIndex:section].zones.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KTVHCDataCacheItem *item = [self.items objectAtIndex:indexPath.section];
    KTVHCDataCacheItemZone *zone = [item.zones objectAtIndex:indexPath.row];
    SGCacheItemZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SGCacheItemZoneCell"];
    [cell configureWithOffset:zone.offset length:zone.length];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    KTVHCDataCacheItem *item = [self.items objectAtIndex:section];
    SGCacheItemView *view = [[SGCacheItemView alloc] initWithURLString:item.URL.absoluteString totalLength:item.totalLength cacheLength:item.cacheLength];
    view.delegate = self;
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 120;
}

#pragma mark - SGCacheItemViewDelegate

- (void)cacheItemView:(SGCacheItemView *)view deleteButtonDidClick:(NSString *)URLString
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
