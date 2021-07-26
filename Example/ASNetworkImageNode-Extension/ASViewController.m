//
//  ASViewController.m
//  ASNetworkImageNode-Extension
//
//  Created by arcangelw on 07/23/2021.
//  Copyright (c) 2021 arcangelw. All rights reserved.
//

#import "ASViewController.h"

@interface ASImageCellNode : ASCellNode
@property (nonatomic, strong, nonnull) ASNetworkImageNode *imageNode;
@end
@implementation ASImageCellNode

- (instancetype)init
{
    self = [super init];
    if (self) {
        _imageNode = [ASNetworkImageNode sd_networkImageNode];
        _imageNode.contentMode = UIViewContentModeScaleAspectFit;
        _imageNode.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [self addSubnode:_imageNode];
        self.neverShowPlaceholders = YES;
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(5.0, 15.0, 5.0, 15.0) child:_imageNode];
}

@end

@interface ASViewController ()<ASCollectionDataSource, ASCollectionDelegate>
@property (nonnull, nonatomic, copy) NSArray<NSString *> *urls;
@end

@implementation ASViewController

- (NSArray<NSString *> *)urls
{
    if (!_urls) {
        _urls = @[
            @"https://pic.5tu.cn/uploads/allimg/1911/pic_5tu_big_201911122201021011.jpg",
            @"https://wx4.sinaimg.cn/large/a6a681ebgy1gojpbioc2sg208c08c0wd.gif",
            @"https://p.upyun.com/demo/webp/animated-gif/0.gif",
            @"https://p.upyun.com/demo/webp/webp/animated-gif-0.webp",
            @"https://p.upyun.com/demo/webp/animated-gif/1.gif",
            @"https://p.upyun.com/demo/webp/webp/animated-gif-1.webp",
            @"https://p.upyun.com/demo/webp/animated-gif/3.gif",
            @"https://p.upyun.com/demo/webp/webp/animated-gif-3.webp",
            @"https://p.upyun.com/demo/webp/animated-gif/5.gif",
            @"https://p.upyun.com/demo/webp/webp/animated-gif-5.webp",
            @"https://p.upyun.com/demo/webp/animated-gif/2.gif",
            @"https://p.upyun.com/demo/webp/webp/animated-gif-2.webp"
        ];
    }
    return _urls;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    ASCollectionNode *node = [[ASCollectionNode alloc] initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    node.backgroundColor = [UIColor whiteColor];
    return [super initWithNode:node];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.node.view.alwaysBounceVertical = YES;
    self.node.delegate = self;
    self.node.dataSource = self;
    [self.node reloadData];
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
    return 1;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    return self.urls.count;
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ASImageCellNode *cellNode = [[ASImageCellNode alloc] init];
    cellNode.imageNode.URL = [NSURL URLWithString: self.urls[indexPath.item]];
    return cellNode;
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = CGRectGetWidth(collectionNode.bounds);
    return ASSizeRangeMake(CGSizeMake(width, 200.0));
}

@end
