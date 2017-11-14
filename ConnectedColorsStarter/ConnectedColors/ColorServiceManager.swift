//
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by SANGAMESH on 06/09/17.
//  Copyright © 2017 Example. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol colorServiceManagerDelegate {
    func connectedDeviceChanged(manager: ColorServiceManager, connectedDevices: [String])
    func colorChanged(manager: ColorServiceManager, colorString: String)
}

class ColorServiceManager: NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let colorServicetype = "example-color"
    
    // peerId is current device
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    // create the advartiser & browser variables
    private let serviceAdvartiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    //create session property
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self as MCSessionDelegate
        return session
    }()
    
    var delegate : colorServiceManagerDelegate?
    
    override init() {
        // initialize the advartiser And browser
        self.serviceAdvartiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: colorServicetype)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: colorServicetype)
        
        super.init()
        
        // set the both delegates to self
        self.serviceAdvartiser.delegate = self as MCNearbyServiceAdvertiserDelegate
        self.serviceBrowser.delegate = self as MCNearbyServiceBrowserDelegate
        
        // start the functions
        self.serviceAdvartiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    func send(colorName:String) {
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(colorName.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } catch let error {
                print(error)
            }
        }
    }
    
    deinit {
        // deinitialize the object by stopping functions
        self.serviceAdvartiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }

}

extension ColorServiceManager : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Did recieve an invitation from \(peerID)")
        
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print(error)
    }
}

extension ColorServiceManager : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found Peer\(peerID)")
        
        print("invite the peer \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost Peer \(peerID)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Did not start browsing for peers \(error)")
    }
}

extension ColorServiceManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("the Peer \(peerID) changed the state \(state)")
        self.delegate?.connectedDeviceChanged(manager: self, connectedDevices: session.connectedPeers.map{$0.displayName})
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("did recieved the data \(data)")
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.colorChanged(manager: self, colorString: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("did recieve stream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
}
