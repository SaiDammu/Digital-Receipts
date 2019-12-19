//
//  OtaViewController.m
//  OtaDemo
//
//  @brief Application Source File for OTA Main View Controller.
//
//  Created by NXP on 4/21/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import "OtaApi.h"
#import "qnLoadFile.h"

#import "QnAlertView.h"

#import "DeviceViewController.h"
#import "FwFileViewController.h"

/// #import "QBleServer.h"

#import "OtaAppPublic.h"
#import "RootViewController.h"

const uint8_t *fileTestData = nil;
uint8_t        fileTestArr[20] = {0xf1,0xa2,0x03,0x01,0x02,0x03,0x01,0x02,0x03,0x01,0x02,0x03,0x01,0xd2,0x03};

@interface RootViewController () {
    NSTimer *qnAdvertisingTimer;
    
    CBPeripheral *otaConnectedPeri;
    CBPeripheral *aConnectedPeri;
    
    NSArray *OTA_StateInfoArr;
    
    BOOL _otaResume;
    
    BOOL _isOtaService;
    
    NSTimer *otaDidConnDevTimeoutTimer;
    
    enum otaEnableResult otaEnableStatus;
    
    NSTimer *otaResumeTimer;

    NSTimer *otaDownloadCountTimer;
    uint16_t otaDownloadCount;
    
    /// bin file no response.
    NSTimer *otaFwBinNoRspTimer;
    uint8_t otaFwNoRspTimeoutCount;
    
    DeviceViewController *deviceVC;
    BOOL flagOnePeriScanned;           /// one peripheral is scanned.
    
    FwFileViewController *fwFileVC;
    
    
@public
    uint16_t pubFwLength;
    u_int64_t preTimeMs, curTimeMs;
}

//@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
//@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;

@property (readwrite) enumOtaClientState OTA_ClientState;
 
@end

@implementation RootViewController

@synthesize OTA_ClientState;

NSString *slaveBinFileName;

BOOL flagOtaProccessing = FALSE;

-(id)init {
    
    return self;
}

+(RootViewController *)sharedInstance{
    static RootViewController *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[RootViewController alloc] init];
    }
    
    return _sharedInstance;
}

//
// state
//
// returns the state value.
//
- (enumOtaClientState)OTA_ClientState
{
    @synchronized(self)
    {
        return OTA_ClientState;
    }
}
//
// setState:
//
// Sets the state and sends a notification that the state has changed.
//
// This method
//
// Parameters:
//    anErrorCode - the error condition
//

- (void)setOTA_ClientState : (enumOtaClientState) aStatus
{
    @synchronized(self)
    {
        if (OTA_ClientState != aStatus)
        {
            OTA_ClientState = aStatus;
        }
    }
}

- (void)otaReset{
    OTA_ClientState = OTA_MS_IDLE;
    
    otaConnectedPeri = nil;
    
    _otaScanDevActInd.hidesWhenStopped = YES;
    _otaDidConnDevActInd.hidesWhenStopped = YES;
    
    [self.otaScanDevActInd stopAnimating];
    [self.otaDidConnDevActInd stopAnimating];
    
    flagOnePeriScanned = FALSE;
    
    /// progress status
    _otaProgressBar.progress = 0.00f;
    _otaProgressBarValue.text = [NSString stringWithFormat: @"%d%@", (uint16_t)(_otaProgressBar.progress * 100), @"%"];
    
    _otaDataRateLbl.text = @"0";
    
    [otaDownloadCountTimer invalidate];
    
    otaDownloadCount = 0;
    _otaLoadTimeLbl.text = @"0";
    
    [self otaDisplayLoadStatusInfo : NO];
    
    preTimeMs = 0l;
    curTimeMs = 0l;
    
    _otaResume = NO;
    flagOtaProccessing = FALSE;
    _otaLoadFileBtn.hidden = YES;
    
    otaFwNoRspTimeoutCount = 0;
    [otaFwBinNoRspTimer invalidate];
}

