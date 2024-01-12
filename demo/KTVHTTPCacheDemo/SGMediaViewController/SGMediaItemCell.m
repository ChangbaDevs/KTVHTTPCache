//
//  SGMediaItemCell.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGMediaItemCell.h"

@interface SGMediaItemCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation SGMediaItemCell

- (void)configureWithTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

@end
