//
//  DeviceViewController.h
//  Qpp Demo
//
//  @brief Application Header File for Device List View Controller. 
//
//  Created by NXP on 5/18/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceViewController : UIViewController{
    IBOutlet UITableView *deviceList;
}

@property (nonatomic,retain) UIRefreshControl *refreshControl;

- (IBAction)backQppMainVC : (id)sender;

-(void) updatePeriInTableView:(UIRefreshControl *)refreshControl;

+(DeviceViewController *)sharedInstance;
@end
