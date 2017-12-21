#import "HTTPMessage.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


@implementation HTTPMessage

- (id)initEmptyRequest
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateEmpty(NULL, YES);
	}
	return self;
}

- (id)initRequestWithMethod:(NSString *)method URL:(NSURL *)url version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateRequest(NULL,
		                                    (__bridge CFStringRef)method,
		                                    (__bridge CFURLRef)url,
		                                    (__bridge CFStringRef)version);
	}
	return self;
}

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateResponse(NULL,
		                                      (CFIndex)code,
		                                      (__bridge CFStringRef)description,
		                                      (__bridge CFStringRef)version);
	}
	return self;
}

- (void)dealloc
{
	if (message)
	{
		CFRelease(message);
	}
}

- (BOOL)appendData:(NSData *)data
{
	return CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
}

- (BOOL)isHeaderComplete
{
	return CFHTTPMessageIsHeaderComplete(message);
}

- (NSString *)version
{
    CFStringRef versionRef = CFHTTPMessageCopyVersion(message);
    NSString *version = (__bridge NSString *)versionRef;
    if (versionRef) {
        CFRelease(versionRef);
    }
    return version;
}

- (NSString *)method
{
    CFStringRef methodRef = CFHTTPMessageCopyRequestMethod(message);
    NSString *method = (__bridge NSString *)methodRef;
    if (methodRef) {
        CFRelease(methodRef);
    }
    return method;
}

- (NSURL *)url
{
    CFURLRef urlRef = CFHTTPMessageCopyRequestURL(message);
    NSURL *url = (__bridge NSURL *)urlRef;
    if (urlRef) {
        CFRelease(urlRef);
    }
    return url;
}

- (NSInteger)statusCode
{
	return (NSInteger)CFHTTPMessageGetResponseStatusCode(message);
}

- (NSDictionary *)allHeaderFields
{
    CFDictionaryRef dictionaryRef = CFHTTPMessageCopyAllHeaderFields(message);
    NSDictionary *dictionary= (__bridge NSDictionary *)dictionaryRef;
    if (dictionaryRef) {
        CFRelease(dictionaryRef);
    }
    return dictionary;
}

- (NSString *)headerField:(NSString *)headerField
{
    CFStringRef headerRef = CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef)headerField);
    NSString *header = (__bridge NSString *)headerRef;
    if (headerRef) {
        CFRelease(headerRef);
    }
    return header;
}

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue
{
	CFHTTPMessageSetHeaderFieldValue(message,
	                                 (__bridge CFStringRef)headerField,
	                                 (__bridge CFStringRef)headerFieldValue);
}

- (NSData *)messageData
{
    CFDataRef dataRef = CFHTTPMessageCopySerializedMessage(message);
    NSData *data = (__bridge NSData *)dataRef;
    if (dataRef) {
        CFRelease(dataRef);
    }
    return data;
}

- (NSData *)body
{
    CFDataRef bodyRef = CFHTTPMessageCopyBody(message);
    NSData *body = (__bridge NSData *)bodyRef;
    if (bodyRef) {
        CFRelease(bodyRef);
    }
    return body;
}

- (void)setBody:(NSData *)body
{
	CFHTTPMessageSetBody(message, (__bridge CFDataRef)body);
}

@end
