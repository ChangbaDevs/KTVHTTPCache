//
//  KTVHCHLSTool.m
//  KTVHTTPCache
//
//  Created by Single on 2025/6/27.
//  Copyright © 2025年 Single. All rights reserved.
//

#import "KTVHCHLSTool.h"

@interface KTVHCHLSTool ()

@end

@implementation KTVHCHLSTool

+ (instancetype)tool
{
    static KTVHCHLSTool *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (NSString *)handleContent:(NSString *)content
{
    if (self.contentHandler) {
        return self.contentHandler(content);
    }
    if ([content containsString:@"\nhttp"]) {
        NSMutableArray *array = [content componentsSeparatedByString:@"\n"].mutableCopy;
        for (NSUInteger index = 0; index < array.count; index++) {
            NSString *line = array[index];
            if ([line hasPrefix:@"http"]) {
                line = [@"./" stringByAppendingString:line];
                [array replaceObjectAtIndex:index withObject:line];
            }
        }
        content = [array componentsJoinedByString:@"\n"];
    }
    return content;
}

@end
