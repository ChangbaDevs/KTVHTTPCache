//
//  KTVHCURLTool.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCURLTool.h"
#import <CommonCrypto/CommonCrypto.h>

@interface KTVHCURLTool ()

@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *md5s;

@end

@implementation KTVHCURLTool

+ (instancetype)tool
{
    static KTVHCURLTool *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.md5s = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)keyWithURL:(NSURL *)URL
{
    if (self.URLConverter && URL.absoluteString.length > 0) {
        NSURL *newURL = self.URLConverter(URL);
        if (newURL.absoluteString.length > 0) {
            URL = newURL;
        }
    }
    return [self md5:URL.absoluteString];
}

- (NSString *)md5:(NSString *)URLString
{
    [self.lock lock];
    NSString *result = [self.md5s objectForKey:URLString];
    if (!result || result.length == 0) {
        const char *value = [URLString UTF8String];
        unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
        CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
        NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH *2];
        for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++) {
            [outputString appendFormat:@"%02x", outputBuffer[count]];
        }
        result = outputString;
        [self.md5s setObject:result forKey:URLString];
    }
    [self.lock unlock];
    return result;
}

- (NSString *)URLEncode:(NSString *)URLString
{
    static NSString *characters =  @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:characters];
    return [URLString stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
}

- (NSString *)URLDecode:(NSString *)URLString
{
    return [URLString stringByRemovingPercentEncoding];
}

- (NSDictionary<NSString *,NSString *> *)parseQuery:(NSString *)query
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSScanner *scanner = [[NSScanner alloc] initWithString:query];
    [scanner setCharactersToBeSkipped:nil];
    while (1) {
        NSString *key = nil;
        if (![scanner scanUpToString:@"=" intoString:&key] || [scanner isAtEnd]) {
            break;
        }
        [scanner setScanLocation:([scanner scanLocation] + 1)];
        NSString *value = nil;
        [scanner scanUpToString:@"&" intoString:&value];
        if (value == nil) {
            value = @"";
        }
        key = [key stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        NSString *unescapedKey = key ? [self URLDecode:key] : nil;
        value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        NSString *unescapedValue = value ? [self URLDecode:value] : nil;
        if (unescapedKey && unescapedValue) {
            [parameters setObject:unescapedValue forKey:unescapedKey];
        }
        if ([scanner isAtEnd]) {
            break;
        }
        [scanner setScanLocation:([scanner scanLocation] + 1)];
    }
    return parameters;
}

@end