-(void)otaUserInit{
    
    otaEnableStatus = OTA_CONFIRM_FAILED;
    
    OTA_StateInfoArr = [NSArray arrayWithObjects:@"Scan",
                        @"Scanning",
                        @"Connecting",
                        @"Connected",
                        @"Disconnecting",
                        @"Disconnected",
                        @"Retrieving",
                        @"Retrieved",
                        @"Downloading...",
                        @"Downloaded",
                        @"Error!",
                        nil];
    
    otaRspCmdArr = [NSArray arrayWithObjects:@"OTA_CMD_NONE",
                    @"OTA_CMD_META_DATA",
                    @"OTA_CMD_BRICK_DATA",
                    @"OTA_CMD_DATA_VERIFY",
                    @"OTA_CMD_EXECUTION_NEW_CODE",
                    nil];
    
    otaRspResultArr = [NSArray arrayWithObjects : @"OTA_RESULT_SUCCESS",
                       @"OTA_RESULT_CHECKSUM_ERROR",// = 1,
                       @"OTA_RESULT_FAIL",
                       @"OTA_RESULT_UNKNOWN",
                       nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sleep(2);
    
    /// _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    [self otaUserInit];
    
    // Do any additional setup after loading the view from its nib.
    self.title = @"OTA";
    
   // [self.OtaVersion setText:[NSString stringWithFormat: @"Ver %1.2f", QBLUE_OTA_VERSION]];
    
    [self otaReset];
    [self scanButton].enabled = TRUE;
    
    /// Note : Please setup for qBleClient connections delegate.
    /// [QBleServer sharedInstance].bleDidPeriConnectedDelegate = self;
    
    /// Note : Please setup for qBleClient connections delegate.
    [qBleClient sharedInstance].bleDidCentConnectPeriDelegate = self;
    /// Note : Please setup for OtaApi update delegate.
    [otaApi sharedInstance].otaApiUpdateAppDataDelegate = self;
    /// Note : Please setup for OtaEnable update delegate.
    [otaApi sharedInstance].otaEnableConfirmDelegate = self;
    
    // UI
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaDidPeriDiscoveredRsp)
                                                  name: blePeriDiscoveredNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaMainVcStopScan) name : mainVcStopScanNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaNoDeviceRsp) name:otaNoDeviceNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaNoOtaServicesRsp) name: otaNoOtaServiceNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaDidRetrievePeriRsp:) name: otaRetrievePeriNoti object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaDisplayPeripherals) name:bleScanDevEndNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaSelOnePeripheralRsp:) name:otaAppSelOnePeripheralNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaSelectedOneFileRsp:) name:otaAppSelectedOneFileNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaDidDiscoveredServicesRsp) name: bleDiscoveredServicesNoti object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaDidDiscoveredCharsRsp) name: bleDiscoveredCharacteristicsNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaEnableConfirmRsp:) name: otaEnableConfirmNoti object:nil];
    
    // rsp ota app error
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaPkgCheckSumErrorRsp) name:otaPkgCheckSumErrorNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaPkgLengthErrorRsp) name:otaPkgLengthErrorNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (otaAppDevNotSupportOtaRsp) name:otaAppDevNotSupportOtaNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaAppSizeErrorRsp) name:otaAppSizeErrorNoti object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaAppVerifyErrorRsp:) name:otaAppVerifyErrorNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaAppVerifyErrorRsp) name:otaAppVerifyErrorNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaReSelectedOneFileRsp) name:otaReLoadFirmwarewFileNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaFwNoRspTimeoutRsp) name : otaFwNoRspTimeoutNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaConnectTimeoutRsp) name : otaConnectTimeoutNoti object:nil];
    
    // DeviceViewController *
    deviceVC = [[DeviceViewController alloc] initWithNibName:@"DeviceViewController" bundle:nil];
    fwFileVC = [[FwFileViewController alloc] initWithNibName:@"FwFileViewController" bundle:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    ///
    //// [[QBleServer sharedInstance] stopAdvertising];
    
    [super viewWillDisappear:animated];
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSDictionary *dictBtnIndex;
    
    if([alertView.title isEqualToString: ALERT_NODEVICE_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaNoDeviceNoti object:nil ];
    }
    else if([alertView.title isEqualToString: ALERT_NO_OTA_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaNoOtaServiceNoti object:nil userInfo : nil];
    }
    else if([alertView.title isEqualToString: ALERT_RETRIEVE_TITLE])
    {
        dictBtnIndex = [NSDictionary dictionaryWithObject : [NSString stringWithFormat:@"%ld", (long)buttonIndex] forKey:keyAlertRetrieve];
        
        [[NSNotificationCenter defaultCenter] postNotificationName : otaRetrievePeriNoti object:nil userInfo : dictBtnIndex];
    }
    else if([alertView.title isEqualToString : ALERT_CONNECT_FAIL_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaConnectTimeoutNoti object:nil userInfo : nil];
    }
    else if([alertView.title isEqualToString: ALERT_PKG_CS_ERROR_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaPkgCheckSumErrorNoti object:nil userInfo : nil];
    }
    else if([alertView.title isEqualToString : ALERT_APP_PKG_LENGTH_ERROR_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaPkgLengthErrorNoti object:nil userInfo : nil];
    }
    else if([alertView.title isEqualToString : ALERT_APP_SIZE_ERROR_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaAppSizeErrorNoti object : nil userInfo : nil];
    }
    else if([alertView.title isEqualToString: ALERT_APP_VERIFY_ERROR_TITLE])
    {
//        dictBtnIndex = [NSDictionary dictionaryWithObject : [NSString stringWithFormat:@"%u", buttonIndex] forKey:keyAlertFailed];
//
//        [[NSNotificationCenter defaultCenter] postNotificationName : otaAppVerifyErrorNoti object:nil userInfo : dictBtnIndex];
        [[NSNotificationCenter defaultCenter] postNotificationName : otaAppVerifyErrorNoti object:nil userInfo : nil];
    }

    else if([alertView.title isEqualToString : ALERT_DEV_NOT_SUPPORT_OTA_TITLE])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : otaAppDevNotSupportOtaNoti object:nil userInfo : nil];
    }

    
    else if([alertView.title isEqualToString : ALERT_FILE_MIN_TITLE])
    {
        /// if(buttonIndex == OTA_BTN_CANCEL)
        [[NSNotificationCenter defaultCenter] postNotificationName : otaReLoadFirmwarewFileNoti object:nil userInfo : nil];
    }
    else if([alertView.title isEqualToString: ALERT_FILE_MAX_TITLE])
    {
        /// if(buttonIndex == OTA_BTN_CANCEL)
        [[NSNotificationCenter defaultCenter] postNotificationName : otaReLoadFirmwarewFileNoti object:nil userInfo : nil];
    }
    
    else if([alertView.title isEqualToString: ALERT_FW_NO_RSP_TITLE])
    {
        /// if(buttonIndex == OTA_BTN_CANCEL)
        [[NSNotificationCenter defaultCenter] postNotificationName : otaFwNoRspTimeoutNoti object:nil userInfo : nil];
    }
}

