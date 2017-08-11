//
//  KTVHCDataSourceProtocol.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KTVHCDataSourceProtocol;
@protocol KTVHCDataSourceDelegate;

@protocol KTVHCDataSourceDelegate <NSObject>

- (void)sourceDidFinishRead:(id<KTVHCDataSourceProtocol>)source;

@end

@protocol KTVHCDataSourceProtocol <NSObject>

@property (nonatomic, weak) id <KTVHCDataSourceDelegate> delegate;

@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign, readonly) NSInteger size;

@end
