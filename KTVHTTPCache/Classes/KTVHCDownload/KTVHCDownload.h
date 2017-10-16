//
//  KTVHCDataDownload.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDownload;


@protocol KTVHCDownloadDelegate <NSObject>

- (void)download:(KTVHCDownload *)download didCompleteWithError:(NSError *)error;
- (BOOL)download:(KTVHCDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)download:(KTVHCDownload *)download didReceiveData:(NSData *)data;

@end


@interface KTVHCDownload : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)download;

@property (nonatomic, assign) NSTimeInterval timeoutInterval;       // default is 30.0s.
@property (nonatomic, copy) NSDictionary <NSString *, NSString *> * commonHeaderFields;      // default is nil.

- (NSURLSessionDataTask *)downloadWithRequest:(NSMutableURLRequest *)request delegate:(id<KTVHCDownloadDelegate>)delegate;


@end
