//
//  DashboardViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>
#import "HomeAssistantClient.h"

@interface DashboardViewController : UIViewController <HomeAssistantClientDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *configButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

- (IBAction)configButtonTapped:(id)sender;
- (IBAction)refreshButtonTapped:(id)sender;

@end