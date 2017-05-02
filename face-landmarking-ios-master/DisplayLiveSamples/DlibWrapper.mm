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

#include "opencv2/features2d/features2d.hpp"
#include "opencv2/nonfree/features2d.hpp"
#include <opencv2/opencv.hpp> // Includes the opencv library
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/opencv.h>
#include "opencv2/video/tracking.hpp"
#import  "opencv2/objdetect/objdetect.hpp"
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#endif


using namespace std;

#define PT_SIZE (10)


@interface DlibWrapper ()

@property (assign) BOOL prepared;

@property (assign) BOOL hoopDone;

// + (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end


@implementation DlibWrapper {
    // should this param be 2?
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp;
    
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp2;
    
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


//VAR
int pt_idx = 0;
int found_temp = 0;
cv::Mat temp_img;
std::vector<cv::Point2f> points0;
cv::TermCriteria termcrit(cv::TermCriteria::COUNT|cv::TermCriteria::EPS,10,0.03);
dlib::dpoint center_pt;
int i, k;
int center_x, center_y;
int temp_width, temp_height;

int t = 0;
int b = 0;
int l = 0;
int r = 0;
int w = 0;
int h = 0;
int optimize = 0;
int bcount = 0;

dlib::dpoint pt_array[PT_SIZE];

cv::Mat A = cv::Mat::zeros(PT_SIZE, 3, CV_32F);
cv::Mat B = cv::Mat::zeros(PT_SIZE, 1, CV_32F);
cv::Mat X;

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"face_detector" ofType:@"svm"];
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
    
    NSDate *start = [NSDate date];
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    //cout << "start " << timeInterval << endl;
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
    dlib::array2d<unsigned char> img_gray;
    dlib::array2d<unsigned char> img_gray_2;
    dlib::array2d<unsigned char> img_gray_small;
    dlib::assign_image(img_gray, img);
    dlib::assign_image(img_gray_2, img);
    int offset = 150;
    dlib::rectangle roi;
    
    
    for(i = 0; i < PT_SIZE; i++){
        A.at<float>(i, 2) = 1.0;
    }
    
    
    /*
    //THIS IS THE BASKETBALL TRACKING SECTION
    if(!found_temp){
        if(optimize == 1){
            roi.set_top(t - offset);
            roi.set_bottom(b + offset);
            roi.set_left(l - offset);
            roi.set_right(r + offset);
            //cout << "roi: "<< roi.top() << " "<< roi.bottom() << " "<< roi.left() << " "<< roi.right() << " " << endl;
            dlib::extract_image_chip(img_gray, roi, img_gray_small);
            dlib::assign_image(img_gray, img_gray_small);
        }

        //cout << "optimized " << optimize << endl;
        std::vector<dlib::rectangle> dets_ball = sp(img_gray);
        //cv::Mat ball, ballg;

        if(optimize == 1){
            //cout << "optimized, this many rects" << dets_ball.size() << endl;
            for(i = 0; i < dets_ball.size(); ++i){
                dets_ball[i].set_top(dets_ball[i].top() + (t - offset));
                dets_ball[i].set_bottom(dets_ball[i].bottom() + (t - offset));
                dets_ball[i].set_left(dets_ball[i].left() + (l - offset));
                dets_ball[i].set_right(dets_ball[i].right() + (l - offset));
            }
        }

        if(optimize && dets_ball.size() == 0){
            bcount++;
            offset = 400;
            if(bcount == 3){
                offset = 150;
                optimize = 0;
                bcount = 0;
            }
            
        }

        for ( i = 0; i < dets_ball.size(); ++i) {
            draw_rectangle(img, dets_ball[i], dlib::rgb_pixel(255,30, 0));
            int center_ball_x = (dets_ball[i].left() + dets_ball[i].right()) / 2;
            int center_ball_y = (dets_ball[i].top() + dets_ball[i].bottom()) / 2;
            dlib::dpoint center_pt = dlib::dpoint(center_ball_x, center_ball_y);
            
            pt_array[pt_idx] = center_pt;
            A.at<float>(pt_idx, 0) = (float)center_ball_x * center_ball_x;
            A.at<float>(pt_idx, 1) = (float)center_ball_x;
            B.at<float>(pt_idx, 0) = (float)center_ball_y;
            pt_idx++;
            if(pt_idx == PT_SIZE){
                pt_idx = 0;
            }

            t = dets_ball[i].top();
            b = dets_ball[i].bottom();
            l = dets_ball[i].left();
            r = dets_ball[i].right();
            
            //cout << "o: "<< t << " "<< b << " "<< l << " "<< r << " " << endl;
            w = r - l;
            h = b - t;
            offset = 150;
            bcount = 0;
            optimize = 1;
        }

        X = (A.t() * A).inv() * A.t() * B;

        for(int i = 0; i < PT_SIZE; i++){
            
            draw_solid_circle(img, pt_array[i], 5, dlib::rgb_pixel(255,150,0));
        }

        if(X.at<float>(0) > 0){
            for(int i = 0; i < 1920; i+=10){
                dlib::dpoint parabola = dlib::dpoint(i, (int)(X.at<float>(0)*i*i + X.at<float>(1)*i + X.at<float>(2)));
                draw_solid_circle(img, parabola, 3, dlib::rgb_pixel(230,230,230));
            }
        }
     
    }
    */
    
    //THIS IS THE HOOP TRACKING SECTION
    
    if(!found_temp) {
        // Run the detector and get the hoop detection
        std::vector<dlib::rectangle> dets = sp2(img_gray_2);
        std::vector<cv::Point2f> pointstemp;

        for ( i = 0; i < dets.size(); ++i) {
            draw_rectangle(img, dets[i], dlib::rgb_pixel(255,0,0));
            center_x = (dets[i].left() + dets[i].right()) / 2;
            center_y = (dets[i].top() + dets[i].bottom()) / 2;
            temp_width = (dets[i].right()  - dets[i].left());
            temp_height = (dets[i].bottom() - dets[i].top());
            
            temp_img = dlib::toMat(img_gray_2);
            
            
            cv::goodFeaturesToTrack(temp_img, pointstemp, 1000, 0.01, 10, cv::Mat(), 3, 0, 0.04);
            //cv::cornerSubPix(temp_img, pointstemp, cv::Size(10,10), cv::Size(-1,-1), termcrit);
            
            cv::Mat image = dlib::toMat(img);
            for( k = 0; k < pointstemp.size(); k++ )
            {
                if(pointstemp[k].x < dets[i].left() || pointstemp[k].x > dets[i].right() || pointstemp[k].y < dets[i].top() || pointstemp[k].y > dets[i].bottom()){
                    continue;
                }
                points0.push_back(pointstemp[k]);
                cv::circle( image, points0[k], 3, cv::Scalar(255,0,0), -1, 8);
            }
            
            dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image));
            if(points0.size() > 1){
                found_temp = 1;
            }
        }
    }
    else {
        cv::Mat image = dlib::toMat(img_gray_2);
        cv::Mat image_disp = dlib::toMat(img);
        std::vector<uchar> status;
        std::vector<float> err;
        std::vector<cv::Point2f> points1, pointstemp;

        cv::calcOpticalFlowPyrLK(temp_img, image, points0, points1, status, err, cv::Size(31, 31), 3, termcrit, 0, 0.001);
        int offset_bool = 1;
        int xoffset = 0;
        int yoffset = 0;
        int numoffset = 0;
        
        for(i = 0; i < points1.size(); i++)
        {
            if(status[i] == 1){
                if(offset_bool){
                    xoffset += points1[i].x - points0[i].x;
                    yoffset += points1[i].y - points0[i].y;
                    numoffset++;
                    
                    offset_bool = 0;
                }
                pointstemp.push_back(points1[i]);
                //}
                cv::circle( image_disp, points1[i], 3, cv::Scalar(0,255,0), -1, 8);
            }

        }
        if(offset_bool == 1){
            found_temp = 0;
        }
        else{
            
            center_x = center_x + (xoffset/numoffset);
            center_y = center_y + (yoffset/numoffset);
        
            cv::circle( image_disp, cv::Point(center_x, center_y), 10, cv::Scalar(255,50,50), -1, 8);
            cv::rectangle( image_disp, cv::Point(center_x-(temp_width/2), center_y-(temp_height/2)), cv::Point(center_x+(temp_width/2), center_y+(temp_height/2)), cv::Scalar(255,50,50), 2, 8);
        }
        dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image_disp));

        points0 = pointstemp;
        temp_img = image.clone();
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
    
    //cout << "end to fin " <<timeInterval << endl;
    timeInterval = [start timeIntervalSinceNow];
    //cout << "total " << timeInterval << endl;


}

@end
