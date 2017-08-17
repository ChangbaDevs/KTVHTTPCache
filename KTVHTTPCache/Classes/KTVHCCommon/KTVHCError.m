//
//  KTVHCError.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCError.h"


NSString * const KTVHCErrorDomainResponseUnavailable = @"KTVHCErrorDomainResponseUnavailable";                   // player error


@implementation KTVHCError


+ (NSError *)errorForResponseUnavailable:(NSString *)URLString response:(NSHTTPURLResponse *)response
{
    if (URLString.length <= 0) {
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
                                                 @"responseURL" : response.URL.absoluteString,
                                                 @"responseHeader" : response.allHeaderFields}];
    return error;
}


@end
