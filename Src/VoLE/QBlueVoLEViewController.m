//
//  QBlueVoLEViewController.m
//  bleDevMonitor
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//
//Orbital


#import "QBlueClient.h"
#import "QBlueDefine.h"

#import "TableViewAlert.h"
#import "CustomAlertView.h"

#import "QBlueVoLEViewController.h"

#import <QuartzCore/CoreAnimation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

#import "Constants.h"

//qpp start
#import "QppPublic.h"
#import "QppApi.h"

#import "CustomAlertView.h"
#import "Utils.h"

#import "DevicesQppViewController.h"
#import "OTAViewController.h"
#import "RootViewController.h"

#define QPP_DIDCONN_DEV_TIMEOUT      5
//qpp end

#define VOLE_TIMER_STEP               (1.0) //was 5.0
#define VOLE_SCAN_DEV_TIMEOUT         1  //was 10
#define VOLE_DIDCONN_DEV_TIMEOUT      50
#define VOLE_RESUME_TIMEOUT           50
volatile int startcounting = 3;
volatile int initialcount = 0;
//double num[5] = {0.9677, -3.8708, 5.8062, -3.8708, 0.9677};
//double den[5] = {1.0000, -3.9343, 5.8051, -3.8072, 0.9364};

//volatile double RegX[5];
//volatile double RegY[5];
//volatile float CenterTap;

// Chart
@import Charts;

@interface QBlueVoLEViewController ()<ChartViewDelegate> {

    NSMutableArray *qppDataArray;
    int qppPacketIndex;
    BOOL qppIndexUpdated;
    uint32_t received_data_length;
    NSDate *refDate;
    NSDate *intDate;
    NSString *fname;
    uint8_t  voleScanDevTimeoutCount;
    NSTimer *voleScanDevTimeoutTimer;
    NSString *filepath;
    uint8_t  voleDidConnDevTimeoutCount;
    NSTimer *voleDidConnDevTimeoutTimer;
    uint16_t numm;
    NSString *numms;
    NSString *nummst;
    int lowerBound;
    int upperBound;
#if QPP_LOG_FILE
    NSString *_fileLog;
    NSFileHandle *_fileHdl;
    NSString *values;
    NSData  *readerBuf;  //
#endif
    
    NSString *fileNameString;
    
    NSMutableData  *writeBuf;  //
    
    uint8_t _prev_type;
    //qpp starty
    NSTimer *qppDidConnDevTimeoutTimer; /// for connection timeout.
    uint8_t  qppDidConnDevTimeoutCount; /// for connection timeout.
    
    /// BOOL qppEnableStatus;               /// enable status.
    
    /// DataRate
    int8_t dataRateStart;
    BOOL   flagDataMonitoring;
    uint16_t qppDataRateMin;
    uint16_t qppDataRateMax;
    
    
    BOOL flagOnePeriScanned;           /// one peripheral is scanned.
    
    // @public
    u_int64_t preTimeMs, curTimeMs;
    u_int64_t dataReceived;
    
    u_int64_t dynRefTimeMs ;
    
    uint8_t qppWrData[512];
    
    QppApi *qppApi;
    DevicesCtrl *devInfo;
    
    NSTimer *repeatWrTimer;
    
    BOOL fEdited;
    BOOL pauseGraph;
    UIBarButtonItem *scanDisconnectItem;
    // qpp end
    LineChartDataSet *set1;
    ChartYAxis *leftAxis;
    NSMutableArray *minMaxArray;
}

@property (strong, nonatomic) NSTimer *voleScanDevTimeoutTimer;
@property (strong, nonatomic) NSTimer *voleDidConnDevTimeoutTimer;
@property (weak, nonatomic) IBOutlet LineChartView *chartView;

@end

@implementation QBlueVoLEViewController

@synthesize voleScanDevTimeoutTimer;
@synthesize voleDidConnDevTimeoutTimer;
//@synthesize myGraph=_myGraph;


+ (QBlueVoLEViewController *)sharedInstance
{
    static QBlueVoLEViewController *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[QBlueVoLEViewController alloc] init];
    }
    
    return _sharedInstance;
}

-(id)init {
    
    return self;
}

-(void)WriteToStringFile:(NSMutableString *)textToWrite{
    
    NSError *err;
    
    
    
    BOOL ok = [textToWrite writeToFile:@"/test.dat" atomically:YES encoding:NSUnicodeStringEncoding error:&err];
    
    if (!ok) {
        NSLog(@"Error writing file at %@\n%@",
              @"/users/davidschie/documents/test.dat", [err localizedFailureReason]);
    }
}

-(NSArray *)ReadTextFromFile:(NSMutableString *)textToRead{
    
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:@"Z005.txt"];
    NSString *myfile = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
    
    return [myfile componentsSeparatedByString:@"\n"];
}


- (void) voleStopScanDevTimeout
{
    voleScanDevTimeoutCount = 0;
    
    [voleScanDevTimeoutTimer invalidate];
    
    [self.voleScanDevActInd stopAnimating];
}

- (void) voleScanDevTimeoutRsp{
    
    if(voleScanDevTimeoutCount < VOLE_SCAN_DEV_TIMEOUT)
    {
        voleScanDevTimeoutCount++;
        
        [self updateScanCountDown: TRUE withCount:(VOLE_SCAN_DEV_TIMEOUT - voleScanDevTimeoutCount)];
        
        return;
    }
    
    [self updateScanCountDown: FALSE withCount : 0];
    
    [self voleStopScanDevTimeout];
    
    bleDevMonitor *dev = [bleDevMonitor sharedInstance];
    
    // create the alert
    NSArray *otaDevList = [dev discoveredPeripherals];
    
    if([otaDevList count])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : voleScanPeriEndNoti object:nil];
    }
    else
    {
        /// to scan a device timeout.
        CustomAlertView *voleScanDevAlert = [[CustomAlertView alloc] initWithTitle : ALERT_NODEVICE_TITLE
                                                                           message : @"No Device Around!"
                                                                          delegate : nil
                                                                 cancelButtonTitle : nil/*@"Cancel" */
                                                                 otherButtonTitles : @"OK", nil];
        [voleScanDevAlert show];
    }
}

