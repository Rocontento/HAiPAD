//
//  EntitySettingsViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>
#import "HomeAssistantClient.h"

@interface EntitySettingsViewController : UIViewController <HomeAssistantClientDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

- (IBAction)doneButtonTapped:(id)sender;

@end