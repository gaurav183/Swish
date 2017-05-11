//
//  DlibWrapper.m
//  DisplayLiveSamples
//
//  
//  Adapted from face detector by Luis Reisewitz on 16.05.16.
//  Used for Hoop and Ball tracking by Anand Kapadia, Gaurav Lahiry 04.17
//

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>

#ifdef __cplusplus

#include "opencv2/features2d/features2d.hpp"
#include "opencv2/nonfree/features2d.hpp"
#include <opencv2/opencv.hpp> 
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/opencv.h>
#include "opencv2/video/tracking.hpp"
#import  "opencv2/objdetect/objdetect.hpp"
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <math.h>
#endif


using namespace std;

#define PT_SIZE (20)
#define PI (3.14159265)


@interface DlibWrapper ()

@property (assign) BOOL prepared;

@property (assign) BOOL hoopDone;

@end


@implementation DlibWrapper {
    // Create the hoop detector object w/ image pyramid downsample ratio 5/6
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp;
    // Create the ball detector object w/ image pyramid downsample ratio 5/6
    dlib::object_detector<dlib::scan_fhog_pyramid<dlib::pyramid_down<6>>> sp2;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
        _hoopDone = NO;
    }
    return self;
}


//variable to keep track of index into circular data array
int pt_idx = 0;

///historical array (circular buffer) of past PT_SIZE ball points
dlib::dpoint pt_array[PT_SIZE];

//boolean int that tracks if a template has been found for the hoop
int found_temp = 0;

//opencv image for hoop detection template identification
cv::Mat temp_img;

//points that indicate features for hoop detection optical flow
std::vector<cv::Point2f> points0;

//termcrit for hoop detection optical flow
cv::TermCriteria termcrit(cv::TermCriteria::COUNT|cv::TermCriteria::EPS,10,0.03);

//point to keep track of center of the ball
dlib::dpoint center_pt;

//iteration variables
int i, k;

//center of the hoop coordinates
int center_x, center_y;

//bounding box of the template
int temp_width, temp_height;

//center of the ball coordinates
int center_ball_x = 0;
int center_ball_y = 0;

//points used to determine intersection between top of the tempate of the hoop and the parabola
int xtl;
int xtr;
int yt;
int intersected;

//angle of the shot
int angle;

//bounding box of the ball (top, bot, left, right, width, height)
int t = 0;
int b = 0;
int l = 0;
int r = 0;
int w = 0;
int h = 0;

//boolean int that switches between dlib HOG detection and template based trackers
int optimize = 0;

//number of consecutive frames the HOG detector must find the ball in to transition to 
//template based tracking
int bcount = 0;

//mean or mode color averages (color of the basketball), either in HSV or RGB
int red = 0;
int green = 0;
int blue = 0;

//matricies to calculate parabola parametrization
cv::Mat A = cv::Mat::zeros(PT_SIZE, 3, CV_32F);
cv::Mat B = cv::Mat::zeros(PT_SIZE, 1, CV_32F);
cv::Mat X;

