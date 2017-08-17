//
//  KTVHCLog.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Log Enable Config
 */

// HTTP Server

#define KTVHCLogHTTPServerEnable            YES
#define KTVHCLogHTTPConnectionEnable        YES
#define KTVHCLogHTTPRequestEnable           YES
#define KTVHCLogHTTPResponseEnable          YES
#define KTVHCLogHTTPURLEnable               YES

// Data Storage

#define KTVHCLogDataStorageEnable           YES
#define KTVHCLogDataRequestEnable           YES
#define KTVHCLogDataReaderEnable            YES

#define KTVHCLogDataUnitEnable              YES
#define KTVHCLogDataUnitItemEnable          YES
#define KTVHCLogDataUnitPoolEnable          YES
#define KTVHCLogDataUnitQueueEnable         YES

#define KTVHCLogDataSourcerEnable           YES
#define KTVHCLogDataSourceQueueEnable       YES
#define KTVHCLogDataFileSourceEnable        YES
#define KTVHCLogDataNetworkSourceEnable     YES
#define KTVHCLogDataDownloadEnable          YES

// Alloc & Dealloc

#define KTVHCLogAllocEnable                 NO
#define KTVHCLogDeallocEnable               NO


/**
 *  Log
 */

#if DEBUG
#define KTVHCLog(target, enable, ...)       if (enable && [KTVHCLog logEnable]) {NSLog(@"%@ : %@", target, [NSString stringWithFormat:__VA_ARGS__]);}
#else
#define KTVHCLog(target, enable, ...)
#endif

// HTTP Server

#define KTVHCLogHTTPServer(...)             KTVHCLog(@"KTVHCHTTPServer",        KTVHCLogHTTPServerEnable,        ##__VA_ARGS__)
#define KTVHCLogHTTPConnection(...)         KTVHCLog(@"KTVHCHTTPConnection",    KTVHCLogHTTPConnectionEnable,    ##__VA_ARGS__)
#define KTVHCLogHTTPRequest(...)            KTVHCLog(@"KTVHCHTTPRequest",       KTVHCLogHTTPRequestEnable,       ##__VA_ARGS__)
#define KTVHCLogHTTPResponse(...)           KTVHCLog(@"KTVHCHTTPResponse",      KTVHCLogHTTPResponseEnable,      ##__VA_ARGS__)
#define KTVHCLogHTTPURL(...)                KTVHCLog(@"KTVHCHTTPURL",           KTVHCLogHTTPURLEnable,           ##__VA_ARGS__)

// Data Storage

#define KTVHCLogDataStorage(...)            KTVHCLog(@"KTVHCDataStorage",       KTVHCLogDataStorageEnable,       ##__VA_ARGS__)
#define KTVHCLogDataRequest(...)            KTVHCLog(@"KTVHCDataRequest",       KTVHCLogDataRequestEnable,       ##__VA_ARGS__)
#define KTVHCLogDataReader(...)             KTVHCLog(@"KTVHCDataReader",        KTVHCLogDataReaderEnable,        ##__VA_ARGS__)

#define KTVHCLogDataUnit(...)               KTVHCLog(@"KTVHCDataUnit",          KTVHCLogDataUnitEnable,          ##__VA_ARGS__)
#define KTVHCLogDataUnitItem(...)           KTVHCLog(@"KTVHCDataUnitItem",      KTVHCLogDataUnitItemEnable,      ##__VA_ARGS__)
#define KTVHCLogDataUnitPool(...)           KTVHCLog(@"KTVHCDataUnitPool",      KTVHCLogDataUnitPoolEnable,      ##__VA_ARGS__)
#define KTVHCLogDataUnitQueue(...)          KTVHCLog(@"KTVHCDataUnitQueue",     KTVHCLogDataUnitQueueEnable,     ##__VA_ARGS__)

#define KTVHCLogDataSourcer(...)            KTVHCLog(@"KTVHCDataSourcer",       KTVHCLogDataSourcerEnable,       ##__VA_ARGS__)
#define KTVHCLogDataSourceQueue(...)        KTVHCLog(@"KTVHCDataSourceQueue",   KTVHCLogDataSourceQueueEnable,   ##__VA_ARGS__)
#define KTVHCLogDataFileSource(...)         KTVHCLog(@"KTVHCDataFileSource",    KTVHCLogDataFileSourceEnable,    ##__VA_ARGS__)
#define KTVHCLogDataNetworkSource(...)      KTVHCLog(@"KTVHCDataNetworkSource", KTVHCLogDataNetworkSourceEnable, ##__VA_ARGS__)
#define KTVHCLogDataDownload(...)           KTVHCLog(@"KTVHCDataDownload",      KTVHCLogDataDownloadEnable,      ##__VA_ARGS__)

// Alloc & Dealloc

#define KTVHCLogAlloc(obj)                  KTVHCLog(obj, KTVHCLogAllocEnable,   @"alloc")
#define KTVHCLogDealloc(obj)                KTVHCLog(obj, KTVHCLogDeallocEnable, @"dealloc")


@interface KTVHCLog : NSObject

+ (void)setLogEnable:(BOOL)enable;
+ (BOOL)logEnable;                          // default is NO.

@end
