//
//  ViewController.m
//  sharingDemo
//
//  Created by 丁磊 on 2018/11/21.
//  Copyright © 2018 丁磊. All rights reserved.
//

#import "ViewController.h"
#import "MultipeerSession.h"    //分享的类
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController () <ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate, UIGestureRecognizerDelegate,MultipeerSessionDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (retain, nonatomic) MultipeerSession *multipeerSession;
@property (strong, nonatomic) MCPeerID *mapProvider;

@property (nonatomic, retain) ARWorldTrackingConfiguration *arConfig;
@property (nonatomic) ARTrackingState currentTrackingState;
@property (strong, nonatomic) UILabel *sessionInfoLabel;
@property (strong, nonatomic) UILabel *mappingStatusLabel;
@property (strong, nonatomic) UIButton *sendMapButton; //分享按钮
@property (strong, nonatomic) UIButton *resetButton;   //重置按钮
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;   //点击手势

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addGestureRecognizer: self.tapGesture];
    [self.view addSubview: self.sendMapButton];
    [self.view addSubview: self.mappingStatusLabel];
    [self.view addSubview: self.sessionInfoLabel];
    [self.view addSubview: self.resetButton];
     // Set the view's delegate
    self.sceneView.delegate = self;
    self.sceneView.session.delegate = self;
    self.currentTrackingState = ARTrackingStateNormal;
    NSData *data = [[NSData alloc] init];
    
    //初始化
    self.multipeerSession = [MultipeerSession MultipeerSessionWithReceivedData:data fromPeer:self.mapProvider];
    self.multipeerSession.delegate = self;

    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    
    // Create a new scene
//    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    
    // Set the scene to the view
//    self.sceneView.scene = scene;
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([ARWorldTrackingConfiguration isSupported]) {
    }
    else
        NSLog(@"ARKit is not available on this device. For apps that require ARKitfor core functionality, use the `arkit` key in the key in the `UIRequiredDeviceCapabilities` section of the Info.plist to prevent the app from installing. (If the app can't be installed, this error can't be triggered in a production scenario.)In apps where AR is an additive feature, use `isSupported` to determine whether to show UI for launching AR experiences.");
    
    // Create a session configuration
    self.arConfig = [[ARWorldTrackingConfiguration alloc] init];
    self.arConfig.planeDetection = ARPlaneDetectionHorizontal;
    // Run the view's session
    
    [self.sceneView.session runWithConfiguration:self.arConfig];
    self.sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    //显示xyz轴
//    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin;
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}


//MultipeerSessionDelegate -- 接收到附近设备的数据后调用
- (void)receivedData:(NSData *)data fromPeers:(MCPeerID *)peer{
    ARWorldMap *worldMap = [NSKeyedUnarchiver unarchivedObjectOfClass: [ARWorldMap class] fromData:data error:nil];
    if (worldMap) {
        self.arConfig.planeDetection = ARPlaneDetectionHorizontal;
        self.arConfig.initialWorldMap = worldMap;
        [self.sceneView.session runWithConfiguration:self.arConfig options:ARSessionRunOptionResetTracking | ARSessionRunOptionRemoveExistingAnchors];
        self.mapProvider = peer;
    }
    ARAnchor *anchor = [NSKeyedUnarchiver unarchivedObjectOfClass:[ARAnchor class] fromData:data error:nil];
    if (anchor) {
        [self.sceneView.session addAnchor: anchor];
    }
    else
        NSLog(@"unknown data recieved from %@",peer);
    
}

