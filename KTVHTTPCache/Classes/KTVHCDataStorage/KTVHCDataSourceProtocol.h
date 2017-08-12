//
//  KTVHCDataSourceProtocol.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KTVHCDataSourceProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString * filePath;

@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign, readonly) NSInteger size;

@property (nonatomic, assign, readonly) BOOL didFinishRead;

- (void)prepare;
- (void)close;

- (NSData *)syncReadDataOfLength:(NSInteger)length;

@end
