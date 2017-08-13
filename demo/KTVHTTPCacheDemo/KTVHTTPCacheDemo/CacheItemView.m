//
//  CacheItemView.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "CacheItemView.h"

@interface CacheItemView ()

@property (nonatomic, strong) UILabel * totalLengthLabel;
@property (nonatomic, strong) UILabel * cacheLengthLabel;
@property (nonatomic, strong) UILabel * textLabel;

@end

@implementation CacheItemView

- (instancetype)initWithURLString:(NSString *)URLString
                      totalLength:(long long)totalLength
                      cacheLength:(long long)cacheLength
{
    if (self = [super initWithFrame:CGRectZero])
    {
        self.totalLengthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.totalLengthLabel.font = [UIFont systemFontOfSize:14];
        self.totalLengthLabel.text = [NSString stringWithFormat:@"Total Length : %lld", totalLength];
        
        self.cacheLengthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.cacheLengthLabel.font = [UIFont systemFontOfSize:14];
        self.cacheLengthLabel.text = [NSString stringWithFormat:@"Cache Length : %lld", cacheLength];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.font = [UIFont systemFontOfSize:14];
        self.textLabel.text = URLString;
        self.textLabel.numberOfLines = 0;
        
        [self addSubview:self.totalLengthLabel];
        [self addSubview:self.cacheLengthLabel];
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.totalLengthLabel.frame = CGRectMake(20,
                                             15,
                                             self.bounds.size.width - 40,
                                             18);
    self.cacheLengthLabel.frame = CGRectMake(20,
                                             33,
                                             self.bounds.size.width - 40,
                                             18);
    self.textLabel.frame = CGRectMake(20,
                                      CGRectGetMaxY(self.cacheLengthLabel.frame) + 5,
                                      self.bounds.size.width - 40,
                                      self.bounds.size.height - 60);
}

@end
