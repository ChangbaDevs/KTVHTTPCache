//
//  KTVHCDataFileSource.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"

@class KTVHCDataFileSource;

@protocol KTVHCDataFileSourceDelegate <NSObject>

@optional
- (void)fileSourceDidFinishPrepare:(KTVHCDataFileSource *)fileSource;
- (void)fileSourceDidFinishRead:(KTVHCDataFileSource *)fileSource;

@end

@interface KTVHCDataFileSource : NSObject <KTVHCDataSourceProtocol>

+ (instancetype)sourceWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                          filePath:(NSString *)filePath
                            offset:(NSInteger)offset
                              size:(NSInteger)size
                       startOffset:(NSInteger)startOffset
                      needReadSize:(NSInteger)needReadSize;

@property (nonatomic, weak, readonly) id <KTVHCDataFileSourceDelegate> fileSourceDelegate;

@property (nonatomic, assign, readonly) NSInteger startOffset;
@property (nonatomic, assign, readonly) NSInteger needReadSize;

@end
