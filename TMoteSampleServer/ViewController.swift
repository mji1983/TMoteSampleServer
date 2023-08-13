//
//  ViewController.swift
//  TMoteSampleServer
//
//  The view controller for our test cocoa view. Contains a few controls to play with as well as the plumbing to manage TUIO and NDI
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


import Cocoa


class ViewController: NSViewController {

    
    var displayLink: CVDisplayLink?
  
    var capturedImg:NSBitmapImageRep?
    let semaphore = DispatchSemaphore(value: 1)
    let tuioManager = TUIOManager()
    
     func start(){
  
         let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in

            
             // below code is the closure that executes at each tick of the displaylink. it caches the view and sends it to our NDI transmitter
             let viewController = unsafeBitCast(displayLinkContext, to: ViewController.self)

             viewController.semaphore.wait()
      
             RunLoop.main.perform(inModes: [RunLoop.Mode.common]) {

                 viewController.capturedImg = viewController.getFrame()
          
                 viewController.semaphore.signal()
             }
         
             viewController.semaphore.wait()
          
             sendNDIFrame(viewController.capturedImg!.bitmapData,Int32(viewController.capturedImg!.pixelsWide) ,Int32(viewController.capturedImg!.pixelsHigh),Int32(viewController.capturedImg!.bytesPerRow))
             viewController.semaphore.signal()

            return kCVReturnSuccess
        }

        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        CVDisplayLinkStart(displayLink!)

    }

    override func viewDidLayout() {
        super.viewDidLayout()
        tuioManager.updateWindowData(width: self.view.bounds.width, height: self.view.bounds.height, windowNumber: view.window!.windowNumber)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        CVDisplayLinkStop(displayLink!)
        tuioManager.stop()
       
        destroyNDI();
     
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        initNDI(makeCString(from: "TMote Test Server"));
        
       
       start()
     
  
    }

    

    //captures the view to a bitmap
    func getFrame() -> NSBitmapImageRep {

        let imageRepresentation = view.bitmapImageRepForCachingDisplay(in: view.bounds)!

         view.cacheDisplay(in: view.bounds, to: imageRepresentation)

        
    return imageRepresentation
    }

    //a function to convert a swift string to a C-style string
    func makeCString(from str: String) -> UnsafeMutablePointer<Int8> {
        let count = str.utf8.count + 1
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: count)
        str.withCString { (baseAddress) in
            // func initialize(from: UnsafePointer<Pointee>, count: Int)
            result.initialize(from: baseAddress, count: count)
        }
        return result
    }
    
    
    // ********* our toy GUI
    
    func display(_ s:String){
        scrollView.documentView?.insertText(s+"\n")
    }
    
    @IBOutlet weak var scrollView: NSScrollView!
    
    
    @IBAction func button1Press(_ sender: Any) {
        display("Button 1 pressed")
    }
    @IBAction func button2Press(_ sender: Any) {
        display("Button 2 pressed")

    }
    @IBAction func button3Press(_ sender: Any) {
        display("Button 3 pressed")

    }
    
    @IBAction func knob1Turned(_ sender: Any) {
        display("Knob 1 value = "+String((sender as! NSSlider).doubleValue ))

    }
    
    @IBAction func knob2Turned(_ sender: Any) {
        display("Knob 2 value = "+String((sender as! NSSlider).doubleValue ))
    }
    @IBAction func knob3Turned(_ sender: Any) {
        display("Knob 3 value = "+String((sender as! NSSlider).doubleValue ))
    }
    @IBAction func slider1Moved(_ sender: Any) {
        display("Slider 1 value = "+String((sender as! NSSlider).doubleValue ))
    }
    @IBAction func slider2Moved(_ sender: Any) {
        display("Slider 2 value = "+String((sender as! NSSlider).doubleValue ))
    }
    @IBAction func slider3Moved(_ sender: Any) {
        display("Slider 3 value = "+String((sender as! NSSlider).doubleValue ))
    }
    
    
}