// 更新显示session信息的标签控件
- (void)updateSessionInfoLabelforFrame:(ARFrame *)frame trackingStateOfCamera:(ARCamera *)camera{
    NSString *message = [[NSString alloc] init];
    if (camera.trackingState == ARTrackingStateNormal) {
        NSArray *arr1 = frame.anchors;
        NSArray *arr2 = [self.multipeerSession getConnectedPeers];
        if (arr1==nil && [arr1 isKindOfClass:[NSNull class]]&&arr1.count==0 &&arr2==nil && [arr2 isKindOfClass:[NSNull class]]&&arr2.count==0) {
            message = @"Move around to map the environment, or wait to join a shared session.";
        }
        if (arr2!=nil && ![arr2 isKindOfClass:[NSNull class]]&&arr2.count!=0 && self.mapProvider == nil) {
            MCPeerID *peer = [self.multipeerSession getConnectedPeers][0];
            message = [NSString stringWithFormat:@"Connected with %@",peer.displayName];
        }
        
    }
    else if (camera.trackingState == ARTrackingStateLimited){
        if (camera.trackingStateReason == ARTrackingStateReasonExcessiveMotion) {
            message = @"Tracking limited - Move the device more slowly.";
        }
        else if (camera.trackingStateReason == ARTrackingStateReasonInsufficientFeatures)
            message = @"Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions.";
        else if (camera.trackingStateReason == ARTrackingStateReasonInitializing && camera.trackingStateReason == ARTrackingStateReasonRelocalizing && self.mapProvider != nil)
            message = @"Received map from near device";
        else if (camera.trackingStateReason == ARTrackingStateReasonInitializing)
            message = @"Resuming session — move to where you were when the session was interrupted.";
        else
            message = @"Initializing AR session.";
    }
    else if (camera.trackingState == ARTrackingStateNotAvailable)
        message = @"Tracking unavailable.";
    else
        message = @"";
    self.sessionInfoLabel.text = message;
}

#pragma mark - ARSCNViewDelegate
// 点击后Session内的anchor更新，调用此函数添加视图
- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if ([anchor.name isEqualToString:@"founction"]) {
        //视图插在这
        SCNBox *phere = [SCNBox boxWithWidth:0.01 height:0.02 length:0.01 chamferRadius:0];
        phere.firstMaterial.diffuse.contents = [UIColor redColor];
        phere.firstMaterial.specular.contents = [UIColor whiteColor];
        SCNNode *carbonNode = [SCNNode nodeWithGeometry:phere];
        carbonNode.position = SCNVector3Make(anchor.transform.columns[3].x, anchor.transform.columns[3].y, anchor.transform.columns[3].z);
        [node addChildNode:carbonNode];
    }
}

#pragma mark - ARSession Delegate
//跟踪现实世界的信息变化时调用
- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera{
    [self updateSessionInfoLabelforFrame:session.currentFrame trackingStateOfCamera:camera];
}

//更新坐标后调用
-(void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame{
    NSString *message = [[NSString alloc] init];
    switch (frame.worldMappingStatus) {
        case ARWorldMappingStatusNotAvailable:
            self.sendMapButton.enabled = NO;
            message = @"Not Available";
            break;
        case ARWorldMappingStatusLimited:
            self.sendMapButton.enabled = NO;
            message = @"Limited";
            break;
        case ARWorldMappingStatusExtending:
            self.sendMapButton.enabled = [self.multipeerSession getConnectedPeers]!=nil && ![[self.multipeerSession getConnectedPeers] isKindOfClass:[NSNull class]]&&[self.multipeerSession getConnectedPeers].count!=0;
            message = @"Extending";
            break;
        case ARWorldMappingStatusMapped:
            self.sendMapButton.enabled = [self.multipeerSession getConnectedPeers]!=nil && ![[self.multipeerSession getConnectedPeers] isKindOfClass:[NSNull class]]&&[self.multipeerSession getConnectedPeers].count!=0;
            message = @"Mapped";
            break;
    }
    self.mappingStatusLabel.text = message;
    [self updateSessionInfoLabelforFrame: frame trackingStateOfCamera: frame.camera];
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    self.sessionInfoLabel.text = [NSString stringWithFormat:@"Session failed: %@",error.localizedDescription];
    [self resetTracking:nil];
}

//置于后台了调用
- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    self.sessionInfoLabel.text = @"Session was interrupted";
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    self.sessionInfoLabel.text = @"Session interruption ended";
}
- (BOOL)sessionShouldAttemptRelocalization:(ARSession *)session{
    return YES;
}

