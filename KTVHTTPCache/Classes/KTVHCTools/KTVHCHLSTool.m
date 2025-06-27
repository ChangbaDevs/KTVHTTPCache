//
//  KTVHCHLSTool.m
//  KTVHTTPCache
//
//  Created by Single on 2025/6/27.
//  Copyright © 2025年 Single. All rights reserved.
//

#import "KTVHCHLSTool.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDownload.h"
#import "KTVHCPathTool.h"

@interface KTVHCHLSTool ()

@property (nonatomic, strong) NSURLSession *session;

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
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 30;
        self.session = [NSURLSession sessionWithConfiguration:configuration];
    }
    return self;
}

- (NSString *)handleContent:(NSString *)content
{
    if (self.contentHandler) {
        return self.contentHandler(content);
    }
    if ([content containsString:@"\nhttp"]) {
        NSMutableArray *components = [content componentsSeparatedByString:@"\n"].mutableCopy;
        for (NSUInteger index = 0; index < components.count; index++) {
            NSString *line = components[index];
            if ([line hasPrefix:@"http"]) {
                line = [@"./" stringByAppendingString:line];
                [components replaceObjectAtIndex:index withObject:line];
            }
        }
        content = [components componentsJoinedByString:@"\n"];
    }
    return content;
}

- (NSArray<NSURL *> *)makeURLsForContent:(NSString *)content sourceURL:(NSURL *)sourceURL
{
    NSMutableArray<NSURL *> *URLs = [NSMutableArray array];
    NSArray *components = [content componentsSeparatedByString:@"\n"];
    for (NSString* obj in components) {
        NSString *line = [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![line hasPrefix:@"#"] && line.length > 0) {
            NSURL *URL = nil;
            if ([line hasPrefix:@"http"]) {
                URL = [NSURL URLWithString:line];
            } else if ([line hasPrefix:@"./http"]) {
                URL = [NSURL URLWithString:[line stringByReplacingOccurrencesOfString:@"./http" withString:@"http"]];
            } else {
                URL = [sourceURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:line];
            }
            [URLs addObject:URL];
        }
    }
    return URLs;
}

- (NSURLSessionDataTask *)taskWithURL:(NSURL *)URL completionHandler:(void (^)(NSData *, NSError *))completionHandler
{
    KTVHCDataRequest *dataRequest = [[KTVHCDataRequest alloc] initWithURL:URL headers:nil];
    NSURLRequest *request = [[KTVHCDownload download] requestWithDataRequest:dataRequest];
    return [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || data.length == 0) {
            completionHandler(nil, error);
        } else {
            KTVHCDataUnit *unit = [[KTVHCDataUnitPool pool] unitWithURL:URL];
            NSURL *completeURL = unit.completeURL;
            if (completeURL) {
                completionHandler([NSData dataWithContentsOfURL:completeURL], error);
            } else {
                NSString *src = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *dst = [[KTVHCHLSTool tool] handleContent:src];
                data = [dst dataUsingEncoding:NSUTF8StringEncoding];
                NSString *path = [KTVHCPathTool filePathWithURL:URL offset:0];
                if ([data writeToFile:path atomically:YES]) {
                    KTVHCDataUnitItem *unitItem = [[KTVHCDataUnitItem alloc] initWithPath:path offset:0];
                    [unitItem updateLength:data.length];
                    [unit insertUnitItem:unitItem];
                    [unit updateResponseHeaders:((NSHTTPURLResponse *)response).allHeaderFields totalLength:data.length];
                    completionHandler(data, error);
                } else {
                    completionHandler(nil, error);
                }
            }
            [unit workingRelease];
        }
    }];
}

@end
