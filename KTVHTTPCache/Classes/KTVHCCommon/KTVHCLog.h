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

#define KTVHCLogEnable(target, log_enable, record_enable)               \
static BOOL const KTVHCLog_##target##_LogEnable = log_enable;           \
static BOOL const KTVHCLog_##target##_RecordEnable = record_enable;

#define KTVHCLogEnableValueLog(target)          KTVHCLog_##target##_LogEnable
#define KTVHCLogEnableValueRecord(target)       KTVHCLog_##target##_RecordEnable

// HTTP Server

KTVHCLogEnable(HTTPServer,        YES, NO)
KTVHCLogEnable(HTTPConnection,    YES, NO)
KTVHCLogEnable(HTTPRequest,       YES, NO)
KTVHCLogEnable(HTTPResponse,      YES, NO)
KTVHCLogEnable(HTTPURL,           YES, NO)

// Data Storage

KTVHCLogEnable(DataStorage,       YES, NO)
KTVHCLogEnable(DataRequest,       YES, NO)
KTVHCLogEnable(DataReader,        YES, NO)

KTVHCLogEnable(DataUnit,          YES, NO)
KTVHCLogEnable(DataUnitItem,      YES, NO)
KTVHCLogEnable(DataUnitPool,      YES, NO)
KTVHCLogEnable(DataUnitQueue,     YES, NO)

KTVHCLogEnable(DataSourcer,       YES, NO)
KTVHCLogEnable(DataSourceQueue,   YES, NO)
KTVHCLogEnable(DataFileSource,    YES, NO)
KTVHCLogEnable(DataNetworkSource, YES, NO)

// Download

KTVHCLogEnable(Download,          YES, NO)

// Alloc & Dealloc

KTVHCLogEnable(Alloc,             YES, NO)
KTVHCLogEnable(Dealloc,           YES, NO)


/**
 *  Log
 */

#if DEBUG

#define KTVHCLogging(target, log_enable, record_enable, ...)                             \
if ([KTVHCLog log].logEnable && (log_enable || record_enable))                           \
{                                                                                        \
    NSString * va_args = [NSString stringWithFormat:__VA_ARGS__];                        \
    NSString * log = [NSString stringWithFormat:@"%@  :   %@", target, va_args];         \
    if (record_enable) {                                                                 \
        [[KTVHCLog log] recordLog:log];                                                  \
    }                                                                                    \
    if (log_enable) {                                                                    \
        NSLog(@"%@", log);                                                               \
    }                                                                                    \
}

#else

#define KTVHCLogging(target, log_enable, record_enable, ...)                             \
if ([KTVHCLog log].logEnable && record_enable)                                           \
{                                                                                        \
    NSString * va_args = [NSString stringWithFormat:__VA_ARGS__];                        \
    NSString * log = [NSString stringWithFormat:@"%@  :   %@", target, va_args];         \
    [[KTVHCLog log] recordLog:log];                                                      \
}

#endif

// HTTP Server

#define KTVHCLogHTTPServer(...)             KTVHCLogging(@"KTVHCHTTPServer       ", KTVHCLogEnableValueLog(HTTPServer),        KTVHCLogEnableValueRecord(HTTPServer),        ##__VA_ARGS__)
#define KTVHCLogHTTPConnection(...)         KTVHCLogging(@"KTVHCHTTPConnection   ", KTVHCLogEnableValueLog(HTTPConnection),    KTVHCLogEnableValueRecord(HTTPConnection),    ##__VA_ARGS__)
#define KTVHCLogHTTPRequest(...)            KTVHCLogging(@"KTVHCHTTPRequest      ", KTVHCLogEnableValueLog(HTTPRequest),       KTVHCLogEnableValueRecord(HTTPRequest),       ##__VA_ARGS__)
#define KTVHCLogHTTPResponse(...)           KTVHCLogging(@"KTVHCHTTPResponse     ", KTVHCLogEnableValueLog(HTTPResponse),      KTVHCLogEnableValueRecord(HTTPResponse),      ##__VA_ARGS__)
#define KTVHCLogHTTPURL(...)                KTVHCLogging(@"KTVHCHTTPURL          ", KTVHCLogEnableValueLog(HTTPURL),           KTVHCLogEnableValueRecord(HTTPURL),           ##__VA_ARGS__)