#pragma mark - sharing
//手势调用方法
- (void)handleSceneTap:(UITapGestureRecognizer *)tapGesture{
    NSArray *hitResultArr = [_sceneView hitTest:[tapGesture locationInView:_sceneView] types:ARHitTestResultTypeExistingPlane | ARHitTestResultTypeEstimatedHorizontalPlane];
    if (hitResultArr!=nil && ![hitResultArr isKindOfClass:[NSNull class]]&&hitResultArr.count!=0) {
        ARHitTestResult *hitResult = hitResultArr[0];
        ARAnchor *anchor = [[ARAnchor alloc] initWithName:@"founction" transform: hitResult.worldTransform];
        
        //可以在这里添加note，可定位添加
        [_sceneView.session addAnchor: anchor];
        NSLog(@"%@",anchor);
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:anchor requiringSecureCoding:YES error:nil];
        [self.multipeerSession sendToAllPeers:data];
    }
    else{
        self.sessionInfoLabel.text = @"Your tap location can't located";
    }
    
}

//分享按钮调用方法
- (void)shareSession:(UIButton *)btn{
    [self.sceneView.session getCurrentWorldMapWithCompletionHandler:^(ARWorldMap * _Nullable worldMap, NSError * _Nullable error) {
        ARWorldMap *map = worldMap;
        if (!map) {
            NSLog(@"error:%@",error.description);
            return ;
        }
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:map requiringSecureCoding:YES error:nil];
        if (!data) {
            return ;
        }
        [self.multipeerSession sendToAllPeers:data];
    }];
}

//重置按钮调用
- (void)resetTracking:(UIButton *)btn{
    ARWorldTrackingConfiguration *configuration = [[ARWorldTrackingConfiguration alloc] init];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    [self.sceneView.session runWithConfiguration:configuration options: ARSessionRunOptionRemoveExistingAnchors|ARSessionRunOptionResetTracking];
}


#pragma mark - 懒加载

- (UITapGestureRecognizer *)tapGesture{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget: self action: @selector(handleSceneTap:)];
    }
    return _tapGesture;
}

- (UIButton *)sendMapButton{
    if (!_sendMapButton) {
        _sendMapButton = [[UIButton alloc] initWithFrame:CGRectMake(20, SCREEN_HEIGHT - 80, 50, 50)];
        [_sendMapButton setTitle:@"send world map" forState: UIControlStateNormal];
        [_sendMapButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
        [_sendMapButton setImage:[UIImage imageNamed:@"shareDefault"] forState:UIControlStateHighlighted];
        [_sendMapButton addTarget:self action:@selector(shareSession:) forControlEvents:UIControlEventTouchDown];
    }
    return _sendMapButton;
}

- (UIButton *)resetButton{
    if (!_resetButton) {
        _resetButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-50, 40, 30, 30)];
        [_resetButton setBackgroundImage:[UIImage imageNamed:@"restart"] forState:UIControlStateNormal];
        [_resetButton setBackgroundImage:[UIImage imageNamed:@"restartPressed"] forState:UIControlStateHighlighted];
        _resetButton.backgroundColor = [UIColor clearColor];
        [_resetButton addTarget:self action:@selector(resetTracking:) forControlEvents:UIControlEventTouchDown];
    }
    return _resetButton;
}

- (UILabel *)sessionInfoLabel{
    if (!_sessionInfoLabel) {
        _sessionInfoLabel = [[UILabel alloc] initWithFrame: CGRectMake(20, 40, 200, 60)];
        _sessionInfoLabel.backgroundColor = [UIColor clearColor];
        _sessionInfoLabel.numberOfLines = 0;
        _sessionInfoLabel.font = [UIFont systemFontOfSize:13];
        
    }
    return _sessionInfoLabel;
}

- (UILabel *)mappingStatusLabel{
    if (!_mappingStatusLabel) {
        _mappingStatusLabel = [[UILabel alloc] initWithFrame: CGRectMake(SCREEN_WIDTH/2-50, SCREEN_HEIGHT - 50, 100, 30)];
        _mappingStatusLabel.backgroundColor = [UIColor clearColor];
        _mappingStatusLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _mappingStatusLabel;
}

@end