- (void) voleStartScanActInd
{
    [self.voleScanDevActInd startAnimating];
    
    voleScanDevTimeoutCount = 0;
    
    voleScanDevTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval : 1.0 target:self selector:@selector(voleScanDevTimeoutRsp) userInfo:nil repeats : YES];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
 
    lowerBound = -100;
    upperBound = 100;
    minMaxArray = [NSMutableArray new];
    values=[NSString new];
    
    scanDisconnectItem = [[UIBarButtonItem alloc]initWithTitle:@"Scan" style:UIBarButtonItemStylePlain target:self action:@selector(searchDisconnectButtonAction:)];
    scanDisconnectItem.tag = 1;
    scanDisconnectItem.tintColor = [UIColor redColor];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    
    self.navigationItem.rightBarButtonItem = scanDisconnectItem;
    qppDataArray = [NSMutableArray new];
    qppPacketIndex = 0;
    qppIndexUpdated = NO;
    
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"mm.MMM.yy-hh:mm:ss"];
    NSString *dateString = [formatter stringFromDate:date];
    fileNameString = [NSString stringWithFormat:@"ECG_%@.txt",dateString];
    
    filepath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:fileNameString];
    
    //    [[NSBundle mainBundle]loadNibNamed:@"" owner:self options:nil];
    
    
    sleep(2);
    refDate = [NSDate date];
    fname = [NSString stringWithFormat:@"ppg[%d][%@].txt",received_data_length,refDate];
    //Dave
    numm=0;
    numms=@"";
    nummst=@"";
    self.ArrayOfValues = [[NSMutableArray alloc] init];
    self.ArrayOfValues1 = [[NSMutableArray alloc] init];
    self.ArrayOfValuesBase = [[NSMutableArray alloc] init];
    
    self.ArrayOfValuesGolay = [[NSMutableArray alloc] init];
    self.ledfilter = [[NSMutableArray alloc] init];
    self.beatdifference = [[NSMutableArray alloc] init];
    
    
    
    _chartView.delegate = self;
    _chartView.chartDescription.enabled = NO;
    
    _chartView.dragEnabled = YES;
    [_chartView setScaleEnabled:YES];
    _chartView.pinchZoomEnabled = NO;
    _chartView.drawGridBackgroundEnabled = NO;
    _chartView.highlightPerDragEnabled = YES;
    
    _chartView.backgroundColor = UIColor.whiteColor;
    
    _chartView.legend.enabled = NO;
    
    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionTopInside;
    xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
    xAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
    xAxis.drawAxisLineEnabled = NO;
    xAxis.drawGridLinesEnabled = YES;
    xAxis.centerAxisLabelsEnabled = YES;
    xAxis.granularity = 3600.0;
    
    
    leftAxis = _chartView.leftAxis;
    leftAxis.labelPosition = YAxisLabelPositionInsideChart;
    leftAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:00.f];
    leftAxis.labelTextColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
    leftAxis.drawGridLinesEnabled = YES;
    leftAxis.granularityEnabled = YES;
    leftAxis.axisMinimum = lowerBound;
    leftAxis.axisMaximum = upperBound;
    leftAxis.yOffset = -9.0;
    leftAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
    
    _chartView.rightAxis.enabled = NO;
    _chartView.legend.form = ChartLegendFormLine;
    [_chartView animateWithXAxisDuration:2.0 yAxisDuration:2.0];
    _chartView.userInteractionEnabled = NO;
    
    // Do any additional setup after loading the view from its nib.
    self.title = @"VoLE Demo";
    self.temperature.text=@" ";
    [self.VoLEVersion setText:[NSString stringWithFormat: @"Ver %1.1f", QBLUE_VOLE_VERSION]];
    
   // [self.connectButton setTitle:@"Scan" forState:UIControlStateNormal];
    self.connStatusLabel.text = @"><";
    
    
    /*[[@"123457" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:@"/tmp/test2.txt" atomically:NO];
     NSString *myfile = [NSString stringWithContentsOfFile:@"/tmp/test2.txt"
     encoding:NSASCIIStringEncoding
     error:NULL];
     NSLog(@"Our file contains this: %@", myfile);*/
    // Documents path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    // Destination path
    NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:@"ecg.txt"];
    
    // Origin path
    NSString *fileInBundlePath = [[NSBundle mainBundle] pathForResource:@"ecg" ofType:@"txt"];
    
    // File manager for copying
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager copyItemAtPath:fileInBundlePath toPath:fileInDocumentsPath error:&error];
    [[@"1234578" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileInDocumentsPath atomically:NO];
    //[[@"123457" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileInDocumentsPath atomically:NO];
    [fileManager copyItemAtPath:fileInDocumentsPath toPath:fileInBundlePath error:&error];
    NSString *my1file = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
    NSLog(@"Our file contains this: %@", my1file);
    
    
    NSFileHandle *file;
    NSMutableData *data;
    
    const char *bytestring = "black dog";
    
    data = [NSMutableData dataWithBytes:bytestring
                                 length:strlen(bytestring)];
    
    file = [NSFileHandle fileHandleForUpdatingAtPath:
            fileInDocumentsPath];
    
    if (file == nil)
        NSLog(@"Failed to open file");
    
    [file seekToFileOffset: 5];
    [file writeData: data];
    [file closeFile];
    NSString *my2file = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
    NSLog(@"Our file contains this: %@", my2file);
    [fileManager copyItemAtPath:fileInDocumentsPath toPath:fileInBundlePath error:&error];
    [self voleResetVC];
    
    [self volePlayerReset ];
    
    [bleDevMonitor sharedInstance].updateDelegate = self;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshConnectBtns) name:voleDidDisconnectNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voleUpdateDidConnDev) name:voleDidConnectNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voleDisplayPeripherals) name:voleScanPeriEndNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voleSelOnePeripheralRsp:) name:voleSelOnePeripheralNoti object:nil];
    
#if QPP_LOG_FILE
    _fileLog = nil; // zfq
#endif
    //qpp star
    
    qppApi = [QppApi sharedInstance];
    
    [self initDevicesInfo];
    // [self initUIComAboutCOnnection:NO];
    
    
    
    qppCentState = QPP_CENT_IDLE;
    
    [self refreshConnectBtns];
    
    [self regNotification];
    
    flagOnePeriScanned = FALSE;
    
    
    //qpp end
    
    //start graph from qpp
    
    NSString *command = @"3130";//_dataSendTextField.text;
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [command length]/2; i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"%@", commandToSend);
    
    [qppApi qppSendData : devInfo.qppPeri
               withData : commandToSend
               withType : CBCharacteristicWriteWithoutResponse/* CBCharacteristicWriteWithResponse */];
    
    qppCentState = QPP_CENT_IDLE;
    [self readQpp];
    
}

-(void)back:(id)sender{
  
     qBleQppClient *dev = [qBleQppClient sharedInstance];
    
       CBPeripheralState stateConnected = devInfo.qppPeri.state; /// iOS 9.0.2
       if (stateConnected==CBPeripheralStateConnected)/// iOS 9.0.2
       {
           
           qppCentState = QPP_CENT_DISCONNECTING;
           
           [dev pubDisconnectPeripheral : devInfo.qppPeri];
                      
       }
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)searchDisconnectButtonAction:(UIBarButtonItem*)item{
   // flagOnePeriScanned = FALSE;
    //[self ScanPeri];
    
    //scanDisconnectItem.title = @"Scan";
    
    qBleQppClient *dev = [qBleQppClient sharedInstance];
    
    #if QPP_IOS8
        BOOL isConnected = qppConnectedPeri.isConnected;
        
        if (isConnected)
    #endif
    
       CBPeripheralState stateConnected = devInfo.qppPeri.state; /// iOS 9.0.2
       if (stateConnected==CBPeripheralStateConnected)/// iOS 9.0.2
       {
             [self qppReset];
           
           qppCentState = QPP_CENT_DISCONNECTING;
           
           [dev pubDisconnectPeripheral : devInfo.qppPeri];
          // [qppApi qppEnableNotify : devInfo.qppPeri withNtfChar : devInfo.aQppNtfChar withEnable : NO];
           scanDisconnectItem.title = @"Disconnect";
           [dev stopScan];
       }else{
           if((qppCentState != QPP_CENT_SCANNING) &&
              (qppCentState != QPP_CENT_CONNECTING) )
           {
               qppCentState = QPP_CENT_SCANNING;
               
               //[self.ptScanDevActInd startAnimating];
               
               [dev stopScan];
               [dev startScan];
               
               // [dev startScan];
               
               scanDisconnectItem.title = @"Scan";
           }
       }
    
}

-(void)qppReset{
    flagDataMonitoring = false;
    
    fEdited=false;
    
    dataRateStart = 0;
    dataReceived = 0;
    //_qppDataRateAvgLbl.text = @"0";
    //_qppDataRateDynLbl.text = @"0";
    
    preTimeMs = 0l;
    curTimeMs = 0l;
    
    dynRefTimeMs = 0l;
    
    qppDataRateMin = 10000;
    qppDataRateMax = 0;
    qppCentState = QPP_CENT_IDLE;
    //[self qppSendReset];
}
-(void)initDevicesInfo{
    devInfo = [[DevicesCtrl alloc] init];
    
    devInfo.intervalBtwPkg=0.03f;
    devInfo.fQppWrRepeat = false;
    devInfo.lengOfPkg2Send=182;
    
    devInfo.pkgIdx=0;
    
    [self refreshData2BeSent:devInfo];
    
    [self refreshQppDataToSend:devInfo ];
}
-(void)refreshQppDataToSend:(DevicesCtrl *)_devInfo{
    ///qppWrData[0]=_devInfo.pkgIdx;
    uint16_t header=_devInfo.pkgIdx; /// todo more.
    /// _devInfo.data2Send=[[NSData alloc] init];
    /// _devInfo.data2Send=[NSData dataWithBytes:&qppWrData length:QPP_ LENGTH_AT_BLE4_2];
    NSRange headerRang;
    headerRang.length=sizeof(header);
    headerRang.location=0;
    
    [_devInfo.data2Send replaceBytesInRange:headerRang withBytes:&header length:sizeof(header)];
}
-(void)refreshData2BeSent:(DevicesCtrl *)_devCtrl{
    for(int i=0; i<_devCtrl.lengOfPkg2Send;i++){
        qppWrData[i]=i;
    }
    
    _devCtrl.data2Send=[[NSMutableData alloc] initWithBytes:qppWrData length:_devCtrl.lengOfPkg2Send];
}

