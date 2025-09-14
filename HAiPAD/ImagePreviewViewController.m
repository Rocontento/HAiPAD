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
@property (nonatomic, assign) CGFloat originalMinZoomScale;
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
    
    // Create scroll view first
    [self setupScrollView];
    
    // Create image view
    [self setupImageView];
    
    // Create overlay last (so it appears on top)
    [self setupOverlay];
    
    NSLog(@"ImagePreview: viewDidLoad completed");
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.scrollView.bounds.size.width > 0 && self.scrollView.bounds.size.height > 0) {
        [self setupZoom];
        NSLog(@"ImagePreview: viewDidLayoutSubviews - zoom setup completed");
    }
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.delegate = self;
    
    // Essential scroll view properties for zoom and pan
    self.scrollView.minimumZoomScale = 0.1;
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.zoomScale = 1.0;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.bounces = YES;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.multipleTouchEnabled = YES;
    self.scrollView.delaysContentTouches = YES;
    self.scrollView.canCancelContentTouches = YES;
    
    [self.view addSubview:self.scrollView];
    
    NSLog(@"ImagePreview: Scroll view created with frame: %@", NSStringFromCGRect(self.scrollView.frame));
}

- (void)setupImageView {
    if (!self.originalImage) {
        NSLog(@"ImagePreview: No image to display");
        return;
    }
    
    self.imageView = [[UIImageView alloc] initWithImage:self.originalImage];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.backgroundColor = [UIColor clearColor];
    
    // Set initial frame to image size
    self.imageView.frame = CGRectMake(0, 0, self.originalImage.size.width, self.originalImage.size.height);
    
    [self.scrollView addSubview:self.imageView];
    
    NSLog(@"ImagePreview: Image view created with size: %@", NSStringFromCGSize(self.originalImage.size));
}

- (void)setupZoom {
    if (!self.originalImage || self.scrollView.bounds.size.width == 0) {
        return;
    }
    
    CGSize imageSize = self.originalImage.size;
    CGSize scrollSize = self.scrollView.bounds.size;
    
    // Calculate scale to fit image in scroll view
    CGFloat scaleX = scrollSize.width / imageSize.width;
    CGFloat scaleY = scrollSize.height / imageSize.height;
    CGFloat minScale = MIN(scaleX, scaleY);
    
    // Set zoom scales
    self.scrollView.minimumZoomScale = minScale * 0.5; // Allow zoom out
    self.scrollView.maximumZoomScale = minScale * 4.0; // Allow zoom in
    self.originalMinZoomScale = minScale;
    
    // Set content size
    self.scrollView.contentSize = imageSize;
    
    // Set initial zoom to fit
    self.scrollView.zoomScale = minScale;
    
    // Center the image
    [self centerImage];
    
    NSLog(@"ImagePreview: Zoom setup - min: %.3f, max: %.3f, current: %.3f", 
          self.scrollView.minimumZoomScale, self.scrollView.maximumZoomScale, self.scrollView.zoomScale);
}

- (void)setupOverlay {
    // Create overlay view that doesn't block touch events
    self.overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayView.backgroundColor = [UIColor clearColor];
    self.overlayView.userInteractionEnabled = YES;
    [self.view addSubview:self.overlayView];
    
    // Instructions label
    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.text = @"Pinch to zoom, drag to reposition\nTap confirm when you're happy with the result";
    self.instructionLabel.textColor = [UIColor whiteColor];
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.font = [UIFont systemFontOfSize:16];
    self.instructionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    self.instructionLabel.layer.cornerRadius = 8;
    self.instructionLabel.clipsToBounds = YES;
    [self.overlayView addSubview:self.instructionLabel];
    
    // Create buttons
    [self createButtons];
    
    // Layout elements
    [self layoutOverlayElements];
    
    // Add tap gesture to toggle overlay (but not on the scroll view itself)
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTapped:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)createButtons {
    // Cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.9];
    self.cancelButton.layer.cornerRadius = 8;
    self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.cancelButton];
    
    // Reset button
    self.resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.resetButton.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.9];
    self.resetButton.layer.cornerRadius = 8;
    self.resetButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.resetButton addTarget:self action:@selector(resetButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.resetButton];
    
    // Confirm button
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:0.9];
    self.confirmButton.layer.cornerRadius = 8;
    self.confirmButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.confirmButton];
}

