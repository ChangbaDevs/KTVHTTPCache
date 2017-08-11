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

- (void)reaaderPrepareDidSuccess:(KTVHCDataReader *)reader;
- (void)reaaderPrepareDidFailure:(KTVHCDataReader *)reader;

@end

@interface KTVHCDataReader : NSObject

@property (nonatomic, weak) id <KTVHCDataReaderDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL didPrepare;

@property (nonatomic, assign, readonly) NSInteger contentSize;

- (void)prepare;
- (void)start;

@end
