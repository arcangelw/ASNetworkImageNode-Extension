//
//  ASSDWebImageDownloader.m
//  ASNetworkImageNode-Extension
//
//  Created by 吴哲 on 2021/7/23.
//  Copyright © 2021 arcangelw. All rights reserved.
//

#import "ASSDWebImageDownloader.h"
#if __has_include(<AsyncDisplayKit/ASThread.h>) && __has_include(<AsyncDisplayKit/ASImageContainerProtocolCategories.h>)
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASImageContainerProtocolCategories.h>
#else
#import "ASThread.h"
#import "ASImageContainerProtocolCategories.h"
#endif
#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/SDAnimatedImage.h>
#import <SDWebImage/UIImage+Metadata.h>
#else
#import "SDWebImageManager.h"
#import "SDImageCache.h"
#import "SDWebImageDownloader.h"
#import "SDAnimatedImage.h"
#import "UIImage+Metadata.h"
#endif
#import "objc/runtime.h"

static inline SDWebImageOptions SDWebImageOptionsWithASImageDownloaderPriority(ASImageDownloaderPriority priority) {
  switch (priority) {
    case ASImageDownloaderPriorityPreload:
      return SDWebImageLowPriority;

    case ASImageDownloaderPriorityImminent:
      return kNilOptions;

    case ASImageDownloaderPriorityVisible:
      return SDWebImageHighPriority;
  }
}

#pragma mark - container
@class ASSDAnimatedImage;
@interface ASSDWebImageContainer : NSObject
@property (nonatomic, nullable, weak) id<SDWebImageOperation> operation;
@property (nonatomic, nullable, weak) ASSDAnimatedImage *animatedImage;
@end
@implementation ASSDWebImageContainer
@end

@interface NSData (ASSDWebImageDownloader)
@property(nonatomic, nullable, strong, readonly) ASSDWebImageContainer *asdk_sd_container;
@end
@implementation NSData (ASSDWebImageDownloader)
- (ASSDWebImageContainer *)asdk_sd_container
{
    ASSDWebImageContainer *container = objc_getAssociatedObject(self, _cmd);
    if (!container) {
        container = [ASSDWebImageContainer new];
        objc_setAssociatedObject(self, _cmd, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return  container;;
}
@end

@interface ASSDAnimatedImage : SDAnimatedImage <ASAnimatedImageProtocol>
@property (nonatomic, readwrite) CFTimeInterval totalDuration;
@end
@implementation ASSDAnimatedImage
@synthesize playbackReadyCallback = _playbackReadyCallback;
@synthesize totalDuration = _totalDuration;

- (NSData *)asdk_animatedImageData
{
    self.animatedImageData.asdk_sd_container.animatedImage = self;
    return self.animatedImageData;
}

- (BOOL)isDataSupported:(NSData *)data
{
  return self.animatedImageData == data;
}

- (UIImage *)coverImage
{
    return [self animatedImageFrameAtIndex:0];
}

- (BOOL)coverImageReady
{
    return self.isAllFramesLoaded;
}

- (NSUInteger)frameInterval
{
    return MAX(self.minimumFrameInterval * [self maximumFramesPerSecond], 1);
}

//Credit to FLAnimatedImage ( https://github.com/Flipboard/FLAnimatedImage ) for display link interval calculations
- (NSTimeInterval)minimumFrameInterval
{
    static dispatch_once_t onceToken;
    static NSTimeInterval kGreatestCommonDivisorPrecision;
    dispatch_once(&onceToken, ^{
        kGreatestCommonDivisorPrecision = 2.0 / (1.0 / [self maximumFramesPerSecond]);
    });
    
    // Scales the frame delays by `kGreatestCommonDivisorPrecision`
    // then converts it to an UInteger for in order to calculate the GCD.
    NSUInteger scaledGCD = lrint([self durationAtIndex:0] * kGreatestCommonDivisorPrecision);
    for (NSUInteger durationIdx = 1; durationIdx < self.frameCount; durationIdx++) {
        CFTimeInterval duration = [self durationAtIndex:durationIdx];
        scaledGCD = gcd(lrint(duration * kGreatestCommonDivisorPrecision), scaledGCD);
    }
    
    // Reverse to scale to get the value back into seconds.
    return (scaledGCD / kGreatestCommonDivisorPrecision);
}

// This likely isn't the most efficient but it's easy to reason about and we don't call it
// with super large numbers.
static NSUInteger gcd(NSUInteger a, NSUInteger b)
{
    // http://en.wikipedia.org/wiki/Greatest_common_divisor
    NSCAssert(a > 0 && b > 0, @"A and B must be greater than 0");
    
    while (a != b) {
        if (a > b) {
            a = a - b;
        } else {
            b = b - a;
        }
    }
    return a;
}

- (NSInteger)maximumFramesPerSecond
{
    static dispatch_once_t onceToken;
    static NSInteger maximumFramesPerSecond = 60;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 10.3, tvOS 10.3, *)) {
            maximumFramesPerSecond = 0;
            for (UIScreen *screen in [UIScreen screens]) {
                if ([screen maximumFramesPerSecond] > maximumFramesPerSecond) {
                    maximumFramesPerSecond = [screen maximumFramesPerSecond];
                }
            }
        }
    });
    return maximumFramesPerSecond;
}

