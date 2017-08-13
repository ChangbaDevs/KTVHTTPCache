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

@property (nonatomic, assign, readonly) long long offset;
@property (nonatomic, assign, readonly) long long length;

@property (nonatomic, assign, readonly) BOOL didClose;
@property (nonatomic, assign, readonly) BOOL didFinishRead;

- (void)prepare;
- (void)close;

- (NSData *)readDataOfLength:(NSUInteger)length;

@end
