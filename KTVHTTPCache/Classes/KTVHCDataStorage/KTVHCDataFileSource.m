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
        KTVHCLogAlloc(self);
        _path = path;
        _range = range;
        _readRange = readRange;
        KTVHCLogDataFileSource(@"%p, Create file source\npath : %@\nrange : %@\nreadRange : %@", self, path, KTVHCStringFromRange(range), KTVHCStringFromRange(readRange));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)prepare
{
    [self lock];
    if (self.didPrepared)
    {
        [self unlock];
        return;
    }
    KTVHCLogDataFileSource(@"%p, Call prepare", self);
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    @try
    {
        [self.readingHandle seekToFileOffset:self.readRange.start];
    }
    @catch (NSException * exception)
    {
        KTVHCLogDataFileSource(@"%p, Seek file exception\nname : %@\nreason : %@\nuserInfo : %@", self, exception.name, exception.reason, exception.userInfo);
    }
    _didPrepared = YES;
    if ([self.delegate respondsToSelector:@selector(fileSourceDidPrepared:)])
    {
        KTVHCLogDataFileSource(@"%p, Callback for prepared - Begin", self);
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            KTVHCLogDataFileSource(@"%p, Callback for prepared - End", self);
            [self.delegate fileSourceDidPrepared:self];
        }];
    }
    [self unlock];
}

- (void)close
{
    [self lock];
    if (self.didClosed)
    {
        [self unlock];
        return;
    }
    _didClosed = YES;
    KTVHCLogDataFileSource(@"%p, Call close", self);
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    [self lock];
    if (self.didClosed)
    {
        [self unlock];
        return nil;
    }
    if (self.didFinished)
    {
        [self unlock];
        return nil;
    }
    long long readLength = KTVHCRangeGetLength(self.readRange);
    length = (NSUInteger)MIN(readLength - self.readedLength, length);
    NSData * data = [self.readingHandle readDataOfLength:length];
    self.readedLength += data.length;
    KTVHCLogDataFileSource(@"%p, Read data : %lld, %lld, %lld", self, (long long)data.length, self.readedLength, readLength);
    if (self.readedLength >= readLength)
    {
        KTVHCLogDataFileSource(@"%p, Read data did finished", self);
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        _didFinished = YES;
    }
    [self unlock];
    return data;
}

- (void)setDelegate:(id<KTVHCDataFileSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    _delegate = delegate;
    _delegateQueue = delegateQueue;
}

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
