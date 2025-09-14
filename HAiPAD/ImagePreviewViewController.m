//
//  ImagePreviewViewController.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "ImagePreviewViewController.h"

@interface ImagePreviewViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UILabel *instructionLabel;
@end

@implementation ImagePreviewViewController

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.originalImage = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // Create main scroll view for zoom and pan
    [self setupScrollView];
    
    // Create overlay with buttons and instructions
    [self setupOverlay];
    
    // Set initial zoom to fit screen
    [self setupInitialZoom];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    // Set zoom range
    self.scrollView.minimumZoomScale = 0.1;
    self.scrollView.maximumZoomScale = 3.0;
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    
    // Create image view
    self.imageView = [[UIImageView alloc] initWithImage:self.originalImage];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.imageView];
    
    // Constraints for scroll view (full screen)
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
    // Constraints for image view
    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.imageView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.imageView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
        [self.imageView.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor]
    ]];
}

- (void)setupOverlay {
    // Create semi-transparent overlay view
    self.overlayView = [[UIView alloc] init];
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.overlayView];
    
    // Instructions label
    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.text = @"Pinch to zoom, drag to reposition\nTap confirm when you're happy with the result";
    self.instructionLabel.textColor = [UIColor whiteColor];
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.font = [UIFont systemFontOfSize:16];
    self.instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView addSubview:self.instructionLabel];
    
    // Cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    self.cancelButton.layer.cornerRadius = 8;
    self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView addSubview:self.cancelButton];
    
    // Reset button
    self.resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.resetButton.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.8];
    self.resetButton.layer.cornerRadius = 8;
    self.resetButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.resetButton addTarget:self action:@selector(resetButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.resetButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView addSubview:self.resetButton];
    
    // Confirm button
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:0.9];
    self.confirmButton.layer.cornerRadius = 8;
    self.confirmButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView addSubview:self.confirmButton];
    
    // Layout overlay and buttons
    [NSLayoutConstraint activateConstraints:@[
        [self.overlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.overlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.overlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.overlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
    // Instructions at top (below status bar)
    [NSLayoutConstraint activateConstraints:@[
        [self.instructionLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40],
        [self.instructionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.instructionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
    
    // Buttons at bottom
    [NSLayoutConstraint activateConstraints:@[
        [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.cancelButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40],
        [self.cancelButton.widthAnchor constraintEqualToConstant:80],
        [self.cancelButton.heightAnchor constraintEqualToConstant:44],
        
        [self.resetButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.resetButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40],
        [self.resetButton.widthAnchor constraintEqualToConstant:80],
        [self.resetButton.heightAnchor constraintEqualToConstant:44],
        
        [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.confirmButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40],
        [self.confirmButton.widthAnchor constraintEqualToConstant:80],
        [self.confirmButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    // Add tap gesture to hide/show overlay
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTapped:)];
    [self.overlayView addGestureRecognizer:tapGesture];
}

- (void)setupInitialZoom {
    // Wait for layout to complete
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resetZoomAndPosition];
    });
}

- (void)resetZoomAndPosition {
    if (!self.originalImage) return;
    
    CGSize imageSize = self.originalImage.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    if (scrollViewSize.width == 0 || scrollViewSize.height == 0) {
        // Layout not ready yet
        return;
    }
    
    // Calculate scale to fit
    CGFloat scaleX = scrollViewSize.width / imageSize.width;
    CGFloat scaleY = scrollViewSize.height / imageSize.height;
    CGFloat minScale = MIN(scaleX, scaleY);
    
    self.scrollView.minimumZoomScale = minScale * 0.5; // Allow zooming out a bit more
    self.scrollView.maximumZoomScale = minScale * 3.0; // Allow zooming in
    self.scrollView.zoomScale = minScale;
    
    // Center the image
    [self centerScrollViewContents];
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0;
    } else {
        contentsFrame.origin.x = 0.0;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0;
    } else {
        contentsFrame.origin.y = 0.0;
    }
    
    self.imageView.frame = contentsFrame;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerScrollViewContents];
}

#pragma mark - Actions

- (void)cancelButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(imagePreviewViewControllerDidCancel:)]) {
        [self.delegate imagePreviewViewControllerDidCancel:self];
    }
}

- (void)confirmButtonTapped:(id)sender {
    UIImage *finalImage = [self captureCurrentView];
    
    if ([self.delegate respondsToSelector:@selector(imagePreviewViewController:didFinishWithImage:transform:)]) {
        [self.delegate imagePreviewViewController:self didFinishWithImage:finalImage transform:self.imageView.transform];
    }
}

- (void)resetButtonTapped:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        [self resetZoomAndPosition];
    }];
}

- (void)overlayTapped:(UITapGestureRecognizer *)gesture {
    // Toggle overlay visibility
    [UIView animateWithDuration:0.3 animations:^{
        self.overlayView.alpha = self.overlayView.alpha > 0.5 ? 0.1 : 0.8;
    }];
}

#pragma mark - Image Capture

- (UIImage *)captureCurrentView {
    // Create a new image that represents what will be shown as background
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    UIGraphicsBeginImageContextWithOptions(screenSize, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Fill with black background
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, screenSize.width, screenSize.height));
    
    // Calculate the visible area of the image
    CGRect visibleRect = [self.scrollView convertRect:self.scrollView.bounds toView:self.imageView];
    
    // Draw the portion of the image that's visible
    [self.originalImage drawAtPoint:CGPointMake(-visibleRect.origin.x, -visibleRect.origin.y)];
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Update zoom when orientation changes
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        [self resetZoomAndPosition];
    }
}

// Support all orientations for preview
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end