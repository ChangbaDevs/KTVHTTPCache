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

// Download

#define KTVHCLogDownloadEnable          YES

// Alloc & Dealloc

#define KTVHCLogAllocEnable                 NO
#define KTVHCLogDeallocEnable               NO


/**
 *  Log
 */

#if DEBUG

#define KTVHCLogging(target, enable, ...)                                                \
if (enable && [KTVHCLog log].logEnable)                                                  \
{                                                                                        \
    NSString * va_args = [NSString stringWithFormat:__VA_ARGS__];                        \
    NSString * log = [NSString stringWithFormat:@"%@  :   %@", target, va_args];         \
    NSLog(@"%@", log);                                                                   \
}

#else

#define KTVHCLogging(target, enable, ...)

#endif

// HTTP Server

#define KTVHCLogHTTPServer(...)             KTVHCLogging(@"KTVHCHTTPServer       ", KTVHCLogHTTPServerEnable,        ##__VA_ARGS__)
#define KTVHCLogHTTPConnection(...)         KTVHCLogging(@"KTVHCHTTPConnection   ", KTVHCLogHTTPConnectionEnable,    ##__VA_ARGS__)
#define KTVHCLogHTTPRequest(...)            KTVHCLogging(@"KTVHCHTTPRequest      ", KTVHCLogHTTPRequestEnable,       ##__VA_ARGS__)
#define KTVHCLogHTTPResponse(...)           KTVHCLogging(@"KTVHCHTTPResponse     ", KTVHCLogHTTPResponseEnable,      ##__VA_ARGS__)
#define KTVHCLogHTTPURL(...)                KTVHCLogging(@"KTVHCHTTPURL          ", KTVHCLogHTTPURLEnable,           ##__VA_ARGS__)

// Data Storage

#define KTVHCLogDataStorage(...)            KTVHCLogging(@"KTVHCDataStorage      ", KTVHCLogDataStorageEnable,       ##__VA_ARGS__)
#define KTVHCLogDataRequest(...)            KTVHCLogging(@"KTVHCDataRequest      ", KTVHCLogDataRequestEnable,       ##__VA_ARGS__)
#define KTVHCLogDataReader(...)             KTVHCLogging(@"KTVHCDataReader       ", KTVHCLogDataReaderEnable,        ##__VA_ARGS__)

#define KTVHCLogDataUnit(...)               KTVHCLogging(@"KTVHCDataUnit         ", KTVHCLogDataUnitEnable,          ##__VA_ARGS__)
#define KTVHCLogDataUnitItem(...)           KTVHCLogging(@"KTVHCDataUnitItem     ", KTVHCLogDataUnitItemEnable,      ##__VA_ARGS__)
#define KTVHCLogDataUnitPool(...)           KTVHCLogging(@"KTVHCDataUnitPool     ", KTVHCLogDataUnitPoolEnable,      ##__VA_ARGS__)
#define KTVHCLogDataUnitQueue(...)          KTVHCLogging(@"KTVHCDataUnitQueue    ", KTVHCLogDataUnitQueueEnable,     ##__VA_ARGS__)

#define KTVHCLogDataSourcer(...)            KTVHCLogging(@"KTVHCDataSourcer      ", KTVHCLogDataSourcerEnable,       ##__VA_ARGS__)
#define KTVHCLogDataSourceQueue(...)        KTVHCLogging(@"KTVHCDataSourceQueue  ", KTVHCLogDataSourceQueueEnable,   ##__VA_ARGS__)
#define KTVHCLogDataFileSource(...)         KTVHCLogging(@"KTVHCDataFileSource   ", KTVHCLogDataFileSourceEnable,    ##__VA_ARGS__)
#define KTVHCLogDataNetworkSource(...)      KTVHCLogging(@"KTVHCDataNetworkSource", KTVHCLogDataNetworkSourceEnable, ##__VA_ARGS__)

// Download

#define KTVHCLogDownload(...)               KTVHCLogging(@"KTVHCDownload         ", KTVHCLogDownloadEnable,          ##__VA_ARGS__)

// Alloc & Dealloc

#define KTVHCLogAlloc(obj)                  KTVHCLogging(obj, KTVHCLogAllocEnable,   @"alloc")
#define KTVHCLogDealloc(obj)                KTVHCLogging(obj, KTVHCLogDeallocEnable, @"dealloc")


@interface KTVHCLog : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)log;

@property (nonatomic, assign) BOOL logEnable;       // default is NO.


@end
