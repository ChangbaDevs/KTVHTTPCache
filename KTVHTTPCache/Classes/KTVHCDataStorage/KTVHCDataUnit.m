//
//  KTVHCDataUnit.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnit.h"
#import "KTVHCURLTools.h"
#import "KTVHCPathTools.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"


@interface KTVHCDataUnit ()


@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, copy) NSString * uniqueIdentifier;

@property (nonatomic, assign) NSTimeInterval createTimeInterval;

@property (nonatomic, copy) NSDictionary * requestHeaderFields;
@property (nonatomic, copy) NSDictionary * responseHeaderFields;

@property (nonatomic, assign) long long totalContentLength;
@property (nonatomic, assign) long long totalCacheLength;
@property (nonatomic, assign) long long totalValidCacheLength;

@property (nonatomic, strong) NSRecursiveLock * coreLock;
@property (nonatomic, strong) NSMutableArray <KTVHCDataUnitItem *> * unitItems;

@property (nonatomic, assign) NSInteger workingCount;

@property (nonatomic, weak) id <KTVHCDataUnitDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;


@end


@implementation KTVHCDataUnit


+ (instancetype)unitWithURLString:(NSString *)URLString
{
    return [[self alloc] initWithURLString:URLString];
}

- (instancetype)initWithURLString:(NSString *)URLString
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.URLString = URLString;
        self.uniqueIdentifier = [KTVHCURLTools uniqueIdentifierWithURLString:self.URLString];
        self.createTimeInterval = [NSDate date].timeIntervalSince1970;
        [self prepare];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.URLString = [aDecoder decodeObjectForKey:@"URLString"];
        self.uniqueIdentifier = [aDecoder decodeObjectForKey:@"uniqueIdentifier"];
        self.createTimeInterval = [[aDecoder decodeObjectForKey:@"createTimeInterval"] doubleValue];
        self.requestHeaderFields = [aDecoder decodeObjectForKey:@"requestHeaderFields"];
        self.responseHeaderFields = [aDecoder decodeObjectForKey:@"responseHeaderFields"];
        self.totalContentLength = [[aDecoder decodeObjectForKey:@"totalContentLength"] longLongValue];
        self.unitItems = [aDecoder decodeObjectForKey:@"unitItems"];
        [self prepare];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.URLString forKey:@"URLString"];
    [aCoder encodeObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];
    [aCoder encodeObject:@(self.createTimeInterval) forKey:@"createTimeInterval"];
    [aCoder encodeObject:self.requestHeaderFields forKey:@"requestHeaderFields"];
    [aCoder encodeObject:self.responseHeaderFields forKey:@"responseHeaderFields"];
    [aCoder encodeObject:@(self.totalContentLength) forKey:@"totalContentLength"];
    [aCoder encodeObject:self.unitItems forKey:@"unitItems"];
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)prepare
{
    self.coreLock = [[NSRecursiveLock alloc] init];
    
    [self lock];
    if (!self.unitItems) {
        self.unitItems = [NSMutableArray array];
    }
    
    if (self.unitItems.count > 0)
    {
        NSMutableArray * removeArray = [NSMutableArray array];
        for (KTVHCDataUnitItem * obj in self.unitItems)
        {
            if (obj.length <= 0) {
                [removeArray addObject:obj];
            }
        }
        [self.unitItems removeObjectsInArray:removeArray];
        [removeArray removeAllObjects];
        [self sortUnitItems];
    }
    
    KTVHCLogDataUnit(@"prepare result, %@, %ld", self.URLString, (long)self.unitItems.count);
    
    [self unlock];
}

- (void)sortUnitItems
{
    [self lock];
    [self.unitItems sortUsingComparator:^NSComparisonResult(KTVHCDataUnitItem * obj1, KTVHCDataUnitItem * obj2) {
        NSComparisonResult result = NSOrderedDescending;
        if (obj1.offset < obj2.offset) {
            result = NSOrderedAscending;
        } else if ((obj1.offset == obj2.offset) && (obj1.length > obj2.length)) {
            result = NSOrderedAscending;
        }
        return result;
    }];
    [self unlock];
}

- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem
{
    [self lock];
    [self.unitItems addObject:unitItem];
    [self sortUnitItems];
    
    KTVHCLogDataUnit(@"insert unit item, %lld", unitItem.offset);
    
    [self unlock];
}