#pragma OTA
-(void)otaButtonAction{
    RootViewController *otaVC = [RootViewController new];
    [self.navigationController pushViewController:otaVC animated:YES];
}

#pragma mark - qpp notification methods
- (void)qppDidDiscoveredServicesRsp{
    NSLog(@"%s", __func__);
    
}

/**
 *****************************************************************
 * @brief  app Discovered Services Char.
 *****************************************************************
 */
- (void)qppDidDiscoveredCharsRsp{
    NSLog(@"%s", __func__);
}

/// update data
/**
 *****************************************************************
 * @brief update state for notify char response.
 *****************************************************************
 */
- (void)qppUpdateStateForCharRsp:(NSNotification *)noti{
    NSLog(@"%s", __func__);
}

- (void)qppSelOnePeripheralRsp :(NSNotification *)noti
{
    // CBPeripheral *selectedPeri
    devInfo.qppPeri=[noti object];
    
    [self qppUserConfig];
    
    /// to conect the peripheral
    qBleQppClient *dev = [qBleQppClient sharedInstance];
    [dev stopScan];
    
    qppCentState = QPP_CENT_CONNECTING;
    
    [dev pubConnectPeripheral : devInfo.qppPeri];
}

-(void)qppUserConfig
{
    
    [qBleQppClient sharedInstance].bleDidConnectionsDelegate = self;
    
    [QppApi sharedInstance].ptReceiveDataDelegate = self;
    
}
- (void)qppMainStopScan
{
    flagOnePeriScanned = FALSE;
    qppCentState = QPP_CENT_IDLE;
    
    [[qBleQppClient sharedInstance] stopScan];
    
}
-(void)readQpp{
    
    [qppApi qppEnableNotify : devInfo.qppPeri
                withNtfChar : devInfo.aQppNtfChar
                 withEnable : YES];
    
    //  [self setDataCount];
    
}
-(void)setDataCount{
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    for (int i=0;i<_ArrayOfValues1.count;i++)
    {
        [values addObject:[[ChartDataEntry alloc] initWithX:(double)i y:[[_ArrayOfValues1 objectAtIndex:i] doubleValue]]];
    }
    
    
    if (_chartView.data && _chartView.data.dataSetCount > 0)
    {
        set1 = (LineChartDataSet *)_chartView.data.dataSets[0];
        [set1 replaceEntries: values];
        [_chartView.data notifyDataChanged];
        [_chartView notifyDataSetChanged];
    }
    else
    {
        set1 = [[LineChartDataSet alloc] initWithEntries:values label:@"DataSet 1"];
        set1.axisDependency = AxisDependencyLeft;
        set1.valueTextColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
        set1.lineWidth = 1.5;
        set1.drawCirclesEnabled = NO;
        set1.drawValuesEnabled = NO;
        set1.fillAlpha = 0.26;
        set1.fillColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
        set1.highlightColor = [UIColor colorWithRed:224/255.0 green:117/255.0 blue:117/255.0 alpha:1.0];
        set1.drawCircleHoleEnabled = NO;
        
        NSMutableArray *dataSets = [[NSMutableArray alloc] init];
        [dataSets addObject:set1];
        
        LineChartData *data = [[LineChartData alloc] initWithDataSets:dataSets];
        [data setValueTextColor:UIColor.whiteColor];
        [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.0]];
        
        _chartView.data = data;
    }
}
-(void)didQppEnableConfirmForAppRsp : (NSNotification *)_noti
{
    NSDictionary *dictInfo=[_noti object];
    
    devInfo.aQppWriteChar = [dictInfo objectForKey:keyWrCharInQpp];
    devInfo.aQppNtfChar = [dictInfo objectForKey:keyNtfCharInQpp];
    devInfo.fQppEnableStatus = (BOOL)[dictInfo objectForKey:keyConfirmStatus];
    
    if(devInfo.fQppEnableStatus)
    {
        NSLog(@"qppEnable ok.");
        
    }
    else
    {
        NSLog(@"qppEnable failed!!!");
        
    }
    if (devInfo.aQppNtfChar!=nil) {
        [self readQpp];
    }
    
    
    
}
#pragma mark - the delegate from QBleQppClient
/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
-(void)bleDidConnectPeripheral : (CBPeripheral *)aPeripheral{
    NSLog(@"line : %d, func: %s ",__LINE__, __func__);
    scanDisconnectItem.title = @"Disconnect";
    if(aPeripheral == devInfo.qppPeri)
    {
        [qppApi  qppEnable : devInfo.qppPeri
           withServiceUUID : UUID_QPP_SVC
                withWrChar : UUID_QPP_CHAR_FOR_WRITE];
        
        qppCentState = QPP_CENT_CONNECTED;
        
        [self qppStopDidConnDevTimeout];
        [self refreshConnectBtns];
        
        
    }
}

-(void)bleDidDisconnectPeripheral : (CBPeripheral *)aPeripheral error : (NSError *)error{
    NSLog(@"device disconnectecd");
    scanDisconnectItem.title = @"Scan";
    qppCentState = QPP_CENT_IDLE;
    
    [self qppStopDidConnDevTimeout];
    
    [self refreshConnectBtns];
    
    [[Utils sharedInst] cancelTimer:repeatWrTimer];
    
}

///**
// *****************************************************************
// * @brief       delegate ble update connected peripheral.
// *
// * @param[out]  aPeripheral : the connected peripheral.
// *
// *****************************************************************
// */
//-(void)bleDidRetrievePeripheral : (NSArray *)aPeripheral{
//    qppCentState = QPP_CENT_RETRIEVED;
//}

/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
-(void)bleDidFailToConnectPeripheral : (CBPeripheral *)aPeripheral
                               error : (NSError *)error{
    qppCentState = QPP_CENT_IDLE;
}

#pragma mark - discovered ....
- (void)qppDidPeriDiscoveredRsp{
    
    NSLog(@"%s", __func__);
    
    [[NSNotificationCenter defaultCenter] postNotificationName: appDevListReloadDataNoti object:nil userInfo:nil];
    
    if(flagOnePeriScanned == FALSE)
    {
        flagOnePeriScanned = TRUE;
        
        
        /// [self presentModalViewController : deviceVC animated:YES ];
        if ([scanDisconnectItem.title isEqualToString:@"Scan"]) {
            DevicesQppViewController *deviceVC = [[DevicesQppViewController alloc]init];
            //deviceVC.isOTA = NO;
            [self presentViewController: deviceVC animated:YES completion:nil];
            
        }
         
    }
   
}
 
