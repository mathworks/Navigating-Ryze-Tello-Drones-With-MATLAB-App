classdef PreFlightCheckManager < telloapplet.HelperClass
    % PREFLIGHTCHECKMANAGER - Class that manages drone Pre-Flight Check
    % workflow

    % Copyright 2022 The MathWorks, Inc.
    properties(Access=private)
        % Mediator handle
        Mediator
        AppMessages

        % Pre Flight Check Dialog structure
        ParentFigurePosition
        ParentFigure
        ParentGrid
        FlightCheckGrid
        InnerFlightCheckGrid
        ButtonGrid
        InnerButtonGrid
        DroneVisualIcon
        WarningLabel

        % Navigation check
        NavigationCheckLabel
        NavigationCheckIcon
        % Sensor Data Check
        SensorDataCheckLabel
        SensorDataCheckIcon
        % Camera Feed check
        CameraFeedCheckLabel
        CameraFeedCheckIcon

        % OK/Continue reused dialog button
        DialogActionButton
        DialogActionButtonListener
        DialogActionButtonState

        % Icon paths
        DroneIconPath

        % Text to show after pre Flight Check
        preFlightCheckCompletionLabel
    end

    properties(Constant, Access=private)
        % Grid dimensions
        ParentGridRowHeight = {'0.3x','1x','0.4x'}
        ParentGridColumnWidth = {'1x'}
        ParentGridPadding = [ 5 5 5 5]
        FlightCheckGridRowHeight = {'1x'}
        FlightCheckGridColumnWidth = {'0.5x','1.5x'}
        InnerFlightCheckGridRowHeight = {'1x','1x','1x'}
        InnerFlightCheckGridColumnWidth = {'0.25x','1x'}
        ButtonGridRowHeight = {'1x','0.7x'}
        ButtonGridColumnWidth = {'1x'}
        InnerButtonGridRowHeight = {'1x'}
        InnerButtonGridColumnWidth = {'1x','0.25x'}
        ButtonGridPadding = [0 0 0 0]

        % Pre Flight Check dialog position
        DialogLeftPosition = 500
        DialogBottomPosition = 300

        % Icon files
        TelloVisualIcon = 'DroneVisualTypeWhite.svg'
        TelloEDUVisualIcon = 'DroneVisualTypeBlack.svg'
        CheckInProgressIcon = 'PreFlightCheckInProgress.svg'
        CheckSuccessIcon = 'Success_16.svg'
        CheckFailureIcon = 'Error_16.svg'

        % Dialog action button pre-defined states
        DialogActionButtonInitialState = "PreFlightCheckNotStarted"
        DialogActionButtonFinalState = "PreFlightCheckCompleted"
    end

    properties(SetObservable)
        % Request Ryze Tello Manager to execute drone functionalities
        PreFlightCheckTakeOff
        PreFlightCheckLand
        PreFlightCheckSnapshot

        % Notify Pre Flight Check process completion
        PreFlightCheckComplete

        % Notify Pre Flight Check success/failure
        preFlightCheckSuccessful
    end

    methods
        % Constructor
        function obj = PreFlightCheckManager(mediator, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.Mediator = mediator;
            obj.AppMessages = appMessages;
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserRequestedPreFlightCheck', @(src, event)obj.handlePreFlightCheckRequest());
        end
    end

    % Callback methods
    methods(Access = private)
        function handlePreFlightCheckRequest(obj)
            % Function to show Pre Flight Check dialog

            obj.createDialog();
            obj.populateDialog();
        end

        function handleDialogActionButtonPushed(obj)
            % Function to handle Pre Flight Check dialog button actions

            if strcmpi(obj.DialogActionButtonState, obj.DialogActionButtonInitialState)
                % If it is initial state Continue button is pushed,
                % initiate checks

                obj.DialogActionButton.Text = obj.AppMessages.preFlightCheckCompletionButtonText;
                obj.DialogActionButton.Enable = false;

                obj.preFlightCheck();

                obj.DialogActionButton.Enable = true;
                obj.DialogActionButtonState = obj.DialogActionButtonFinalState;

                if obj.preFlightCheckSuccessful
                    preFlightCheckLabel = obj.AppMessages.preFlightCheckSuccessLabel;
                else
                    preFlightCheckLabel = obj.AppMessages.preFlightCheckFailureLabel;
                end
                obj.preFlightCheckCompletionLabel = uilabel(obj.ButtonGrid, ...
                    "Text",preFlightCheckLabel, ...
                    "HorizontalAlignment",'left');
                obj.preFlightCheckCompletionLabel.Layout.Row = 1;
                obj.preFlightCheckCompletionLabel.Layout.Column = 1;
            elseif strcmpi(obj.DialogActionButtonState, obj.DialogActionButtonFinalState)
                % If it is final state OK button is pushed, close dialog
                % and notify completion of Pre Flight Check process
                obj.closeDialog();
                obj.PreFlightCheckComplete = true;
            end
        end
    end

    methods(Access = private)
        function createDialog(obj)
            % Create modal tab for PreFlight Check
            % Determine screen position for the modal dialog
            screenSize = get(groot,'ScreenSize');
            left = (screenSize(3) - obj.DialogLeftPosition)/2;
            bottom = (screenSize(4) - obj.DialogBottomPosition)/2;

            obj.ParentFigurePosition = [left bottom obj.DialogLeftPosition obj.DialogBottomPosition];

            % Create modal figure
            obj.ParentFigure = uifigure("Position",obj.ParentFigurePosition,...
                "Name",obj.AppMessages.preFlightCheckDialogTitle);
            obj.ParentFigure.WindowStyle = "modal";
            obj.ParentFigure.Resize = "off";

            obj.ParentGrid = uigridlayout(obj.ParentFigure,...
                "RowHeight",obj.ParentGridRowHeight,"ColumnWidth", ...
                obj.ParentGridColumnWidth, ...
                "Padding", obj.ParentGridPadding);
        end

        function populateDialog(obj)
            % Function to populate the PreFlight Check dialog

            % Get icon path
            resourcesLocation = telloapplet.internal.Utility.getResourcesLocation();
            obj.DroneIconPath = fullfile(resourcesLocation, 'workingarea');

            obj.populateTextLabel();
            obj.populateFlightCheckField();
            drawnow limitrate
            obj.populateButtons();

            obj.DialogActionButtonState = obj.DialogActionButtonInitialState;
            obj.addWidgetEventListeners();
        end

        function populateTextLabel(obj)
            % Function to populate the PreFlight Check text label

            obj.WarningLabel = uilabel(obj.ParentGrid,...
                "Text",obj.AppMessages.preFlightCheckWarningText);
            obj.WarningLabel.Layout.Row = 1;
            obj.WarningLabel.Layout.Column = 1;
        end

        function populateFlightCheckField(obj)
            % Function to populate navigation, sensor data and camera field
            % check fields

            obj.FlightCheckGrid = uigridlayout(obj.ParentGrid,...
                "RowHeight",obj.FlightCheckGridRowHeight, ...
                "ColumnWidth",obj.FlightCheckGridColumnWidth);
            obj.FlightCheckGrid.Layout.Row = 2;
            obj.FlightCheckGrid.Layout.Column = 1;

            % Differentiate between icons based on the drone type
            if strcmpi(obj.Mediator.DroneModelName,"Tello")
                iconPath = fullfile(obj.DroneIconPath, obj.TelloVisualIcon);
            elseif strcmpi(obj.Mediator.DroneModelName,"TelloEDU")
                iconPath = fullfile(obj.DroneIconPath, obj.TelloEDUVisualIcon);
            end
            obj.DroneVisualIcon = uiimage(obj.FlightCheckGrid, ...
                "ImageSource",iconPath,"ScaleMethod",'scaledown');
            obj.DroneVisualIcon.Layout.Row = 1;
            obj.DroneVisualIcon.Layout.Column = 1;

            obj.InnerFlightCheckGrid = uigridlayout(obj.FlightCheckGrid,...
                "RowHeight",obj.InnerFlightCheckGridRowHeight, ...
                "ColumnWidth",obj.InnerFlightCheckGridColumnWidth);
            obj.InnerFlightCheckGrid.Layout.Row = 1;
            obj.InnerFlightCheckGrid.Layout.Column = 2;

            % Navigation check
            obj.NavigationCheckLabel = uilabel(obj.InnerFlightCheckGrid, ...
                "Text",obj.AppMessages.preNavigationCheckText, ...
                "HorizontalAlignment",'left');
            obj.NavigationCheckLabel.Layout.Row = 1;
            obj.NavigationCheckLabel.Layout.Column = 2;

            obj.NavigationCheckIcon = uiimage(obj.InnerFlightCheckGrid, ...
                "ImageSource",fullfile(obj.DroneIconPath,obj.CheckInProgressIcon), ...
                "HorizontalAlignment",'right',"ScaleMethod",'scaledown');
            obj.NavigationCheckIcon.Layout.Row = 1;
            obj.NavigationCheckIcon.Layout.Column = 1;

            % Sensor Data check
            obj.SensorDataCheckLabel = uilabel(obj.InnerFlightCheckGrid, ...
                "Text",obj.AppMessages.preSensorDataCheckText, ...
                "HorizontalAlignment",'left');
            obj.SensorDataCheckLabel.Layout.Row = 2;
            obj.SensorDataCheckLabel.Layout.Column = 2;

            obj.SensorDataCheckIcon = uiimage(obj.InnerFlightCheckGrid, ...
                "ImageSource",fullfile(obj.DroneIconPath,obj.CheckInProgressIcon), ...
                "HorizontalAlignment",'right',"ScaleMethod",'scaledown');
            obj.SensorDataCheckIcon.Layout.Row = 2;
            obj.SensorDataCheckIcon.Layout.Column = 1;

            % Camera Feed check
            obj.CameraFeedCheckLabel = uilabel(obj.InnerFlightCheckGrid, ...
                "Text",obj.AppMessages.preCameraFeedCheckText, ...
                "HorizontalAlignment",'left');
            obj.CameraFeedCheckLabel.Layout.Row = 3;
            obj.CameraFeedCheckLabel.Layout.Column = 2;

            obj.CameraFeedCheckIcon = uiimage(obj.InnerFlightCheckGrid, ...
                "ImageSource",fullfile(obj.DroneIconPath,obj.CheckInProgressIcon), ...
                "HorizontalAlignment",'right',"ScaleMethod",'scaledown');
            obj.CameraFeedCheckIcon.Layout.Row = 3;
            obj.CameraFeedCheckIcon.Layout.Column = 1;

        end

        function populateButtons(obj)
            % Function to populate the PreFlight Check dialog action button

            obj.ButtonGrid = uigridlayout(obj.ParentGrid,...
                "RowHeight",obj.ButtonGridRowHeight, ...
                "ColumnWidth",obj.ButtonGridColumnWidth, ...
                "Padding",obj.ButtonGridPadding);
            obj.ButtonGrid.Layout.Row = 3;
            obj.ButtonGrid.Layout.Column = 1;

            obj.InnerButtonGrid = uigridlayout(obj.ButtonGrid,...
                "RowHeight",obj.InnerButtonGridRowHeight, ...
                "ColumnWidth",obj.InnerButtonGridColumnWidth, ...
                "Padding",obj.ButtonGridPadding);
            obj.InnerButtonGrid.Layout.Row = 2;
            obj.InnerButtonGrid.Layout.Column = 1;

            obj.DialogActionButton = uibutton(obj.InnerButtonGrid, ...
                "Text",obj.AppMessages.continuePreFlightCheckButtonText);
            obj.DialogActionButton.Layout.Row = 1;
            obj.DialogActionButton.Layout.Column = 2;
        end

        function closeDialog(obj)
            delete(obj.ParentFigure);
        end

        function addWidgetEventListeners(obj)
            % All event listeners
            obj.DialogActionButtonListener = obj.DialogActionButton.listener('ButtonPushed',@(src,event)obj.handleDialogActionButtonPushed());
        end
    end
    methods (Access=private)
        function preFlightCheck(obj)
            % Function to do PreFlight Check

            navigationCheckSuccess = obj.checkDroneNavigation();

            sensorDataCheckSuccess = obj.checkDroneSensorData();

            cameraFeedCheckSuccess = obj.checkDroneCameraFeed();

            % Update PreFlight Check success/failure status
            if navigationCheckSuccess && sensorDataCheckSuccess &&...
                    cameraFeedCheckSuccess
                obj.preFlightCheckSuccessful = true;
            else
                obj.preFlightCheckSuccessful = false;
            end
        end

        function checkSuccess = checkDroneNavigation(obj)
            % Function to Check drone navigation as part of PreFlight Check

            obj.PreFlightCheckTakeOff = true;
            obj.PreFlightCheckLand = true;
            if obj.Mediator.PreFlightCheckTakeOffSuccessful && ...
                    obj.Mediator.PreFlightCheckLandSuccessful
                obj.NavigationCheckIcon.ImageSource = fullfile(obj.DroneIconPath,obj.CheckSuccessIcon);
                obj.NavigationCheckLabel.Text = obj.AppMessages.successfulNavigationCheckText;
                obj.NavigationCheckIcon.ScaleMethod = 'scaledown';
                checkSuccess = true;
            else
                obj.NavigationCheckIcon.ImageSource = fullfile(obj.DroneIconPath,obj.CheckFailureIcon);
                obj.NavigationCheckLabel.Text = obj.AppMessages.failedNavigationCheckText;
                obj.NavigationCheckIcon.ScaleMethod = 'scaledown';
                checkSuccess = false;
            end
        end

        function checkSuccess = checkDroneSensorData(obj)
            % Function to Check sensor data as part of PreFlight Check

            if obj.Mediator.ReceivedSensorData
                obj.SensorDataCheckIcon.ImageSource = fullfile(obj.DroneIconPath,obj.CheckSuccessIcon);
                obj.SensorDataCheckLabel.Text = obj.AppMessages.successfulSensorDataCheckText;
                obj.SensorDataCheckIcon.ScaleMethod = 'scaledown';
                checkSuccess = true;
            else
                obj.SensorDataCheckIcon.ImageSource = fullfile(obj.DroneIconPath,obj.CheckFailureIcon);
                obj.SensorDataCheckLabel.Text = obj.AppMessages.failedSensorDataCheckText;
                obj.SensorDataCheckIcon.ScaleMethod = 'scaledown';
                checkSuccess = false;
            end
        end

        function checkSuccess = checkDroneCameraFeed(obj)
            % Function to Check camera feed as part of PreFlight Check

            obj.PreFlightCheckSnapshot = true;
            if obj.Mediator.ReceivedImageData
                obj.CameraFeedCheckIcon.ImageSource = fullfile(obj.DroneIconPath,obj.CheckSuccessIcon);
                obj.CameraFeedCheckLabel.Text = obj.AppMessages.successfulCameraFeedCheckText;
                obj.CameraFeedCheckIcon.ScaleMethod = 'scaledown';
                checkSuccess = true;
            else
                obj.CameraFeedCheckIcon.ImageSource = fullfile(obj.DroneIconPath,obj.CheckFailureIcon);
                obj.CameraFeedCheckLabel.Text = obj.AppMessages.failedCameraFeedCheckText;
                obj.CameraFeedCheckIcon.ScaleMethod = 'scaledown';
                checkSuccess = false;
            end
        end
    end

end