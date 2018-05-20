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

@interface KTVHCDataFileSource () <NSLocking>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, assign) long long readedLength;

@end

@implementation KTVHCDataFileSource

- (instancetype)initWithPath:(NSString *)path range:(KTVHCRange)range readRange:(KTVHCRange)readRange
{
    if (self = [super init])
    {
        _path = path;
        _range = range;
        _readRange = readRange;
        KTVHCLogAlloc(self);
        KTVHCLogDataFileSource(@"did setup, %@, %@", KTVHCStringFromRange(range), KTVHCStringFromRange(readRange));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)prepare
{
    if (self.didPrepared) {
        return;
    }
    [self lock];
    _didPrepared = YES;
    KTVHCLogDataFileSource(@"call prepare");
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    @try {
        [self.readingHandle seekToFileOffset:self.readRange.start];
    } @catch (NSException *exception) {
        KTVHCLogDataSourcer(@"seek file exception, %@, %@, %@",
                            exception.name,
                            exception.reason,
                            exception.userInfo);
    }
    [self unlock];
    if ([self.delegate respondsToSelector:@selector(sourceDidPrepared:)])
    {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourceDidPrepared:self];
        }];
    }
}

- (void)close
{
    if (self.didClosed) {
        return;
    }
    [self lock];
    _didClosed = YES;
    KTVHCLogDataFileSource(@"call close");
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClosed) {
        return nil;
    }
    if (self.didFinished) {
        return nil;
    }
    [self lock];
    long long readLength = KTVHCRangeGetLength(self.readRange);
    length = (NSUInteger)MIN(readLength - self.readedLength, length);
    NSData * data = [self.readingHandle readDataOfLength:length];
    self.readedLength += data.length;
    KTVHCLogDataFileSource(@"read data : %lld, %lld, %lld", (long long)data.length, self.readedLength, readLength);
    if (self.readedLength >= readLength)
    {
        KTVHCLogDataFileSource(@"read data finished");
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        _didFinished = YES;
    }
    [self unlock];
    return data;
}

- (void)setDelegate:(id <KTVHCDataSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    _delegate = delegate;
    _delegateQueue = delegateQueue;
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
