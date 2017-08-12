//
//  KTVHCDataFileSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataFileSource.h"

@interface KTVHCDataFileSource ()


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger size;

@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, assign) NSInteger startOffset;
@property (nonatomic, assign) NSInteger needReadSize;

@end

@implementation KTVHCDataFileSource

+ (instancetype)sourceWithFilePath:(NSString *)filePath
                            offset:(NSInteger)offset
                              size:(NSInteger)size
                       startOffset:(NSInteger)startOffset
                      needReadSize:(NSInteger)needReadSize
{
    return [[self alloc] initWithFilePath:filePath
                                   offset:offset
                                     size:size
                              startOffset:startOffset
                             needReadSize:needReadSize];
}

- (instancetype)initWithFilePath:(NSString *)filePath
                          offset:(NSInteger)offset
                            size:(NSInteger)size
                     startOffset:(NSInteger)startOffset
                    needReadSize:(NSInteger)needReadSize
{
    if (self = [super init])
    {
        self.filePath = filePath;
        
        self.offset = offset;
        self.size = size;
        self.startOffset = startOffset;
        self.needReadSize = needReadSize;
    }
    return self;
}

- (NSData *)syncReadDataOfLength:(NSInteger)length
{
    return nil;
}

@end