/**
 ****************************************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 ****************************************************************************************
 */
-(void)bleDidConnectPeripheral : (CBPeripheral *)aPeripheral{
    [otaDidConnDevTimeoutTimer invalidate];
    
    if(_otaResume == YES)
    {
        aConnectedPeri = otaConnectedPeri;
    }
    else ///
    {
        
    }
    
    /// there is ota service
    if(aPeripheral.identifier != aConnectedPeri.identifier)
    {
        return;
    }
    
    if(aPeripheral == otaConnectedPeri)
    {
        [[otaApi sharedInstance] otaEnable : otaConnectedPeri
                           withServiceUUID : UUID_OTA_SERVICE_DEF];
    }
    
    OTA_ClientState = OTA_MS_CONNECTED;
    
  //  [self.navigationController popViewControllerAnimated : YES];
    
    /////
    [self otaStopDidConnDevTimeout];
    [self refreshOtaClientState];
}

/**
 ****************************************************************************************
 * @brief       delegate ble update disconnected peripheral.
 *
 * @param[out]  aPeripheral : the disconnected peripheral.
 * @param[out]  error
 *
 ****************************************************************************************
 */
-(void)bleDidDisconnectPeripheral : (CBPeripheral *)aPeripheral error : (NSError *)error{
    aConnectedPeri = nil;
    
    OTA_ClientState = OTA_MS_IDLE;
    
    [self refreshOtaClientState];
    
    if(flagOtaProccessing == TRUE)
    {
        QnAlertView *otaResumeAlert = [[QnAlertView alloc] initWithTitle : ALERT_RETRIEVE_TITLE
                                                                 message : @"Do you want to re-connect?"
                                                                delegate : self /* to map key rsp */
                                                       cancelButtonTitle : @"No"
                                                       otherButtonTitles : @"Yes", nil];
        [otaResumeAlert show];
    }
}

/**
 ****************************************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 ****************************************************************************************
 */
-(void)bleDidRetrievePeripheral : (NSArray *)aPeripheral{
    
    OTA_ClientState = OTA_MS_RETRIEVED;
    [self updateScanBtn];
    
    [otaResumeTimer invalidate];
}

/**
 ****************************************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 ****************************************************************************************
 */
-(void)bleDidFailToConnectPeripheral : (CBPeripheral *)aPeripheral
                               error : (NSError *)error{
    OTA_ClientState = OTA_MS_IDLE;
    
    [self updateScanBtn];
}

- (void) didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    [qnAdvertisingTimer invalidate];
}

- (void) didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    [qnAdvertisingTimer invalidate];}

/// central -> Peripheral

- (IBAction)scanPeripheral:(id)sender {
    qBleClient *dev = [qBleClient sharedInstance];
    
    BOOL isConnected = (aConnectedPeri.state == CBPeripheralStateConnected);
    if (isConnected) {
        [self otaReset];
        
        [self.scanButton setTitle : @"Scan" forState:UIControlStateNormal];
        
        OTA_ClientState = OTA_MS_DISCONNECTING;
        
        [dev pubDisconnectPeripheral : aConnectedPeri];
    }
    else
    {
        if(OTA_ClientState != OTA_MS_SCANNING && OTA_ClientState != OTA_MS_CONNECTING)
        {
            OTA_ClientState = OTA_MS_SCANNING;
            
            [self.otaScanDevActInd startAnimating];
            
            [dev stopScan];
            
            [dev startScan];
        }
    }
}

- (void)otaSelOnePeripheralRsp :(NSNotification *)notifyFromPeripheral
{
    aConnectedPeri = [notifyFromPeripheral.userInfo objectForKey : keyOtaAppSelectPeri];
    
    /// to conect the peripheral
    qBleClient *dev = [qBleClient sharedInstance];
    [dev stopScan];
    
    OTA_ClientState = OTA_MS_CONNECTING;
    
    [self updateScanBtn];
    
    /// reg ota end
    
    [self otaStartDidConnActInd];
    
    [dev pubConnectPeripheral : aConnectedPeri];
}

- (void)otaSelectedOneFileRsp :(NSNotification *)notifyFromFile
{
    slaveBinFileName = [notifyFromFile.userInfo objectForKey : keyOtaAppSelectFile];
    
    [self otaSelectOneFileAndLoad : slaveBinFileName ];
}

