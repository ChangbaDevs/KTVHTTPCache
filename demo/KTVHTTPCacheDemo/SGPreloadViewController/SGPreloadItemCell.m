//
//  SGPreloadItemCell.m
//  KTVHTTPCacheDemo
//
//  Created by WBY888666 on 2024/1/12.
//  Copyright © 2024 Single. All rights reserved.
//

#import "SGPreloadItemCell.h"

@interface SGPreloadItemCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *progressLable;

@end


@implementation SGPreloadItemCell

- (void)configureWithTitle:(NSString *)title progress:(double)progress
{
    self.titleLabel.text = title;
    self.progressLable.text = [NSString stringWithFormat:@"%ld%%", (NSInteger)(progress * 100)];
}

@end