- (size_t)loopCount
{
    return self.animatedImageLoopCount;
}

- (size_t)frameCount
{
    return self.animatedImageFrameCount;
}

- (BOOL)playbackReady
{
    return self.isAllFramesLoaded;
}

- (NSError *)error
{
    return nil;
}

- (CGImageRef)imageAtIndex:(NSUInteger)index
{
    return [self animatedImageFrameAtIndex:index].CGImage;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return [self animatedImageDurationAtIndex:index];
}

- (void)clearAnimatedImageCache
{
//    [self unloadAllFrames];
//    _totalDuration = -1.0;
}

- (void)preloadAllFrames
{
    [super preloadAllFrames];
    if (!self.isAllFramesLoaded) return;
    _totalDuration = 0.0;
    for (NSUInteger idx = 0; idx < self.animatedImageFrameCount; idx++) {
        _totalDuration += [self animatedImageDurationAtIndex:idx];
    }
    if (self.playbackReadyCallback) {
        self.playbackReadyCallback();
    }
}
@end

#pragma mark - SDWebImageManager
@interface ASSDImageCache : SDImageCache
@end
@implementation ASSDImageCache
@end

@interface ASSDImageDownloader : SDWebImageDownloader
@end
@implementation ASSDImageDownloader
@end

@interface ASSDWebImageManager : SDWebImageManager
@end
@implementation ASSDWebImageManager

+ (id<SDImageCache>)defaultImageCache
{
    static id<SDImageCache> imageCache;
    static dispatch_once_t shared_init_imageCache;
    dispatch_once(&shared_init_imageCache, ^{
        imageCache = [ASSDImageCache new];
    });
    return imageCache;
}

+ (id<SDImageLoader>)defaultImageLoader
{
    static id<SDImageLoader> imageLoader;
    static dispatch_once_t shared_init_imageLoader;
    dispatch_once(&shared_init_imageLoader, ^{
        imageLoader = [ASSDImageDownloader new];
    });
    return imageLoader;
}

+ (SDWebImageManager *)sharedManager
{
    static ASSDWebImageManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    return sharedManager;
}
@end

static ASSDWebImageDownloader *downloader;
static SDWebImageManager *sharedSDWebImageManager;

@interface ASSDWebImageDownloader()
@end

@implementation ASSDWebImageDownloader

+ (instancetype)sharedDownloader
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[self class] new];
    });
    return downloader;
}


static dispatch_once_t shared_init_predicate;

+ (void)setPreconfiguredSDWebImageManager:(SDWebImageManager *)preconfiguredSDWebImageManager
{
    dispatch_once(&shared_init_predicate, ^{
        sharedSDWebImageManager = preconfiguredSDWebImageManager;
    });
}

- (SDWebImageManager *)sharedSDWebImageManager
{
    dispatch_once(&shared_init_predicate, ^{
        sharedSDWebImageManager = [ASSDWebImageManager sharedManager];
    });
    return sharedSDWebImageManager;
}