- (void)otaSelectOneFileAndLoad :(NSString *)fileName
{
    OTA_ClientState = OTA_MS_DOWNLOADING;
    
    [self updateScanBtn];
    
    newFwFile = [[qnLoadFile sharedInstance] readBinFile : fileName];
    
    const uint8_t *newFwFileByte = [newFwFile bytes];
    
    // uint32_t
    pubFwLength = [newFwFile length];
    
    if(pubFwLength == FW_FILE_CODE_LENGTH_MIN)
    {
        QnAlertView *otaOpenFileAlert = [[QnAlertView alloc] initWithTitle : ALERT_FILE_MIN_TITLE
                                                                   message : @"The firmware size is zero!"
                                                                  delegate : self
                                                         cancelButtonTitle : @"OK"
                                                         otherButtonTitles : nil, nil];
        [otaOpenFileAlert show];
        
        return;
    }
    
    if(pubFwLength > FW_FILE_CODE_LENGTH_MAX)
    {
        QnAlertView *otaOpenFileAlert = [[QnAlertView alloc] initWithTitle : ALERT_FILE_MAX_TITLE
                                                                   message : @"The firmware size exceeds the maximum size allowed!"
                                                                  delegate : self
                                                         cancelButtonTitle : @"OK"
                                                         otherButtonTitles : nil, nil];
        [otaOpenFileAlert show];
        
        return;
    }
    
    // ===== to start download ======
    BOOL isConnected = (aConnectedPeri.state == CBPeripheralStateConnected);
    if (isConnected) {
        _otaProgressBar.progress = 0.0f;
        _otaProgressBarValue.text = [NSString stringWithFormat: @"%d%@", 0,@"%"];
        
        [self otaDisplayLoadStatusInfo : YES];
        
        otaDownloadCountTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(otaUpdateDownloadCount) userInfo:nil repeats:YES];
        
        /// [self otaSetupRefTime];
        
        _otaLoadFileBtn.hidden = YES;
        
        if(otaConnectedPeri)
        {
            [self otaStartUIReset];
            
            [[otaApi sharedInstance] otaStart : otaConnectedPeri
                                 withDataByte : newFwFileByte
                                   withLength : pubFwLength
                                     withFlag : FALSE];
        }
    }
}

/***************************************************
 @brief re-select a bin file
 ***************************************************/
-(void)otaReSelectedOneFileRsp{
    [[NSNotificationCenter defaultCenter] postNotificationName: appFileListReloadDataNoti object:nil userInfo:nil];
    
    /// [self presentModalViewController : fwFileVC animated:YES];
    [self presentViewController:fwFileVC animated:YES completion:nil ];
}

/***************************************************
 @brief open  a bin file view
 ***************************************************/
- (IBAction)otaOpenFwFileVC:(id)sender {
    BOOL isConnected = (aConnectedPeri.state == CBPeripheralStateConnected);
    
    if(isConnected == FALSE)
    {
        QnAlertView *otaNoConnectionAlert = [[QnAlertView alloc] initWithTitle : ALERT_NO_CONNECT_TITLE
                                                                       message:@"No connection!"
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:@"OK", nil];
        [otaNoConnectionAlert show];
        
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: appFileListReloadDataNoti object:nil userInfo:nil];
    
    //[self presentModalViewController : fwFileVC animated:YES];
    [self presentViewController:fwFileVC animated:YES completion:nil ];
}

- (NSString *) otaSlaveFileName
{
    return slaveBinFileName;
}

/// display ota peripheral list
- (void)otaDisplayPeripherals
{
    OTA_ClientState = OTA_MS_IDLE;
    [self updateScanBtn];
    [self.otaScanDevActInd stopAnimating];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: appDevListReloadDataNoti object:nil userInfo:nil];
    
    /// [self presentModalViewController : deviceVC animated:YES];
    deviceVC.isOTA = YES;
    [self presentViewController:deviceVC animated:YES completion:nil ];
}


- (void) otaUpdateDidConnDev
{
    [self otaStopDidConnDevTimeout];
    [self refreshOtaClientState];
}

- (void)updateScanBtn {
    NSString *strScanBtn;
    
    if(OTA_ClientState == OTA_MS_IDLE){
        strScanBtn = @"Scan";
        _otaLoadFileBtn.hidden = YES;
    }else{
        strScanBtn = @"Disconnect";
        _otaLoadFileBtn.hidden = NO;
    }

    [self.scanButton setTitle : strScanBtn forState : UIControlStateNormal];
}

- (void)refreshOtaClientState {
    [self updateScanBtn];
    BOOL isConnected = (aConnectedPeri.state == CBPeripheralStateConnected);
    if (isConnected)
    {
        NSString *dev_name = aConnectedPeri.name;
        
        if (dev_name)
        {
            self.devNameLabel.text = dev_name;
        }
        else
        {
            self.devNameLabel.text = @"No Name !\n";
        }
        
        self.connStatusLabel.text = @"<>";
    }
    else
    {
        self.connStatusLabel.text = @"><";
        self.devNameLabel.text = @"No Device! \n";
        
        _otaLoadFileBtn.hidden = YES; ///
    }
}

#pragma mark - RECEIVED_DATA_LENGTH

