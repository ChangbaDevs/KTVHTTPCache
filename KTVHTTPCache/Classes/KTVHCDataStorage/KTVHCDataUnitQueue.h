//
//  KTVHCDataUnitQueue.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataUnit.h"


@interface KTVHCDataUnitQueue : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitQueueWithArchiverPath:(NSString *)archiverPath;

- (NSArray <KTVHCDataUnit *> *)allUnits;
- (KTVHCDataUnit *)unitWithUniqueIdentifier:(NSString *)uniqueIdentifier;

- (void)putUnit:(KTVHCDataUnit *)unit;
- (void)popUnit:(KTVHCDataUnit *)unit;

- (void)archive;


@end
