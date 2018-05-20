//
//  KTVHCDataSourceProtocol.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KTVHCDataSourceProtocol <NSObject>

- (long long)offset;
- (long long)length;

- (BOOL)didPrepared;
- (BOOL)didFinished;
- (BOOL)didClosed;

- (void)prepare;
- (void)close;

- (NSData *)readDataOfLength:(NSUInteger)length;

@end

@protocol KTVHCDataSourceDelegate <NSObject>

- (void)sourceDidPrepared:(id <KTVHCDataSourceProtocol>)source;

@end
