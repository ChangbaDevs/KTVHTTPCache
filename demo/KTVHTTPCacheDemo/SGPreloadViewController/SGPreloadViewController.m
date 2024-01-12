//
//  SGPreloadViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2024/1/12.
//  Copyright © 2024 Single. All rights reserved.
//

#import "SGPreloadViewController.h"
#import "SGPreloadItemCell.h"
#import "SGMediaItem.h"

#import <KTVHTTPCache/KTVHTTPCache.h>

@interface SGPreloadViewController () <UITableViewDelegate, UITableViewDataSource, KTVHCDataLoaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableVIew;
@property (nonatomic, strong) NSArray<KTVHCDataLoader *> *loaders;

@end

@implementation SGPreloadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *items = [SGMediaItem items];
    NSMutableArray *loaders = [NSMutableArray array];
    for (SGMediaItem *obj in items) {
        if ([obj.URL.absoluteString containsString:@".m3u"]) {
            NSLog(@"HLS files do not support preloading using KTVHCDataLoader");
            continue;
        }
        NSDictionary *headers = @{
            // Set preload length if needed.
            // @"Range" : @"bytes=0-1"
        };
        KTVHCDataRequest *request = [[KTVHCDataRequest alloc] initWithURL:obj.URL headers:headers];
        KTVHCDataLoader *loader = [KTVHTTPCache cacheLoaderWithRequest:request];
        loader.object = obj;
        loader.delegate = self;
        [loaders addObject:loader];
    }
    self.loaders = loaders;
    [self.loaders.firstObject prepare];
}

- (void)dealloc
{
    for (KTVHCDataLoader *obj in self.loaders) {
        [obj close];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.loaders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KTVHCDataLoader *loader = [self.loaders objectAtIndex:indexPath.row];
    SGMediaItem *item = (SGMediaItem *)loader.object;
    SGPreloadItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SGPreloadItemCell"];
    [cell configureWithTitle:item.title progress:loader.progress];
    return cell;
}

- (void)ktv_loaderDidFinish:(KTVHCDataLoader *)loader
{
    NSUInteger index = [self.loaders indexOfObject:loader] + 1;
    if (index < self.loaders.count) {
        [[self.loaders objectAtIndex:index] prepare];
    }
}

- (void)ktv_loader:(KTVHCDataLoader *)loader didFailWithError:(NSError *)error
{
    NSLog(@"Preload failed : %@, %@", loader, error);
    NSUInteger index = [self.loaders indexOfObject:loader] + 1;
    if (index < self.loaders.count) {
        [[self.loaders objectAtIndex:index] prepare];
    }
}

- (void)ktv_loader:(KTVHCDataLoader *)loader didChangeProgress:(double)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableVIew reloadData];
    });
}

@end
