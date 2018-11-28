//
//  MultipeerSession.m
//  sharingDemo
//
//  Created by 丁磊 on 2018/11/21.
//  Copyright © 2018 丁磊. All rights reserved.
//

#import "MultipeerSession.h"
#import "ViewController.h"

@interface MultipeerSession () <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>
@property(strong, nonatomic) NSString *serviceType; //本机信息，判断设备是否支持ARKit
@property(strong, nonatomic) MCPeerID *myPeerId;    //本机的ID
@property(strong, nonatomic) MCSession *session;
@property(strong, nonatomic) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property(strong, nonatomic) MCNearbyServiceBrowser *serviseBrowser;

@end

@implementation MultipeerSession



- (instancetype)initWithReceivedDataHandeler:(NSData *)data fromPeer:(MCPeerID *)peerID{
    self = [super init];
    if(self){
        self.serviceType = @"ar-multi-sample";
        self.myPeerId = [[MCPeerID alloc] initWithDisplayName:UIDevice.currentDevice.name];
        
        self.session = [[MCSession alloc] initWithPeer:self.myPeerId securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        self.session.delegate = self;
        
        self.serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerId discoveryInfo:nil serviceType:_serviceType];
        _serviceAdvertiser.delegate = self;
        [self.serviceAdvertiser startAdvertisingPeer];
        
        self.serviseBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer: _myPeerId serviceType: _serviceType];
        self.serviseBrowser.delegate = self;
        [self.serviseBrowser startBrowsingForPeers];
    }
    return self;
}

+ (instancetype) MultipeerSessionWithReceivedData:(NSData *)data fromPeer:(MCPeerID *)peer{
    return [[self alloc] initWithReceivedDataHandeler:data fromPeer:peer];
}

- (void)sendToAllPeers: (NSData *)data{
    [_session sendData: data toPeers: _session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
}

- (NSArray *)getConnectedPeers{
    return self.session.connectedPeers;
}

#pragma mark - session delegate
- (void)session:(nonnull MCSession *)session didFinishReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error {
    NSLog(@"This service does not send %@.",resourceName);
}

- (void)session:(nonnull MCSession *)session didReceiveData:(nonnull NSData *)data fromPeer:(nonnull MCPeerID *)peerID {
    [MultipeerSession MultipeerSessionWithReceivedData:data fromPeer:peerID];
    [self.delegate receivedData:data fromPeers:peerID];
}

- (void)session:(nonnull MCSession *)session didReceiveStream:(nonnull NSInputStream *)stream withName:(nonnull NSString *)streamName fromPeer:(nonnull MCPeerID *)peerID {
    NSLog(@"This service does not send %@",streamName);
}

- (void)session:(nonnull MCSession *)session didStartReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID withProgress:(nonnull NSProgress *)progress {
    NSLog(@"This service does not send %@",resourceName);
}

- (void)session:(nonnull MCSession *)session peer:(nonnull MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
}


#pragma mark - advertise delegate
- (void)advertiser:(nonnull MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(nonnull MCPeerID *)peerID withContext:(nullable NSData *)context invitationHandler:(nonnull void (^)(BOOL, MCSession * _Nullable))invitationHandler {
    invitationHandler(true,self.session);
}

#pragma mark - browser delegate

- (void)browser:(nonnull MCNearbyServiceBrowser *)browser foundPeer:(nonnull MCPeerID *)peerID withDiscoveryInfo:(nullable NSDictionary<NSString *,NSString *> *)info {
    [browser invitePeer:peerID toSession: self.session withContext: nil timeout: 10];
}

- (void)browser:(nonnull MCNearbyServiceBrowser *)browser lostPeer:(nonnull MCPeerID *)peerID {
}

@end
