//
//  KTVHCError.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCError.h"


// Error Domain
NSString * const KTVHCErrorDomainResponseUnavailable    = @"KTVHCErrorDomainResponseUnavailable";
NSString * const KTVHCErrorDomainUnsupportTheContent    = @"KTVHCErrorDomainUnsupportTheContent";
NSString * const KTVHCErrorDomainNotEnoughDiskSpace     = @"KTVHCErrorDomainNotEnoughDiskSpace";

// Error UserInfo Key
NSString * const KTVHCErrorUserInfoKeyURLString         = @"KTVHCErrorUserInfoKeyURLString";
NSString * const KTVHCErrorUserInfoKeyRequest           = @"KTVHCErrorUserInfoKeyRequest";
NSString * const KTVHCErrorUserInfoKeyResponse          = @"KTVHCErrorUserInfoKeyResponse";


@implementation NSError (KTVHTTPCache)

- (NSString *)userInfoVauleForURLString
{
    return [self.userInfo objectForKey:KTVHCErrorUserInfoKeyURLString];
}

- (NSURLRequest *)userInfoVauleForRequest
{
    return [self.userInfo objectForKey:KTVHCErrorUserInfoKeyRequest];
}

- (NSHTTPURLResponse *)userInfoVauleForResponse
{
    return [self.userInfo objectForKey:KTVHCErrorUserInfoKeyResponse];
}

@end


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
    if (!response) {
        return nil;
    }
    
    NSError * error = [NSError errorWithDomain:KTVHCErrorDomainResponseUnavailable
                                          code:KTVHCErrorCodeResponseUnavailable
                                      userInfo:@{KTVHCErrorUserInfoKeyURLString : URLString,
                                                 KTVHCErrorUserInfoKeyRequest : request,
                                                 KTVHCErrorUserInfoKeyResponse : response}];
    return error;
}

+ (NSError *)errorForUnsupportTheContent:(NSString *)URLString
                                 request:(NSURLRequest *)request
                                response:(NSHTTPURLResponse *)response
{
    if (URLString.length <= 0) {
        return nil;
    }
    if (request.allHTTPHeaderFields.count <= 0) {
        return nil;
    }
    if (!response) {
        return nil;
    }
    
    NSError * error = [NSError errorWithDomain:KTVHCErrorDomainUnsupportTheContent
                                          code:KTVHCErrorCodeUnsupportTheContent
                                      userInfo:@{KTVHCErrorUserInfoKeyURLString : URLString,
                                                 KTVHCErrorUserInfoKeyRequest : request,
                                                 KTVHCErrorUserInfoKeyResponse : response}];
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
