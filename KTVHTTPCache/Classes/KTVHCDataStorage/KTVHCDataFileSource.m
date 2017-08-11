//
//  KTVHCDataFileSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataFileSource.h"

@interface KTVHCDataFileSource ()

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) NSInteger readOffset;
@property (nonatomic, assign) NSInteger readSize;

@end

@implementation KTVHCDataFileSource

+ (instancetype)sourceWithFilePath:(NSString *)filePath
                            offset:(NSInteger)offset
                              size:(NSInteger)size
                        readOffset:(NSInteger)readOffset
                          readSize:(NSInteger)readSize
{
    return [[self alloc] initWithFilePath:filePath
                                   offset:offset
                                     size:size
                               readOffset:readOffset
                                 readSize:readSize];
}

- (instancetype)initWithFilePath:(NSString *)filePath
                          offset:(NSInteger)offset
                            size:(NSInteger)size
                      readOffset:(NSInteger)readOffset
                        readSize:(NSInteger)readSize
{
    if (self = [super init])
    {
        self.filePath = filePath;
        
        self.offset = offset;
        self.size = size;
        self.readOffset = readOffset;
        self.readSize = readSize;
    }
    return self;
}

@end
