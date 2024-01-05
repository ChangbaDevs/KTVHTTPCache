#import <Foundation/Foundation.h>
#import <KTVCocoaHTTPServer/KTVCocoaHTTPServer.h>


@interface HTTPDataResponse : NSObject <HTTPResponse>
{
	NSUInteger offset;
	NSData *data;
}

- (id)initWithData:(NSData *)data;

@end
