//
//  KTVHCDataFileSource.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"

@interface KTVHCDataFileSource : NSObject <KTVHCDataSourceProtocol>

+ (instancetype)sourceWithFilePath:(NSString *)filePath
                            offset:(NSInteger)offset
                              size:(NSInteger)size
                       startOffset:(NSInteger)startOffset
                      needReadSize:(NSInteger)needReadSize;

@property (nonatomic, assign, readonly) NSInteger startOffset;
@property (nonatomic, assign, readonly) NSInteger needReadSize;

@end
