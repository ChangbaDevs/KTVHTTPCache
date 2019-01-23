//
//  KTVHCDataSource.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCRange.h"

@protocol KTVHCDataSource <NSObject>

@property (nonatomic, copy, readonly) NSError *error;

@property (nonatomic, readonly) BOOL prepared;
@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, readonly) BOOL closed;

@property (nonatomic, readonly) KTVHCRange range;
@property (nonatomic, readonly) long long readedLength;

- (void)prepare;
- (void)close;

- (NSData *)readDataOfLength:(NSUInteger)length;

@end
