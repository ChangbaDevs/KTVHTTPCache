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

@interface KTVHCDataReader (Private)

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit request:(KTVHCDataRequest *)request;

@end

static NSInteger const KTVHCDataRequestRangeMinVaule = 0;
static NSInteger const KTVHCDataRequestRangeMaxVaule = -1;

@interface KTVHCDataRequest (Private)

@property (nonatomic, assign, readonly) NSInteger rangeMin;     // default is KTVHCDataRequestRangeMinVaule.
@property (nonatomic, assign, readonly) NSInteger rangeMax;     // default is KTVHCDataRequestRangeMaxVaule.

@end
