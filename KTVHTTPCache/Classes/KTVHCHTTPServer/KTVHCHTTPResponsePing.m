//
//  KTVHCHTTPResponsePing.m
//  KTVHTTPCache
//
//  Created by Single on 2017/10/23.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPResponsePing.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCLog.h"


NSString * const KTVHCHTTPResponsePingTokenString = @"pang";


@interface KTVHCHTTPResponsePing ()


@property (nonatomic, weak) KTVHCHTTPConnection * connection;

@property (nonatomic, strong) NSData * responseData;
@property (nonatomic, assign) long long readOffset;


@end


@implementation KTVHCHTTPResponsePing


+ (instancetype)responseWithConnection:(KTVHCHTTPConnection *)connection
{
    return [[self alloc] initWithConnection:connection];
}

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        static NSData * data = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            data = [KTVHCHTTPResponsePingTokenString dataUsingEncoding:NSUTF8StringEncoding];
        });
        self.responseData = data;
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


#pragma mark - HTTPResponse

- (NSData *)readDataOfLength:(NSUInteger)length
{
    NSData * data = nil;
    
    NSUInteger readLength = (NSUInteger)MIN(length, self.responseData.length - self.readOffset);
    if (readLength == self.responseData.length)
    {
        data = self.responseData;
    } 
    else if (readLength > 0)
    {
        data = [self.responseData subdataWithRange:NSMakeRange((NSUInteger)self.readOffset, readLength)];
    }
    self.readOffset += data.length;
    
    KTVHCLogHTTPResponsePing(@"read data length, %lld, offset, %lld %@", (long long)data.length, self.readOffset, KTVHCHTTPResponsePingTokenString);
    
    return data;
}

- (BOOL)delayResponseHeaders
{
    return NO;
}

- (UInt64)contentLength
{
    KTVHCLogHTTPResponsePing(@"conetnt length, %lld", (long long)self.responseData.length);
    
    return self.responseData.length;
}

- (UInt64)offset
{
    KTVHCLogHTTPResponsePing(@"offset, %lld", self.readOffset);
    
    return self.readOffset;
}

- (void)setOffset:(UInt64)offset
{
    KTVHCLogHTTPResponsePing(@"set offset, %lld, %lld", offset, self.readOffset);
    
    self.readOffset = offset;
}

- (BOOL)isDone
{
    BOOL result = self.readOffset == self.responseData.length;
    
    KTVHCLogHTTPResponsePing(@"check done, %d", result);
    
    return result;
}

- (void)connectionDidClose
{
    KTVHCLogHTTPResponsePing(@"connection did close, %lld, %lld", (long long)self.responseData.length, self.readOffset);
}


@end