#pragma mark - qpp delegate
- (void)didQppReceiveData : (CBPeripheral *) aPeripheral
             withCharUUID : (CBUUID *)qppUUIDForNotifyChar
                 withData : (NSData *)data{
    
    
    
    scanDisconnectItem.tag = 0;
    scanDisconnectItem.title = @"Disconnect";
    
    uint8_t * bytePtr = (uint8_t  * )[data bytes];
    
    for (int i = 0 ; i < data.length; i ++)
    {
        
        NSString *str = [NSString stringWithFormat:@"0x%02x%02x",bytePtr[i+1],bytePtr[i]];
        
        i++;
        
        unsigned int outVal;
        NSScanner* scanner1 = [NSScanner scannerWithString:str];
        [scanner1 scanHexInt:&outVal];
        
        values = [NSString stringWithFormat:@"%@\n%u",values,outVal];
        
        int spikes;
        
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            spikes = 500;
        }else{
            spikes = 500;
        }
        
        /* if (lowerBound>outVal){
         
         lowerBound = outVal;
         leftAxis.axisMinimum = lowerBound-100;
         }
         if (upperBound<outVal){
         upperBound = outVal;
         leftAxis.axisMaximum = upperBound+100;
         } */
        
        
        if (self.ArrayOfValues1.count>spikes){
            [self.ArrayOfValues1 removeObjectAtIndex:0];
        }
        [self.ArrayOfValues1 addObject:[NSNumber numberWithInteger:outVal]];
        [minMaxArray addObject:[NSNumber numberWithInteger:outVal]];
        
    }
    
    if (minMaxArray.count>500){
        [minMaxArray removeAllObjects];
    }
    
    NSArray *numbers = [minMaxArray sortedArrayUsingSelector:@selector(compare:)];
    
    int min = [[numbers firstObject] intValue];
    int max = [[numbers lastObject] intValue];
    
    leftAxis.axisMinimum = min-15000;
    leftAxis.axisMaximum = max+15000;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setDataCount];
    });
    
    
    
    NSError *error;
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:fileNameString];
    NSString *string = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    NSString *writeString = [NSString stringWithFormat:@"%@\n %@",string,values];
    
    [writeString writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    values = @"";
    
    
#if QPP_LOG_FILE
    // write data to log file
    // [writeBuf appendBytes:[data bytes] length:20 ];
#endif
    
    
   // [qppApi qppEnableNotify : devInfo.qppPeri withNtfChar : devInfo.aQppNtfChar withEnable : YES];
    
    
    
    
    // }
    
}


/*{
 
 
 NSDate *endDate = [NSDate date];
 
 // Way 2
 NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:refDate];
 
 // double minutes = timeDifference / 60;
 // double hours = minutes / 60;
 double seconds = timeDifference;
 // double days = minutes / 1440;
 
 // NSLog(@" days = %.0f,hours = %.2f, minutes = %.0f,seconds = %.0f", days, hours, minutes, seconds);
 
 //  if (seconds >= 0.45){
 //  NSLog(@"End Date is grater");
 
 pauseGraph = NO;
 scanDisconnectItem.tag = 0;
 scanDisconnectItem.title = @"Disconnect";
 
 const unsigned char *value = data.bytes;
 
 
 
 for (int i=0; i<data.length; i++) {
 //[buf appendFormat:@" %02lx",(unsigned long)value[i]];
 NSString *hexString = [NSString stringWithFormat:@" %02lx",(unsigned long)value[i]];
 unsigned result = 0;
 NSScanner *scanner = [NSScanner scannerWithString:hexString];
 [scanner setScanLocation:0];
 [scanner scanHexInt:&result];
 // NSLog(@"qpp float %d",result);
 //[self setDataCount:result range:result];
 
 [self.ArrayOfValues1 removeObjectAtIndex:0];
 
 // [self.ArrayOfValuesBase addObject:[NSNumber numberWithInteger:result]];
 [self.ArrayOfValues1 addObject:[NSNumber numberWithInteger:result]];
 
 
 
 }
 // _RespGraph.delegate = self;
 // [_RespGraph reloadGraph];
 
 #if QPP_LOG_FILE
 // write data to log file
 [writeBuf appendBytes:[data bytes] length:20 ];
 #endif
 refDate = [NSDate date];
 //  }
 /*  NSDate * date = [NSDate date];
 NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
 [dateFormatter setDateFormat:@"HH:mm:ss"];
 NSString *currentTime = [dateFormatter stringFromDate:date];
 NSLog(@"current time is:%@",currentTime); */
//}

/*
-(void)writeDataTxtFile:(NSString*)inputString{
    
    NSError *error;
    [inputString writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    // NSLog(@"qpp txt write error %@",error);
    
    NSString *str = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    // NSLog(@"ecg %@",str);
    
}
*/
/* {
 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
 NSString *documentsPath = [paths objectAtIndex:0];
 
 // Destination path
 NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:@"ecg1.txt"];
 
 // Origin path
 NSString *fileInBundlePath = [[NSBundle mainBundle] pathForResource:@"ecg1" ofType:@"txt"];
 
 // File manager for copying
 NSError *error = nil;
 NSFileManager *fileManager = [NSFileManager defaultManager];
 [fileManager copyItemAtPath:fileInBundlePath toPath:fileInDocumentsPath error:&error];
 [[@"1234578" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileInDocumentsPath atomically:NO];
 //[[@"123457" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileInDocumentsPath atomically:NO];
 [fileManager copyItemAtPath:fileInDocumentsPath toPath:fileInBundlePath error:&error];
 NSString *my1file = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
 NSLog(@"Our file contains this: %@", my1file);
 
 
 NSFileHandle *file;
 NSMutableData *data;
 
 const char *bytestring = [inputString UTF8String];
 
 data = [NSMutableData dataWithBytes:bytestring
 length:strlen(bytestring)];
 
 file = [NSFileHandle fileHandleForUpdatingAtPath:
 fileInDocumentsPath];
 
 if (file == nil)
 NSLog(@"Failed to open file");
 
 [file seekToFileOffset: 5];
 [file writeData: data];
 [file closeFile];
 NSString *my2file = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
 NSLog(@"Our file contains this: %@", my2file);
 [fileManager copyItemAtPath:fileInDocumentsPath toPath:fileInBundlePath error:&error];
 }*/
/*
 {
 
 if(!devInfo.fQppEnableStatus )
 {
 
 return;
 }
 
 const int8_t *rspData = [qppData bytes];
 
 if(rspData == nil)
 {
 return;
 }
 
 NSDate *  currentTime = [NSDate date];
 
 NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
 
 [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
 
 curTimeMs = [self getDateTimeTOMilliSeconds : currentTime];
 
 uint64_t deltaTime = curTimeMs - preTimeMs;
 
 if(deltaTime == 0) /// overflow
 return;
 
 /// NSLog(@"deltaTime %llu", deltaTime);
 
 #if 1
 dataReceived += [qppData length]; /// * 255;
 
 float qppCurDataRate = (dataReceived * 1000 / deltaTime);
 #else
 /// float qppCurDataRate = (dataReceived * 1000 / deltaTime);
 float qppCurDataRate = (255 * 20 * 1000 / deltaTime);
 #endif
 
 NSString *qppDataString= [NSString stringWithFormat:@"%d", (int)qppCurDataRate];
 NSLog(@"data qp %@",qppDataString);
 
 NSUInteger capacity = qppData.length;
 NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
 const unsigned char *buf = qppData.bytes;
 NSInteger i;
 
 for (int i=0; i<qppData.length; i++) {
 [sbuf appendFormat:@"%02X",(NSUInteger)buf[i]];
 }
 
 NSLog(@"char data %@",sbuf);
 
 NSString *hexString = [NSString stringWithFormat:@"0x%@",sbuf];
 
 
 NSScanner *scaner = [[NSScanner alloc]initWithString:hexString];
 double opValue = 0;
 [scaner scanHexDouble:&opValue];
 NSLog(@"val:: %.0f",opValue);
 
 NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc]init];
 numFormatter.numberStyle = kCFNumberFormatterDecimalStyle;
 [numFormatter setMaximumFractionDigits:20];
 
 NSLog(@"VVal:: %@",[numFormatter stringFromNumber:[NSNumber numberWithDouble:opValue]]);
 
 
 
 
 char myString[]="0x3f9d70a4";
 uint32_t num;
 long f;
 sscanf(myString, "%x", &num);  // assuming you checked input
 f = *((long*)&num);
 printf("the hexadecimal 0x%08x becomes %.3ld as a float\n", num, f);
 /*
 
 typedef union {
 float f;
 uint32_t i;
 }FloatInt;
 
 FloatInt f1;
 
 NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"0x%@",sbuf]];
 
 if ([scanner scanHexInt:&f1.i]) {
 NSLog(@"%x -- %f",f1.i,f1.f);
 }else{
 NSLog(@"parse error");
 }
 */
