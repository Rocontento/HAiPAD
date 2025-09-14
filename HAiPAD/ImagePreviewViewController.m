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
@property (nonatomic, assign) BOOL overlayVisible;
@end

@implementation ImagePreviewViewController

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.originalImage = image;
        self.overlayVisible = YES;
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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Setup zoom after layout is complete
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
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.scrollView];
    
    // Create image view
    self.imageView = [[UIImageView alloc] initWithImage:self.originalImage];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.imageView];
    
    // Constraints for scroll view (full screen)
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]);
    
    // Add tap gesture to scroll view for hiding overlay
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)];
    [self.scrollView addGestureRecognizer:tapGesture];
}

- (void)setupOverlay {
    // Create semi-transparent overlay view
    self.overlayView = [[UIView alloc] init];
    self.overlayView.backgroundColor = [UIColor clearColor]; // Start transparent, we'll add background to individual elements
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.overlayView];
    
    // Instructions label with background
    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.text = @"Pinch to zoom, drag to reposition\nTap confirm when you're happy with the result";
    self.instructionLabel.textColor = [UIColor whiteColor];
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.font = [UIFont systemFontOfSize:16];
    self.instructionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    self.instructionLabel.layer.cornerRadius = 8;
    self.instructionLabel.clipsToBounds = YES;
    self.instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView addSubview:self.instructionLabel];
    
    // Cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.9];
    self.cancelButton.layer.cornerRadius = 8;
    self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView addSubview:self.cancelButton];
    
    // Reset button
    self.resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.resetButton.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.9];
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
    
    // Layout overlay (full screen but doesn't intercept touches)
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
        [self.instructionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.instructionLabel.heightAnchor constraintGreaterThanOrEqualToConstant:44]
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
}

- (void)setupInitialZoom {
    if (!self.originalImage || self.scrollView.bounds.size.width == 0) {
        return;
    }
    
    CGSize imageSize = self.originalImage.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    // Calculate scale to fit
    CGFloat scaleX = scrollViewSize.width / imageSize.width;
    CGFloat scaleY = scrollViewSize.height / imageSize.height;
    CGFloat minScale = MIN(scaleX, scaleY);
    
    // Set zoom scales
    self.scrollView.minimumZoomScale = minScale * 0.5; // Allow zooming out
    self.scrollView.maximumZoomScale = minScale * 4.0; // Allow zooming in
    self.scrollView.zoomScale = minScale;
    
    // Set image view frame based on image size and scale
    CGSize scaledImageSize = CGSizeMake(imageSize.width * minScale, imageSize.height * minScale);
    self.imageView.frame = CGRectMake(0, 0, scaledImageSize.width, scaledImageSize.height);
    
    // Update content size
    self.scrollView.contentSize = scaledImageSize;
    
    // Center the image
    [self centerImageInScrollView];
}

- (void)centerImageInScrollView {
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
    [self centerImageInScrollView];
}

#pragma mark - Actions

- (void)cancelButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(imagePreviewViewControllerDidCancel:)]) {
        [self.delegate imagePreviewViewControllerDidCancel:self];
    }
}

- (void)confirmButtonTapped:(id)sender {
    // Instead of capturing current view, pass the original image and current transform information
    if ([self.delegate respondsToSelector:@selector(imagePreviewViewController:didFinishWithImage:transform:)]) {
        [self.delegate imagePreviewViewController:self didFinishWithImage:self.originalImage transform:CGAffineTransformIdentity];
    }
}

- (void)resetButtonTapped:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        [self setupInitialZoom];
    }];
}

- (void)scrollViewTapped:(UITapGestureRecognizer *)gesture {
    // Toggle overlay visibility
    [UIView animateWithDuration:0.3 animations:^{
        if (self.overlayVisible) {
            self.instructionLabel.alpha = 0.0;
            self.cancelButton.alpha = 0.0;
            self.resetButton.alpha = 0.0;
            self.confirmButton.alpha = 0.0;
        } else {
            self.instructionLabel.alpha = 1.0;
            self.cancelButton.alpha = 1.0;
            self.resetButton.alpha = 1.0;
            self.confirmButton.alpha = 1.0;
        }
        self.overlayVisible = !self.overlayVisible;
    }];
}

// Support all orientations for preview
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end