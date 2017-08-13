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

@interface CacheViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray <KTVHCDataCacheItem *> * cacheItems;

@end

@implementation CacheViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cacheItems = [KTVHTTPCache cacheFetchAllCacheItem];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.cacheItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cacheItems objectAtIndex:section].zones.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KTVHCDataCacheItemZone * zone = [[self.cacheItems objectAtIndex:indexPath.section].zones objectAtIndex:indexPath.row];

    static NSString * identifier = @"CacheItemZoneCell";
    CacheItemZoneCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    [cell configureWithOffset:zone.offset length:zone.length];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    KTVHCDataCacheItem * item = [self.cacheItems objectAtIndex:section];
    CacheItemView * view = [[CacheItemView alloc] initWithURLString:item.URLString
                                                        totalLength:item.totalLength
                                                        cacheLength:item.cacheLength];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 120;
}

@end
