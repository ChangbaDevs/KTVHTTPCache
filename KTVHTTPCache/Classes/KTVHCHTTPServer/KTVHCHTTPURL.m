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
static NSString * const KTVHCHTTPURL_Placeholder_Param = @"placeholder=single";


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
        
        NSRange range = [URIString rangeOfString:[NSString stringWithFormat:@"%@&", KTVHCHTTPURL_Placeholder_Param]];
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
        
        KTVHCLogHTTPURL(@"URI, %@, original url, %@", URIString, _originalURLString);
    }
    return self;
}

- (instancetype)initWithOriginalURLString:(NSString *)originalURLString
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        _originalURLString = [originalURLString copy];
        
        KTVHCLogHTTPURL(@"original url, %@", _originalURLString);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (NSString *)proxyURLString
{
    NSString * lastPathComponent = [NSURL URLWithString:self.originalURLString].lastPathComponent;
    NSMutableString * mutableString = [NSMutableString stringWithFormat:@"http://localhost:%ld/request-%@?%@",
                                       self.listeningPort,
                                       lastPathComponent,
                                       KTVHCHTTPURL_Placeholder_Param];
    
    NSDictionary <NSString *, id> * params = @{KTVHCHTTPURL_KEY_originalURL : [KTVHCURLTools URLEncode:self.originalURLString]};
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [mutableString appendString:[NSString stringWithFormat:@"&%@=%@", key, obj]];
    }];
    
    NSString * result = [mutableString copy];
    
    KTVHCLogHTTPURL(@"proxy url, %@", result);
    
    return result;
}

- (NSInteger)listeningPort
{
    return [KTVHCHTTPServer server].listeningPort;
}


@end
