//
//  DashboardViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>
#import "HomeAssistantClient.h"
#import "WhiteboardGridLayout.h"

@interface DashboardViewController : UIViewController <HomeAssistantClientDelegate, UICollectionViewDataSource, UICollectionViewDelegate, WhiteboardGridLayoutDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *configButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *entitiesButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

- (IBAction)configButtonTapped:(id)sender;
- (IBAction)refreshButtonTapped:(id)sender;
- (IBAction)entitiesButtonTapped:(id)sender;
- (IBAction)editButtonTapped:(id)sender;

@end