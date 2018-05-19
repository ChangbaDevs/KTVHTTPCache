//
//  KTVHCDataFileSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataFileSource.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"


@interface KTVHCDataFileSource ()


#pragma mark - Protocol

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Setter

@property (nonatomic, assign) long long startOffset;
@property (nonatomic, assign) long long needReadLength;

@property (nonatomic, weak) id <KTVHCDataFileSourceDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;


#pragma mark - File

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, assign) long long fileReadedLength;


@end


@implementation KTVHCDataFileSource


+ (instancetype)sourceWithFilePath:(NSString *)filePath
                            offset:(long long)offset
                            length:(long long)length
                       startOffset:(long long)startOffset
                    needReadLength:(long long)needReadLength
{
    return [[self alloc] initWithFilePath:filePath
                                   offset:offset
                                     length:length
                              startOffset:startOffset
                             needReadLength:needReadLength];
}

- (instancetype)initWithFilePath:(NSString *)filePath
                          offset:(long long)offset
                          length:(long long)length
                     startOffset:(long long)startOffset
                  needReadLength:(long long)needReadLength
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        self.filePath = filePath;
        self.offset = offset;
        self.length = length;
        self.startOffset = startOffset;
        self.needReadLength = needReadLength;
        self.lock = [[NSLock alloc] init];
        
        KTVHCLogDataFileSource(@"did setup, %lld, %lld, %lld, %lld", self.offset, self.length, self.startOffset, self.needReadLength);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)setDelegate:(id <KTVHCDataFileSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    self.delegate = delegate;
    self.delegateQueue = delegateQueue;
}

- (void)prepare
{
    if (self.didCallPrepare) {
        return;
    }
    self.didCallPrepare = YES;
    
    KTVHCLogDataFileSource(@"call prepare");
    
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
    
    @try {
        [self.readingHandle seekToFileOffset:self.startOffset];
    } @catch (NSException *exception) {
        KTVHCLogDataSourcer(@"seek file exception, %@, %@, %@, %lld, %lld, %lld, %lld",
                            exception.name,
                            exception.reason,
                            exception.userInfo,
                            self.length,
                            self.offset,
                            self.startOffset,
                            self.needReadLength);
    }
    
    if ([self.delegate respondsToSelector:@selector(fileSourceDidFinishPrepare:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate fileSourceDidFinishPrepare:self];
        }];
    }
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    [self.lock lock];
    self.didClose = YES;
    
    KTVHCLogDataFileSource(@"call close");
    
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    [self.lock unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    [self.lock lock];
    NSData * data = [self.readingHandle readDataOfLength:(NSUInteger)MIN(self.needReadLength - self.fileReadedLength, length)];
    self.fileReadedLength += data.length;
    
    KTVHCLogDataFileSource(@"read data : %lld, %lld, %lld", (long long)data.length, self.fileReadedLength, self.needReadLength);
    
    if (self.fileReadedLength >= self.needReadLength)
    {
        KTVHCLogDataFileSource(@"read data finished");
        
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        
        self.didFinishRead = YES;
    }
    [self.lock unlock];
    return data;
}


@end
