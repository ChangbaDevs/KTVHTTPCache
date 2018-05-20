//
//  KTVHCRange.m
//  KTVHTTPCache
//
//  Created by Single on 2018/5/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVHCRange.h"

BOOL KTVHCRangeIsVaild(KTVHCRange range)
{
    return !KTVHCRangeIsInvaild(range);
}

BOOL KTVHCRangeIsInvaild(KTVHCRange range)
{
    return range.start == KTVHCNotFound;
}

long long KTVHCRangeGetLength(KTVHCRange range)
{
    return range.end - range.start + 1;
}

NSString * KTVHCStringFromRange(KTVHCRange range)
{
    return [NSString stringWithFormat:@"Range : {%lld, %lld}", range.start, range.end];
}

KTVHCRange KTVHCMakeRange(long long start, long long end)
{
    KTVHCRange range = {start, end};
    return range;
}

KTVHCRange KTVHCRangeZero(void)
{
    return KTVHCMakeRange(0, 0);
}

KTVHCRange KTVHCRangeInvaild()
{
    return KTVHCMakeRange(KTVHCNotFound, KTVHCNotFound);
}

KTVHCRange KTVHCRangeWithHeaderValue(NSString * value)
{
    KTVHCRange range = KTVHCRangeInvaild();
    NSString * rangeHeader = value;
    if (rangeHeader) {
        if ([rangeHeader hasPrefix:@"bytes="]) {
            NSArray * components = [[rangeHeader substringFromIndex:6] componentsSeparatedByString:@","];
            if (components.count == 1) {
                components = [[components firstObject] componentsSeparatedByString:@"-"];
                if (components.count == 2) {
                    NSString * startString = [components objectAtIndex:0];
                    NSInteger startValue = [startString integerValue];
                    NSString * endString = [components objectAtIndex:1];
                    NSInteger endValue = [endString integerValue];
                    if (startString.length && (startValue >= 0)
                        && endString.length && (endValue >= startValue)) {
                        // The second 500 bytes: "500-999"
                        range.start = startValue;
                        range.end = endValue;
                    } else if (startString.length && (startValue >= 0)) {
                        // The bytes after 9500 bytes: "9500-"
                        range.start = startValue;
                        range.end = KTVHCNotFound;
                    } else if (endString.length && (endValue > 0)) {
                        // The final 500 bytes: "-500"
                        range.start = KTVHCNotFound;
                        range.end = endValue;
                    }
                }
            }
        }
    }
    return range;
}

KTVHCRange KTVHCRangeWithEnsureLength(KTVHCRange range, NSUInteger ensureLength)
{
    if (range.end == KTVHCNotFound && ensureLength > 0) {
        return KTVHCMakeRange(range.start, ensureLength - 1);
    }
    return range;
}
