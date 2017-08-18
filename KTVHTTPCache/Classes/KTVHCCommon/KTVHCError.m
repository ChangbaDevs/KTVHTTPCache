//
//  KTVHCError.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCError.h"


NSString * const KTVHCErrorDomainResponseUnavailable    = @"KTVHCErrorDomainResponseUnavailable";       // player error
NSString * const KTVHCErrorDomainNotEnoughDiskSpace     = @"KTVHCErrorDomainNotEnoughDiskSpace";        // player error


@implementation KTVHCError


+ (NSError *)errorForResponseUnavailable:(NSString *)URLString
                                 request:(NSURLRequest *)request
                                response:(NSHTTPURLResponse *)response
{
    if (URLString.length <= 0) {
        return nil;
    }
    if (request.allHTTPHeaderFields.count <= 0) {
        return nil;
    }
    if (response.URL.absoluteString.length <= 0) {
        return nil;
    }
    if (response.allHeaderFields.count <= 0) {
        return nil;
    }
    
    NSError * error = [NSError errorWithDomain:KTVHCErrorDomainResponseUnavailable
                                          code:KTVHCErrorCodeResponseUnavailable
                                      userInfo:@{@"originalURL" : URLString,
                                                 @"requestHeader" : request.allHTTPHeaderFields,
                                                 @"responseURL" : response.URL.absoluteString,
                                                 @"responseHeader" : response.allHeaderFields}];
    return error;
}

+ (NSError *)errorForNotEnoughDiskSpace:(long long)totlaContentLength
                                request:(long long)currentContentLength
                       totalCacheLength:(long long)totalCacheLength
                         maxCacheLength:(long long)maxCacheLength
{
    NSError * error = [NSError errorWithDomain:KTVHCErrorDomainNotEnoughDiskSpace
                                          code:KTVHCErrorCodeNotEnoughDiskSpace
                                      userInfo:@{@"totlaContentLength" : @(totlaContentLength),
                                                 @"currentContentLength" : @(currentContentLength),
                                                 @"totalCacheLength" : @(totalCacheLength),
                                                 @"maxCacheLength" : @(maxCacheLength)}];
    return error;
}


@end
