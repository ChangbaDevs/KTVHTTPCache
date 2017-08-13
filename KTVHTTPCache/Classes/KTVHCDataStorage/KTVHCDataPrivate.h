//
//  KTVHCDataReaderPrivate.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"
#import "KTVHCDataRequest.h"

@class KTVHCDataUnit;
@class KTVHCDataReader;


#pragma mark - KTVHCDataReader

@protocol KTVHCDataReaderWorkingDelegate <NSObject>

@optional
- (void)readerDidStartWorking:(KTVHCDataReader *)reader;
- (void)readerDidStopWorking:(KTVHCDataReader *)reader;

@end

@interface KTVHCDataReader (Private)

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit
                       request:(KTVHCDataRequest *)request
               workingDelegate:(id <KTVHCDataReaderWorkingDelegate>)workingDelegate;

@property (nonatomic, weak, readonly) id <KTVHCDataReaderWorkingDelegate> workingDelegate;

@property (nonatomic, strong, readonly) KTVHCDataUnit * unit;

@end


#pragma mark - KTVHCDataRequest

static long long const KTVHCDataRequestRangeMinVaule = 0;
static long long const KTVHCDataRequestRangeMaxVaule = -1;

@interface KTVHCDataRequest (Private)

@property (nonatomic, assign, readonly) long long rangeMin;     // default is KTVHCDataRequestRangeMinVaule.
@property (nonatomic, assign, readonly) long long rangeMax;     // default is KTVHCDataRequestRangeMaxVaule.

@end
