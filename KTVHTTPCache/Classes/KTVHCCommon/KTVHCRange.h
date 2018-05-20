//
//  KTVHCRange.h
//  KTVHTTPCache
//
//  Created by Single on 2018/5/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct KTVHCRange {
    long long start;
    long long end;
} KTVHCRange;

static const NSInteger KTVHCNotFound = LONG_LONG_MAX;

BOOL KTVHCRangeIsVaild(KTVHCRange range);
BOOL KTVHCRangeIsInvaild(KTVHCRange range);
BOOL KTVHCEqualRanges(KTVHCRange range1, KTVHCRange range2);
long long KTVHCRangeGetLength(KTVHCRange range);
NSString * KTVHCStringFromRange(KTVHCRange range);
NSDictionary * KTVHCRangeFillToHeaders(KTVHCRange range, NSDictionary * headers);

KTVHCRange KTVHCMakeRange(long long start, long long end);
KTVHCRange KTVHCRangeZero(void);
KTVHCRange KTVHCRangeInvaild(void);
KTVHCRange KTVHCRangeWithHeaderValue(NSString * value);
KTVHCRange KTVHCRangeWithEnsureLength(KTVHCRange range, NSUInteger ensureLength);
