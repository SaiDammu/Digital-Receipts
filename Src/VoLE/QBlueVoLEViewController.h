//
//  QBlueVoLEViewController.h
//  bleDevMonitor
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QBlueClient.h"
#import "GraphView1.h"
#import "GraphView2.h"
#import "GraphViewDelegate1.h"
#import "GraphViewDelegate2.h"
#import "QppApi.h"
#define QPP_LOG_LEN     (1000*50)

#define _ENABLE_AUDIO_TEST 1 // zfq

 
#import <AVFoundation/AVFoundation.h>

// #import "QBlueAudio.h"

#define ALERT_DISCONNECT_TITLE     @"Disconnect Warning!"
#define ALERT_NODEVICE_TITLE       @"No Device !"
#define ALERT_CS_ERROR_TITLE       @"CheckSum Error Warning!"
#define ALERT_FAILED_TITLE         @"Failed Warning!"
#define ALERT_RETRIEVE_TITLE       @"Retrieve ?"

#define keyAlertDisconnect             @"keyAlertDisconnect"
#define keyAlertNoDevice               @"keyAlertNoDevice"
#define keyAlertCSError                @"keyAlertCSError"
#define keyAlertFailed                 @"keyAlertFailed"
#define keyAlertRetrieve               @"keyAlertRetrieve"

 

@class TableViewAlert;

@interface QBlueVoLEViewController : UIViewController <bleDevMonitorUpdateDelegate,GraphViewDelegate1,GraphViewDelegate2,qppReceiveDataDelegate>
{

    
}

@property (strong, nonatomic) NSMutableArray *ArrayOfValues;
@property (strong, nonatomic) NSMutableArray *ArrayOfValues1;
@property (strong, nonatomic) NSMutableArray *ArrayOfValuesBase;
/////////
@property (strong, nonatomic) NSMutableArray *ArrayOfValuesGolay;   // vardhman
@property (strong, nonatomic) NSMutableArray *ledfilter;   // vardhman
@property (strong, nonatomic) NSMutableArray *beatdifference;   // vardhman

@property (weak, nonatomic) IBOutlet GraphView1 *myGraph;
@property (weak, nonatomic) IBOutlet GraphView2 *RespGraph;
//- (IBAction)_FileButton;
//Dave
@property (strong, nonatomic) IBOutlet UILabel *VoLEVersion;
@property (weak, nonatomic) IBOutlet UILabel *temperature;

@property (strong, nonatomic) TableViewAlert *voleDisplayDevicesVC;

@property (strong, nonatomic) IBOutlet UILabel *connStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *devNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedDataLabel;
 
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
 

@property (strong, nonatomic) IBOutlet UILabel *voleScanCountDnLbl;
@property (strong, nonatomic) IBOutlet UILabel *voleScanCountDnUnitLbl;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *voleScanDevActInd;

- (IBAction)voleScanPeri:(id)sender;  

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *voleDidConnDevActInd;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

- (NSString *)toGetFileName;
 

//- (void)appendTextToView:(NSString *)fileString;

- (void)WriteToStringFile:(NSMutableString *)textToWrite;
 
+ (QBlueVoLEViewController *)sharedInstance;

@end
