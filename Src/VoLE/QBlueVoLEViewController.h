//
//  QBlueVoLEViewController.h
//  bleDevMonitor
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QBlueClient.h"
#import "OtaAppPublic.h"
//#import "GraphView1.h"
//#import "GraphView2.h"
//#import "GraphViewDelegate1.h"
//#import "GraphViewDelegate2.h"

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

//QPP -- start
#import "QbleQppClient.h"

#import "QppApi.h"
#import "DevicesCtrl.h"

/// QPP Peripheral UUID
#define UUID_USER0_PERIPHERAL         @"UUID_QPP_PERIPHERAL"

/// QPP Service's UUID
#define UUID_USER0_SERVICE            @"0000FEE9-0000-1000-8000-00805F9B34FB"

/// QPP a Peripheral's Characteristic with CBCharacteristicPropertyRead
#define UUID_USER0_READ               @"CE01"

/// QPP a Peripheral's Characteristic with CBCharacteristicPropertyWrite
#define UUID_USER0_WRITE              @"D44BC439-ABFD-45A2-B575-925416129600"

/// QPP a Peripheral's Characteristic with CBCharacteristicPropertyNotify
#define UUID_USER0_NOTI               @"D44BC439-ABFD-45A2-B575-925416129601"

/// for user1
#define UUID_USER1_PERIPHERAL         @"UUID_USER1_PERIPHERAL"

/// read
#define UUID_USER1_SVC_FOR_READ       @"FFE5"    /// svc for write
#define UUID_USER1_CHAR_FOR_READ      @"FFE5"    /// for write

/// write
#define UUID_USER1_SVC_FOR_WRITE      @"FFE5"    /// svc for write
#define UUID_USER1_CHAR_FOR_WRITE     @"FFE9"    /// for write

/// notify
#define UUID_USER1_SVC_FOR_NOTIFY     @"FFE0"    /// svc for notify
#define UUID_USER1_CHAR_FOR_NOTIFY    @"FFE4"    /// for notify
/// indicate
#define UUID_USER1_SVC_FOR_INDICATE   @"FFE5"    /// svc for notify
#define UUID_USER1_CHAR_FOR_INDICATE  @"FFE5"    /// for notify


#define UUID_PT_PERIPHERAL            @"UUID_PT_PERIPHERAL"
#define UUID_PT_SVC_FOR_NT            UUID_QPP_SERVICE
#define UUID_PT_CHAR_FOR_NT           UUID_QPP_SC_NOTI      // for noti
#define UUID_PT_CHAR_FOR_WR           UUID_QPP_WRITE        // for write

#define _ENABLE_QPP_TEST 0

#if _ENABLE_QPP_TEST
#define UUID_QPP_PERIPHERAL        UUID_USER1_PERIPHERAL

#define UUID_QPP_SVC_FOR_READ      UUID_USER1_SVC_FOR_READ
#define UUID_QPP_CHAR_FOR_READ     UUID_USER1_CHAR_FOR_READ

#define UUID_QPP_SVC_FOR_WRITE     UUID_USER1_SVC_FOR_WRITE
#define UUID_QPP_CHAR_FOR_WRITE    UUID_USER1_CHAR_FOR_WRITE

#define UUID_QPP_SVC_FOR_NOTIFY    UUID_USER1_SVC_FOR_NOTIFY
#define UUID_QPP_CHAR_FOR_NOTIFY   UUID_USER1_CHAR_FOR_NOTIFY

#define UUID_QPP_SVC_FOR_INDICATE  UUID_USER1_SVC_FOR_INDICATE
#define UUID_QPP_CHAR_FOR_INDICATE UUID_USER1_CHAR_FOR_INDICATE

#else

//#define UUID_QPP_PERIPHERAL        UUID_USER0_PERIPHERAL
#define UUID_QPP_SVC               UUID_USER0_SERVICE

//#define UUID_QPP_SVC_FOR_READ      UUID_USER0_SERVICE      /// service for read.
//#define UUID_QPP_CHAR_FOR_READ     UUID_USER0_READ     /// char for read.

#define UUID_QPP_SVC_FOR_WRITE     UUID_USER0_SERVICE     /// service for write.
#define UUID_QPP_CHAR_FOR_WRITE    UUID_USER0_WRITE    /// char for write.

