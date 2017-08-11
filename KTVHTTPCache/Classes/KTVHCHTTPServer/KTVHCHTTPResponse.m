//
//  KTVHCHTTPResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPResponse.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCDataRequest.h"

@interface KTVHCHTTPResponse ()

@property (nonatomic, weak) KTVHCHTTPConnection * connection;
@property (nonatomic, strong) KTVHCDataRequest * dataRequest;

@end

@implementation KTVHCHTTPResponse

+ (instancetype)responseWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest
{
    return [[self alloc] initWithConnection:connection dataRequest:dataRequest];
}

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest
{
    if (self = [super init])
    {
        self.connection = connection;
        self.dataRequest = dataRequest;
    }
    return self;
}

- (UInt64)contentLength
{
    return 0;
}

- (UInt64)offset
{
    return 0;
}

- (void)setOffset:(UInt64)offset
{
    
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    return nil;
}

- (BOOL)isDone
{
    return YES;
}

@end