/*
 
 devInfo.lengOfPkg2Send=[self selectPkgLengMax:devInfo.lengOfPkg2Send withNewLength:(int)[qppData length]];
 
 
 if(flagDataMonitoring)
 {
 if(dataRateStart == rspData[0])
 {
 [[NSNotificationCenter defaultCenter] postNotificationName : strQppUpdateDataRateDynNoti object:qppData ];
 }
 
 [[NSNotificationCenter defaultCenter] postNotificationName : strQppUpdateDataRateAvgNoti object:qppData ];
 }
 else{
 flagDataMonitoring = TRUE;
 
 dynRefTimeMs = 0l;
 
 if(dataRateStart != rspData[0])
 {
 dataRateStart = rspData[0];
 }
 }
 [self qppDataRateAveragedReset];
 [qppApi qppEnableNotify : devInfo.qppPeri
 withNtfChar : devInfo.aQppNtfChar
 withEnable : NO];
 [self readQpp];
 }
 
 */

-(void)qppDataRateAveragedReset{
    dataReceived = 0;
    
    
    NSDate *  qppRefTime = [NSDate date];
    
    preTimeMs = [self getDateTimeTOMilliSeconds : qppRefTime];
}

-(int)selectPkgLengMax:(int)curLength withNewLength:(int)newLength{
    if(newLength>=curLength)
        return newLength;
    
    return curLength;
}
#if __BACKUP_CODE
-(void)didQppEnableConfirm : (CBPeripheral *)aPeripheral
                withStatus : (BOOL) qppEnableResult{
    
    qppEnableStatus = qppEnableResult;
    
    if(qppEnableStatus)
    {
        NSLog(@"qppEnable OK !");
    }
    else
    {
        NSLog(@"qppEnable failed!!!");
    }
}
#endif

#pragma mark -
- (void)qppDisplayPeripherals
{
    NSLog(@"%s", __func__);
    // [self.ptScanDevActInd stopAnimating];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: appDevListReloadDataNoti object:nil userInfo:nil];
    
    /// [self presentModalViewController : deviceVC animated:YES];
}

/**
 *****************************************************************
 * @brief Qpp Stop connect device timeout.
 *****************************************************************
 */
- (void) qppStopDidConnDevTimeout
{
    qppDidConnDevTimeoutCount = 0;
    [qppDidConnDevTimeoutTimer invalidate];
    //    [self.ptDidConnDevActInd stopAnimating];
}

/**
 *****************************************************************
 * @brief Qpp Connect device timeout response.
 *****************************************************************
 */
- (void) qppDidConnDevTimeoutRsp{
    // if(qppDidConnDevTimeoutCount > QPP_DIDCONN_DEV_TIMEOUT)
    {
        [self qppStopDidConnDevTimeout];
        
        /// to scan a device timeout.
        CustomAlertView *pbDidConnDevAlert = [[CustomAlertView alloc] initWithTitle : ALERT_CONNECT_FAIL_TITLE
                                                                             message:@"Connection failed!"
                                                                            delegate:nil
                                                                   cancelButtonTitle:nil /*@"Cancel" */
                                                                   otherButtonTitles:@"OK", nil];
        [pbDidConnDevAlert show];
    }
}

/**
 *****************************************************************
 * @brief Qpp Start connect device Activity Indicator.
 *****************************************************************
 */

///
/**
 *****************************************************************
 * @brief Qpp Get reference time.
 *****************************************************************
 */
- (NSDate *)getDateTimeFromMilliSeconds:(uint64_t) miliSeconds
{
    NSTimeInterval tempMilli = miliSeconds;
    NSTimeInterval seconds = tempMilli/1000.0;
    
    return [NSDate dateWithTimeIntervalSince1970:seconds];
}

/**
 *****************************************************************
 * @brief Qpp Start Scan device Activity Indicator.
 * convert time with NSDate format into NSInteger, from 1970/1/1
 *****************************************************************
 */
- (uint64_t)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    
    uint64_t totalMilliseconds = interval*1000 ;
    
    return totalMilliseconds;
}

/**
 *****************************************************************
 * @brief Qpp Update Data Rate.
 *****************************************************************
 */




-(NSString *) CBUUIDToUUID : (CBUUID *) UUID {
    
    NSString *strUUID = [NSString stringWithFormat:@"%s",[[UUID.data description] cStringUsingEncoding : NSStringEncodingConversionAllowLossy]];
    
    return strUUID;
}
-(void)regNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDidPeriDiscoveredRsp) name: blePeriDiscoveredNotiQpp object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDidDiscoveredServicesRsp) name: bleDiscoveredServicesNotiQpp object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDidDiscoveredCharsRsp) name: bleDiscoveredCharacteristicsNotiQpp object:nil];
    
    /// update data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppUpdateStateForCharRsp:) name: strQppUpdateStateForCharNoti object:nil];
    
    /// UI
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDisplayPeripherals) name:strQppScanPeriEndNoti object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppSelOnePeripheralRsp:) name : qppSelOnePeripheralNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppMainStopScan) name : qppMainStopScanNoti object:nil];
    //qpp
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didQppEnableConfirmForAppRsp:) name: didQppEnableConfirmForAppNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppWriteValueForCharRsp:) name : bleWriteValueForCharNotiQpp object:nil];
    
}
-(void)qppWriteValueForCharRsp : (NSNotification *)noti
{
#if 0
    if(qppCentState == QPP_CENT_IDLE)
    {
        return;
    }
    
    if(devInfo.fQppWrRepeat)
    {
        CBPeripheral *aPeri = [noti.userInfo objectForKey: keyQppPeriWritten];
        if([aPeri isEqual: devInfo.qppPeri])
        {
            //[btnSend setTitle:@"Stop" forState : UIControlStateNormal];
            
            Byte *dataSentPkgArr = (Byte *)[devInfo.data2Send bytes];
            dataSentPkgArr[0]++;
    
            /// devInfo.dat a2Send = [[NSData alloc] initWithBytes : dataSentPkgArr length : [devInfo.data 2Send length]];
            ///QppApi *qppApi = [QppApi sharedInstance];
            
            [qppApi qppSendData : devInfo.qppPeri
                       withData : devInfo.data2Send
                       withType : CBCharacteristicWriteWithResponse];
            
            /// update UI
            qppSendCounter++;
           // repeatCounterLbl.text = [NSString stringWithFormat:@"%lld", qppSendCounter];
        }
    }
#endif
}
- (int)numberOfPointsInGraph {
    return (int)[self.ArrayOfValues count];
}

- (float)valueForIndex:(NSInteger)index {
    NSLog(@"index 0 %ld",(long)index);
    return [[self.ArrayOfValues objectAtIndex:index] floatValue];
}
-(BOOL)pauseGraph{
    NSLog(@"yes qpp");
    return pauseGraph;
}
- (int)numberOfPointsInGraph1 {
    return (int)[self.ArrayOfValues1 count];
}

