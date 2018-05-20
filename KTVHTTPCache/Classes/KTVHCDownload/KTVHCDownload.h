//
//  KTVHCDataDownload.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataRequest.h"
#import "KTVHCDataResponse.h"

@class KTVHCDownload;

@protocol KTVHCDownloadDelegate <NSObject>

- (void)download:(KTVHCDownload *)download didCompleteWithError:(NSError *)error;
- (void)download:(KTVHCDownload *)download didReceiveResponse:(KTVHCDataResponse *)response;
- (void)download:(KTVHCDownload *)download didReceiveData:(NSData *)data;

@end

@interface KTVHCDownload : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)download;

@property (nonatomic, assign) NSTimeInterval timeoutInterval;       // default is 30.0s.
@property (nonatomic, copy) NSDictionary * commonHeaderFields;      // default is nil.

- (NSURLSessionTask *)downloadWithRequest:(KTVHCDataRequest *)request delegate:(id<KTVHCDownloadDelegate>)delegate;

@property (nonatomic, copy) BOOL (^contentTypeFilter)(NSString * URLString, NSString * contentType, NSArray <NSString *> * defaultAcceptContentTypes);

@end
