//
//  QppViewController.h
//  Qpp Demo
//
//  @brief Application header file for Peripheral to Centtral View Controller.
//
//  Created by NXP on 4/21/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBleQppClient.h"

#import "QppApi.h"
#import "DevicesCtrl.h"
#import "QBlueVoLEViewController.h"
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

/*typedef enum
{
	QPP_CENT_IDLE1 = 0, // scan
    QPP_CENT_SCANNING1,
    QPP_CENT_SCANNED1,
    QPP_CENT_CONNECTING1,
    QPP_CENT_CONNECTED,
    QPP_CENT_DISCONNECTING,
    QPP_CENT_DISCONNECTED,
    QPP_CENT_RETRIEVING,
    QPP_CENT_RETRIEVED,
    QPP_CENT_SENDING,        /// sending package
    QPP_CENT_ERROR,
} qppCentralState1;
*/
@class TableViewAlert;
@import Charts;
@interface QppViewController : UIViewController <bleDidConnectionsDelegate, qppReceiveDataDelegate /*,qppEnableConfirmDelegate */>
{
    qppCentralState qppCentState;
}


@property (nonatomic,readonly) qppCentralState qppCentState;

@property (strong, nonatomic) IBOutlet UILabel *qppConnectStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *qppDevNameLabel;

//@property (weak, nonatomic) IBOutlet UIButton *qppConnectButton;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ptScanDevActInd;

@property (strong, nonatomic) TableViewAlert *ptDisDevicesVC;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *ptDidConnDevActInd;

- (IBAction)ScanPeri:(id)sender;

/// peripheral 2 central
@property (strong, nonatomic) IBOutlet UIButton *btnToggleNtf;  
- (IBAction)toggleIndicate:(id)sender;
@property (weak, nonatomic) IBOutlet LineChartView *chartView;
@property (weak, nonatomic) IBOutlet UILabel *qppReceivedData;
/// @property (weak, nonatomic) IBOutlet UILabel *qppReceivedDataFromChar;

@property (weak, nonatomic) IBOutlet UILabel *qppDataRateAvgLbl; /// current data rate
- (IBAction)qppDataRateAvgReset:(id)sender;

///dynamic data rate
@property (weak, nonatomic) IBOutlet UILabel *qppDataRateDynLbl; /// dynamic data rate

@property (weak, nonatomic) IBOutlet UILabel *lblVersion;

- (IBAction)backgroundTap:(id)sender; 
@property (strong, nonatomic) IBOutlet UITextField *indata2send;

@property (strong, nonatomic) IBOutlet UITextField *inIntervalBtwPkg;

@property (weak, nonatomic) IBOutlet UIButton *btnSend;
- (IBAction)qppSendPackage:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *swRepeatSendData;
- (IBAction)swRepeatQppSent:(id)sender;
/// - (IBAction)qppSendWoRsp:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *repeatCounterLbl;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (IBAction)btnHelp:(id)sender;



+ (QppViewController *)sharedInstance;

@end