#pragma mark ASImageProtocols
- (void)cachedImageWithURL:(NSURL *)URL
             callbackQueue:(dispatch_queue_t)callbackQueue
                completion:(ASImageCacherCompletion)completion
{
    SDWebImageManager *manager = [self sharedSDWebImageManager];
    NSString *imageCacheKey = [manager cacheKeyForURL:URL];
    [manager.imageCache queryImageForKey:imageCacheKey
                                 options:SDWebImagePreloadAllFrames | SDWebImageRetryFailed
                                 context:@{
                                     SDWebImageContextAnimatedImageClass: ASSDAnimatedImage.class
                                 }
                              completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        [ASSDWebImageDownloader _performWithCallbackQueue:callbackQueue work:^{
            ASImageCacheType asCacheType = (cacheType == SDImageCacheTypeMemory ? ASImageCacheTypeSynchronous : ASImageCacheTypeAsynchronous);
            completion(image, asCacheType);
        }];
    }];
}

- (void)clearFetchedImageFromCacheWithURL:(NSURL *)URL
{
    SDWebImageManager *manager = [self sharedSDWebImageManager];
    NSString *imageCacheKey = [manager cacheKeyForURL:URL];
    [manager.imageCache removeImageForKey:imageCacheKey cacheType: SDImageCacheTypeAll completion:nil];
}

#pragma mark ASImageDownloaderProtocol
- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
    if (![downloadIdentifier isKindOfClass:[ASSDWebImageContainer class]]) return;
    id<SDWebImageOperation> operation = [(ASSDWebImageContainer *)downloadIdentifier operation];
    [operation cancel];
}

- (id)downloadImageWithURL:(NSURL *)URL
             callbackQueue:(dispatch_queue_t)callbackQueue
          downloadProgress:(ASImageDownloaderProgress)downloadProgress
                completion:(ASImageDownloaderCompletion)completion
{
  return [self downloadImageWithURL:URL
                           priority:ASImageDownloaderPriorityImminent // maps to default priority
                      callbackQueue:callbackQueue
                   downloadProgress:downloadProgress
                         completion:completion];
}

- (id)downloadImageWithURL:(NSURL *)URL
                  priority:(ASImageDownloaderPriority)priority
             callbackQueue:(dispatch_queue_t)callbackQueue
          downloadProgress:(ASImageDownloaderProgress)downloadProgress
                completion:(ASImageDownloaderCompletion)completion
{

    SDWebImageManager *manager = [self sharedSDWebImageManager];
    __block ASSDWebImageContainer *downloadIdentifier = [ASSDWebImageContainer new];
    SDWebImageOptions options = SDWebImageOptionsWithASImageDownloaderPriority(priority);
    options |= SDWebImagePreloadAllFrames;
    options |= SDWebImageRetryFailed;
    downloadIdentifier.operation = [manager loadImageWithURL:URL
      options:options context: @{
          SDWebImageContextAnimatedImageClass: ASSDAnimatedImage.class
      }
      progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        if (!downloadProgress || expectedSize < 0.0) return;;
        [ASSDWebImageDownloader _performWithCallbackQueue:callbackQueue work:^{
            downloadProgress((receivedSize * 1.0) / (expectedSize * 1.0));
        }];
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        [ASSDWebImageDownloader _performWithCallbackQueue:callbackQueue work:^{
            completion(image, error, downloadIdentifier, nil);
        }];
    }];
    return downloadIdentifier;
}

- (id<ASAnimatedImageProtocol>)animatedImageWithData:(NSData *)animatedImageData
{
    return animatedImageData.asdk_sd_container.animatedImage;
}

#pragma mark - Private

+ (void)_performWithCallbackQueue:(dispatch_queue_t)queue work:(void (^)(void))work
{
  if (work == nil) {
    // No need to assert here, really. We aren't expecting any feedback from this method.
    return;
  }

  if (ASDisplayNodeThreadIsMain() && queue == dispatch_get_main_queue()) {
    work();
  } else if (queue == nil) {
    ASDisplayNodeFailAssert(@"Callback queue should not be nil.");
    work();
  } else {
    dispatch_async(queue, work);
  }
}

@end

@implementation ASNetworkImageNode (ASSDWebImageDownloader)

+ (instancetype)sd_networkImageNode
{
    return [[[self class] alloc] initWithCache:ASSDWebImageDownloader.sharedDownloader downloader:ASSDWebImageDownloader.sharedDownloader];
}
@end
