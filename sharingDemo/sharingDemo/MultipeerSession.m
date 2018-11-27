//
//  MultipeerSession.m
//  sharingDemo
//
//  Created by 丁磊 on 2018/11/21.
//  Copyright © 2018 丁磊. All rights reserved.
//

#import "MultipeerSession.h"

@interface MultipeerSession () <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>
@property(strong, nonatomic) NSString *serviceType;
@property(strong, nonatomic) MCPeerID *myPeerId;
@property(strong, nonatomic) MCSession *session;
@property(strong, nonatomic) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property(strong, nonatomic) MCNearbyServiceBrowser *serviseBrowser;

@end

@implementation MultipeerSession

- (instancetype)ReceivedDataHandeler:(NSData *)data fromPeer:(MCPeerID *)peerID{
    self.serviceType = @"ar-multi-sample";
    [MultipeerSession init];
    self.myPeerId = [_myPeerId initWithDisplayName: UIDevice.currentDevice.name];
    
    self.session = [_session initWithPeer:_myPeerId securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    _session.delegate = self;
    
    self.serviceAdvertiser = [_serviceAdvertiser initWithPeer:_myPeerId discoveryInfo:nil serviceType:_serviceType];
    _serviceAdvertiser.delegate = self;
    [_serviceAdvertiser startAdvertisingPeer];
    
    self.serviseBrowser = [_serviseBrowser initWithPeer: _myPeerId serviceType: _serviceType];
    _serviseBrowser.delegate = self;
    [_serviseBrowser startBrowsingForPeers];
    
    return self;
}

- (void)sendToAllPeers: (NSData *)data{
    [_session sendData: data toPeers: _session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
}

- (NSArray *)getConnectedPeers{
    return self.session.connectedPeers;
}

#pragma mark - session delegate
- (void)session:(nonnull MCSession *)session didFinishReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error {
    
}

- (void)session:(nonnull MCSession *)session didReceiveData:(nonnull NSData *)data fromPeer:(nonnull MCPeerID *)peerID {
    [self ReceivedDataHandeler:data fromPeer:peerID];
}

- (void)session:(nonnull MCSession *)session didReceiveStream:(nonnull NSInputStream *)stream withName:(nonnull NSString *)streamName fromPeer:(nonnull MCPeerID *)peerID {
    
}

- (void)session:(nonnull MCSession *)session didStartReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID withProgress:(nonnull NSProgress *)progress {
    
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
