# Navigating Ryze Tello Drones With MATLAB App

[![View Navigating-Ryze-Tello-Drones-With-MATLAB-App on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/111210-navigating-ryze-tello-drones-with-matlab-app)

To interactively control a Ryze&reg; Tello Drone connected to your computer running MATLAB&reg;, MathWorks&reg; provides a MATLAB app - Ryze Tello Navigator. This app helps you to:

 - View all the Ryze Tello drones connected to the WiFi network of the computer.

 - Perform take-off/land of a drone.

 - Control the drone’s navigation using keyboard or by using the navigation control buttons in the app.

 - Preview the camera feed and capture images.

 - Record the drone's video feed into MATLAB workspace variable.

 - Generate MATLAB script for the completed navigation.

![alt text](resources/readmeimages/app_image_whole.png?raw=true)

## Installation and Setup 

1. Install MATLAB and MATLAB Support Package for Ryze Tello Drones
2. Perform the initial [Setup and Configuration](https://www.mathworks.com/help/supportpkg/ryzeio/setup-and-configuration.html) and connect to one or more Ryze Tello Drones.
3. Download or clone this repository.
4. Navigate to the local repository folder in MATLAB
5. Execute the following commands in MATLAB command window:
>> addpath(pwd);

>> savepath;
6. Launch the app by executing *ryzeTelloNavigator* command.

### MathWorks Products (http://www.mathworks.com)

Requires MATLAB release R2022a or newer
- [MATLAB&reg; Support Package for Ryze Tello&reg; Drones](https://www.mathworks.com/hardware-support/tello-drone-matlab.html)


## Verify that the Connected Drone is Listed in the App and Perform Pre-Flight Check

Ensure that the drone that appears in the *Device List* is the one that you would like to control using the app. If the drone is not listed, perform [Setup and Configuration](https://www.mathworks.com/help/supportpkg/ryzeio/setup-and-configuration.html) again.

| Step | Action | Result  |
| ------ | ------ | ------ 
|1 | ![alt text](resources/readmeimages/prefligtcheck.png?raw=true)Click the drone’s name from the *Device List* and click *Pre-flight Check* in the Navigation section at the top.  |A new dialog box, Running Pre-flight Checklist, appears. All other controls in the app are disabled while the pre-flight check is in progress. If there are errors, the dialog box provides links to the required troubleshooting steps|
 | 2 | After verifying that all pre-flight checks are successfully completed, click OK. | ![alt text](resources/readmeimages/pre-flight-completed.png?raw=true) The **Pre-Flight Check Completed** indication appears on the right side of the app. All other controls are also enabled. |



## Perform Take-off and Navigation
Ryze Tello Navigator helps you to perform take-off/land and interactively control the Ryze Tello drone. 

**Note**: Before initiating the take-off of the drone, consider the general safety precautions. If you sense any damage that can occur to the drone and the surroundings during the take-off or while performing manual navigation control (as mentioned in the subsequent steps), you can click **Emergency Land**. Clicking this button triggers an emergency shutdown of the drone’s motors causing it to fall to the ground from the current height (for Tello EDU drones) or forces the drone to land vertically from its current position (for Tello drones).

| Step | Action | Result  |
| ------ | ------ | ------ |
|1 | ![alt text](resources/readmeimages/battery_and_signal.png?raw=true)     Check that the battery charge and signal strength of the drone, as displayed in the app, are sufficient to perform the take-off and control.  |
 | 2 | ![alt text](resources/readmeimages/view_camerafeed.png?raw=true) Click View Camera Feed to verify that the camera feed from the drone is working properly. | The app displays the preview, as seen by the drone’s camera before take-off. Later, when the drone moves, the preview will be updated with the live feed from the camera. | 
 |3| ![alt text](resources/readmeimages/takeoff.png?raw=true) Either press <kbd>Spacebar</kbd> on your keyboard or click *Take Off* that appears in the Navigation section in the toolstrip area.|The drone’s motors start and the drone takes-off to a particular altitude and hovers at that position. The *Take Off* button is replaced by the *Land* button. |
 |4|Perform manual navigation of the drone from the app either by clicking the respective icons in the app or by using your keyboard.|The drone moves according to the navigation control that you triggered. The camera feed (preview), if it is enabled, also gets updated. To increase the area of the preview window as seen in the app, you can hide the pane that shows buttons for manual control. Click *Show Controls* to disable the pane. You can still use the keyboard keys to control the drone.

 WASD keys:
 - <kbd>W</kbd> – Move forward
 - <kbd>A</kbd> – Move Left
 - <kbd>S</kbd> – Move backward
 - <kbd>D</kbd> – Move right

![alt text](resources/readmeimages/wasd_icons.png?raw=true)

Arrow keys:
 - <kbd>▲</kbd> – Move the drone upwards
 - <kbd>▼</kbd> – Move the drone downwards
 - <kbd>◄</kbd> – Turn the drone counterclockwise
 - <kbd>►</kbd> – Turn the drone clockwise

![alt text](resources/readmeimages/arrow_icons.png?raw=true)

### Settings for Navigation
You can change the navigation settings that the drone uses each time you trigger movement along a particular direction. Click *Settings* to open the Setup Navigation dialog box, and specify the distance, angle, and speed values using the sliders. If you want to restore the default values (Navigation Distance: 0.2m, Turn Angle: π/2, Navigation speed: 0.4m/s), click *Restore Defaults* in the dialog box.

![alt text](resources/readmeimages/settings.png?raw=true)

![alt text](resources/readmeimages/navigation_settings.png?raw=true)

### View Live Navigation Data and Log
The app also displays the live navigation data (as captured by the drone's sensors) and also the log of the commands that you triggered using the navigation buttons or keyboard keys. This information appears on the right side panel.

![alt text](resources/readmeimages/live_data.png??raw=true)

## Capture Image and Record Video
Ryze Tello Navigator helps you to capture images and record video as seen through the Ryze Tello drone’s FPV camera.
| Step | Action | Result  |
| ------ | ------ | ------ 
|1 | ![alt text](resources/readmeimages/capture_image.png?raw=true) Capture one image at a time.|The image is stored as a workspace variable.|
 | 2 | ![alt text](resources/readmeimages/record_video.png?raw=true) Define the Workspace Variable and the Duration to record the video, and then click Record Video. | The video from the drone’s camera starts getting recorded for the specified duration. Click Stop to stop the recording anytime during recording and the video is then automatically saved in the workspace as image array.|

## Generate Script for the Navigation
Ryze Tello Navigator helps you to generate a Live Editor script of the navigation that you performed. You can use this script to define the initial setup and flight path of the drone and then add custom algorithms for performing additional workflows.

![alt text](resources/readmeimages/generate_script.png?raw=true)

To do this, click **Generate Script** after you successfully land the drone.

## Troubleshooting the App

| Warnings | Issue and Recommended Action | 
| ------ | ------
|Low battery level | The app starts displaying warnings if the **Charge Remaining** indication shows a value below 20% and the drone is flying or hovering. If the battery level falls below 10%, the drone lands automatically from its current position. To avoid this, ensure that you land the drone using the Land button in the app and then replace the drone’s battery.|
 | Low signal strength | The app constantly displays the **Signal Strength** values while the drone is flying. It is recommended that you take necessary action if the signal strength is below 20% to avoid losing control of the drone. If the connection with drone is lost, a dialog box appears showing the option to reconnect with the drone. If it still fails, an error message is displayed.|


## License
The license for <insert repo name> is available in the [LICENSE.TXT](https://github.com/mathworks/Navigating-Ryze-Tello-Drones-With-MATLAB-App/blob/main/license.txt) file in this GitHub repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2022 The MathWorks, Inc. 