#define UUID_QPP_SVC_FOR_NOTIFY    UUID_USER0_SERVICE    /// service for notify.
#define UUID_QPP_CHAR_FOR_NOTIFY   UUID_USER0_NOTI   /// char for notify.

//#define UUID_QPP_SVC_FOR_INDICATE  UUID_USER0_SERVICE  /// service for indicate.
//#define UUID_QPP_CHAR_FOR_INDICATE UUID_USER0_NOTI /// char for indicate.
#endif

#define ALERT_DISCONNECT_TITLE              @"Disconnect Warning"
#define ALERT_NODEVICE_TITLE                @"No Device"
#define ALERT_CS_ERROR_TITLE                @"CheckSum Error Warning"
#define ALERT_FAILED_TITLE                  @"Failed Warning"
#define ALERT_RETRIEVE_TITLE                @"Retrieve"
#define ALERT_CONNECT_FAIL_TITLE            @"Connection Warning"
#define ALERT_INPUT_ERROR_TITLE             @"Input Error"

#define strQppScanPeriEndNoti               @"qppScanPeripheralsEndNotification"

#define strQppUpdateDataRateAvgNoti         @"qppUpdateDataRateAverageNotification"

#define strQppUpdateDataRateDynNoti         @"qppUpdateDataRateDynamicNotification"


#define strQppDidConnectNoti                @"bleQppDidConnectNoti"
#define strQppDidDisconnectNoti             @"bleQppDidDisconnectNoti"
#define strQppFailToConnectNoti             @"bleQppFailToConnectNoti"
#define strQppRetrievePeripheralsNoti       @"bleQppRetrievePeripheralsNoti"

#define strQppDiscoveredServicesNoti        @"bleQppDiscoveredServicesNoti"

#define strQppUpdateStateForCharNoti        @"bleQppUpdateStateForCharNoti"

#define strQppReceiveDataNoti               @"bleQppUpdateValueForCharNoti"

/// UI noti
#define strQppSendFileEndNoti               @"qppSendFileEndNotification"


#define QPP_LENGTH_AT_BLE4_2                155

#define TEXT_EDITED_LENGTH_MIN       00
#define TEXT_EDITED_LENGTH_MAX       (256<<1)

typedef enum
{
    QPP_CENT_IDLE = 0, // scan
    QPP_CENT_SCANNING,
    QPP_CENT_SCANNED,
    QPP_CENT_CONNECTING,
    QPP_CENT_CONNECTED,
    QPP_CENT_DISCONNECTING,
    QPP_CENT_DISCONNECTED,
    QPP_CENT_RETRIEVING,
    QPP_CENT_RETRIEVED,
    QPP_CENT_SENDING,        /// sending package
    QPP_CENT_ERROR,
} qppCentralState;

// QPP end
 

@class TableViewAlert;

@interface QBlueVoLEViewController : UIViewController <bleDevMonitorUpdateDelegate,bleDidConnectionsDelegate, qppReceiveDataDelegate>
{
   qppCentralState qppCentState;
    
}

@property (strong, nonatomic) NSMutableArray *ArrayOfValues;
@property (strong, nonatomic) NSMutableArray *ArrayOfValues1;
@property (strong, nonatomic) NSMutableArray *ArrayOfValuesBase;
/////////
@property (strong, nonatomic) NSMutableArray *ArrayOfValuesGolay;   // vardhman
@property (strong, nonatomic) NSMutableArray *ledfilter;   // vardhman
@property (strong, nonatomic) NSMutableArray *beatdifference;   // vardhman

//@property (weak, nonatomic) IBOutlet GraphView1 *myGraph;
//@property (weak, nonatomic) IBOutlet GraphView2 *RespGraph;
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


@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *voleDidConnDevActInd;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

- (NSString *)toGetFileName;
 

//- (void)appendTextToView:(NSString *)fileString;

- (void)WriteToStringFile:(NSMutableString *)textToWrite;
 
+ (QBlueVoLEViewController *)sharedInstance;


// qpp start
@property (nonatomic,readonly) qppCentralState qppCentState;



/// peripheral 2 central
@property (strong, nonatomic) IBOutlet UIButton *btnToggleNtf;
- (IBAction)toggleIndicate:(id)sender;


// qpp end


@end