//THIS CODE FUNTION IS FROM REISEWITZ
- (void)prepare {
    //load the svm for the ball detection 
    //NOTE: even though it says face detector, this was a renaming oversight when transfered
    //from the computer HOG trainer. I did not want to change any code except comments after 
    //presentation due date, so this has been left as is. 
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"face_detector" ofType:@"svm"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    dlib::deserialize(modelFileNameCString) >> sp;
    
    //load the svm for the hoop detection 
    NSString *modelFileName2 = [[NSBundle mainBundle] pathForResource:@"hoop_detector" ofType:@"svm"];
    std::string modelFileNameCString2 = [modelFileName2 UTF8String];
    dlib::deserialize(modelFileNameCString2) >> sp2;
    
    self.prepared = YES;
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    //THIS CODE SEGMENT IS FROM REISEWITZ

    if (!self.prepared) {
        [self prepare];
    }
    
    //image
    dlib::array2d<dlib::bgr_pixel> img;
    
    //timing helper variables
    NSDate *start = [NSDate date];
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    //cout << "start " << timeInterval << endl;

    //retrieve image from buffer
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
        long bufferLocation = position * 4; 
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);


    //INITIALIZATION 


    //create various images to work and process on so original is not changed
    dlib::array2d<unsigned char> img_gray;
    dlib::array2d<unsigned char> img_gray_2;
    dlib::array2d<unsigned char> img_gray_small;

    dlib::assign_image(img_gray, img);

    //int to determine extra width and height added to ROI in which to search for ball
    //in color tracker
    int offset = 175;

    //variance allowed in the r or H channels
    int range = 2;

    //variance allowed in the S, V channelrs
    int range2 = 40;

    //size of gaussian blurs
    int blur_size = 3;

    //region of interest initialization
    dlib::rectangle roi;
    std::vector<dlib::rectangle> dets_ball;
    
    //Fill third column of A matrix to 1's
    for(i = 0; i < PT_SIZE; i++){
        A.at<float>(i, 2) = 1.0;
    }

    

    //THIS IS THE BALL TRACKING SECTION
    


    //if the template based tracker is running (color tracker)
    if(optimize == 1){

        //calculate a safe ROI for ball tracking
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
        
        //calculate a safe ROI for color extraction
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
        
        //convert dlib to opencv
        cv::Mat image_orig = dlib::toMat(img);

        //convert the color of the image to hsv
        cv::cvtColor(image_orig, image_orig, CV_BGR2HSV);

        //retrieve the box image, or the image from which to extract the ball color from
        cv::Mat image_box = image_orig.clone();
        image_box = image_box(temp);

        //split the image into seperate channels after a gaussian blur
        cv::Mat bgr[3];
        cv::GaussianBlur(image_box, image_box, cv::Size(blur_size, blur_size), 0, 0);
        cv::split(image_box, bgr);

        //if this is the first time we are running the color tracker, derive the color of the ball
        if(bcount != 0){
            //this for loop calculates the mode H, S, V values and stores them into blue, green, red
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

        //get the region of the image that is to be used to search for the ball 
        cv::Mat image_roi = image_orig.clone();
        image_roi = image_roi(myROI);

        //blur said image
        cv::GaussianBlur(image_roi, image_roi, cv::Size(blur_size, blur_size), 0, 0);

        //ensure the color values found (with range offsets)are within reasonable limits
        int blue2 = blue - range;
        if(blue2 < 0)  blue2 = 0;
        int red2 = red - range;
        if(red2 < 0) red2 = 0;
        int green2 = green - range;
        if(green2 < 0)  green2 = 0;

        //threshold the ROI to only display the key colors we want
        cv::inRange(image_roi, cv::Scalar(blue-range, green-range2, red-range2), cv::Scalar(blue + range, green+range2, red + range2), image_roi);
        
        //Canny / HOUGH Circles was originally attempted here, but was deleted due to bugs and lack of time
        
        //variables to help find the center of the ball in this new region we have found
        int r_sum = 0;
        int c_sum = 0;
        int num = 0;
        
        //find the center fo the ball based on the average color distribution within the searched ROI
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
        
        //convert from HSV to BGR
        cv::cvtColor(image_orig, image_orig, CV_HSV2BGR);

        //draw centerpoint and bounding boxes
        cv::circle( image_orig, cv::Point(center_ball_x, center_ball_y), 30, cv::Scalar(105,50,150), -1, 8);
        cv::rectangle(image_orig, myROI, cv::Scalar(255, 100, 250), 5, 8, 0);
        
        //calculate movement of bounding box        
        int diffx = -center_ball_x + (tpx + c_sum);
        int diffy = -center_ball_y + (tpy + r_sum);
        
        //update the center values from within ROI to relative to entire image
        center_ball_x += diffx;
        center_ball_y += diffy;
        if(center_ball_x < 0) center_ball_x = 0;
        if(center_ball_x >= 1920) center_ball_x = 1919;
        if(center_ball_y < 0) center_ball_y = 0;
        if(center_ball_y >= 1080) center_ball_y = 1079;
        
        //update bounding box location
        t += diffy;
        b += diffy;
        l += diffx;
        r += diffx;
        
        //convert center point to dlib point
        dlib::dpoint center_pt = dlib::dpoint(center_ball_x, center_ball_y);

        //add point to the historical data circular array
        pt_array[pt_idx] = center_pt;

        //update matricies for linear least squares with the point (RANSAC, if enabled, will overwrite this)
        A.at<float>(pt_idx, 0) = (float)center_ball_x * center_ball_x;
        A.at<float>(pt_idx, 1) = (float)center_ball_x;
        B.at<float>(pt_idx, 0) = (float)center_ball_y;
        
        //increment buffer index
        pt_idx++;
        if(pt_idx == PT_SIZE){
            pt_idx = 0;
        }
        
        //convert image
        dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image_orig));

        //indicate that template based tracking has run at least once (clear flags left from HOG detector)
        bcount = 0;
    }

    //HOG detection 
    else{

        //This line does the full HOG detection using the dlib library. Returns the rectangles
        dets_ball = sp(img_gray);

        //if no ball found, reset counter
        if(dets_ball.size() == 0){
            bcount = 0;
            
        }
    }
    
    //for every ball found
    for ( i = 0; i < dets_ball.size(); ++i) {
        //if no ball found yet
        if(optimize == 0){

            //draw the location where it was found
            draw_rectangle(img, dets_ball[i], dlib::rgb_pixel(255,30, 0));

            //find the center point
            center_ball_x = (dets_ball[i].left() + dets_ball[i].right()) / 2;
            center_ball_y = (dets_ball[i].top() + dets_ball[i].bottom()) / 2;
            cout << center_ball_x << " center " << center_ball_y << endl;
            
            //find the bounding region
            t = dets_ball[i].top();
            b = dets_ball[i].bottom();
            l = dets_ball[i].left();
            r = dets_ball[i].right();

            //increment counter for ball found in this frame
            bcount++;

            //if 4 consecutive frames with balls found, change to template based tracking
            if(bcount > 3){
                optimize = 1;
            }
            break;
        }
        
    }
    

    //ransac iterations variable
    int iterations = 500;

    //tracker for inliers
    int best_inliers = 0;

    //points to use in RANSAC calculation
    int num_points = 8;

    //matrix for RANSAC
    cv::Mat bestX;
    
    //run RANSAC
    for(int i = 0; i < iterations; i++){
    
        //Init matricies for ransac linear least squares
        cv::Mat smallA = cv::Mat::zeros(num_points, 3, CV_32F);
        cv::Mat smallB = cv::Mat::zeros(num_points, 1, CV_32F);
        cv::Mat smallX;
        
        //find random points and fill them in matrix
        for(int j = 0; j < num_points; j++){
            int rand = std::rand() % PT_SIZE;
            smallA.at<float>(j, 0) = (float)pt_array[rand].x() * pt_array[rand].x();
            smallA.at<float>(j, 1) = (float)pt_array[rand].x();
            smallA.at<float>(j, 2) = (float)1;
            smallB.at<float>(j, 0) = (float)pt_array[rand].y();
        }

        //run linear least squares
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
        
        //keep track of best parametrization
        if(inliers > best_inliers){
            best_inliers = inliers;
            bestX = smallX.clone();
            //15 inliers is best we can expect
            if(inliers == 15) break;
        }
    }
    cout << "in: " << best_inliers << endl;

    //if no good parametrization, just run linear least squares on all the points found.
    //Otherwise take RANSAC result to be the best
    X = bestX;
    if(best_inliers == 0){
        X = (A.t() * A).inv() * A.t() * B;
    }
    
    //draw all the historic points found for reference 
    for(int i = 0; i < PT_SIZE; i++){
        draw_solid_circle(img, pt_array[i], 5, dlib::rgb_pixel(0,150,255));
    }
    
    //if the parabola makes gravitational sense...
    if(X.at<float>(0) > 0){

        //iterate through parabola
        for(int i = 0; i < 1920; i+=10){

            //reset intersected bool on init
            if (i == 0) {
                intersected = 0;
            }

            //calculate y point
            int parabY = (int)(X.at<float>(0)*i*i + X.at<float>(1)*i + X.at<float>(2));
            dlib::dpoint parabola = dlib::dpoint(i, parabY);
            int expand = 20;

            //if the y is within range
            if (parabY < 1080) {
                //if the parabola has intersected with the hoop
                if (yt != 0 && (intersected || (i >= xtl-expand && i <= xtr+expand && abs(parabY-yt) < 25))) {
                   
                    //report
                    cout << "xtl = " << xtl << endl;
                    cout << "xtl = " << xtr << endl;
                    cout << "yt = " << yt << endl;
                    cout << "paraby = " << parabY << endl;
                    
                    //draw point in green
                    draw_solid_circle(img, parabola, 3, dlib::rgb_pixel(0,230,0));
                    
                    //calculate angle if not already done so
                    if (intersected == 0) {
                        angle = atan(2*X.at<float>(0)*i + X.at<float>(1)) * 180 / PI;
                    }

                    //report intersection has happened
                    intersected = 1;
                } 
                //if the parabola has not intersected with the hoop at this point
                else {
                    //draw the parabola in a blue-green
                    draw_solid_circle(img, parabola, 3, dlib::rgb_pixel(0,230,230));
                }
            }
            
        }
    }    
    dlib::assign_image(img_gray_2, img);
    
    


    //THIS IS THE HOOP TRACKING SECTION
 


    //if a template has not been found yet for the hoop
    if(!found_temp) {

        // Run the detector and get the hoop bounding rectangle
        std::vector<dlib::rectangle> dets = sp2(img_gray_2);
        
        //init a point
        std::vector<cv::Point2f> pointstemp;
        
        //for every hoop found
        for ( i = 0; i < dets.size(); ++i) {

            //draw the rectangle around the hoop
            draw_rectangle(img, dets[i], dlib::rgb_pixel(255,0,0));

            //get the center and regions of the hoop
            center_x = (dets[i].left() + dets[i].right()) / 2;
            center_y = (dets[i].top() + dets[i].bottom()) / 2;
            temp_width = (dets[i].right()  - dets[i].left());
            temp_height = (dets[i].bottom() - dets[i].top());
            
            //convert to opencv
            temp_img = dlib::toMat(img_gray_2);
            
            //find the features to track on the hoop
            cv::goodFeaturesToTrack(temp_img, pointstemp, 1000, 0.01, 10, cv::Mat(), 3, 0, 0.04);
            
            //convert orig image to opencv
            cv::Mat image = dlib::toMat(img);
            
            //for every point found, sort based on if it is in the region of the hoop detector
            for( k = 0; k < pointstemp.size(); k++ )
            {
                //if not in region, pass
                if(pointstemp[k].x < dets[i].left() || pointstemp[k].x > dets[i].right() || pointstemp[k].y < dets[i].top() || pointstemp[k].y > dets[i].bottom()){
                    continue;
                }

                //add to points list
                points0.push_back(pointstemp[k]);

                //draw point
                cv::circle( image, points0[k], 3, cv::Scalar(255,0,0), -1, 8);
            }
            
            //convert image
            dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image));

            //if points were detected, transfer to template based tracking
            if(points0.size() > 1){
                found_temp = 1;
            }
        }
    } 
    //template based tracking
    else {
        //convert images
        cv::Mat image = dlib::toMat(img_gray_2);
        cv::Mat image_disp = dlib::toMat(img);
        
        //if the angle was found, display it
        if (angle) {
            cv::putText(image_disp, std::to_string(angle), cv::Point(960,960), 1, 10.0, cvScalar(0,0,0,5), 5);
        }
        
        //init vectors
        std::vector<uchar> status;
        std::vector<float> err;
        std::vector<cv::Point2f> points1, pointstemp;
        
        //calculate optical flow
        cv::calcOpticalFlowPyrLK(temp_img, image, points0, points1, status, err, cv::Size(31, 31), 3, termcrit, 0, 0.001);
        
        //offset boolearns for how much template has moved
        int offset_bool = 1;
        int xoffset = 0;
        int yoffset = 0;
        int numoffset = 0;
        
        //iterate through points found
        for(i = 0; i < points1.size(); i++) {

            //if status shows valid
            if(status[i] == 1){

                //find displacement
                if(offset_bool){
                    xoffset += points1[i].x - points0[i].x;
                    yoffset += points1[i].y - points0[i].y;
                    numoffset++;
                    
                    offset_bool = 0;
                }

                //add point to important vector
                pointstemp.push_back(points1[i]);

                //draw point
                cv::circle( image_disp, points1[i], 3, cv::Scalar(0,255,0), -1, 8);
            }
        }

        //if no valid points found, go back to HOG detector
        if(offset_bool == 1) {
            found_temp = 0;
        } 

        //if valid points found
        else {    

            //calculate template movement
            center_x = center_x + (xoffset/numoffset);
            center_y = center_y + (yoffset/numoffset);
            
            //update global template location parameters
            xtl = center_x-(temp_width/2);
            yt = center_y-(temp_height/2);
            xtr = center_x+(temp_width/2);

            //display hoop and key points on the screen
            int xbr = center_x+(temp_width/2);
            int ybr = center_y+(temp_height/2);
            cv::circle( image_disp, cv::Point(center_x, center_y), 10, cv::Scalar(255,50,50), -1, 8);
            cv::rectangle( image_disp, cv::Point(center_x-(temp_width/2), center_y-(temp_height/2)), cv::Point(center_x+(temp_width/2), center_y+(temp_height/2)), cv::Scalar(255,50,50), 2, 8);
        }

        //convert image
        dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image_disp));
        
        //transfer current to previous (so next frame can be processed)
        points0 = pointstemp;
        temp_img = image.clone();
    }
    



    //THIS CODE SEGMENT IS FROM REISEWITZ
    
    //restore buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        long bufferLocation = position * 4; 
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    timeInterval = [start timeIntervalSinceNow];    
    
}

@end