- (void)viewDidUnload {
    //    [self setReceivedDataLabel:nil];
    [self setDevNameLabel:nil];
    [self setConnStatusLabel:nil];
    //    deviceList = nil;
    [super viewDidUnload];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

- (BOOL)shouldAutorOtateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return NO;
}

/**
 ****************************************************************************************
 * @brief       Update the result of the meta data sent.
 *
 * @param[out]  otaMetaDataSentStatus : the status of the meta data sent.
 *                                      OTA_RESULT_SUCCESS | OTA_RESULT_DEVICE_NOT_SUPPORT_OTA
 * @ref         enum otaResult definitions
 *
 * @return : none
 ****************************************************************************************
 */
-(void)didOtaMetaDataResult : (enum otaResult)otaMetaDataSentStatus{
    
}

/**********************************************************
 @breif : updating loading result : dispatch different warning
          according to the different result
 @refer : the enum otaApiResult
 **********************************************************/
- (void)didOtaAppProgress : (enum otaResult)otaPackageSentStatus
             withDataSent : (uint16_t)otaDataSent
{
    otaFwNoRspTimeoutCount = 0;
    
    enum otaResult otaPackageStatus = otaPackageSentStatus;
    
    if(otaPackageStatus == OTA_RESULT_SUCCESS)
    {
        [self otaAppUpdateProgress : otaDataSent];
        
        [self otaAppUpdateDataRate : otaDataSent >> 8];
    }
    else if(otaPackageStatus == OTA_RESULT_PKT_CHECKSUM_ERROR){
        
        [self otaPkgCheckSumErrorWarning];
    }
    else if(otaPackageStatus == OTA_RESULT_PKT_LEN_ERROR){
        
        [self otaAppPkgLengthErrorWarning];
    }
    else if(otaPackageStatus == OTA_RESULT_DEVICE_NOT_SUPPORT_OTA){
        
        [self otaAppNotSupportOtaWarning];
    }
    else if(otaPackageStatus == OTA_RESULT_FW_SIZE_ERROR){
        
        [self otaAppSizeErrorWarning];
    }
    else if(otaPackageStatus == OTA_RESULT_FW_VERIFY_ERROR){
        [self otaAppVerifyErrorWarning];
    }
}

/**********************************************************
 @breif : update progress bar.
 **********************************************************/
-(void)otaAppUpdateProgress : (uint16_t )dataSent
{
    /// uint8_t sentPkg = (uint8_t)(dataSent >> 8);
    
    /// float progBarValue = (float)(100 * sentPkg / (pubFwLength >> 8 ));
    float progBarValue = (float)(100 * dataSent / pubFwLength);
    
    if(progBarValue > 100.0) /// bug3
        progBarValue = 100.0;
    
    _otaProgressBar.progress = (float)progBarValue / 100;
    
    _otaProgressBarValue.text = [NSString stringWithFormat: @"%d%@", (uint8_t)progBarValue, @"%"];
}

-(void)didOtaEnableConfirm : (CBPeripheral *)aPeripheral
                withStatus : (enum otaEnableResult) otaEnableResult{
    
    otaEnableStatus = otaEnableResult;
    
    if(otaEnableStatus == OTA_CONFIRM_OK)
    {
        if(!_isOtaService)
            return;
        
        _otaLoadFileBtn.hidden = NO;
        
        otaConnectedPeri = aConnectedPeri;
        
        if(_otaResume == YES)
        {
            [otaResumeTimer invalidate];
             
            _otaResume = NO;
            
            if(otaConnectedPeri)
            {
                _otaLoadFileBtn.hidden = YES;
                                
                [self otaStartUIReset];
                
                [[otaApi sharedInstance] otaStart : otaConnectedPeri withDataByte : nil withLength: 0 withFlag : TRUE];
            }
        }
    }
    else
    {
        
    }
}

-(void)otaStartUIReset{
    [self otaFwNoRspTimeoutReq];
    
    [self otaSetupRefTime];
    
    flagOtaProccessing = TRUE;
}

/**********************************************************
 @brief response to discovered Char .
 **********************************************************/
-(void)otaEnableConfirmRsp : (NSNotification *)noti
{
    ///CBPeripheral *otaPeri = [noti.userInfo objectForKey : keyOtaPeripheral];
    
    NSData *statusData = [noti.userInfo objectForKey : keyOtaEnableConfirm];
    
    const uint8_t *statusOta = [statusData bytes];
    
    otaEnableStatus = (enum otaEnableResult)statusOta[0];
    
    if(otaEnableStatus == OTA_CONFIRM_OK)
    {

    }
    else
    {
        
    }
}

#pragma mark - UI
/**********************************************************
 @breif : switch to hide progress bar or not.
 **********************************************************/
-(void)otaHideProgressBar:(BOOL) flagHiden{
    if(flagHiden){
        _otaProgressBar.hidden = YES;
        _otaProgressBarValue.hidden = YES;
    }
    else{
        _otaProgressBar.hidden = NO;
        _otaProgressBarValue.hidden = NO;
    }
}

/**********************************************************
 @breif : setup reference time
 **********************************************************/
-(void)otaSetupRefTime{
    NSDate *  currentTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    preTimeMs = [self getDateTimeTOMilliSeconds : currentTime];
}