- (float)valueForIndex1:(NSInteger)index {
    // NSLog(@"indx %ld",(long)index);
    
   /* NSError *error;
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:fileNameString];
    
    NSString *str = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    // NSLog(@"ecg %@",str);
    //NSNumber *num =
    NSString *valueString = [NSString stringWithFormat:@"%f",[[self.ArrayOfValues1 objectAtIndex:index] floatValue]];
    if (![valueString isEqualToString:@"99999.000000"]){
        NSString *writeString = [NSString stringWithFormat:@"%@\nLinear::%@",str,valueString];
        [self writeDataTxtFile:writeString];
    }
    */
    return [[self.ArrayOfValues1 objectAtIndex:index] floatValue];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

- (IBAction)qppDataSend:(id)sender{
    
    
    // use UIAlertController
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"QPP Input"
                               message:nil
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
        //Do Some action here
        UITextField *textField = alert.textFields[0];
        NSLog(@"text was %@", textField.text);
        
        
        if(devInfo.fQppEnableStatus == FALSE){
            NSLog(@"qppEnable failed!!!");
        }
        else
        {
            
            qppCentState = QPP_CENT_SENDING;
            
            NSString *strEdited = textField.text;
            
            if(fEdited){
                NSData *inData=[[Utils sharedInst] hexStrToBytes : strEdited withStrMin:TEXT_EDITED_LENGTH_MIN withStrMax: [strEdited length]];
                
                devInfo.data2Send=[[NSMutableData alloc] initWithData:inData];
            }
            
            if(devInfo.data2Send == NULL)
            {
                /// illegal input
                CustomAlertView *inputAlert = [[CustomAlertView alloc]
                                               initWithTitle : ALERT_INPUT_ERROR_TITLE
                                               message : @"Input error!"
                                               delegate : nil
                                               cancelButtonTitle : nil
                                               otherButtonTitles : @"OK", nil];
                [inputAlert show];
                
                return;
            }
            
            NSString *command = textField.text;
            
            command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSMutableData *commandToSend= [[NSMutableData alloc] init];
            unsigned char whole_byte;
            char byte_chars[3] = {'\0','\0','\0'};
            int i;
            for (i=0; i < [command length]/2; i++) {
                byte_chars[0] = [command characterAtIndex:i*2];
                byte_chars[1] = [command characterAtIndex:i*2+1];
                whole_byte = strtol(byte_chars, NULL, 16);
                [commandToSend appendBytes:&whole_byte length:1];
            }
            NSLog(@"%@", commandToSend);
            pauseGraph = YES;
            // [_RespGraph reloadGraph];
            [qppApi qppSendData : devInfo.qppPeri
                       withData : commandToSend
                       withType : CBCharacteristicWriteWithoutResponse/* CBCharacteristicWriteWithResponse */];
            
            qppCentState = QPP_CENT_IDLE;
            [self readQpp];
            
            
        }
        
        
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
        
        NSLog(@"cancel btn");
        
        [alert dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Input";
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    [self refreshData2BeSent:devInfo];
    
}


/*{
 
 sendValue++;
 
 // use UIAlertController
 UIAlertController *alert= [UIAlertController
 alertControllerWithTitle:@"QPP Input"
 message:nil
 preferredStyle:UIAlertControllerStyleAlert];
 
 UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault
 handler:^(UIAlertAction * action){
 //Do Some action here
 UITextField *textField = alert.textFields[0];
 NSLog(@"text was %@", textField.text);
 
 
 if(devInfo.fQppEnableStatus == FALSE){
 NSLog(@"qppEnable failed!!!");
 }
 else
 {
 
 qppCentState = QPP_CENT_SENDING;
 
 NSString *strEdited = textField.text;
 
 if(fEdited){
 NSData *inData=[[Utils sharedInst] hexStrToBytes : strEdited withStrMin:TEXT_EDITED_LENGTH_MIN withStrMax: [strEdited length]];
 
 devInfo.data2Send=[[NSMutableData alloc] initWithData:inData];
 }
 
 if(devInfo.data2Send == NULL)
 {
 /// illegal input
 CustomAlertView *inputAlert = [[CustomAlertView alloc]
 initWithTitle : ALERT_INPUT_ERROR_TITLE
 message : @"Input error!"
 delegate : nil
 cancelButtonTitle : nil
 otherButtonTitles : @"OK", nil];
 [inputAlert show];
 
 return;
 }
 
 NSString *command = textField.text;
 
 command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
 NSMutableData *commandToSend= [[NSMutableData alloc] init];
 unsigned char whole_byte;
 char byte_chars[3] = {'\0','\0','\0'};
 int i;
 for (i=0; i < [command length]/2; i++) {
 byte_chars[0] = [command characterAtIndex:i*2];
 byte_chars[1] = [command characterAtIndex:i*2+1];
 whole_byte = strtol(byte_chars, NULL, 16);
 [commandToSend appendBytes:&whole_byte length:1];
 }
 NSLog(@"%@", commandToSend);
 pauseGraph = YES;
 // [_RespGraph reloadGraph];
 [qppApi qppSendData : devInfo.qppPeri
 withData : commandToSend
 withType : CBCharacteristicWriteWithoutResponse/* CBCharacteristicWriteWithResponse *//*];
                                                                                        
                                                                                        qppCentState = QPP_CENT_IDLE;
                                                                                        [self readQpp];
                                                                                        
                                                                                        
                                                                                        }
                                                                                        
                                                                                        
                                                                                        }];
                                                                                        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                                                        handler:^(UIAlertAction * action) {
                                                                                        
                                                                                        NSLog(@"cancel btn");
                                                                                        
                                                                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                                                                        
                                                                                        }];
                                                                                        
                                                                                        [alert addAction:ok];
                                                                                        [alert addAction:cancel];
                                                                                        
                                                                                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                                                        textField.placeholder = @"Input";
                                                                                        textField.keyboardType = UIKeyboardTypeDefault;
                                                                                        }];
                                                                                        
                                                                                        [self presentViewController:alert animated:YES completion:nil];
                                                                                        
                                                                                        [self refreshData2BeSent:devInfo];
                                                                                        
                                                                                        }
                                                                                        */
- (void)refreshConnectBtns {
    //NEW CODE
    
    
    
    
    BOOL isConnected = [bleDevMonitor sharedInstance].isConnected;
    
    NSLog(@"\n func : %s\n", __func__);
    
    if (isConnected) {
        [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        
        
        
        NSString *dev_name = [[bleDevMonitor sharedInstance] devName];
        if (dev_name) {
            self.devNameLabel.text = dev_name;
            NSLog(@"Device Name is %@", dev_name);
        }
        self.connStatusLabel.text = @"<>";
        received_data_length = 0;
        refDate = [NSDate date];
        NSLog(@"refDate %@", refDate.description);
        
#if QPP_LOG_FILE
        NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        
        //NSString *_filePath= [documentsDirectory stringByAppendingPathComponent:@"log.txt"];
        NSString *_filePath= [documentsDirectory stringByAppendingPathComponent:@"testAudio.caf"];
        
        BOOL r = [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
        
        _fileHdl = [NSFileHandle fileHandleForUpdatingAtPath:_filePath];
        
        if (r == NO || _fileHdl == nil)
        {
            NSLog(@"File Open Error!\n");
        }
        
        _fileLog = [[NSString alloc] init];
        
#endif
        // device side should send the first type be 1 every time the link be created
        _prev_type = 0;
    }
    else
    {
        [self.connectButton setTitle:@"Scan" forState:UIControlStateNormal];
        
        
        self.connStatusLabel.text = @"><";
        self.devNameLabel.text = @"No Device";
        
#if QPP_LOG_FILE
        
        NSLog(@"_fileHdl %@\n",_fileHdl);
        
        [_fileHdl seekToEndOfFile];
        
        [_fileHdl writeData: writeBuf];
        
        [_fileHdl closeFile];
        
        // clean writeBuf
        
        writeBuf = [NSMutableData alloc] ;
        
        _fileLog = nil;
        
#endif
    }
}

#pragma mark - RECEIVED_DATA_LENGTH

- (void)bleDevMonitor:(bleDevMonitor *)client didUpdateReceivedData:(NSData *)data
{
    uint16_t length = data.length;
    
    NSMutableString *buf = [NSMutableString stringWithCapacity:100];
    const unsigned char *value = data.bytes;
    
    for (int i=0; i<data.length; i++) {
        [buf appendFormat:@" %02lx",(unsigned long)value[i]];
    }
    NSLog(@"hexOp old  %@",buf);
    
#if QPP_DATA_CHECK
    // check the received data
    const uint8_t *reportData = [data bytes];
    
    uint8_t type = reportData[0];
    if ((uint8_t)(type - _prev_type) != 1)
    {
        NSLog(@"Error: %d:%d", _prev_type, type);
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"QPP Alert View"
                                                    message:@"Received data check failed!"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil, nil];
        [av show];
    }
    _prev_type = type;
#endif
    
    // data rate
    uint16_t data_rate;
    static uint32_t length_interval = 0;
    static bool data_rate_history = NO;
    
    
    if (received_data_length == 0)
    {
        refDate = [NSDate date];
        data_rate = 0;
        length_interval = 0;
        data_rate_history = NO;
    }
    else
    {
#if UPDATE_DATA_RATE_IN_TIME
        length_interval += length;
        if (length_interval <= 20)
        {
            refDate = [NSDate date];
            intDate = [[NSDate date]initWithTimeInterval:UPDATE_DATA_RATE_INTERVAL sinceDate:refDate];
            data_rate = 0;
        }
        else
        {
            NSDate *curDate = [NSDate date];
            if ([curDate compare: intDate] != NSOrderedAscending)
            {
                NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:refDate];
                data_rate = (length_interval-20)/interval;
                // NSLog(@"data length = %d, date rate = %d", length_interval, data_rate);
                length_interval = 0;
                data_rate_history = YES;
            }
            else
            {
                if (data_rate_history == NO)
                {
                    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:refDate];
                    data_rate = (length_interval-20)/interval;
                }
                else
                {
                    data_rate = 0;
                }
            }
        }
#else
        NSTimeInterval interval;
        interval = [[NSDate date] timeIntervalSinceDate:refDate];
        data_rate = (received_data_length-20)/interval;
#endif
    }
    // total length
    received_data_length += length;
    
    if (length && received_data_length) {
        // total length display
        self.receivedDataLabel.text = [NSString stringWithFormat:@"%d", received_data_length];
        // data rate display
        if (data_rate != 0)
        {
            self.dataRateLabel.text = [NSString stringWithFormat:@"%d", data_rate];
        }
        //self.temperature.text = [NSString stringWithFormat:@"%d", 80];
        //        NSString* myString;
        // myString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        uint16_t number2[10];
        
        uint16_t *number = (uint16_t*)data.bytes;// [data bytes];
        //        int16_t temp;
        int8_t ia=0;
        int8_t ib=0;
        int8_t i=0;
        uint16_t latest;
        
        static int start = 0;
        static int countcheck = 0;
        static int printbeat = 0;
        static int fileCount = 0;
        static double RegX[41];
        static double RegX1[41];
        
        double CenterTap;
        double CenterTap1; /// first derivative
        
        // NSLog(@"Old number I :: %d",number);
        
        while(i<([data length]/2))
        {
            // number2[i]=number[i];
            number2[i] = (0x3FFF & number[i]);
            i++;
        }
        
        i=0;ia=0;ib=0;
        int A = 0, B = 65000;
        int a = 75, b = 125;
        int newvalue;
        int currentvalue;
        static float timestamp = 0.0;
        if(start == 0)
        {
            for(int j=0;j<41;j++)
            {
                RegX[j]=0;
                RegX1[j]=0;
            }
            start = 1;
        }
        
        
        for (i=0; i<[data length]/2; i++)
        {
            /* Store it in a file */
            [self.ArrayOfValuesBase addObject:[NSNumber numberWithInteger:(number[i])]];
            numm=[(NSNumber *)[self.ArrayOfValuesBase objectAtIndex:(fileCount)] intValue];
            numms = [NSString stringWithFormat:@"%d\n", numm];
            nummst = [nummst stringByAppendingString:numms];
            fileCount++;
            if(fileCount>=240)
            {
                
                NSFileHandle *file;
                // Documents path
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                // Destination path
                NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:fname];
                NSData* writeData = [nummst dataUsingEncoding:NSUTF8StringEncoding];
                
                //  NSString* tempString;
                //  tempString = [[NSString alloc] initWithData:writeData encoding:NSASCIIStringEncoding];
                if (![[NSFileManager defaultManager] fileExistsAtPath:fileInDocumentsPath]) {
                    [[NSFileManager defaultManager] createFileAtPath:fileInDocumentsPath contents:nil attributes:nil];
                }
                
                
                file = [NSFileHandle fileHandleForUpdatingAtPath:fileInDocumentsPath];
                [file seekToEndOfFile];
                [file writeData: writeData];
                [file closeFile];
                [self.ArrayOfValuesBase removeAllObjects];  //empty storage array
                numm=0;
                numms=@"";
                nummst=@"";
                fileCount=0;
            }
            
            int count_leddata;
            
            int data = number2[i];
            float signal;
            signal = (float) data;
            // Shift the register values.
            for(int k=40; k>0; k--)
            {
                RegX[k] = RegX[k-1];
                RegX1[k] = RegX1[k-1];
            }
            
            // numerator
            CenterTap = 0.0;
            CenterTap1 = 0.0;
            RegX[0] = signal;
            RegX1[0] = signal;
            for(int k=0; k<=40; k++)
            {
                CenterTap += fil[k] * RegX[k];
                CenterTap1 += der[k] * RegX1[k];
            }
            
            [self.ledfilter addObject:[NSNumber numberWithInteger:((int)(CenterTap))]];
            if(CenterTap1 < 0)
                CenterTap1= CenterTap1 * -1;
            [self.ArrayOfValuesGolay addObject:[NSNumber numberWithInteger:((int)(CenterTap1))]];
            count_leddata = (int)[self.ledfilter count];
            if(count_leddata>=90) // 61
            {
                A = 66000;
                B = 0;
                for(int i=0; i<=89;i++)     // till 40
                {
                    currentvalue = [(NSNumber *)[self.ledfilter objectAtIndex:(i)] intValue];
                    if(currentvalue > B)
                    {
                        B = currentvalue;       // maximum
                        
                    }
                    if(currentvalue < A)
                    {
                        A = currentvalue;      // minimum
                    }
                }
                if(B-A <= 20) //30// 10      // if it is actual value change it to 80
                {
                    a = 98;
                    b = 102;
                }
                else
                {
                    a = 65;
                    b = 135;
                }
                latest = [(NSNumber *)[self.ledfilter objectAtIndex:(29)] intValue];
                newvalue = a + (latest - A)*(b-a)/(B-A);
                newvalue = b - newvalue + a;
                
                [self.ArrayOfValues1 removeObjectAtIndex:0];
                [self.ArrayOfValues1 addObject:[NSNumber numberWithInteger:(newvalue)]];
                
                latest = [(NSNumber *)[self.ArrayOfValuesGolay objectAtIndex:(29)] intValue];
                newvalue = (latest + 20)*4;
                [self.ArrayOfValues removeObjectAtIndex:0];
                [self.ArrayOfValues addObject:[NSNumber numberWithInteger:(newvalue)]]; //accelerometer plot
                
                [self.ledfilter removeObjectAtIndex:0];
                [self.ArrayOfValuesGolay removeObjectAtIndex:0];
                
                
                countcheck = countcheck+1;
                int startindex =0;
                int betweenindex=0;
                int endindex = 0;
                int beatdiffindex=0;
                float meandiff=0.0;
                double sum_deviation = 0.0;
                int temp;
                int countbeats = 0;
                static int heartrate = 0;
                
                /* count beats */
                if(countcheck >=1000) // 80
                {
                    countcheck = 1; //250
                    timestamp = timestamp+8;
                    int k=50;
                    while(950-k-30 > 10)  // 78
                    {
                        int numb1 = [(NSNumber *)[self.ArrayOfValues1 objectAtIndex:(950-k-30)] intValue];
                        int numb2 = [(NSNumber *)[self.ArrayOfValues1 objectAtIndex:(950-k)] intValue];
                        int numb3 = [(NSNumber *)[self.ArrayOfValues1 objectAtIndex:(950-k+30)] intValue];
                        if (numb2 > numb3 && numb2 > numb1 && numb2 - numb3 > 15 && numb2 - numb1 > 15 && numb2 < 250 && numb2 > 0)
                        {
                            countbeats = countbeats + 1;
                            if (startindex == 0)
                            {
                                startindex = k;
                            }
                            else
                            {
                                betweenindex = k;
                                beatdiffindex = betweenindex - endindex;
                                [self.beatdifference addObject:[NSNumber numberWithInteger:(beatdiffindex)]];
                                meandiff += beatdiffindex;
                            }
                            endindex = k;
                            k=k+70;
                        }
                        else
                        {
                            k=k+10;
                        }
                    }
                    if (countbeats >= 7)
                    {
                        meandiff = meandiff/(125*(countbeats-1));
                        for(int i=0;i<countbeats-1;i++)
                        {
                            temp = [(NSNumber *)[self.beatdifference objectAtIndex:(i)] intValue];
                            sum_deviation += (temp/125 - meandiff) * (temp/125-meandiff);
                        }
                        sum_deviation = sum_deviation*1000/(countbeats-1);  // 1000 (ms)
                        sum_deviation = sqrt(sum_deviation);
                        countbeats = (countbeats-1)*125*60/(endindex-startindex);
                        if(printbeat == 0)
                        {
                            heartrate = countbeats;
                            printbeat = 1;
                        }
                        else
                        {
                            heartrate = (0.3*heartrate + 0.7*countbeats);
                        }
                        
                        self.temperature.text=[NSString stringWithFormat:@"%d", heartrate];//(int)(sum_deviation)]; // heartrate
                        
                    }
                    [self.beatdifference removeAllObjects];
                    countbeats = 0;
                }
                /* count beats end */
                
            }
            
        }
        
        
    }
    //_RespGraph.delegate = self;
    
    
    //  [self.RespGraph reloadGraph];
#if QPP_LOG_FILE
    // write data to log file
    [writeBuf appendBytes:[data bytes] length:20 ];
#endif
    
}

