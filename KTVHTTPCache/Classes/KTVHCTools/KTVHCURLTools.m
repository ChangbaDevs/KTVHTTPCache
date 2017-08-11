//
//  KTVHCURLTools.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCURLTools.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation KTVHCURLTools

+ (NSString *)md5:(NSString *)URLString
{
    const char *value = [URLString UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}

static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

+ (NSString *)base64:(NSString *)URLString
{
    NSData * data = [URLString dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger length = data.length;
    
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;
    
    lentext = [data length];
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = [data bytes];
    ixtext = 0;
    
    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0)
            break;
        for (i = 0; i < 3; i++) {
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
        
        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }
    return result;
}

+ (NSString *)URLEncode:(NSString *)URLString
{
    URLString = [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger length = [URLString length];
    const char * c = [URLString UTF8String];
    
    NSString * resultString = @"";
    for(int i = 0; i < length; i++) {
        switch (*c) {
            case '/':
                resultString = [resultString stringByAppendingString:@"%2F"];
                break;
            case '\'':
                resultString = [resultString stringByAppendingString:@"%27"];
                break;
            case ';':
                resultString = [resultString stringByAppendingString:@"%3B"];
                break;
            case '?':
                resultString = [resultString stringByAppendingString:@"%3F"];
                break;
            case ':':
                resultString = [resultString stringByAppendingString:@"%3A"];
                break;
            case '@':
                resultString = [resultString stringByAppendingString:@"%40"];
                break;
            case '&':
                resultString = [resultString stringByAppendingString:@"%26"];
                break;
            case '=':
                resultString = [resultString stringByAppendingString:@"%3D"];
                break;
            case '+':
                resultString = [resultString stringByAppendingString:@"%2B"];
                break;
            case '$':
                resultString = [resultString stringByAppendingString:@"%24"];
                break;
            case ',':
                resultString = [resultString stringByAppendingString:@"%2C"];
                break;
            case '[':
                resultString = [resultString stringByAppendingString:@"%5B"];
                break;
            case ']':
                resultString = [resultString stringByAppendingString:@"%5D"];
                break;
            case '#':
                resultString = [resultString stringByAppendingString:@"%23"];
                break;
            case '!':
                resultString = [resultString stringByAppendingString:@"%21"];
                break;
            case '(':
                resultString = [resultString stringByAppendingString:@"%28"];
                break;
            case ')':
                resultString = [resultString stringByAppendingString:@"%29"];
                break;
            case '*':
                resultString = [resultString stringByAppendingString:@"%2A"];
                break;
            default:
                resultString = [resultString stringByAppendingFormat:@"%c", *c];
        }
        c++;
    }
    
    return resultString;
}

+ (NSString *)URLDecode:(NSString *)URLString
{
    return [URLString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
