classdef RyzeTelloManager <  telloapplet.HelperClass...
        & telloapplet.modules.internal.ErrorSource
    % RYZETELLOMANAGER - Class that manages communication with drone

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % Drone related information
        DeviceInfo

        % Drone object
        RyzeObj
        % Drone FPV camera object
        CameraObj

        % Variable to store preview image handle
        PreviewImageHandle

        % Timer fcn handle to query sensor data
        SensorDataTimerFcn
        %Sensor data timer period
        SensorDataTimerPeriod = 2

        % Drone navigation parameters
        DroneNavigationDistance = 0.2
        DroneTurnAngle = pi/2
        DroneNavigationSpeed = 0.4

        % Workspace variable to store image capture data
        ImageVarName = "image1"

        % Keep a track of sensor data error
        SensorDataErrorGiven = false
    end

    properties(SetObservable)
        % Pre Flightcheck Status related properties
        PreFlightCheckTakeOffSuccessful
        PreFlightCheckLandSuccessful

        % Drone navigation commands' execution completion status
        DroneStateLanded
        DroneExecutedTakeOff
        DroneExecutedLand
        DroneExecutedAbort
        DroneExecutedMoveLeft
        DroneExecutedMoveRight
        DroneExecutedMoveForward
        DroneExecutedMoveBack
        DroneExecutedMoveUp
        DroneExecutedMoveDown
        DroneExecutedTurnCCW
        DroneExecutedTurnCW
        DroneExecutedSnapshot
        NavigationCommandIgnored
        TakeOffIgnored
        LandIgnored

        % Drone model
        DroneModelName

        % Image related properties
        ImageResolution
        ImageCaptured
        ReceivedImageData
        RecordingError

        % Battery and Signal Strength related properties
        BatteryLevel
        SignalStrength
        UpdateEssentialData

        % Sensor data related properties
        Orientation
        Speed
        Height
        UpdateSensorData
        ReceivedSensorData

        % Reconnect input dialog related prperty
        ShowReconnectInputDialog

        % Request to destro the app
        RequestToDestroyApp
    end

    methods
        % Constructor
        function obj = RyzeTelloManager(deviceInfo, mediator)

            obj@telloapplet.HelperClass(mediator);
            % Store references
            obj.Mediator = mediator;
            obj.DeviceInfo = deviceInfo;

            obj.createRyzeObject();
            obj.createCameraObject();

            obj.updateCameraResolution();
            obj.updateDroneEssentialData;
            obj.updateDroneSensorData;
            obj.DroneModelName = obj.DeviceInfo.ModelName;

            obj.setupSensorTimer();

            start(obj.SensorDataTimerFcn);

            obj.DroneStateLanded = true;
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Events related to navigation button clicks
            obj.subscribe('UserRequestedTakeOff', @(src, event)obj.handleTakeOffRequest());
            obj.subscribe('UserRequestedLand', @(src, event)obj.handleLandRequest());
            obj.subscribe('UserRequestedMoveLeft', @(src, event)obj.handleMoveLeftRequest());
            obj.subscribe('UserRequestedMoveForward', @(src, event)obj.handleMoveForwardRequest());
            obj.subscribe('UserRequestedMoveRight', @(src, event)obj.handleMoveRightRequest());
            obj.subscribe('UserRequestedMoveBack', @(src, event)obj.handleMoveBackRequest());
            obj.subscribe('UserRequestedMoveUp', @(src, event)obj.handleMoveUpRequest());
            obj.subscribe('UserRequestedMoveDown', @(src, event)obj.handleMoveDownRequest());
            obj.subscribe('UserRequestedTurnCCW', @(src, event)obj.handleTurnCCWRequest());
            obj.subscribe('UserRequestedTurnCW', @(src, event)obj.handleTurnCWRequest());
            obj.subscribe('UserRequestedEmergencyLand', @(src, event)obj.handleEmergencyLandRequest());

            % Events related to keyboard navigation
            obj.subscribe('UserPressedSpaceForTakeOff', @(src, event)obj.handleTakeOffRequest());
            obj.subscribe('UserPressedSpaceForLand', @(src, event)obj.handleLandRequest());
            obj.subscribe('UserPressedA', @(src, event)obj.handleMoveLeftRequest());
            obj.subscribe('UserPressedW', @(src, event)obj.handleMoveForwardRequest());
            obj.subscribe('UserPressedD', @(src, event)obj.handleMoveRightRequest());
            obj.subscribe('UserPressedS', @(src, event)obj.handleMoveBackRequest());
            obj.subscribe('UserPressedUp', @(src, event)obj.handleMoveUpRequest());
            obj.subscribe('UserPressedDown', @(src, event)obj.handleMoveDownRequest());
            obj.subscribe('UserPressedLeft', @(src, event)obj.handleTurnCCWRequest());
            obj.subscribe('UserPressedRight', @(src, event)obj.handleTurnCWRequest());

            obj.subscribe('UserRequestedStartCameraFeed', @(src, event)obj.startPreview());
            obj.subscribe('UserRequestedStopCameraFeed', @(src, event)obj.stopPreview());

            obj.subscribe('NavigationDistanceValue', @(src, event)obj.updateDefaultNavigationDistance());
            obj.subscribe('NavigationTurnAngle', @(src, event)obj.updateDefaultNavigationTurn());
            obj.subscribe('NavigationSpeedValue', @(src, event)obj.updateDefaultNavigationSpeed());

            obj.subscribe('CurrentImageVarName', @(src, event)obj.updateImageVarName());
            obj.subscribe('UserRequestedCaptureImage', @(src, event)obj.captureImage());

            obj.subscribe('PreFlightCheckTakeOff', @(src, event)obj.preFlightCheckTakeOffRequest());
            obj.subscribe('PreFlightCheckLand', @(src, event)obj.preFlightCheckLandRequest());
            obj.subscribe('PreFlightCheckSnapshot', @(src, event)obj.preFlightCheckSnapshotRequest());

            obj.subscribe('UpdateSensorData', @(src, event)obj.updateDroneSensorData());

            obj.subscribe('UserRequestedReconnect', @(src, event)obj.handleReconnectRequest());
        end
    end

    methods
        function updatePreviewImageHandle (obj, previewImageHandle)
            obj.PreviewImageHandle = previewImageHandle;
        end

        function frame = getLatestFrame(obj)
            try
                frame = obj.executeSnapshot();
            catch err
                obj.RecordingError = true;
                obj.setErrorObjProperty(err);
            end
        end

        function clearConnection(obj)
            obj.cleanup();
        end
    end

    methods (Access = private)
        function preFlightCheckTakeOffRequest(obj)
            % Callback for pre-flight check take-off
            % This needs to be separate from normal takeoff to set relevant
            % observable variables for Pre-Flight Check module
            try
                if strcmpi(obj.RyzeObj.State,"Landed")
                    executeTakeOff(obj);
                    obj.DroneStateLanded = false;
                    obj.PreFlightCheckTakeOffSuccessful = true;
                end
            catch err
                obj.PreFlightCheckTakeOffSuccessful = false;
                obj.setErrorObjProperty(err);
            end
        end

        function preFlightCheckLandRequest(obj)
            % Callback for pre-flight check land
            try
                if strcmpi(obj.RyzeObj.State,"Hovering")
                    executeLand(obj);
                    obj.DroneStateLanded = true;
                    obj.PreFlightCheckLandSuccessful = true;
                end
            catch err
                obj.PreFlightCheckLandSuccessful = false;
                obj.setErrorObjProperty(err);
            end
        end

        function preFlightCheckSnapshotRequest(obj)
            % Callback for pre-flight check image capture
            try
                obj.executeSnapshot();
                obj.ReceivedImageData = true;
            catch err
                obj.ReceivedImageData = false;
                obj.setErrorObjProperty(err);
            end
        end

        function handleTakeOffRequest(obj)
            % Callback function to execute when user clicks the "Take Off"
            % toolstrip button
            try
                if strcmpi(obj.RyzeObj.State,"landed")
                    executeTakeOff(obj);
                    obj.DroneStateLanded = false;
                    obj.DroneExecutedTakeOff = true;
                else
                    obj.TakeOffIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleLandRequest(obj)
            % Callback function to execute when user clicks the "Land"
            % toolstrip button
            try
                if strcmpi(obj.RyzeObj.State,"hovering")
                    executeLand(obj);
                    obj.DroneStateLanded = true;
                    obj.DroneExecutedLand= true;
                else
                    obj.LandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleEmergencyLandRequest(obj)
            % Callback function to execute when user clicks the
            % "Emergency Land" button in navigation pane
            try
                if strcmpi(obj.RyzeObj.State,"Hovering")
                    % Abort causes connection error to maintain app state
                    % signal abort being executed first to other modules
                    obj.DroneExecutedAbort = true;
                    executeAbort(obj);
                    obj.DroneStateLanded = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                % Executing Abort causes drone connection error
                obj.setErrorObjProperty(err);
                obj.RequestToDestroyApp = true;
            end
        end

        function handleMoveLeftRequest(obj)
            % Callback for move left navigation

            % The check for drone state is to ensure we log commands only
            % when it gets executed, otherwise drone may ignore the command
            % if issued while flying and we won't know
            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeMoveLeft(obj);
                    obj.DroneExecutedMoveLeft = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleMoveForwardRequest(obj)
            % Callback for move forward navigation

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeMoveForward(obj);
                    obj.DroneExecutedMoveForward = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleMoveRightRequest(obj)
            % Callback for move right navigation

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeMoveRight(obj);
                    obj.DroneExecutedMoveRight = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleMoveBackRequest(obj)
            % Callback for move back navigation

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeMoveBack(obj);
                    obj.DroneExecutedMoveBack = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleMoveUpRequest(obj)
            % Callback for move up navigation

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeMoveUp(obj);
                    obj.DroneExecutedMoveUp = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleMoveDownRequest(obj)
            % Callback for move down navigation

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeMoveDown(obj);
                    obj.DroneExecutedMoveDown = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleTurnCCWRequest(obj)
            % Callback for turning counter clockwise

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeTurnCCW(obj);
                    obj.DroneExecutedTurnCCW = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function handleTurnCWRequest(obj)
            % Callback for turning clockwise

            try
                if ~strcmpi(obj.RyzeObj.State,"Flying")
                    executeTurnCW(obj);
                    obj.DroneExecutedTurnCW = true;
                else
                    obj.NavigationCommandIgnored = true;
                end
            catch err
                obj.setErrorObjProperty(err);
                obj.getReconnectInput(err);
            end
        end

        function captureImage(obj)
            % Callback for image capture

            try
                image = obj.executeSnapshot();
                assignin('base',obj.ImageVarName,image);
                obj.ImageCaptured = true;
                obj.DroneExecutedSnapshot = true;
            catch err
                obj.setErrorObjProperty(err);
            end
        end

        function handleReconnectRequest(obj)
            % Callback to handle reconnection request
            obj.cleanup;
            obj.createRyzeObject();
            obj.createCameraObject();
            obj.setupSensorTimer();
            start(obj.SensorDataTimerFcn);
        end

        function getDataFromDrone(obj)
            % Timer callback function to update drone sensor data
            try
                obj.updateDroneEssentialData();
                obj.updateDroneSensorData();
            catch

            end
        end
    end

    % Methods to notify other modules
    methods (Access = private)
        function getReconnectInput(obj,err)
            % Notify reconnection module about drone disconnection

            if strcmpi(err.identifier,'MATLAB:ryze:general:commandFailed')...
                    || strcmpi(err.identifier,'MATLAB:structRefFromNonStruct')
                obj.ShowReconnectInputDialog = true;
            end
        end
    end

    % Methods to update variables depending on other modules
    methods (Access = private)
        function updateImageVarName(obj)
            obj.ImageVarName = obj.Mediator.CurrentImageVarName;
        end

        function updateDefaultNavigationDistance(obj)
            obj.DroneNavigationDistance = obj.Mediator.NavigationDistanceValue;
        end

        function updateDefaultNavigationTurn(obj)
            obj.DroneTurnAngle = obj.Mediator.NavigationTurnAngle;
        end

        function updateDefaultNavigationSpeed(obj)
            obj.DroneNavigationSpeed = obj.Mediator.NavigationSpeedValue;
        end
    end

    % Methods calling Ryze Tello drone APIs
    methods (Access = private)
        function createRyzeObject(obj)
            obj.RyzeObj = ryze(obj.DeviceInfo.SerialNumber);
        end

        function createCameraObject(obj)
            obj.CameraObj = camera(obj.RyzeObj);
        end

        function updateCameraResolution(obj)
            obj.ImageResolution = obj.CameraObj.Resolution;
        end

        function executeTakeOff(obj)
            takeoff(obj.RyzeObj);
        end

        function executeLand(obj)
            land(obj.RyzeObj);
        end

        function executeAbort(obj)
            abort(obj.RyzeObj);
        end

        function executeMoveLeft(obj)
            moveleft(obj.RyzeObj,'Distance',obj.DroneNavigationDistance,...
                'Speed',obj.DroneNavigationSpeed,'WaitUntilDone',false);
        end

        function executeMoveRight(obj)
            moveright(obj.RyzeObj,'Distance',obj.DroneNavigationDistance,...
                'Speed',obj.DroneNavigationSpeed,'WaitUntilDone',false);
        end

        function executeMoveForward(obj)
            moveforward(obj.RyzeObj,'Distance',obj.DroneNavigationDistance,...
                'Speed',obj.DroneNavigationSpeed,'WaitUntilDone',false);
        end

        function executeMoveBack(obj)
            moveback(obj.RyzeObj,'Distance',obj.DroneNavigationDistance,...
                'Speed',obj.DroneNavigationSpeed,'WaitUntilDone',false);
        end

        function executeMoveUp(obj)
            moveup(obj.RyzeObj,'Distance',obj.DroneNavigationDistance,...
                'Speed',obj.DroneNavigationSpeed,'WaitUntilDone',false);
        end

        function executeMoveDown(obj)
            movedown(obj.RyzeObj,'Distance',obj.DroneNavigationDistance,...
                'Speed',obj.DroneNavigationSpeed,'WaitUntilDone',false);
        end

        function executeTurnCCW(obj)
            turn(obj.RyzeObj,obj.DroneTurnAngle);
        end

        function executeTurnCW(obj)
            turn(obj.RyzeObj,-(obj.DroneTurnAngle));
        end

        function startPreview(obj)
            preview(obj.CameraObj, obj.PreviewImageHandle);
        end

        function stopPreview(obj)
            closePreview(obj.CameraObj);
        end

        function frame = executeSnapshot(obj)
            frame = snapshot(obj.CameraObj);
        end

        function updateDroneEssentialData(obj)
            % Function to update battery level and signal strength data

            if ~isempty(obj.RyzeObj)
                obj.BatteryLevel = obj.RyzeObj.BatteryLevel;
                obj.SignalStrength = ryzeio.internal.Utility.findSignalStrength;
                obj.UpdateEssentialData = true;
            end
        end

        function updateDroneSensorData(obj)
            % Function to update battery orientation, speed hieght data

            try
                [obj.Orientation,~] = readOrientation(obj.RyzeObj);
                [obj.Speed,~] = readSpeed(obj.RyzeObj);
                [obj.Height,~] = readHeight(obj.RyzeObj);
                obj.UpdateSensorData = true;
                obj.ReceivedSensorData = true;
            catch err
                % This is a timer callback should show the error only once
                if ~obj.SensorDataErrorGiven
                    obj.ReceivedSensorData = false;
                    obj.setErrorObjProperty(err);
                    obj.getReconnectInput(err);
                    obj.SensorDataErrorGiven = true;
                end
            end
        end
    end

    % Private methods to setup timer and do cleanups
    methods(Access=private)
        function setupSensorTimer(obj)
            obj.SensorDataTimerFcn = timer('TimerFcn', ...
                @(src, event)obj.getDataFromDrone(), ...
                'Period',obj.SensorDataTimerPeriod, ...
                'ExecutionMode','fixedRate','TasksToExecute',2000,...
                'BusyMode','drop');
        end

        function cleanup(obj)
            obj.cleanupSensorTimer();
            obj.cleanupRyzeObj();
            obj.cleanupCameraObj();
        end

        function cleanupSensorTimer(obj)
            stop(obj.SensorDataTimerFcn);
            delete(obj.SensorDataTimerFcn);
        end

        function cleanupRyzeObj(obj)
            delete(obj.RyzeObj)
            obj.RyzeObj = [];
        end

        function cleanupCameraObj(obj)
            obj.CameraObj = [];
        end
    end

end