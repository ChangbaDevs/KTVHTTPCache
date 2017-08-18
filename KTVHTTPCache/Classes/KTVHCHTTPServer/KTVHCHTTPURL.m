//
//  KTVHCHTTPURL.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPURL.h"
#import "KTVHCHTTPServer.h"
#import "KTVHCURLTools.h"
#import "KTVHCLog.h"


static NSString * const KTVHCHTTPURL_KEY_originalURL = @"originalURL";


@implementation KTVHCHTTPURL


+ (KTVHCHTTPURL *)URLWithURIString:(NSString *)URIString
{
    return [[self alloc] initWithURIString:URIString];
}

+ (KTVHCHTTPURL *)URLWithOriginalURLString:(NSString *)originalURLString
{
    return [[self alloc] initWithOriginalURLString:originalURLString];
}

- (instancetype)initWithURIString:(NSString *)URIString
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        NSRange range = [URIString rangeOfString:@"/request?"];
        if (range.location != NSNotFound)
        {
            URIString = [URIString substringFromIndex:range.location + range.length];
            
            NSCharacterSet * delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
            NSScanner * scanner = [[NSScanner alloc] initWithString:URIString];
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
                    
                    if ([key isEqualToString:KTVHCHTTPURL_KEY_originalURL])
                    {
                        _originalURLString = [[KTVHCURLTools URLDecode:value] copy];
                    }
                }
            }
        }
    }
    return self;
}

- (instancetype)initWithOriginalURLString:(NSString *)originalURLString
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _originalURLString = [originalURLString copy];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (NSString *)proxyURLString
{
    NSDictionary <NSString *, id> * params = @{KTVHCHTTPURL_KEY_originalURL : [KTVHCURLTools URLEncode:self.originalURLString]};
    
    NSMutableString * mutableString = [NSMutableString stringWithFormat:@"http://localhost:%ld/request?", self.listeningPort];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [mutableString appendString:[NSString stringWithFormat:@"%@=%@&", key, obj]];
    }];
    
    NSString * result = [mutableString substringToIndex:mutableString.length - 1];
    
    KTVHCLogHTTPURL(@"proxy url, %@", result);
    
    return result;
}

- (NSInteger)listeningPort
{
    return [KTVHCHTTPServer server].listeningPort;
}


@end
