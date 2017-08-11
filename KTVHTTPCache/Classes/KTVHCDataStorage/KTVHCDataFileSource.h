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
                        readOffset:(NSInteger)readOffset
                          readSize:(NSInteger)readSize;

@property (nonatomic, copy, readonly) NSString * filePath;

@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, assign, readonly) NSInteger readOffset;
@property (nonatomic, assign, readonly) NSInteger readSize;

@end
