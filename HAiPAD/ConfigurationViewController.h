//
//  ConfigurationViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@interface ConfigurationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UITextField *tokenTextField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *columnsSegmentedControl;
@property (weak, nonatomic) IBOutlet UISlider *gridSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel *gridSizeLabel;
@property (weak, nonatomic) IBOutlet UISlider *gridWidthSlider;
@property (weak, nonatomic) IBOutlet UISlider *gridHeightSlider;
@property (weak, nonatomic) IBOutlet UILabel *gridWidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *gridHeightLabel;

- (IBAction)saveButtonTapped:(id)sender;
- (IBAction)testButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;
- (IBAction)gridSizeSliderChanged:(id)sender;
- (IBAction)gridWidthSliderChanged:(id)sender;
- (IBAction)gridHeightSliderChanged:(id)sender;

@end