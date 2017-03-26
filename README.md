# Swish
Using optimized mobile vision algorithms to detect, track and predict basketball shot trajectory.

Anand Kapadia and Gaurav Lahiry

Summary
We plan to make a basketball shot tracking app that analyzes the arc of your basketball shot in real time, and makes a prediction on whether or not it will go in. Additionally, it will measure the angle at which the ball goes through the hoop, providing the user with feedback (ideal shot arc angle vs distance to hoop) to help you obtain the perfect swish.
Background
We will implement our app using Inverse Compositional Lucas Kanade, Kinematics, Least Squares Estimation, and Homographies. Inverse LK would be an optimal algorithm to track optical flow so we could follow the path of the basketball as it is shot. We would use a well chosen template image that we could sample beforehand and use it to exhaustively search from an area sufficiently near the expected ‘event horizon’.
After getting a successful tracking algorithm, the next step would be to plot some points and use least squares estimation to fit a parabola to the math of the ball. This combined with Kinematics from Mechanical Physics should be enough to track whether the ball is on the right trajectory to the hoop (allowing for a prediction on shot accuracy before it goes through the hoop). We could also fit and project a homography as necessary, to map the court and hoop so we know the relative position of the basket so that we are able to guide and predict shot trajectories.
The Challenge
The biggest challenge lies in being able to efficiently detect and track a basketball in real time. Additionally, to make the app useful, a player needs this to be something that is conveniently available and potable. Hence, it makes sense to utilize mobile computer vision since it is a very suitable platform for this kind of processing and computation. It would also be possible to optimize trajectory projection and real time tracking on a mobile platform so it would be a reasonable problem to tackle. Some vital information we could learn from this project involves the angle of the shot.
Why Shot Angle Matters
Shot angle, while not the most common thought of aspect of a basketball shot, is one of the most importance for the sole reason that the angle you approach the basketball hoop changes the “size”, or error of margin of the hoop. However, make the angle too high and the shot is very hard to control due to the additional forces on the ball. In fact, studies have been done on shot angles, and it has been determined that the “perfect shot angle” is based on distance to the basket -- at the foul shot line it is 45 degrees, and at the three point line it is 51 degrees.
Additionally, there are three main components of a basketball shot: release (follow through), backspin, and shot arc. Of these three, shot arc is by far the hardest to judge as a shooter. Hence,
we think making an app that measures this would be both fun and useful to basketball fans like ourselves, giving the user key feedback without needing to invest in an expensive “smart” basketball.
Goals & Deliverables
Plan to achieve (using fixed camera position at corner three point line): 
* Full basketball tracking using Lucas Kanade
* Parabola path tracking of basketball
* Basketball Hoop Recognition
* Basketball Angle of Entry
Hope to achieve:
* High Frame Rate
* Basketball shot accuracy prediction
* Dynamic angle feedback based on player height and distance to the hoop (there is a formula
for ideal shot angle)
* Tracking from any camera position on the court
Goal:
What we would define to be a success would include being able to follow the path of a basketball being shot from the point of release to the entry point at the basket. We would use this to generate a parabolic plot mapping the trajectory of a shot. We would then project the homographies of the court and hoop and combine this with our plot to calculate the shot angle.
Checkpoints
* End of 1st week of April • Lucas Kanade
* End of 2nd week of April
* Parabola tracking and “mock” angle of entry
* End of 3rd week of April • Hoop tracking
* End of April
* Project complete
