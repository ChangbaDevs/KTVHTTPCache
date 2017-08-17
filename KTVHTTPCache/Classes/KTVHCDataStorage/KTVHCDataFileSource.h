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

@end


@interface KTVHCDataFileSource : NSObject <KTVHCDataSourceProtocol>


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sourceWithFilePath:(NSString *)filePath
                            offset:(long long)offset
                            length:(long long)length
                       startOffset:(long long)startOffset
                    needReadLength:(long long)needReadLength;

@property (nonatomic, assign, readonly) long long startOffset;
@property (nonatomic, assign, readonly) long long needReadLength;


#pragma mark - Delegate

@property (nonatomic, weak, readonly) id <KTVHCDataFileSourceDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;

- (void)setDelegate:(id <KTVHCDataFileSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;


@end