/**********************************************************
 @breif : update the loading data rate(it is average value)
 **********************************************************/
-(void)otaAppUpdateDataRate:(uint8_t) otaSentPkg{
    NSDate *  currentTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    curTimeMs = [self getDateTimeTOMilliSeconds : currentTime];
    
    uint64_t deltaTime = curTimeMs - preTimeMs;
    
    /// to xxx.x KBit/Sec
    /********************
     270(Byte) * 8(Bit) * 1000(s) / deltaTime(ms).
     ********************/
    
    float otaDataRate = (otaSentPkg * 256 * 1000 / deltaTime);
    
    _otaDataRateLbl.text = [NSString stringWithFormat:@"%lld", (uint64_t)(otaDataRate)];
}

/**********************************************************
 @breif : to get the current time according to the reference time.
 **********************************************************/
- (NSDate *)getDateTimeFromMilliSeconds:(uint64_t) miliSeconds
{
    NSTimeInterval tempMilli = miliSeconds;
    NSTimeInterval seconds = tempMilli/1000.0;
    
    return [NSDate dateWithTimeIntervalSince1970 : seconds];
}

/**********************************************************
 @breif : convert time with NSDate format into NSInteger,
 from 1970/1/1
 **********************************************************/
- (uint64_t)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    
    uint64_t totalMilliseconds = interval*1000 ;
    
    return totalMilliseconds;
}

/**********************************************************
 @breif : refresh loading result.
 **********************************************************/
-(void)didOtaAppResult : (enum otaResult )otaResult
{
    if(otaResult == OTA_RESULT_SUCCESS)
    {
        [self otaReset];
        
        OTA_ClientState = OTA_MS_DISCONNECTING;
    }
    else
    {
        OTA_ClientState = OTA_MS_ERROR;
    }
    
    [self updateScanBtn];
}

/**********************************************************
 @breif : switch fw filename to hide or not.
 **********************************************************/
-(void)otaHideFileName:(BOOL) flagHiden{
    if(flagHiden){
        _otaBinFileLbl.hidden = YES;
        _otaBinFileLbl.hidden = YES;
    }
    else{
        _otaBinFileLbl.hidden = NO;
        _otaBinFileLbl.hidden = NO;
    }
}
/**********************************************************
 @breif : switch data rate to hide or not.
 **********************************************************/
-(void)otaHideDataRate:(BOOL) flagHiden{
    if(flagHiden){
        _otaDataRateLbl.hidden = YES;
        _otaDataRateBpsLbl.hidden = YES;
    }
    else{
        _otaDataRateLbl.hidden = NO;
        _otaDataRateBpsLbl.hidden = NO;
    }
}

/**********************************************************
 @brief switch loading count to hide or not.
 **********************************************************/
-(void)otaHideLoadCount:(BOOL) flagHiden{
    if(flagHiden){
        _otaLoadTimeLbl.hidden = YES;
        _otaLoadTimeUnitLbl.hidden = YES;
    }
    else{
        _otaLoadTimeLbl.hidden = NO;
        _otaLoadTimeUnitLbl.hidden = NO;
    }
}

/**********************************************************
 @brief refresh the loading count.
 **********************************************************/
- (void) otaUpdateDownloadCount
{
    otaDownloadCount++;
    _otaLoadTimeLbl.text = [NSString stringWithFormat:@"%d", otaDownloadCount];
}

/**********************************************************
 @brief start the connection indicator.
 **********************************************************/
- (void) otaStartDidConnActInd
{
    [self scanButton].enabled = TRUE;
    
    [self.otaDidConnDevActInd startAnimating];
    
    // otaDidConnDevTimeoutCount = 0;
    
    otaDidConnDevTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval : DIDCONN_DEV_TIMEOUT target:self selector:@selector(otaDidConnDevTimeoutRsp) userInfo:nil repeats : NO];
}

/**********************************************************
 @brief response to the connection device timeout.
 **********************************************************/
- (void) otaDidConnDevTimeoutRsp{
    
    // otaDidConnDevTimeoutCount++;
    
    // if(otaDidConnDevTimeoutCount > DIDCONN_DEV_TIMEOUT)
    {
        [self otaStopDidConnDevTimeout];
        
        /// to scan a device timeout.
        QnAlertView *otaDidConnDevAlert = [[QnAlertView alloc] initWithTitle : ALERT_CONNECT_FAIL_TITLE
                                                                     message : @"Connection failed!"
                                                                    delegate : self
                                                           cancelButtonTitle : @"OK"
                                                           otherButtonTitles : Nil, nil];
        [otaDidConnDevAlert show];
    }
}

/**********************************************************
 @brief stop the disconnection device timeout.
 **********************************************************/
- (void) otaStopDidConnDevTimeout
{
    // otaDidConnDevTimeoutCount = 0;
    
    [otaDidConnDevTimeoutTimer invalidate];
    
    [self.otaDidConnDevActInd stopAnimating];
}

/**********************************************************
 @brief response to no OTA service.
 **********************************************************/
