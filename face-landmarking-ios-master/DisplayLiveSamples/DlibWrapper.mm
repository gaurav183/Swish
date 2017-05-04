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

#define PT_SIZE (20)


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
int colorstuff = 0;
cv::Mat temp_img;
std::vector<cv::Point2f> points0;
cv::TermCriteria termcrit(cv::TermCriteria::COUNT|cv::TermCriteria::EPS,10,0.03);
dlib::dpoint center_pt;
int i, k;
int center_x, center_y;
int temp_width, temp_height;

int xtl;
int xtr;
int yt;
int intersected;
int angle;


int t = 0;
int b = 0;
int l = 0;
int r = 0;
int w = 0;
int h = 0;
int optimize = 0;
int bcount = 0;
 int red = 0;
 int green = 0;
 int blue = 0;

int center_ball_x = 0;
int center_ball_y = 0;

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
    //dlib::assign_image(img_gray_2, img);
    int offset = 175;
    /*
    int range = 1;
    int range2 = 30;
    int blur_size = 15;
     */
    int range = 1;
    int range2 = 30;
    int blur_size = 9;
    dlib::rectangle roi;
    std::vector<dlib::rectangle> dets_ball;
    
    for(i = 0; i < PT_SIZE; i++){
        A.at<float>(i, 2) = 1.0;
    }
    
    
    //if(!colorstuff){
    if(optimize == 1){
        offset = 2 * (r-l);
        int tpx = 0;
        int tpy = 0;
        int bpx = 0;
        int bpy = 0;
        tpx= l - offset;
        if (tpx < 0) tpx = 0;
        if(tpx >= 1920) tpx = 1919;
        tpy= t - offset;
        if (tpy < 0) tpy = 0;
        if(tpy >= 1080) tpy = 1079;
        bpx= r + offset;
        if (bpx >= 1920) bpx = 1919;
        if(bpx < 0) bpx = 0;
        bpy= b + offset;
        if (bpy >= 1080) bpy = 1079;
        if(bpy < 0) bpy = 0;
        cv::Point tp(tpx, tpy);
        cv::Point bp(bpx, bpy);
        cv::Rect myROI(tp, bp);
        
        int region = (r-l)/4;
        int new_t = t;
        if(new_t > 1079-region) new_t = 1079-region;
        int new_b = b;
        if(new_b < region) new_b = region;
        int new_r = r;
        if(new_r < region) new_r = region;
        int new_l = l;
        if(new_l > 1919-region) new_l = 1919-region;
        cv::Rect temp(new_l+region, new_t+region, new_r-new_l-(2*region), new_b-new_t-(2*region));
        
        
        cv::Mat image_orig = dlib::toMat(img);
        cv::cvtColor(image_orig, image_orig, CV_BGR2HSV);
        
        cv::Mat image_box = image_orig.clone();
        image_box = image_box(temp);
        cv::Mat bgr[3];
        cv::GaussianBlur(image_box, image_box, cv::Size(blur_size, blur_size), 0, 0);
        
        cv::split(image_box, bgr);
        if(bcount != 0){
            //red = cv::mean(bgr[2]).val[0];
            //green = cv::mean(bgr[1]).val[0];
            //blue = cv::mean(bgr[0]).val[0];
            //cout << red << " " << green << " " << blue << endl;
            for (int color = 0; color < 3; color++) {
                int maxCount = 0;
                int maxIndex = 0;
                vector<int>count(256,0);
                
                for(int i=0;i<bgr[color].rows;i++)
                {
                    for(int j=0;j<bgr[color].cols;j++)
                    {
                        int index = (int) bgr[color].at<unsigned char>(i,j);
                        //cout << bgr[color] << endl;
                        //cout << "idx" << index<< endl;
                        count[index]++;
                        if(count[index] > maxCount)
                        {
                            maxCount = count[index];
                            maxIndex = index;
                        }
                    }
                }
                if (color == 0) {
                    blue = maxIndex;
                } else if (color == 1) {
                    green = maxIndex;
                } else {
                    red = maxIndex;
                }
            }
        }
        cv::Mat image_roi = image_orig.clone();
        image_roi = image_roi(myROI);
        cv::GaussianBlur(image_roi, image_roi, cv::Size(blur_size, blur_size), 0, 0);
        //cv::inRange(image_roi, cv::Scalar(blue - range2, green-range2, red-range), cv::Scalar(blue + range2, green+range2, red + range), image_roi);
        int blue2 = blue - range;
        if(blue2 < 0)  blue2 = 0;
        int red2 = red - range;
        if(red2 < 0) red2 = 0;
        int green2 = green - range;
        if(green2 < 0)  green2 = 0;
        //cout << red2 << " " <<  green2 << " " <<  blue2 << endl;
        //cv::inRange(image_roi, cv::Scalar(blue2, green2, red2), cv::Scalar(blue + range2, green+range2, red + range2), image_roi);
        cv::inRange(image_roi, cv::Scalar(blue-range, green-range2, red-range2), cv::Scalar(blue + range, green+range2, red + range2), image_roi);
        
        std::vector<cv::Vec3f> circles;
        
        /// Apply the Hough Transform to find the circles
        
/*
        cv::HoughCircles( image_roi, circles, CV_HOUGH_GRADIENT, 1, image_roi.rows/16, 200, 50, 0, 0 );
        cout << "circles" << circles.size() << endl;
        /// Draw the circles detected
        for( size_t q = 0; q < circles.size(); q++ )
        {
            cv::Point center(cvRound(circles[q][0]), cvRound(circles[i][1]));
            int radius = cvRound(circles[q][2]);
            // circle center
            circle( image_roi, center, 3, cv::Scalar(0,255,0), -1, 8, 0 );
            // circle outline
            circle( image_roi, center, radius, cv::Scalar(0,0,255), 3, 8, 0 );
        }
  */
        /*
         cv::Mat canny_output;
         std::vector<std::vector<cv::Point> > contours;
         std::vector<cv::Vec4i> hierarchy;
         
         /// Detect edges using canny
        
         // cv::GaussianBlur(image_roi, image_roi, cv::Size(21, 21), 0, 0);
         
         cv::Mat canny_dest;
         cv::Canny(image_roi, canny_dest, 100, 255, 3);
         /// Find contours
         cv::findContours( canny_dest, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
         
         cv::Rect bounding_rect;
         int largest_area = 0;
         for( int i = 0; i< contours.size(); i++ ) // iterate through each contour.
         {
         double a= cv::contourArea(contours[i],false);  //  Find the area of contour
         if(a>largest_area){
         largest_area=a;
         bounding_rect=cv::boundingRect(contours[i]); // Find the bounding rectangle for biggest contour
         
         }
         }
         
         int c_sum = bounding_rect.x + bounding_rect.width/2;
         int r_sum = bounding_rect.y + bounding_rect.height/2;
         
        
        */
        
        int r_sum = 0;
        int c_sum = 0;
        int num = 0;
        
        
        for(int r = 0; r < image_roi.rows; r++){
            for(int c = 0; c < image_roi.cols; c++){
                if(image_roi.at<unsigned char>(r, c) > 0){
                    c_sum += c;
                    r_sum += r;
                    num++;
                }
            }
        }
        r_sum = r_sum / num;
        c_sum = c_sum / num;
        
        
        //cv::cvtColor(image_roi, image_roi, CV_GRAY2BGR);
        //cv::circle( image_roi, cv::Point(c_sum, r_sum), 10, cv::Scalar(105,50,150), -1, 8);
        //image_roi.copyTo(image_orig(myROI));

        cv::cvtColor(image_orig, image_orig, CV_HSV2BGR);
        cv::circle( image_orig, cv::Point(center_ball_x, center_ball_y), 30, cv::Scalar(105,50,150), -1, 8);
        cv::rectangle(image_orig, myROI, cv::Scalar(255, 100, 250), 5, 8, 0);
        
        //cv::rectangle(image_orig, bounding_rect, cv::Scalar(105,50,150), 1, 8, 0);
        
        int diffx = -center_ball_x + (tpx + c_sum);
        int diffy = -center_ball_y + (tpy + r_sum);
        
        center_ball_x += diffx;
        center_ball_y += diffy;
        if(center_ball_x < 0) center_ball_x = 0;
        if(center_ball_x >= 1920) center_ball_x = 1919;
        if(center_ball_y < 0) center_ball_y = 0;
        if(center_ball_y >= 1080) center_ball_y = 1079;
        
        t += diffy;
        b += diffy;
        l += diffx;
        r += diffx;
        
        dlib::dpoint center_pt = dlib::dpoint(center_ball_x, center_ball_y);
        pt_array[pt_idx] = center_pt;
        A.at<float>(pt_idx, 0) = (float)center_ball_x * center_ball_x;
        A.at<float>(pt_idx, 1) = (float)center_ball_x;
        B.at<float>(pt_idx, 0) = (float)center_ball_y;
        pt_idx++;
        if(pt_idx == PT_SIZE){
            pt_idx = 0;
        }
        
        dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image_orig));
        bcount = 0;
    }
    else{
        //cout << "optimized " << optimize << endl;
        dets_ball = sp(img_gray);
        //cv::Mat ball, ballg;
        if(dets_ball.size() == 0){
            bcount = 0;
            
        }
    }
    
    for ( i = 0; i < dets_ball.size(); ++i) {
        if(optimize == 0){
            draw_rectangle(img, dets_ball[i], dlib::rgb_pixel(255,30, 0));
            center_ball_x = (dets_ball[i].left() + dets_ball[i].right()) / 2;
            center_ball_y = (dets_ball[i].top() + dets_ball[i].bottom()) / 2;
            cout << center_ball_x << " center " << center_ball_y << endl;
            
            t = dets_ball[i].top();
            b = dets_ball[i].bottom();
            l = dets_ball[i].left();
            r = dets_ball[i].right();
            bcount++;
            if(bcount > 3){
                optimize = 1;
            }
            break;
        }
        
    }
    //comment
    
    /*
     //cout << "o: "<< t << " "<< b << " "<< l << " "<< r << " " << endl;
     w = r - l;
     h = b - t;
     offset = 300;
     bcount = 0;
     optimize = 1;
     */
    //comment
    
    
    //comment
    
    
    
    
    int iterations = 500;
    int best_inliers = 0;
    int num_points = 8;
    cv::Mat bestX;
    
    for(int i = 0; i < iterations; i++){
    
        //make a parabola
        cv::Mat smallA = cv::Mat::zeros(num_points, 3, CV_32F);
        cv::Mat smallB = cv::Mat::zeros(num_points, 1, CV_32F);
        cv::Mat smallX;
        
        for(int j = 0; j < num_points; j++){
            int rand = std::rand() % PT_SIZE;
            smallA.at<float>(j, 0) = (float)pt_array[rand].x() * pt_array[rand].x();
            smallA.at<float>(j, 1) = (float)pt_array[rand].x();
            smallA.at<float>(j, 2) = (float)1;
            smallB.at<float>(j, 0) = (float)pt_array[rand].y();
        }
       smallX = (smallA.t() * smallA).inv() * smallA.t() * smallB;

        //get number of reasonable inliers
        int inliers = 0;
        for(int j = 0; j < PT_SIZE; j++){
            int x_to_check = pt_array[j].x();
            int y_to_check = pt_array[j].y();
            int parabY = (int)(smallX.at<float>(0)*x_to_check*x_to_check + smallX.at<float>(1)*x_to_check + smallX.at<float>(2));
            if(abs(parabY-y_to_check) < 2){
                inliers++;
            }
        }
        
        
        if(inliers > best_inliers){
            best_inliers = inliers;
            bestX = smallX.clone();
            if(inliers == 15) break;
        }
    }
    cout << "in: " << best_inliers << endl;
    X = bestX;
    if(best_inliers == 0){
        X = (A.t() * A).inv() * A.t() * B;
    }
    
    
    
    
    
    
    for(int i = 0; i < PT_SIZE; i++){
        
        draw_solid_circle(img, pt_array[i], 5, dlib::rgb_pixel(0,150,255));
    }
    
    if(X.at<float>(0) > 0){
        for(int i = 0; i < 1920; i+=10){
            if (i == 0) {
                intersected = 0;
            }
            int parabY = (int)(X.at<float>(0)*i*i + X.at<float>(1)*i + X.at<float>(2));
            dlib::dpoint parabola = dlib::dpoint(i, parabY);
            
            
            int expand = 20;
            if (parabY < 1080) {
                if (yt != 0 && (intersected || (i >= xtl-expand && i <= xtr+expand && abs(parabY-yt) < 25))) {
                    cout << "xtl = " << xtl << endl;
                    cout << "xtl = " << xtr << endl;
                    cout << "yt = " << yt << endl;
                    cout << "paraby = " << parabY << endl;
                    
                    draw_solid_circle(img, parabola, 3, dlib::rgb_pixel(0,230,0));
                    if (intersected == 0) {
                        angle = -1*(2*X.at<float>(0)*i + X.at<float>(1));
                    }
                    intersected = 1;
                } else {
                    draw_solid_circle(img, parabola, 3, dlib::rgb_pixel(0,230,230));
                }
            }
            
        }
    }    
    
    dlib::assign_image(img_gray_2, img);
    
    
    //THIS IS THE HOOP TRACKING SECTION
    /*
     
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
    } else {
        cv::Mat image = dlib::toMat(img_gray_2);
        cv::Mat image_disp = dlib::toMat(img);
        
        if (angle) {
            cv::putText(image_disp, std::to_string(angle), cv::Point(960,960), 1, 10.0, cvScalar(0,0,0,5), 5);
        }
        
        std::vector<uchar> status;
        std::vector<float> err;
        std::vector<cv::Point2f> points1, pointstemp;
        
        cv::calcOpticalFlowPyrLK(temp_img, image, points0, points1, status, err, cv::Size(31, 31), 3, termcrit, 0, 0.001);
        int offset_bool = 1;
        int xoffset = 0;
        int yoffset = 0;
        int numoffset = 0;
        
        for(i = 0; i < points1.size(); i++) {
            if(status[i] == 1){
                if(offset_bool){
                    xoffset += points1[i].x - points0[i].x;
                    yoffset += points1[i].y - points0[i].y;
                    numoffset++;
                    
                    offset_bool = 0;
                }
                pointstemp.push_back(points1[i]);
                cv::circle( image_disp, points1[i], 3, cv::Scalar(0,255,0), -1, 8);
            }
        }
        if(offset_bool == 1) {
            found_temp = 0;
        } else {
            
            center_x = center_x + (xoffset/numoffset);
            center_y = center_y + (yoffset/numoffset);
            
            xtl = center_x-(temp_width/2);
            yt = center_y-(temp_height/2);
            xtr = center_x+(temp_width/2);
            
            int xbr = center_x+(temp_width/2);
            int ybr = center_y+(temp_height/2);
            
            cv::circle( image_disp, cv::Point(center_x, center_y), 10, cv::Scalar(255,50,50), -1, 8);
            cv::rectangle( image_disp, cv::Point(center_x-(temp_width/2), center_y-(temp_height/2)), cv::Point(center_x+(temp_width/2), center_y+(temp_height/2)), cv::Scalar(255,50,50), 2, 8);
        }
        dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image_disp));
        
        points0 = pointstemp;
        temp_img = image.clone();
    }
    */
    
    
    
    
    
    
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
