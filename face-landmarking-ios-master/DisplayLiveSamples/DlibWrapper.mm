//
//  DlibWrapper.m
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 16.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>

#ifdef __cplusplus

#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#endif


using namespace std;

#define PT_SIZE (20)


@interface DlibWrapper ()

@property (assign) BOOL prepared;

@property (assign) BOOL hoopDone;

// + (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end


@implementation DlibWrapper {
    //dlib::shape_predictor sp;
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp;
    
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp2;
    
    dlib::dpoint pt_array[PT_SIZE];    
    //arma::fmat A;face_detector.svm
    //arma::fmat b;
    //arma::fmat x;
    //arma::fmat y;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
        _hoopDone = NO;
    }
    return self;
}

int pt_idx = 0;

- (void)prepare {
    //NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"ball_detector_5" ofType:@"svm"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
    NSString *modelFileName2 = [[NSBundle mainBundle] pathForResource:@"hoop_detector" ofType:@"svm"];
    std::string modelFileNameCString2 = [modelFileName2 UTF8String];
    
    dlib::deserialize(modelFileNameCString2) >> sp2;
    
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer {// inRects:(NSArray<NSValue *> *)rects {
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // set_size expects rows, cols format
    img.set_size(height, width);
     
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();

        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    
    // can also try grayscale img using unsigned char instead of bgr_pixel
    //dlib::array2d<unsigned char> img_gray;
    //dlib::assign_image(img_gray, img);
    
    
    
    // Run the detector and get the bball detections.
    // not sure what all the diddropsamplebuffer shit is...
    // this line makes everything VERY SLOWWWWWW...
    //std::vector<dlib::rectangle> dets = sp(img);
    if (!self.hoopDone){
        std::vector<dlib::rectangle> dets2 = sp2(img);
        for (unsigned long i = 0; i < dets2.size(); ++i) {
            draw_rectangle(img, dets2[i], dlib::rgb_pixel(0,255,0));
        }
        self.hoopDone = YES;
    }
    //std::vector<dlib::rectangle> dets = sp(img_down);
    
    
    
    
     /*
    
    for (unsigned long i = 0; i < dets.size(); ++i) {
        draw_rectangle(img, dets[i], dlib::rgb_pixel(255,0,0));
        int center_x = (dets[i].left() + dets[i].right()) / 2;
        int center_y = (dets[i].top() + dets[i].bottom()) / 2;
        dlib::dpoint center_pt = dlib::dpoint(center_x, center_y);
        
        
        //A << center_x^2 << center_x << 1 << arma::endr;
        //b << center_y << arma::endr;
        
        pt_array[pt_idx] = center_pt;
        pt_idx++;
        if(pt_idx == PT_SIZE){
            pt_idx = 0;
        }
    }
    
    //x = inv(trans(A) * A) * trans(A);
    
    //cout << A << endl;
    //cout << b << endl;
    //cout << x << endl;
    
    
    for(int i = 0; i < PT_SIZE; i++){
        draw_solid_circle(img, pt_array[i], 5, dlib::rgb_pixel(100,100,100));
    }
    
    */
    //for(int i = 0; i < 640; i++){
        //dlib::dpoint parabola = dlib::dpoint(i, x(0)*i^2 + x(1)*i + x(2));
        //draw_solid_circle(img, parabola, 1, dlib::rgb_pixel(30,30,30));
    //}
    
    // lets put everything back where it belongs
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
