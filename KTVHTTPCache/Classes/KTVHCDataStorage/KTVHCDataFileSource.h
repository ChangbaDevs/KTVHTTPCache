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

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sourceWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                          filePath:(NSString *)filePath
                            offset:(long long)offset
                            length:(long long)length
                       startOffset:(long long)startOffset
                    needReadLength:(long long)needReadLength;

@property (nonatomic, weak, readonly) id <KTVHCDataFileSourceDelegate> fileSourceDelegate;

@property (nonatomic, assign, readonly) long long startOffset;
@property (nonatomic, assign, readonly) long long needReadLength;

@end
