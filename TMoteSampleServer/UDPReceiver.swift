//
//  TUIOReceiver.swift
//  TMoteSampleServer
//
/*
Copyright (c) 2023 Michael Ilardi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation
import Network
import AppKit

class UDPReceiver {
    
    
    
    private var talking: NWConnection?
    private var udpListener: NWListener?
    private var connections = [NWConnection]()
    
    var backgroundQueueUdpListener   = DispatchQueue(label: "listenerBGQueue", attributes: [])
    var backgroundQueueUdpConnection = DispatchQueue(label: "connectionBGQueue", attributes: [])
    
   
    var receivedDataCallback:(Data)->()
    
    init(receivedDataCallback:@escaping (Data)->()){
        self.receivedDataCallback=receivedDataCallback
    }
    
    
    func listenUDP(port: NWEndpoint.Port) {


        do {
            let parameters = NWParameters.udp
            parameters.allowLocalEndpointReuse = true
            self.udpListener = try NWListener(using: parameters, on: port)
            self.udpListener?.stateUpdateHandler = { (listenerState) in
             
                switch listenerState {
              //  case .setup:
                case .waiting(let error):
                    print("Waiting \(error)")
                case .ready:
                    print("Listening on port \(self.udpListener?.port?.debugDescription ?? "-")")
                case .failed(let error):
                    print("Listener: Failed \(error)")
                    self.udpListener = nil
                case .cancelled:
                    print("Listener: Cancelled")
                    for connection in self.connections {
                        connection.cancel()
                    }
                    self.udpListener = nil
                default:
                    break;

                }
            }

        self.udpListener?.start(queue: backgroundQueueUdpListener)
        self.udpListener?.newConnectionHandler = { (incomingUdpConnection) in
            incomingUdpConnection.stateUpdateHandler = { (udpConnectionState) in

                switch udpConnectionState {
              //  case .setup:
               //
                case .waiting(let error):
                    print("Connection: waiting: \(error)")
                case .ready:
                    print("Connection:  ready")
                    self.connections.append(incomingUdpConnection)
                    self.processData(incomingUdpConnection)
                case .failed(let error):
                    print("Connection: failed: \(error)")
                    self.connections.removeAll(where: {incomingUdpConnection === $0})
                case .cancelled:
                    print("Connection: cancelled")
                    self.connections.removeAll(where: {incomingUdpConnection === $0})
                default:
                    break
                }
            }

            incomingUdpConnection.start(queue: self.backgroundQueueUdpConnection)
        }

    } catch {
        print("TUIO Receiver Error")
    }

    
        
    }
    
    
    
    func processData(_ incomingUdpConnection :NWConnection) {

        incomingUdpConnection.receiveMessage(completion: {(data, context, isComplete, error) in

            if let data = data, !data.isEmpty {
               
                self.receivedDataCallback(data)
           
            }
           

            if error == nil {
                self.processData(incomingUdpConnection)
            }
        })

    }
    
    
    func stop(){
        udpListener?.cancel()
    
    }
    
  
}
