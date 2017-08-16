//
//  KTVHCDataFileSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataFileSource.h"
#import "KTVHCDataCallback.h"

@interface KTVHCDataFileSource ()


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataFileSourceDelegate> fileSourceDelegate;

@property (nonatomic, assign) long long startOffset;
@property (nonatomic, assign) long long needReadLength;


#pragma mark - File

@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, assign) long long fileReadedLength;

@end

@implementation KTVHCDataFileSource

+ (instancetype)sourceWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                          filePath:(NSString *)filePath
                            offset:(long long)offset
                            length:(long long)length
                       startOffset:(long long)startOffset
                    needReadLength:(long long)needReadLength
{
    return [[self alloc] initWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                                 filePath:filePath
                                   offset:offset
                                     length:length
                              startOffset:startOffset
                             needReadLength:needReadLength];
}

- (instancetype)initWithDelegate:(id <KTVHCDataFileSourceDelegate>)delegate
                        filePath:(NSString *)filePath
                          offset:(long long)offset
                          length:(long long)length
                     startOffset:(long long)startOffset
                  needReadLength:(long long)needReadLength
{
    if (self = [super init])
    {
        self.fileSourceDelegate = delegate;
        self.filePath = filePath;
        self.offset = offset;
        self.length = length;
        self.startOffset = startOffset;
        self.needReadLength = needReadLength;
    }
    return self;
}

- (void)prepare
{
    if (self.didCallPrepare) {
        return;
    }
    self.didCallPrepare = YES;
    
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
    [self.readingHandle seekToFileOffset:self.startOffset];
    if ([self.fileSourceDelegate respondsToSelector:@selector(fileSourceDidFinishPrepare:)]) {
        [KTVHCDataCallback commonCallbackWithBlock:^{
            [self.fileSourceDelegate fileSourceDidFinishPrepare:self];
        }];
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
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    NSData * data = [self.readingHandle readDataOfLength:MIN(self.needReadLength - self.fileReadedLength, length)];
    self.fileReadedLength += data.length;
    if (self.fileReadedLength >= self.needReadLength)
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
        [KTVHCDataCallback commonCallbackWithBlock:^{
            [self.fileSourceDelegate fileSourceDidFinishRead:self];
        }];
    }
}

@end
