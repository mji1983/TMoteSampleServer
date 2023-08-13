//
//  OSC.swift
//  TMoteSampleServer
//
//  A simple OSC parser. May not be fully compliant as it's only been tested with a
//  particular subset of the TUIO
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


func padByteArray( byteArray:inout [UInt8]){
    //pad to 32-bit alignment
    let padding = (4 - (byteArray.count % 4)) % 4
    
    for  _ in 0..<padding{
        byteArray += [0]
    }
 
}

public enum OSCValue {
    case FloatVal(Float)
    case IntVal(Int32)
    case StringVal(String)
    case Array([OSCValue])
    
}


class OSCClient{

    init(){
        searchZeroData = NSData(bytes:zero , length: 1)
        
    }

    
    private let zero:[UInt8] = [0]
    private let searchZeroData:NSData!

  

    func decodePacket(data:NSData)->[OSCIncomingPacket]{
 

        var searchRange = NSMakeRange(0, 8)

        let foundBundle = data.range(of: "#bundle".data(using: .utf8)! , options: [], in: searchRange)
        
        if foundBundle.location != NSNotFound{ // it's a bundle
            
            var bytes = [UInt8](data)
           
         
            var pArray: [OSCIncomingPacket] = []
            
            
            var offset = 16
            
            
            while (offset < data.length){
                
                
                let pSize = fromByteArray32Bit(&bytes, offset: offset, toType:Int32.self)
                 offset = offset + 4
                
                let packetRange = NSMakeRange(offset, Int(pSize))
                offset = offset + Int(pSize)
                
                let subPacket = data.subdata(with: packetRange)
                
              
                pArray =  pArray + decodePacket(data: subPacket as NSData)
                
                
            
            }
            return pArray
            
        } else {
        
        var searchRange = NSMakeRange(0, data.length)

      
        
    var foundRange = data.range(of: searchZeroData as Data, options: [], in: searchRange)

        
    if (foundRange.location != NSNotFound){
        searchRange.length = foundRange.location
        let sData = data.subdata(with: searchRange)
        
        
        let path = NSString(data: sData, encoding: String.Encoding.utf8.rawValue)! as String
     
        
        let decodedPacket: OSCIncomingPacket = OSCIncomingPacket(path: path)
        
        searchRange.location = foundRange.location
        searchRange.length = data.length  - foundRange.location
        let remainder = data.subdata(with: searchRange)
      
       
       
     
        // copy bytes into array
        var typeStart = -1
       
        var tList = [UInt8]()
       
       var array = [UInt8](remainder)
        for i in 0..<array.count{
            
            if (typeStart > -1 && array[i] == 0 ) {
                break;
            }
            if (typeStart > -1){
                tList.append(array[i])
            }
            if array[i] == 44{ //found the comma
            
                typeStart = i
            }
        }
     
        if tList.count > 0 {
          
            var offset = tList.count + 2 // comma + type list + terminating zero
            let padding = (4 - (offset % 4)) % 4
            offset = offset + padding + typeStart
            
            for t in tList{
                switch(t){
                case 105: //'i'
                    let bArray:[UInt8] = [array[offset+3], array[offset+2],array[offset+1],array[offset]]
                    let i = fromByteArray(bArray,toType: Int32.self)
                
                    offset = offset + 4
                    
                    decodedPacket.addArgument(argument: OSCValue.IntVal(i))
                  
                case 102: //'f'
                    let bArray:[UInt8] = [array[offset+3], array[offset+2],array[offset+1],array[offset]]
                    let f = fromByteArray(bArray,toType: Float32.self)
                   
                    offset = offset + 4
                    decodedPacket.addArgument(argument: OSCValue.FloatVal(f))
                    
                case 115: //'s'
                  
                    let foundRange = remainder.range(of: searchZeroData as Data, options: [], in: Range(NSMakeRange(offset, remainder.count-offset)))

                   
                    
                    if let fRange = foundRange?.startIndex{
                  
                    
                        searchRange.length = fRange
                    
                        
                        let sData =  remainder.subdata(in:  Range(NSMakeRange(offset, fRange - offset))!)
                        
                        let sOffset = sData.count + 4 - (sData.count % 4)
                       
                        
                        offset=offset + sOffset
                        
                        let s = NSString(data: sData, encoding: String.Encoding.utf8.rawValue)! as String
                        
                        decodedPacket.addArgument(argument: OSCValue.StringVal(s))
                     
                        
                    }
                    
                    break
                
                default:
                    break
                }
            }
         
        }
        
       
        return [decodedPacket]
            }
    }

  return []

}

    
    func fromByteArray32Bit<T>(_ bytes: inout [UInt8], offset:Int, toType type: T.Type)->T{
    
        if 4 + offset < bytes.count{
            let bArray:[UInt8] = [bytes[offset+3], bytes[offset+2],bytes[offset+1],bytes[offset]]
            let f = fromByteArray(bArray,toType: T.self)
            return f
        } else{
            
            let bArray:[UInt8] = [0,0,0,0]
            let f = fromByteArray(bArray,toType:T.self
)
            return f
        }
        
    }
    
    
    func fromByteArray<T: Any>(_ bytes: [UInt8], toType type: T.Type) -> T {
      
        return bytes.withUnsafeBufferPointer {
            return $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
                $0.pointee
            }
        }
    }
    

    
    


}


class OSCType{
    
    func toByteArray<T: Any>( _ value: T) -> [UInt8] {
     
        var value = value // inout works only for var not let types
        let valueByteArray = withUnsafePointer(to: &value) {
            Array(UnsafeBufferPointer(start: $0.withMemoryRebound(to: UInt8.self, capacity: 1){$0}, count: MemoryLayout<T>.size))
        }
        return valueByteArray
    }
    
}



class OSCIncomingPacket{
    var path:String
    var args:[OSCValue] = []
    
    init(path:String){
        self.path = path
    }
    
    func addArgument(argument:OSCValue){
        args = args + [argument]
    }
    
}

