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

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didFinishClose;
@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataFileSourceDelegate> fileSourceDelegate;

@property (nonatomic, assign) NSInteger startOffset;
@property (nonatomic, assign) NSInteger needReadSize;


#pragma mark - File

@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, assign) NSInteger fileReadOffset;

@end

@implementation KTVHCDataFileSource

+ (instancetype)sourceWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                          filePath:(NSString *)filePath
                            offset:(NSInteger)offset
                              size:(NSInteger)size
                       startOffset:(NSInteger)startOffset
                      needReadSize:(NSInteger)needReadSize
{
    return [[self alloc] initWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                                 filePath:filePath
                                   offset:offset
                                     size:size
                              startOffset:startOffset
                             needReadSize:needReadSize];
}

- (instancetype)initWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                        filePath:(NSString *)filePath
                          offset:(NSInteger)offset
                            size:(NSInteger)size
                     startOffset:(NSInteger)startOffset
                    needReadSize:(NSInteger)needReadSize
{
    if (self = [super init])
    {
        self.fileSourceDelegate = delegate;
        self.filePath = filePath;
        self.offset = offset;
        self.size = size;
        self.startOffset = startOffset;
        self.needReadSize = needReadSize;
    }
    return self;
}

- (void)prepare
{
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
    [self.readingHandle seekToFileOffset:self.startOffset];
    if ([self.fileSourceDelegate respondsToSelector:@selector(fileSourceDidFinishPrepare:)]) {
        [self.fileSourceDelegate fileSourceDidFinishPrepare:self];
    }
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    self.didClose = YES;
    
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    
    self.didFinishClose = YES;
}

- (NSData *)syncReadDataOfLength:(NSInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    NSData * data = [self.readingHandle readDataOfLength:length];
    self.fileReadOffset += data.length;
    if (self.fileReadOffset >= self.needReadSize)
    {
        [self callbackForFinishRead];
    }
    return data;
}


#pragma mark - Callback

- (void)callbackForFinishRead
{
    [self.readingHandle closeFile];
    self.readingHandle = nil;

    self.didFinishRead = YES;
    if ([self.fileSourceDelegate respondsToSelector:@selector(fileSourceDidFinishRead:)]) {
        [self.fileSourceDelegate fileSourceDidFinishRead:self];
    }
}

@end
