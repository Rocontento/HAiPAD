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
@property (weak, nonatomic) IBOutlet UISlider *gridColumnsSlider;
@property (weak, nonatomic) IBOutlet UILabel *gridColumnsLabel;
@property (weak, nonatomic) IBOutlet UISlider *gridRowsSlider;
@property (weak, nonatomic) IBOutlet UILabel *gridRowsLabel;

- (IBAction)saveButtonTapped:(id)sender;
- (IBAction)testButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;
- (IBAction)gridColumnsSliderChanged:(id)sender;
- (IBAction)gridRowsSliderChanged:(id)sender;

@end