-(void)otaNoOtaServicesRsp
{
    if(aConnectedPeri != nil){
        OTA_ClientState = OTA_MS_DISCONNECTING;
        [[qBleClient sharedInstance] pubDisconnectPeripheral : aConnectedPeri];
    }
    else{
        OTA_ClientState = OTA_MS_IDLE;
    }
    
    [self refreshOtaClientState];
}

/**********************************************************
 @brief response to discovered service.
 **********************************************************/
-(void)otaDidDiscoveredServicesRsp
{
    _isOtaService = FALSE;
    
    for(CBService *aService in [[qBleClient sharedInstance] discoveredServices])
    {
        if([aService.UUID isEqual:[CBUUID UUIDWithString : UUID_OTA_SERVICE_DEF]])
        {
            _isOtaService = TRUE;
            break; ///
        }
    }
    
    if(!_isOtaService)
    {
        QnAlertView *otaOpenOtaServiceAlert =
        [[QnAlertView alloc] initWithTitle : ALERT_NO_OTA_TITLE
                                   message : @"No OTA service discovered,\n please scan again!"
                                  delegate : self
                         cancelButtonTitle : nil
                         otherButtonTitles : @"OK", nil];
        
        [otaOpenOtaServiceAlert show];
        
        return;
    }
}

/**********************************************************
 @brief UI response after retrieve end .
 **********************************************************/
- (void) otaDidRetrievePeriRsp : (NSNotification *)noti
{
    NSString *alertBtnIndex = [NSString stringWithFormat:@"%@", [noti.userInfo objectForKey:keyAlertRetrieve]];
    
    if([alertBtnIndex intValue] == OTA_BTN_OK)
    {
        _otaResume = YES;
        
        OTA_ClientState = OTA_MS_RETRIEVING;
        
        flagOtaProccessing = FALSE;
        
        [[qBleClient sharedInstance] stopScan];
        
        if(otaConnectedPeri) ///
        {
            [[qBleClient sharedInstance] pubRetrievePeripheral: otaConnectedPeri];
        
            [self otaResumeReq];
        }
    }
    else if([alertBtnIndex intValue] == OTA_BTN_CANCEL)
    {
        [self otaReset];
        
        _otaResume = NO;
        
        OTA_ClientState = OTA_MS_IDLE;
    }
    else
    {
        
    }
    
    [self updateScanBtn];
}

/**********************************************************
 @brief setup resume timeout.
 **********************************************************/
-(void)otaResumeReq{
    otaResumeTimer = [NSTimer scheduledTimerWithTimeInterval : RESUME_TIMEOUT target:self selector:@selector(otaResumeTimeoutRsp) userInfo:nil repeats : NO];
}

/**********************************************************
 @brief setup FwNoRsp Timeout Req .
 **********************************************************/
-(void)otaFwNoRspTimeoutReq{
    otaFwNoRspTimeoutCount = 0;
    
    [otaFwBinNoRspTimer invalidate];
    
    otaFwBinNoRspTimer = [NSTimer scheduledTimerWithTimeInterval : 1.0 target:self selector : @selector(otaFwNoRspTimeoutStart) userInfo:nil repeats : YES];
}

/**********************************************************
 @brief start FwNoRspTimer.
 **********************************************************/
-(void)otaFwNoRspTimeoutStart{
    otaFwNoRspTimeoutCount++;
    
    if(otaFwNoRspTimeoutCount > FW_NO_RSP_TIMEOUT)
    {
        otaFwNoRspTimeoutCount = 0;
        [otaFwBinNoRspTimer invalidate];
        
        [self otaFwNoRspTimeoutWarning];
    }
}

/**********************************************************
 @brief FwNoRspTimeout warning.
 **********************************************************/
- (void)otaFwNoRspTimeoutWarning
{
    QnAlertView *otaFwNoRspTimeoutAlert =
    [[QnAlertView alloc] initWithTitle : ALERT_FW_NO_RSP_TITLE
                               message : @"Please check the firmware \n and load it again!"
                              delegate : self
                     cancelButtonTitle : @"OK"
                     otherButtonTitles : nil, nil];
    
    [otaFwNoRspTimeoutAlert show];
}

/**********************************************************
 @brief response Fw No Rsp Timeout.
 **********************************************************/
-(void)otaFwNoRspTimeoutRsp{
    [otaFwBinNoRspTimer invalidate];
 
    otaFwNoRspTimeoutCount = 0;
    
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    
    [self updateScanBtn];
}

/**********************************************************
 @brief response to discover one device.
 **********************************************************/
- (void)otaDidPeriDiscoveredRsp{
    [[NSNotificationCenter defaultCenter] postNotificationName: appDevListReloadDataNoti object:nil userInfo:nil];
    
    if(flagOnePeriScanned == FALSE)
    {
        flagOnePeriScanned = TRUE;
        
        [self.otaScanDevActInd stopAnimating];
        
        ///[self presentModalViewController : deviceVC animated:YES];
        deviceVC.isOTA = YES;
        [self presentViewController:deviceVC animated:YES completion:nil ];
    }
}

/**********************************************************
 @brief response to stop scan.
 **********************************************************/
- (void)otaMainVcStopScan{
    flagOnePeriScanned = FALSE;
    OTA_ClientState = OTA_MS_IDLE;
    [[qBleClient sharedInstance] stopScan];
}

