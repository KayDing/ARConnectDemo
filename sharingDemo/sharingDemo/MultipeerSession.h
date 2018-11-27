//
//  MultipeerSession.h
//  sharingDemo
//
//  Created by 丁磊 on 2018/11/21.
//  Copyright © 2018 丁磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

NS_ASSUME_NONNULL_BEGIN

@interface MultipeerSession : NSObject

- (instancetype)ReceivedDataHandeler:(NSData *)data fromPeer:(MCPeerID *)peerID;
- (void)sendToAllPeers: (NSData *)data;
- (NSArray *)getConnectedPeers;

@end

NS_ASSUME_NONNULL_END
