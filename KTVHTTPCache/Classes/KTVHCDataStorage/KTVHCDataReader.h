//
//  KTVHCDataReader.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataReader;

@protocol KTVHCDataReaderDelegate <NSObject>

- (void)reaaderDidFinishPrepare:(KTVHCDataReader *)reader;
- (void)reaader:(KTVHCDataReader *)reader didFailure:(NSError *)error;

@end

@interface KTVHCDataReader : NSObject

@property (nonatomic, weak) id <KTVHCDataReaderDelegate> delegate;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) BOOL didClose;
@property (nonatomic, assign, readonly) BOOL didFinishPrepare;
@property (nonatomic, assign, readonly) BOOL didFinishRead;

@property (nonatomic, assign, readonly) NSInteger currentContentLength;
@property (nonatomic, assign, readonly) NSInteger readedContentLength;
@property (nonatomic, assign, readonly) NSInteger totalContentLength;

- (void)prepare;
- (void)close;

- (NSData *)syncReadDataOfLength:(NSUInteger)length;

@end
