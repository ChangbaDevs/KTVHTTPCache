//
//  KTVHCHTTPConnection.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCHTTPHeader.h"
@interface HTTPFileResponse : NSObject
@property (nonatomic,strong) NSURL * fileUrl;
@end
@interface KTVHCHTTPConnection : HTTPConnection

@end