- (void)updateRequestHeaderFields:(NSDictionary *)requestHeaderFields
{
    self.requestHeaderFields = requestHeaderFields;
    
    KTVHCLogDataUnit(@"update request\n%@", self.requestHeaderFields);
}

- (void)updateResponseHeaderFields:(NSDictionary *)responseHeaderFields
{
    self.responseHeaderFields = responseHeaderFields;
    [self updateTotalContentLength];
    
    KTVHCLogDataUnit(@"update response\n%@", self.responseHeaderFields);
}

- (void)updateTotalContentLength
{
    NSString * contentRange = [self.responseHeaderFields objectForKey:@"Content-Range"];
    if (!contentRange) {
        contentRange = [self.responseHeaderFields objectForKey:@"content-range"];
    }
    NSRange range = [contentRange rangeOfString:@"/"];
    if (contentRange.length > 0 && range.location != NSNotFound)
    {
        long long totalContentLength = [contentRange substringFromIndex:range.location + range.length].longLongValue;
        if (self.totalContentLength != totalContentLength)
        {
            self.totalContentLength = totalContentLength;
            
            KTVHCLogDataUnit(@"set total content length, %lld", totalContentLength);
            
            if ([self.delegate respondsToSelector:@selector(unitDidUpdateTotalContentLength:)]) {
                [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                    [self.delegate unitDidUpdateTotalContentLength:self];
                }];
            }
        }
    }
}


#pragma mark - Setter/Getter

- (NSString *)filePath
{
    [self lock];
    NSString * filePath = nil;
    KTVHCDataUnitItem * item = self.unitItems.firstObject;
    if (item.offset == 0
        && item.length > 0
        && item.length == self.totalContentLength)
    {
        filePath = item.absolutePath;
    }
    [self unlock];
    return filePath;
}

- (long long)totalCacheLength
{
    [self lock];
    long long length = 0;
    for (KTVHCDataUnitItem * obj in self.unitItems)
    {
        length += obj.length;
    }
    [self unlock];
    return length;
}

- (long long)totalValidCacheLength
{
    [self lock];
    long long offset = 0;
    long long length = 0;
    for (KTVHCDataUnitItem * obj in self.unitItems)
    {
        long long invalidLength = MAX(offset - obj.offset, 0);
        long long vaildLength = MAX(obj.length - invalidLength, 0);
        offset = MAX(offset, obj.offset + obj.length);
        length += vaildLength;
    }
    [self unlock];
    return length;
}

- (NSDictionary *)requestHeaderFieldsWithoutRange
{
    if ([self.requestHeaderFields objectForKey:@"Range"]) {
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:self.requestHeaderFields];
        [headers removeObjectForKey:@"Range"];
        return headers;
    }
    return self.requestHeaderFields;
}

- (NSDictionary *)responseHeaderFieldsWithoutRangeAndLength
{
    if ([self.responseHeaderFields objectForKey:@"Content-Range"]
        || [self.responseHeaderFields objectForKey:@"Content-Length"]
        || [self.responseHeaderFields objectForKey:@"content-range"]
        || [self.responseHeaderFields objectForKey:@"content-length"])
    {
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:self.responseHeaderFields];
        [headers removeObjectForKey:@"Content-Range"];
        [headers removeObjectForKey:@"Content-Length"];
        [headers removeObjectForKey:@"content-range"];
        [headers removeObjectForKey:@"content-length"];
        return headers;
    }
    return self.responseHeaderFields;
}

- (NSTimeInterval)lastItemCreateInterval
{
    [self lock];
    NSTimeInterval timeInterval = self.createTimeInterval;
    for (KTVHCDataUnitItem * obj in self.unitItems)
    {
        if (obj.createTimeInterval > timeInterval)
        {
            timeInterval = obj.createTimeInterval;
        }
    }
    [self unlock];
    return timeInterval;
}

- (void)setDelegate:(id <KTVHCDataUnitDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    self.delegate = delegate;
    self.delegateQueue = delegateQueue;
}


#pragma mark - Working State

- (BOOL)working
{
    [self.coreLock lock];
    BOOL working = self.workingCount > 0;
    [self.coreLock unlock];
    return working;
}

- (void)workingRetain
{
    [self.coreLock lock];
    self.workingCount++;
    
    KTVHCLogDataUnit(@"working retain, %@, %ld", self.URLString, (long)self.workingCount);
    
    [self.coreLock unlock];
}

