//
//  NDISender.cpp
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

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <algorithm>
#include "Processing.NDI.Lib.h"

extern "C" {
    #include "NDISender.h"
}





NDIlib_send_create_t NDI_send_create_desc = NULL;
NDIlib_send_instance_t pNDI_send;

 NDIlib_video_frame_v2_t NDI_video_frame;


void* p_frame_buffers[2];

int oddEven =0;

int bSize =0;

int ySize = 0;
int uvSize = 0;


int xSize;

int setupRGBFrame(int x,int y,int bytesPerRow);

char sName[32];
int initNDI(char *senderName){
    if (!NDIlib_initialize()) return 0;
    p_frame_buffers[0] = NULL;
    p_frame_buffers[1] = NULL;
    
    strcpy(sName, senderName);
    
    NDI_send_create_desc.p_ndi_name = sName;
    NDI_send_create_desc.clock_video = true;
    
    NDI_send_create_desc.clock_audio = false;
    
    NDI_send_create_desc.p_groups = "tmote";
    
       
    pNDI_send = NDIlib_send_create(&NDI_send_create_desc);
        if (!pNDI_send) return 0;
    
    return 1;
}

int setupRGBFrame(int x,int y,int bytesPerRow){
   
    if ( p_frame_buffers[0] != NULL) free( p_frame_buffers[0]);
    if ( p_frame_buffers[1] != NULL) free( p_frame_buffers[1]);
    
    p_frame_buffers[0] = malloc(bytesPerRow * y);
    p_frame_buffers[1] = malloc(bytesPerRow * y);
       
    NDI_video_frame.xres = x;
    NDI_video_frame.yres = y;
    NDI_video_frame.FourCC = NDIlib_FourCC_video_type_RGBX;
    NDI_video_frame.line_stride_in_bytes = bytesPerRow ;
    

    
    NDI_video_frame.frame_format_type= NDIlib_frame_format_type_progressive;
    
    xSize=x;
    ySize=y;

    return 1;
    

}




void sendNDIFrame(void* imgAddress,int width,int height,int bytesPerRow ){
    
    oddEven++;
    oddEven = oddEven % 2;
    
    if (width!=xSize || height !=ySize){
        setupRGBFrame(width, height,bytesPerRow);
    }

    memcpy(p_frame_buffers[oddEven], imgAddress,bytesPerRow * ySize);
     
    NDI_video_frame.p_data = (uint8_t*)p_frame_buffers[oddEven];
  //  NDIlib_send_send_video_async_v2(pNDI_send, &NDI_video_frame);
    NDIlib_send_send_video_v2(pNDI_send, &NDI_video_frame);
    return ;
    
}




void destroyNDI(){
    NDIlib_send_destroy(pNDI_send);

   
    NDIlib_destroy();
}






