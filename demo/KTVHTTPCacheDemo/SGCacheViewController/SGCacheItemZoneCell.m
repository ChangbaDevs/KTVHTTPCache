//
//  SGCacheItemZoneCell.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "SGCacheItemZoneCell.h"

@interface SGCacheItemZoneCell ()

@property (nonatomic, weak) IBOutlet UILabel *offsetLabel;
@property (nonatomic, weak) IBOutlet UILabel *lengthLabel;

@end

@implementation SGCacheItemZoneCell

- (void)configureWithOffset:(long long)offset length:(long long)length
{
    self.offsetLabel.text = [NSString stringWithFormat:@"Offset : %lld", offset];
    self.lengthLabel.text = [NSString stringWithFormat:@"Length : %lld", length];
}

@end