- (void)layoutOverlayElements {
    // Use manual frame-based layout for iOS 9.3.5 compatibility
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    // Instructions at top
    self.instructionLabel.frame = CGRectMake(20, 40, screenWidth - 40, 60);
    
    // Buttons at bottom
    CGFloat buttonWidth = 80;
    CGFloat buttonHeight = 44;
    CGFloat bottomMargin = 40;
    
    self.cancelButton.frame = CGRectMake(20, screenHeight - bottomMargin - buttonHeight, buttonWidth, buttonHeight);
    self.resetButton.frame = CGRectMake((screenWidth - buttonWidth) / 2, screenHeight - bottomMargin - buttonHeight, buttonWidth, buttonHeight);
    self.confirmButton.frame = CGRectMake(screenWidth - 20 - buttonWidth, screenHeight - bottomMargin - buttonHeight, buttonWidth, buttonHeight);
}

- (void)centerImage {
    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGSize imageSize = self.imageView.frame.size;
    
    CGFloat offsetX = MAX(0, (scrollViewSize.width - imageSize.width) / 2.0);
    CGFloat offsetY = MAX(0, (scrollViewSize.height - imageSize.height) / 2.0);
    
    self.scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX);
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerImage];
    NSLog(@"ImagePreview: Did zoom to scale: %.3f", scrollView.zoomScale);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"ImagePreview: Did scroll to offset: %@", NSStringFromCGPoint(scrollView.contentOffset));
}

#pragma mark - Actions

- (void)cancelButtonTapped:(id)sender {
    NSLog(@"ImagePreview: Cancel tapped");
    if ([self.delegate respondsToSelector:@selector(imagePreviewViewControllerDidCancel:)]) {
        [self.delegate imagePreviewViewControllerDidCancel:self];
    }
}

- (void)confirmButtonTapped:(id)sender {
    NSLog(@"ImagePreview: Confirm tapped");
    
    // Calculate the relative scale (compared to fit-to-screen scale)
    CGFloat currentZoomScale = self.scrollView.zoomScale;
    CGFloat relativeScale = currentZoomScale / self.originalMinZoomScale;
    
    // Calculate offset relative to image center
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGSize imageSize = self.originalImage.size;
    CGPoint imageCenter = CGPointMake(imageSize.width / 2.0, imageSize.height / 2.0);
    
    // Calculate offset from image center in original image coordinates
    CGPoint relativeOffset = CGPointMake(
        (contentOffset.x / currentZoomScale) - imageCenter.x,
        (contentOffset.y / currentZoomScale) - imageCenter.y
    );
    
    NSLog(@"ImagePreview: Confirming with relative scale: %.3f, offset: %@", relativeScale, NSStringFromCGPoint(relativeOffset));
    
    if ([self.delegate respondsToSelector:@selector(imagePreviewViewController:didFinishWithImage:scale:offset:)]) {
        [self.delegate imagePreviewViewController:self didFinishWithImage:self.originalImage scale:relativeScale offset:relativeOffset];
    }
}

- (void)resetButtonTapped:(id)sender {
    NSLog(@"ImagePreview: Reset tapped");
    [UIView animateWithDuration:0.3 animations:^{
        // Reset to fit-to-screen scale and center
        self.scrollView.zoomScale = self.originalMinZoomScale;
        [self centerImage];
    }];
}

- (void)overlayTapped:(UITapGestureRecognizer *)gesture {
    // Only respond if the tap is not on a button
    CGPoint tapLocation = [gesture locationInView:self.overlayView];
    
    if (!CGRectContainsPoint(self.cancelButton.frame, tapLocation) &&
        !CGRectContainsPoint(self.resetButton.frame, tapLocation) &&
        !CGRectContainsPoint(self.confirmButton.frame, tapLocation) &&
        !CGRectContainsPoint(self.instructionLabel.frame, tapLocation)) {
        
        // Toggle overlay visibility
        [UIView animateWithDuration:0.3 animations:^{
            CGFloat targetAlpha = self.overlayVisible ? 0.0 : 1.0;
            self.instructionLabel.alpha = targetAlpha;
            self.cancelButton.alpha = targetAlpha;
            self.resetButton.alpha = targetAlpha;
            self.confirmButton.alpha = targetAlpha;
        }];
        self.overlayVisible = !self.overlayVisible;
    }
}

#pragma mark - Orientation Support

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Re-layout after rotation
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutOverlayElements];
        [self setupZoom];
    } completion:nil];
}

@end