- (void)viewDidUnload {
    [self setReceivedDataLabel:nil];
    [self setDevNameLabel:nil];
    [self setConnStatusLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    
    return NO;
}

- (IBAction)_FileButton:(id)sender {
    NSLog(@"here");
    fname = [NSString stringWithFormat:@"ecg[%d][%@].txt",received_data_length,refDate];
    
}

/*
 Hex 2 NSData.
 */
-(NSString *)hexData2NSString:(NSData *)toConvertData : (int16_t)strLenght
{
    ///// 将16进制数据转化成Byte 数组
    NSString *hexString = @" "; //16进制字符串
    
    const uint8_t *arrData = [toConvertData bytes];
    
    ///3ds key的Byte 数组， 128位
    for(int i=0; i < strLenght; i++)
    {
        
        unichar hex_char1 = arrData[i]>>4; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1+48);   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1+55); //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1+87); //// a 的Ascll - 97
        
        // hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x",int_ch1]];
        hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x", hex_char1]];
        
        unichar hex_char2 = arrData[i]&0x0f; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2+48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2+55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2+87; //// a 的Ascll - 97
        
        hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x",hex_char2]];
        
        i++;
        
        //hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x",arrData[i]]];
        
        //  NSLog(@"hexString:%@",hexString);
    }
    
    // NSData *newData = [[NSData alloc] initWithBytes:bytes length:strLenght];
    // NSLog(@"newData=%@",newData);
    
    
    // NSData 2 NSString.
    // NSString *testString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
    
    return hexString;
}

