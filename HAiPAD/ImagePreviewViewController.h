//
//  ImagePreviewViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@class ImagePreviewViewController;

@protocol ImagePreviewViewControllerDelegate <NSObject>
- (void)imagePreviewViewController:(ImagePreviewViewController *)controller didFinishWithImage:(UIImage *)croppedImage scale:(CGFloat)scale offset:(CGPoint)offset;
- (void)imagePreviewViewControllerDidCancel:(ImagePreviewViewController *)controller;
@end

@interface ImagePreviewViewController : UIViewController

@property (nonatomic, weak) id<ImagePreviewViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *originalImage;

- (instancetype)initWithImage:(UIImage *)image;

@end