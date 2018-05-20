//
//  KTVHCDataFunctions.h
//  KTVHTTPCache
//
//  Created by Single on 2018/5/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataRequest.h"
#import "KTVHCDataResponse.h"

KTVHCDataRequest * KTVHCCopyRequestIfNeeded(KTVHCDataRequest * request, KTVHCRange range);
KTVHCDataResponse * KTVHCCopyResponseIfNeeded(KTVHCDataResponse * response, KTVHCRange range, long long totalLength);
