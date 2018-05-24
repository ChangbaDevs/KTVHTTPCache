//
//  KTVHCHTTPURL.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPURL.h"
#import "KTVHCURLTools.h"
#import "KTVHCLog.h"

static NSString * const KTVHCHTTPURL_Domain = @"localhost";
static NSString * const KTVHCHTTPURL_Key_OriginalURL = @"originalURL";
static NSString * const KTVHCHTTPURL_Key_RequestType = @"requestType";
static NSString * const KTVHCHTTPURL_Vaule_RequestType_Content = @"content";
static NSString * const KTVHCHTTPURL_Vaule_RequestType_Ping= @"ping";

@interface KTVHCHTTPURL ()

@property (nonatomic, assign) KTVHCHTTPURLType type;
@property (nonatomic, copy) NSString * originalURLString;

@end

@implementation KTVHCHTTPURL

- (instancetype)initForPing
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.type = KTVHCHTTPURLTypePing;
        self.originalURLString = @"KTVHCHTTPURLPingResponseFile";
        KTVHCLogHTTPURL(@"%p, Ping URL\n%@", self, self.originalURLString);
    }
    return self;
}

- (instancetype)initWithServerURIString:(NSString *)serverURIString
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        NSRange requestTypeRange = [serverURIString rangeOfString:[NSString stringWithFormat:@"%@=", KTVHCHTTPURL_Key_RequestType]];
        if (requestTypeRange.location != NSNotFound)
        {
            NSString * valueString = [serverURIString substringFromIndex:requestTypeRange.location];
            NSCharacterSet * delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
            NSScanner * scanner = [[NSScanner alloc] initWithString:valueString];
            while (![scanner isAtEnd])
            {
                NSString * pairString = nil;
                [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
                [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
                NSArray <NSString *> * pair = [pairString componentsSeparatedByString:@"="];
                if (pair.count == 2)
                {
                    NSString * key = pair.firstObject;
                    NSString * value = pair.lastObject;
                    if ([key isEqualToString:KTVHCHTTPURL_Key_OriginalURL])
                    {
                        self.originalURLString = [[KTVHCURLTools URLDecode:value] copy];
                    }
                    else if ([key isEqualToString:KTVHCHTTPURL_Key_RequestType])
                    {
                        if ([value isEqualToString:KTVHCHTTPURL_Vaule_RequestType_Ping])
                        {
                            self.type = KTVHCHTTPURLTypePing;
                        }
                        else if ([value isEqualToString:KTVHCHTTPURL_Vaule_RequestType_Content])
                        {
                            self.type = KTVHCHTTPURLTypeContent;
                        }
                    }
                }
            }
        }
        KTVHCLogHTTPURL(@"%p, Server URI\n%@\n%@", self, serverURIString, self.originalURLString);
    }
    return self;
}

- (instancetype)initWithOriginalURLString:(NSString *)originalURLString
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.type = KTVHCHTTPURLTypeContent;
        self.originalURLString = [originalURLString copy];
        KTVHCLogHTTPURL(@"%p, Content URL\n%@", self, self.originalURLString);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSURL *)proxyURLWithServerPort:(NSInteger)serverPort
{
    NSString * proxyURLString = [self proxyURLStringWithServerPort:serverPort];
    return [NSURL URLWithString:proxyURLString];
}

- (NSString *)proxyURLStringWithServerPort:(NSInteger)serverPort
{
    NSString * pathExtension = [NSURL URLWithString:self.originalURLString].pathExtension;
    if (pathExtension.length)
    {
        pathExtension = [NSString stringWithFormat:@".%@", pathExtension];
    }
    NSString * requestType = KTVHCHTTPURL_Vaule_RequestType_Content;
    switch (self.type) {
        case KTVHCHTTPURLTypePing:
            requestType = KTVHCHTTPURL_Vaule_RequestType_Ping;
            break;
        default:
            break;
    }
    NSMutableString * mutableString = [NSMutableString stringWithFormat:@"http://%@:%d/request%@?%@=%@",
                                       KTVHCHTTPURL_Domain,
                                       (int)serverPort,
                                       pathExtension ? pathExtension : @"",
                                       KTVHCHTTPURL_Key_RequestType,
                                       requestType];
    NSDictionary <NSString *, id> * params = @{KTVHCHTTPURL_Key_OriginalURL : [KTVHCURLTools URLEncode:self.originalURLString]};
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [mutableString appendString:[NSString stringWithFormat:@"&%@=%@", key, obj]];
    }];
    NSString * result = [mutableString copy];
    KTVHCLogHTTPURL(@"%p, Proxy URL\n%@", self, result);
    return result;
}

@end