- (void)workingRelease
{
    [self.coreLock lock];
    self.workingCount--;
    
    KTVHCLogDataUnit(@"working release, %@, %ld", self.URLString, (long)self.workingCount);
    
    if (self.workingCount <= 0)
    {
        if ([self mergeFilesIfNeeded])
        {
            NSAssert(self.fileDelegate, @"archive callback can't be nil.");
            [self.fileDelegate unitShouldRearchive:self];
            
            KTVHCLogDataUnit(@"merge files rearchive callback");
        }
        
        if ([self.workingDelegate respondsToSelector:@selector(unitDidStopWorking:)])
        {
            KTVHCLogDataUnit(@"working release callback add, %@, %ld", self.URLString, (long)self.workingCount);
            
            [KTVHCDataCallback workingCallbackWithBlock:^{
                
                KTVHCLogDataUnit(@"working release callback begin, %@, %ld", self.URLString, (long)self.workingCount);
                
                [self.workingDelegate unitDidStopWorking:self];
                
                KTVHCLogDataUnit(@"working release callback end, %@, %ld", self.URLString, (long)self.workingCount);
            }];
        }
    }
    
    [self.coreLock unlock];
}


#pragma mark - File

- (NSString *)absolutePathForFileDirectory
{
    return [KTVHCPathTools absolutePathForDirectoryWithURLString:self.URLString];
}

- (void)deleteFiles
{
    [KTVHCPathTools deleteFolderAtPath:self.absolutePathForFileDirectory];
}

- (BOOL)mergeFilesIfNeeded
{
    [self.coreLock lock];
    if (self.working || self.unitItems.count <= 1)
    {
        [self.coreLock unlock];
        return NO;
    }
    
    BOOL success = NO;
    if (self.totalContentLength == self.totalValidCacheLength)
    {
        long long offset = 0;
        NSString * path = [KTVHCPathTools absolutePathForCompleteFileWithURLString:self.URLString];
        [KTVHCPathTools deleteFileAtPath:path];
        [KTVHCPathTools createFileIfNeeded:path];
        NSFileHandle * writingHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        for (KTVHCDataUnitItem * obj in self.unitItems)
        {
            NSAssert(offset >= obj.offset, @"invaild unit item.");
            if (offset >= (obj.offset + obj.length))
            {
                KTVHCLogDataUnit(@"merge files continue");
                continue;
            }
            NSFileHandle * readingHandle = [NSFileHandle fileHandleForReadingAtPath:obj.absolutePath];
            @try
            {
                [readingHandle seekToFileOffset:offset - obj.offset];
            }
            @catch (NSException *exception)
            {
                KTVHCLogDataUnit(@"merge files seek exception");
            }
            while (YES)
            {
                @autoreleasepool
                {
                    NSData * data = [readingHandle readDataOfLength:1024 * 1024];
                    if (data.length <= 0)
                    {
                        KTVHCLogDataUnit(@"merge files break");
                        
                        break;
                    }
                    KTVHCLogDataUnit(@"merge files write data, %lld", (long long)data.length);
                    
                    [writingHandle writeData:data];
                }
            }
            [readingHandle closeFile];
            offset = obj.offset + obj.length;
            
            KTVHCLogDataUnit(@"merge files next, %lld", offset);
        }
        [writingHandle synchronizeFile];
        [writingHandle closeFile];
        
        KTVHCLogDataUnit(@"merge files finish, %@, %lld, %lld", path, self.totalCacheLength, offset);
        
        if ([KTVHCPathTools sizeOfItemAtFilePath:path] == self.totalContentLength)
        {
            KTVHCLogDataUnit(@"merge files replace unit item");
            
            NSString * relativePath = [KTVHCPathTools relativePathForCompleteFileWithURLString:self.URLString];
            KTVHCDataUnitItem * finalItem = [KTVHCDataUnitItem unitItemWithOffset:0
                                                                     relativePath:relativePath];
            for (KTVHCDataUnitItem * obj in self.unitItems)
            {
                [KTVHCPathTools deleteFileAtPath:obj.absolutePath];
            }
            [self.unitItems removeAllObjects];
            [self.unitItems addObject:finalItem];
            success = YES;
        }
    }
    [self.coreLock unlock];
    return success;
}


#pragma mark - NSLocking

- (void)lock
{
    [self.coreLock lock];
    for (KTVHCDataUnitItem * obj in self.unitItems) {
        [obj lock];
    }
}

- (void)unlock
{
    for (KTVHCDataUnitItem * obj in self.unitItems) {
        [obj unlock];
    }
    [self.coreLock unlock];
}


@end
