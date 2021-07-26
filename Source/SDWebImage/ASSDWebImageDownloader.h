//
//  ASSDWebImageDownloader.h
//  ASNetworkImageNode-Extension
//
//  Created by 吴哲 on 2021/7/23.
//  Copyright © 2021 arcangelw. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<AsyncDisplayKit/ASImageProtocols.h>) && __has_include(<AsyncDisplayKit/ASNetworkImageNode.h>)
#import <AsyncDisplayKit/ASImageProtocols.h>
#import <AsyncDisplayKit/ASNetworkImageNode.h>
#else
#import "ASImageProtocols.h"
#import "ASNetworkImageNode.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class SDWebImageManager;

@interface ASSDWebImageDownloader : NSObject<ASImageCacheProtocol, ASImageDownloaderProtocol>

+ (instancetype)sharedDownloader NS_RETURNS_RETAINED;


+ (void)setPreconfiguredSDWebImageManager:(SDWebImageManager *)preconfiguredSDWebImageManager;

- (SDWebImageManager *)sharedSDWebImageManager;

@end

@interface ASNetworkImageNode (ASSDWebImageDownloader)
+ (instancetype)sd_networkImageNode;
@end

NS_ASSUME_NONNULL_END
