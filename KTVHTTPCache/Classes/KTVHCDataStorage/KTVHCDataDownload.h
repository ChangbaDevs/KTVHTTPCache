//
//  KTVHCDataDownload.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataDownload;

@protocol KTVHCDataDownloadDelegate <NSObject>

- (void)download:(KTVHCDataDownload *)download didCompleteWithError:(NSError *)error;
- (BOOL)download:(KTVHCDataDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)download:(KTVHCDataDownload *)download didReceiveData:(NSData *)data;

@end

@interface KTVHCDataDownload : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)download;

- (void)downloadWithRequest:(NSURLRequest *)request delegate:(id<KTVHCDataDownloadDelegate>)delegate;

@end
