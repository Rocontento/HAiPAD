//
//  DashboardViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>
#import "HomeAssistantClient.h"
#import "WhiteboardLayout.h"

@interface DashboardViewController : UIViewController <HomeAssistantClientDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *configButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *entitiesButton;

- (IBAction)configButtonTapped:(id)sender;
- (IBAction)refreshButtonTapped:(id)sender;
- (IBAction)entitiesButtonTapped:(id)sender;

@end