// Data Storage

#define KTVHCLogDataStorage(...)            KTVHCLogging(@"KTVHCDataStorage      ", KTVHCLogEnableValueLog(DataStorage),       KTVHCLogEnableValueRecord(DataStorage),       ##__VA_ARGS__)
#define KTVHCLogDataRequest(...)            KTVHCLogging(@"KTVHCDataRequest      ", KTVHCLogEnableValueLog(DataRequest),       KTVHCLogEnableValueRecord(DataRequest),       ##__VA_ARGS__)
#define KTVHCLogDataReader(...)             KTVHCLogging(@"KTVHCDataReader       ", KTVHCLogEnableValueLog(DataReader),        KTVHCLogEnableValueRecord(DataReader),        ##__VA_ARGS__)

#define KTVHCLogDataUnit(...)               KTVHCLogging(@"KTVHCDataUnit         ", KTVHCLogEnableValueLog(DataUnit),          KTVHCLogEnableValueRecord(DataUnit),          ##__VA_ARGS__)
#define KTVHCLogDataUnitItem(...)           KTVHCLogging(@"KTVHCDataUnitItem     ", KTVHCLogEnableValueLog(DataUnitItem),      KTVHCLogEnableValueRecord(DataUnitItem),      ##__VA_ARGS__)
#define KTVHCLogDataUnitPool(...)           KTVHCLogging(@"KTVHCDataUnitPool     ", KTVHCLogEnableValueLog(DataUnitPool),      KTVHCLogEnableValueRecord(DataUnitPool),      ##__VA_ARGS__)
#define KTVHCLogDataUnitQueue(...)          KTVHCLogging(@"KTVHCDataUnitQueue    ", KTVHCLogEnableValueLog(DataUnitQueue),     KTVHCLogEnableValueRecord(DataUnitQueue),     ##__VA_ARGS__)

#define KTVHCLogDataSourcer(...)            KTVHCLogging(@"KTVHCDataSourcer      ", KTVHCLogEnableValueLog(DataSourcer),       KTVHCLogEnableValueRecord(DataSourcer),       ##__VA_ARGS__)
#define KTVHCLogDataSourceQueue(...)        KTVHCLogging(@"KTVHCDataSourceQueue  ", KTVHCLogEnableValueLog(DataSourceQueue),   KTVHCLogEnableValueRecord(DataSourceQueue),   ##__VA_ARGS__)
#define KTVHCLogDataFileSource(...)         KTVHCLogging(@"KTVHCDataFileSource   ", KTVHCLogEnableValueLog(DataFileSource),    KTVHCLogEnableValueRecord(DataFileSource),    ##__VA_ARGS__)
#define KTVHCLogDataNetworkSource(...)      KTVHCLogging(@"KTVHCDataNetworkSource", KTVHCLogEnableValueLog(DataNetworkSource), KTVHCLogEnableValueRecord(DataNetworkSource), ##__VA_ARGS__)

// Download

#define KTVHCLogDownload(...)               KTVHCLogging(@"KTVHCDownload         ", KTVHCLogEnableValueLog(Download),          KTVHCLogEnableValueRecord(Download),          ##__VA_ARGS__)

// Alloc & Dealloc

#define KTVHCLogAlloc(obj)                  KTVHCLogging(obj, KTVHCLogEnableValueLog(Alloc),   KTVHCLogEnableValueRecord(Alloc),   @"alloc")
#define KTVHCLogDealloc(obj)                KTVHCLogging(obj, KTVHCLogEnableValueLog(Dealloc), KTVHCLogEnableValueRecord(Dealloc), @"dealloc")


@interface KTVHCLog : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)log;

/**
 *  DEBUG   : default is NO.
 *  RELEASE : default is YES.
 */
@property (nonatomic, assign) BOOL logEnable;
@property (nonatomic, copy, readonly) NSString * logFilePath;

- (void)recordLog:(NSString *)log;
- (void)deleteLog;


@end
