//
//  DlibWrapper.m
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 16.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>

#include <dlib/image_processing.h>
#include <dlib/image_io.h>

@interface DlibWrapper ()

@property (assign) BOOL prepared;

// + (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end
@implementation DlibWrapper {
    //dlib::shape_predictor sp;
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    //NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"bball_detector" ofType:@"svm"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
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
    
    // convert the face bounds list to dlib format
    // std::vector<dlib::rectangle> convertedRectangles = [DlibWrapper convertCGRectValueArray:rects];
    
    // for every detected face
    /*for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
        }
    }*/
    
    // Try this downsampling if the resizing doesn't work
    
    dlib::array2d<dlib::bgr_pixel> img_down;
    unsigned long downsample = 3.0;
    img_down.set_size((img.nr()+downsample-1)/downsample,
                     (img.nc()+downsample-1)/downsample);
    
    for (long r = 0; r < img_down.nr(); ++r)
    {
        for (long c = 0; c < img_down.nc(); ++c)
        {
            img_down[r][c] = img[r*downsample][c*downsample];
        }
    }
    
    
    // can also try grayscale img using unsigned char instead of bgr_pixel
    /*
    dlib::array2d<unsigned char> img_gray;
    dlib::assign_image(img_gray, img);
    */
    
    
    // Run the detector and get the bball detections.
    // not sure what all the diddropsamplebuffer shit is...
    // this line makes everything VERY SLOWWWWWW...
    // std::vector<dlib::rectangle> dets = sp(img);
    std::vector<dlib::rectangle> dets = sp(img_down);
    
    
    /*
    for (unsigned long i = 0; i < dets.size(); ++i) {
        draw_rectangle(img, dets[i], dlib::rgb_pixel(255,0,0));
    }
    */
    
    if (dets.size()) {
        std::vector<std::vector<dlib::rectangle>> dets_vec;
        dets_vec.push_back(dets);
        dlib::array<dlib::array2d<dlib::bgr_pixel>> img_arr;
        img_arr.push_back(img_down);
        // should be upsampling by factor of 3 but rect position is off
        dlib::upsample_image_dataset<dlib::pyramid_down<3>> (img_arr, dets_vec);
        
        for (unsigned long i = 0; i < dets_vec[0].size(); ++i) {
            draw_rectangle(img, dets_vec[0][i], dlib::rgb_pixel(255,0,0));
        }
    }
    
    
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

/*
+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);

        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}
*/

@end
