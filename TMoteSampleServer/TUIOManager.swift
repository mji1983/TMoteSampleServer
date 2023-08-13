//
//  TUIOManager.swift
//  TMoteSampleServer
//
//  An example of how to process touches. Because Cocoa doesn't support multitouch, this just emulates left mouse clicks and drags,
//  but could be expanded to support multi-touch for a custom application
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
import AppKit


class TUIOManager{

    var windowNumber:Int = 0
    var viewWidth:CGFloat = 0
    var viewHeight:CGFloat = 0
    
    var listener:UDPReceiver?
    let osc = OSCClient()
    init(){
        
        
        listener = UDPReceiver(receivedDataCallback: { data in
            let packets =  self.osc.decodePacket(data:NSData(data: data)) //decode all UDP packets as OSC
            self.processOSC(bundle: packets)  //process the OSC to pull out the TUIO data
        })
        
        listener?.listenUDP(port: 3333) //start listening for UDP packets
    }
    
    
    func stop(){
        listener?.stop()
    }
    
    func updateWindowData(width:CGFloat,height:CGFloat,windowNumber:Int){
        viewWidth = width
        viewHeight = height
        self.windowNumber = windowNumber
 
    }
    
    var touchCircularBuffer = Array<(id:Int32,active:Bool,x:Float32,y:Float32)>(repeating: (Int32(-1),false,Float32(0),Float32(0)), count: 10)
    
    func processOSC(bundle:[OSCIncomingPacket]){
   
        
        for packet in bundle{
            
            if packet.path == "/tuio/2Dcur"{
                
                  if case .StringVal(let action) = packet.args[0]{
                    
                    if action == "alive"{
                        for i in 0..<10{ //clear all 10 possible touches
                            touchCircularBuffer[i].active=false
                        }
                        
                        for i in (1..<packet.args.count){ //set those that are still being held to active
                            if case .IntVal(let id) = packet.args[i]{
                            
                                touchCircularBuffer[Int(id) % 10].active = true
                            }
                        }
                        
                   
                      
                        for i in 0..<10{ //iterate through all the touches
                            if touchCircularBuffer[i].active==false &&  touchCircularBuffer[i].id > -1{ //Handle touches that have ended
            
                                let x = self.touchCircularBuffer[i].x
                                let y = self.touchCircularBuffer[i].y
                                let xMult = viewWidth * CGFloat(x)
                                let yMult = viewHeight - (viewHeight * CGFloat(y))
                                
                              
                                let newMousUpEvent = NSEvent.mouseEvent(with: .leftMouseUp,location: NSPoint(x:xMult, y:yMult), modifierFlags: [], timestamp: 0,windowNumber: windowNumber,context: nil,eventNumber: 0,clickCount: 1, pressure: 1)
                            
                                NSApplication.shared.postEvent(newMousUpEvent!,atStart: false) //mouse up to end
             
                                 self.touchCircularBuffer[i].id = -1
 
                            }
                        }
                      
                        
                    }
                    
                    if action == "set"{
                        
                        if case .IntVal(let id) = packet.args[1]{
                            if case .FloatVal(let x) = packet.args[2]{
                                if case .FloatVal(let y) = packet.args[3]{
                                    let bufferLocation = Int(id % 10)
                                    if touchCircularBuffer[bufferLocation].active{
                                        if touchCircularBuffer[bufferLocation].id == id { // Handle touches that have been moved/dragged
                               
                                            
                                            touchCircularBuffer[bufferLocation].x = x
                                            touchCircularBuffer[bufferLocation].y = y
                                           
                                            let xMult = viewWidth * CGFloat(x)
                                            let yMult = viewHeight - (viewHeight * CGFloat(y))
                                          
                             
                                            let mouseMoveEvent = NSEvent.mouseEvent(with: .leftMouseDragged, location: NSPoint(x:xMult, y:yMult), modifierFlags: [], timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
                                    NSApplication.shared.postEvent(mouseMoveEvent!,atStart: false)
                                    
                                            
                                            
                                        } else { //Handle new touches
                  
                                            
                                            let xMult = viewWidth * CGFloat(x)
                                            let yMult = viewHeight - (viewHeight * CGFloat(y))
                                                

                                          let newMouseDownEvent = NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x:xMult, y:yMult), modifierFlags: [], timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
                                           
                                           
                                           
                                            
                                            NSApplication.shared.postEvent(newMouseDownEvent!,atStart: false)
                                            
                                                    
             
                                            
                                            touchCircularBuffer[bufferLocation].id = id
                                            touchCircularBuffer[bufferLocation].x = x
                                            touchCircularBuffer[bufferLocation].y = y
                                            
                                        }
                                    }
                                }
                            }
                        }
                    
                    }
                    
                }

            
            }
        }
    }
}
