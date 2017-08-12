//
//  KTVHCPathTools.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCPathTools : NSObject

+ (NSString *)pathForArchiver;
+ (NSString *)pathForInsertBasePath:(NSString *)path;
+ (NSString *)pathWithURLString:(NSString *)string offset:(NSInteger)offset;

+ (NSInteger)sizeOfItemAtFilePath:(NSString *)filePath;

@end
