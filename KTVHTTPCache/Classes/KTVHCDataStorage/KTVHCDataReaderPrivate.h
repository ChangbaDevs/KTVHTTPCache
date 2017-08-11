//
//  KTVHCDataReaderPrivate.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"

@class KTVHCDataUnit;
@class KTVHCDataRequest;

@interface KTVHCDataReader (Private)

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit request:(KTVHCDataRequest *)request;

@end
