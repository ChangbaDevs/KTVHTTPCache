//
//  KTVHCError.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCError.h"

NSString * const KTVHCErrorUserInfoKeyURL      = @"KTVHCErrorUserInfoKeyURL";
NSString * const KTVHCErrorUserInfoKeyRequest  = @"KTVHCErrorUserInfoKeyRequest";
NSString * const KTVHCErrorUserInfoKeyResponse = @"KTVHCErrorUserInfoKeyResponse";

@implementation KTVHCError

+ (NSError *)errorForException:(NSException *)exception
{
    NSError *error = [NSError errorWithDomain:@"KTVHTTPCache error"
                                        code:KTVHCErrorCodeException
                                    userInfo:exception.userInfo];
    return error;
}

+ (NSError *)errorForNotEnoughDiskSpace:(long long)totlaContentLength
                                request:(long long)currentContentLength
                       totalCacheLength:(long long)totalCacheLength
                         maxCacheLength:(long long)maxCacheLength
{
    NSError *error = [NSError errorWithDomain:@"KTVHTTPCache error"
                                         code:KTVHCErrorCodeNotEnoughDiskSpace
                                     userInfo:@{@"totlaContentLength" : @(totlaContentLength),
                                                @"currentContentLength" : @(currentContentLength),
                                                @"totalCacheLength" : @(totalCacheLength),
                                                @"maxCacheLength" : @(maxCacheLength)}];
    return error;
}

+ (NSError *)errorForResponseClass:(NSURL *)URL 
                           request:(NSURLRequest *)request 
                          response:(NSURLResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (URL) {
        [userInfo setObject:URL forKey:KTVHCErrorUserInfoKeyURL];
    }
    if (request) {
        [userInfo setObject:request forKey:KTVHCErrorUserInfoKeyRequest];
    }
    if (response) {
        [userInfo setObject:response forKey:KTVHCErrorUserInfoKeyResponse];
    }
    NSError *error = [NSError errorWithDomain:@"KTVHTTPCache error"
                                         code:KTVHCErrorCodeResponseClass
                                     userInfo:userInfo];
    return error;
}

+ (NSError *)errorForResponseStatusCode:(NSURL *)URL
                                request:(NSURLRequest *)request
                               response:(NSURLResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (URL) {
        [userInfo setObject:URL forKey:KTVHCErrorUserInfoKeyURL];
    }
    if (request) {
        [userInfo setObject:request forKey:KTVHCErrorUserInfoKeyRequest];
    }
    if (response) {
        [userInfo setObject:response forKey:KTVHCErrorUserInfoKeyResponse];
    }
    NSError *error = [NSError errorWithDomain:@"KTVHTTPCache error"
                                         code:KTVHCErrorCodeResponseStatusCode
                                     userInfo:userInfo];
    return error;
}

+ (NSError *)errorForResponseContentType:(NSURL *)URL
                                 request:(NSURLRequest *)request
                                response:(NSURLResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (URL) {
        [userInfo setObject:URL forKey:KTVHCErrorUserInfoKeyURL];
    }
    if (request) {
        [userInfo setObject:request forKey:KTVHCErrorUserInfoKeyRequest];
    }
    if (response) {
        [userInfo setObject:response forKey:KTVHCErrorUserInfoKeyResponse];
    }
    NSError *error = [NSError errorWithDomain:@"KTVHTTPCache error"
                                         code:KTVHCErrorCodeResponseContentType
                                     userInfo:userInfo];
    return error;
}

+ (NSError *)errorForResponseContentLength:(NSURL *)URL 
                                   request:(NSURLRequest *)request 
                                  response:(NSURLResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (URL) {
        [userInfo setObject:URL forKey:KTVHCErrorUserInfoKeyURL];
    }
    if (request) {
        [userInfo setObject:request forKey:KTVHCErrorUserInfoKeyRequest];
    }
    if (response) {
        [userInfo setObject:response forKey:KTVHCErrorUserInfoKeyResponse];
    }
    NSError *error = [NSError errorWithDomain:@"KTVHTTPCache error"
                                         code:KTVHCErrorCodeResponseContentLength
                                     userInfo:userInfo];
    return error;
}

@end