- (NSString *)toGetFileName{
    // create file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // get the path
    // arg:NSDocumentDirectory: to get the path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // change to the path to be access
    [fileManager changeCurrentDirectoryPath:[documentsDirectory stringByExpandingTildeInPath]];
    
    // to get file's path
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"testAudio.caf"];
    
    return filePath;
}

#pragma mark - bleDevMonitorDelegate

/// display vole peripheral list
- (void)voleDisplayPeripherals //:(CBPeripheral *)aPeripheral
{
    [self.voleScanDevActInd stopAnimating];
    
    // create the alert
    NSArray *volePeriList = [[bleDevMonitor sharedInstance] discoveredPeripherals ];// [[otaFirmwareFile sharedInstance] enumBinFiles];
    
    self.voleDisplayDevicesVC = [TableViewAlert tableAlertWithTitle:@"Choose a Peripheral..." cancelButtonTitle:@"Cancel" numberOfRows:^NSInteger (NSInteger section)
                                 {
        return [volePeriList count];
    }
                                 
                                                           andCells:^UITableViewCell* (TableViewAlert *anAlert, NSIndexPath *indexPath)
                                 {
        static NSString *CellIdentifier = @"CellIdentifier";
        UITableViewCell *cell = [anAlert.table dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        //cell.textLabel.text = [[volePeriList objectAtIndex:indexPath.row] name];
        NSString *temp=[[NSUserDefaults standardUserDefaults] valueForKey:@"localName"];
        cell.textLabel.text=temp;
        
        return cell;
    }];
    
    // Setting custom alert height
    self.voleDisplayDevicesVC.height = 250;
    
    // configure actions to perform
    [self.voleDisplayDevicesVC configureSelectionBlock:^(NSIndexPath *selectedIndex){
        self.devNameLabel.text = [[volePeriList objectAtIndex:selectedIndex.row] name];
        
        NSDictionary *dictPeri = [NSDictionary dictionaryWithObject : [volePeriList objectAtIndex:selectedIndex.row] forKey:@"selectedDevice"];
        
        [[NSNotificationCenter defaultCenter]postNotificationName: voleSelOnePeripheralNoti object:nil userInfo:dictPeri];
        
    } andCompletionBlock:^{
        self.devNameLabel.text = @"No Device! \n";
    }];
    
    // show the alert
    [self.voleDisplayDevicesVC show];
}

/// connect act ind.
- (void) voleStartDidConnActInd
{
    [self.voleDidConnDevActInd startAnimating];
    
    // voleDidConnDevTimeoutCount = 0;
    
    voleDidConnDevTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval : VOLE_DIDCONN_DEV_TIMEOUT/* VOLE_TIMER_STEP */ target:self selector:@selector(voleDidConnDevTimeoutRsp) userInfo:nil repeats : NO];
}

- (void)voleSelOnePeripheralRsp :(NSNotification *)notifyFromPeripheral
{
    NSLog(@"%s", __func__);
    
    CBPeripheral *selectedPeri = [notifyFromPeripheral.userInfo objectForKey:@"selectedDevice"];
    
    NSLog(@"testPeri = %@ \n", selectedPeri);
    
    /// to conect the peripheral
    bleDevMonitor *dev = [bleDevMonitor sharedInstance];
    [dev stopScan];
    
    [self voleStartDidConnActInd];
    
    [dev connectPeripheral : selectedPeri];
}

- (void) voleDidConnDevTimeoutRsp{
    
    // voleDidConnDevTimeoutCount++;
    
    // if(voleDidConnDevTimeoutCount > VOLE_DIDCONN_DEV_TIMEOUT)
    {
        [self voleStopDidConnDevTimeout];
        
        /// to scan a device timeout.
        CustomAlertView *voleDidConnDevAlert = [[CustomAlertView alloc] initWithTitle:@"Warning!"
                                                                              message:@"Connection Failed!"
                                                                             delegate:nil
                                                                    cancelButtonTitle:nil/*@"Cancel" */
                                                                    otherButtonTitles:@"OK", nil];
        [voleDidConnDevAlert show];
    }
}

- (void) voleStopDidConnDevTimeout
{
    voleDidConnDevTimeoutCount = 0;
    [voleDidConnDevTimeoutTimer invalidate];
    [self.voleDidConnDevActInd stopAnimating];
}

- (void)voleResetVC{
    //    received_data_length = 0;
    
    _voleScanDevActInd.hidesWhenStopped = YES;
    _voleDidConnDevActInd.hidesWhenStopped = YES;
    
    [self.voleScanDevActInd stopAnimating];
    [self.voleDidConnDevActInd stopAnimating];
    
    // _voleLoadFileBtn.hidden = YES;
    
    /// data rate
    // volePreTimeMs = 0l;
    // voleCurTimeMs = 0l;
    
    voleScanDevTimeoutCount = 0;
    [voleScanDevTimeoutTimer invalidate];
    
    voleDidConnDevTimeoutCount = 0;
    [voleDidConnDevTimeoutTimer invalidate];
    
}

-(void) volePlayerReset
{
    writeBuf = [NSMutableData alloc] ;
    
    received_data_length = 0;
}

- (void)updateScanCountDown : (BOOL)flag withCount : (uint8_t)ScanCountDn
{
    if(flag)
    {
        _voleScanCountDnLbl.text = [NSString stringWithFormat:@"%d", ScanCountDn];
        _voleScanCountDnLbl.hidden = NO;
        _voleScanCountDnUnitLbl.hidden = NO;
    }
    else
    {
        _voleScanCountDnLbl.text = @"0";
        _voleScanCountDnLbl.hidden = YES;
        _voleScanCountDnUnitLbl.hidden = YES;
    }
}

- (void) voleUpdateDidConnDev
{
    NSLog(@"method: %s", __func__);
    
    [self voleStopDidConnDevTimeout];
    [self refreshConnectBtns];
}

@end