/**********************************************************
 @brief response to no device.
 **********************************************************/
- (void)otaNoDeviceRsp{
    OTA_ClientState = OTA_MS_IDLE;
    
    [self updateScanBtn];
}

/**********************************************************
 @brief response to each package check sum error.
 **********************************************************/
-(void)otaPkgCheckSumErrorRsp
{
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    [self updateScanBtn];
}

/**********************************************************
 @brief response to app package length error.
 **********************************************************/
-(void)otaPkgLengthErrorRsp
{
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    [self updateScanBtn];
}

/**********************************************************
 @brief response to app code size error.
 **********************************************************/
-(void)otaAppSizeErrorRsp
{
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    [self updateScanBtn];
}

/**********************************************************
 @brief response to Ota Info Invalid.
 **********************************************************/
-(void)otaAppDevNotSupportOtaRsp
{
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    [self updateScanBtn];
}

/**********************************************************
 @brief response to app verify error.
 **********************************************************/
-(void)otaAppVerifyErrorRsp
{
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    [self updateScanBtn];
}

/**********************************************************
 @brief response to connect timeout.
 **********************************************************/
-(void)otaConnectTimeoutRsp
{
    if(otaConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    if(aConnectedPeri != nil)
        [[qBleClient sharedInstance] pubDisconnectPeripheral : aConnectedPeri];
    
    [self otaReset];
    [self updateScanBtn];
}

#pragma ota results error wraning
/**********************************************************
 @brief alert to a package checksum error.
 **********************************************************/
- (void)otaPkgCheckSumErrorWarning
{
    QnAlertView *otaPkgCSErrorAlert =
                [[QnAlertView alloc] initWithTitle : ALERT_PKG_CS_ERROR_TITLE
                                           message : @"Please check the firmware \n and load it again!"
                                          delegate : self
                                 cancelButtonTitle : @"OK"
                                 otherButtonTitles : nil, nil];
    
    [otaPkgCSErrorAlert show];
}

/**********************************************************
 @brief alert to app total package length error.
 **********************************************************/
- (void)otaAppPkgLengthErrorWarning
{
    QnAlertView *otaPkgLengthErrorAlert =
                 [[QnAlertView alloc] initWithTitle : ALERT_APP_PKG_LENGTH_ERROR_TITLE
                                            message : @"Please check the firmware \n and load it again!"
                                           delegate : self
                                  cancelButtonTitle : @"OK"
                                  otherButtonTitles : nil, nil];
    
    [otaPkgLengthErrorAlert show];
}

/**********************************************************
 @brief alert to app code size error.
 **********************************************************/
- (void)otaAppSizeErrorWarning
{
    QnAlertView *otaAppSizeErrorAlert =
                [[QnAlertView alloc] initWithTitle : ALERT_APP_SIZE_ERROR_TITLE
                                           message : @"Please check the firmware \n and load it again!"
                                          delegate : self
                                 cancelButtonTitle : @"OK"
                                 otherButtonTitles : nil, nil];
    
    [otaAppSizeErrorAlert show];
}

/**********************************************************
 @brief alert to app verify error.
 **********************************************************/
- (void)otaAppVerifyErrorWarning
{
    QnAlertView *otaAppVerifyErrorAlert =
                [[QnAlertView alloc] initWithTitle : ALERT_APP_VERIFY_ERROR_TITLE
                                           message : @"Please check the firmware \n and load it again!"
                                          delegate : self
                                 cancelButtonTitle : @"OK"
                                 otherButtonTitles : nil, nil];
    
    [otaAppVerifyErrorAlert show];
}

/**********************************************************
 @brief alert to Ota Info Invalid.
 **********************************************************/
- (void)otaAppNotSupportOtaWarning
{
    QnAlertView *otaInfoInvalidErrorAlert =
                [[QnAlertView alloc] initWithTitle : ALERT_DEV_NOT_SUPPORT_OTA_TITLE
                                           message : @"Please enable OTA at the server side!"
                                          delegate : self
                                 cancelButtonTitle : @"OK"
                                 otherButtonTitles : nil, nil];
    
    [otaInfoInvalidErrorAlert show];
}

/**********************************************************
 @brief response to resume timeout.
 **********************************************************/
-(void)otaResumeTimeoutRsp
{
    [otaResumeTimer invalidate];
    
    /// cancel retrieve!
    [[qBleClient sharedInstance] pubDisconnectPeripheral : otaConnectedPeri];
    
    [self otaReset];
    
    [self updateScanBtn];
}

#pragma mark - UI process
/**********************************************************
 @brief switch to display Loading data or not.
 **********************************************************/
- (void) otaDisplayLoadStatusInfo:(BOOL)flag
{
    if(flag){
        [self otaHideFileName : NO];
        [self otaHideDataRate : NO];
        [self otaHideProgressBar : NO];
        [self otaHideLoadCount : NO];
    }
    else
    {
        [self otaHideFileName : YES];
        [self otaHideDataRate : YES];
        [self otaHideProgressBar : YES];
        [self otaHideLoadCount : YES];
    }
}




@end
