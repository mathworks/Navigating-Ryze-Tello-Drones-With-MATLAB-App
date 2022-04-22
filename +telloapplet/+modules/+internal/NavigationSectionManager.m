classdef NavigationSectionManager < telloapplet.HelperClass
    % NAVIGATIONSECTIONMANAGER - Class that places widgets in the
    % navigation section of the Applet space and controls navigation button
    % actions and updates drone battery level and signal strength data

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % App message texts
        AppMessages
        % Parent Grid
        ParentGrid

        % Navigation section structure
        ParentGridWithoutControl
        ParentNavigationSectionPanel
        NavigationPanelGrid
        BasicNavigationInnerGrid
        BasicNavigationIconBase

        % Store navigation section position for control enabled and
        % disabled states
        ShowControlsPosition
        HideControlsPosition

        % Navigation buttons and listeners
        MoveLeftButton
        MoveForwardButton
        MoveRightButton
        MoveBackButton
        MoveLeftButtonListener
        MoveForwardButtonListener
        MoveRightButtonListener
        MoveBackButtonListener

        % Battery and Signal Strength information grid
        EssentialDataInnerGrid
        % Battery level storing variable, icon, UI labels
        BatteryValueLabel
        BatteryLevelLabel
        BatteryValue = '0%'
        BatteryLevelIcon
        % Signal strength storing variable, icon, UI labels
        SignalStrengthIcon
        SignalStrengthValueLabel
        SignalStrengthLabel
        SignalStrengthValue = '0%'

        % Emergency land button and listener
        EmergencyLandButton
        EmergencyLandButtonListener

        % Emergency land confirmation dialog
        EmergencyLandDialogPosition
        EmergencyLandDialogFigure
        EmergencyLandDialogParentGrid
        EmergencyLandDialogInnerGrid
        EmergencyLandDialogIcon
        EmergencyLandDialogTextTitle
        EmergencyLandDialogTextLabel
        ButtonGrid
        ContinueEmergencyLandButton
        ContinueEmergencyLandButtonListener
        CancelButton
        CancelButtonListener

        % Right side Navigation grid for up/down navigation and turn
        AdvancedNavigationInnerGrid
        % Up/down navigation and turn buttons and listeners
        TurnCCWButton
        MoveUpButton
        TurnCWButton
        MoveDownButton
        TurnCCWButtonListener
        MoveUpButtonListener
        TurnCWButtonListener
        MoveDownButtonListener

        % Icon paths
        WorkingAreaIconPath
        NavigationControlIconPath
        BatteryLevelIconPath
        SignalStrengthIconPath

        % Grids for battery level, signal strength and emergency land
        % button
        BatteryLevelInnerGrid
        SignalStrengthInnerGrid
        EmergencyLandInnerGrid

        % Drone state
        HasStateLanded = true
        % Control button visibility state
        HasControlsHidden = false

        % Low battery related parameters
        WarningDlgPosition
        WarningDlg
        LowBatteryWarningGiven = false
        ReconnectOptionGiven = false
        BatteryLowNotified = false
    end

    properties(Access=private)
        % Sensor panel layout parameters
        ParentGridRowHeight = {'1x'}
        ParentGridColumnWidth = {'1x','0.7x','1x'}
        ParentGridRowSpacing = 0
        ParentGridColumnSpacing = 5

        % Left side navigation button cluster related dimensions
        BasicNavigationRowHeight = {'0.1x','0.75x','0.75x','0.75x','0.1x'}
        BasicNavigationColumnWidth = {'0.5x','0.75x','0.75x','0.75x'}
        BasicNavigationRowSpacing = 0
        BasicNavigationColumnSpacing = 0

        % Left side navigation button cluster icons
        MoveLeftButtonIcon = "Left.png"
        MoveForwardButtonIcon = "Forward.png"
        MoveRightButtonIcon = "Right.png"
        MoveBackButtonIcon = "Backward.png"

        % Middle cluster of battery level, signal strength and emergency
        % land button related dimensions
        EssentialDataGridRowHeight = {'0.4x','0.6x','1x','1.2x','0.3x','0.75x','0.4x'}
        EssentialDataGridColumnWidth = {'0.25x','1.25x','1.25x','0.25x'}
        EssentialDataGridRowSpacing = 0
        EssentialDataGridColumnSpacing = 5

        % Icons for different battery levels
        BatteryCriticalIcon = "BatteryCritical.svg"
        BatteryLowIcon = "BatteryLow.svg"
        BatteryLevel40Icon = "Battery40.svg"
        BatteryLevel60Icon = "Battery60.svg"
        BatteryLevel80Icon = "Battery80.svg"
        BatteryLevel100Icon = "Battery100.svg"
        % Icons for different signal strengths
        NoSignalIcon = "NoSignal.svg"
        SignalLevel25Icon = "Signal25.svg"
        SignalLevel50Icon = "Signal50.svg"
        SignalLevel75Icon = "Signal75.svg"
        SignalLevel100Icon = "Signal100.svg"
        % Battery and Signal Strength Font Sizes
        ValueFontSize = 24;
        LabelFontSize = 14;
        % Icon for Emergency land button
        EmergencyLandButtonIcon = "Error_16.svg"
        % Emergency land button related colors
        EmergencyButtonBackground = [0.97,0.88,0.88]
        EmergencyButtonFontColor = [0.73,0.23,0.09]
        % Battery level, signal strength and emergency land inner grid
        % dimensions
        BatteryLevelInnerGridRowHeight = {'1x'}
        BatteryLevelInnerGridColumnWidth = {'1x','0.55x','1x'}
        SignalStrengthInnerGridRowHeight = {'1x'}
        SignalStrengthInnerGridColumnWidth = {'0.7x','1x','1x'}
        EmergencyLandInnerGridRowHeight = {'0.5x','1x','0.5x'}
        EmergencyLandInnerGridColumnWidth = {'0.5x','1x','0.5x'}
        EmergencyLandDialogParentGridRowHeight = {'1x','0.3x'}
        EmergencyLandDialogParentGridColumnWidth = {'1x'}
        EmergencyLandDialogInnerGridRowHeight = {'0.3x','1x'}
        EmergencyLandDialogInnerGridColumnWidth = {'0.3x','1x'}
        ButtonGridRowHeight = {'0.3x'}
        ButtonGridColumnWidth = {'1x','0.5x','0.3x'}

        % Right side navigation button cluster related dimensions
        AdvancedNavigationRowHeight = {'0.1x','0.75x','0.75x','0.75x','0.1x'}
        AdvancedNavigationColumnWidth = {'0.75x','0.75x','0.75x','0.5x'}
        AdvancedNavigationRowSpacing = 0
        AdvancedNavigationColumnSpacing = 0
        % Right side navigation button cluster related icons
        TurnCCWButtonIcon = "Turn_CCW.png"
        MoveUpButtonIcon = "Up.png"
        TurnCWButtonIcon = "Turn_CW.png"
        MoveDownButtonIcon = "Down.png"

        NavigationButtonBacground = [0.3882 0.3843 0.3843]
        NavigationButtonFontColor = 'white'
        NavigationGridBackground = 'white'

        % Low battery warning dialog position
        DialogLeftPosition = 500
        DialogBottomPosition = 300

        % Emergency land confirmation dialog position
        EmergencyLandDialogLeftPosition = 450
        EmergencyLandDialogBottomPosition = 150
    end

    properties (SetObservable)
        % Notify Ryze Tello manager to navigate drone according to button
        % pushed
        UserRequestedMoveLeft
        UserRequestedMoveForward
        UserRequestedMoveRight
        UserRequestedMoveBack
        UserRequestedMoveUp
        UserRequestedMoveDown
        UserRequestedTurnCCW
        UserRequestedTurnCW
        UserRequestedEmergencyLand
        UserRequestedLand

        % Update sensor data after controls hide or un-hide
        UpdateSensorData

        % Triggers reconnection when signal strength drops below 10%
        ShowReconnectInputDialog

        % Notify low battery to update toolstrip and generate code
        BatteryLow
    end

    methods
        % Constructor
        function obj = NavigationSectionManager(mediator, parentGrid,...
                showControlsPosition, hideControlsPosition, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.ParentGrid = parentGrid;
            obj.Mediator = mediator;
            obj.ShowControlsPosition = showControlsPosition;
            obj.HideControlsPosition = hideControlsPosition;
            obj.AppMessages = appMessages;

            % Create pin table area table and position it in the grid
            % Create pin table panel
            obj.ParentNavigationSectionPanel = uipanel(obj.ParentGrid);
            obj.ParentNavigationSectionPanel.Layout.Row = obj.ShowControlsPosition{1};
            obj.ParentNavigationSectionPanel.Layout.Column = obj.ShowControlsPosition{2};

            populateNavigationSectionWithControls(obj);
            drawnow limitrate

            addWidgetEventListeners(obj);
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserClickedShowControls', @(src, event)obj.handleShowControls());
            obj.subscribe('UserClickedHideControls', @(src, event)obj.handleHideControls());
            obj.subscribe('UpdateEssentialData', @(src, event)obj.handleUpdateEssentialData());
            obj.subscribe('UserRequestedNavigate', @(src, event)obj.handleNavigationInProgress());
            obj.subscribe('DroneExecutedTakeOff', @(src, event)obj.handleTakeOff());
            obj.subscribe('DroneExecutedLand', @(src, event)obj.handleLand());
            obj.subscribe('DroneExecutedAbort', @(src, event)obj.handleLand());

            obj.subscribe('DroneExecutedMoveLeft', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedMoveRight', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedMoveForward', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedMoveBack', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedMoveUp', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedMoveDown', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedTurnCCW', @(src, event)obj.handleNavigationCompleted());
            obj.subscribe('DroneExecutedTurnCW', @(src, event)obj.handleNavigationCompleted());

            obj.subscribe('NavigationCommandIgnored', @(src, event)obj.handleNavigationCompleted());

            obj.subscribe('DroneStateLanded', @(src, event)obj.updateDronelandedState());
        end

    end

    methods (Access=private)
        function populateNavigationSectionWithControls(obj)
            % Function to populate navigation buttons, battery level,
            % signal strength and emergency land button

            obj.NavigationPanelGrid = uigridlayout(obj.ParentNavigationSectionPanel,...
                'RowHeight',obj.ParentGridRowHeight,...
                'ColumnWidth',obj.ParentGridColumnWidth,...
                'RowSpacing',obj.ParentGridRowSpacing,...
                'ColumnSpacing',obj.ParentGridColumnSpacing,...
                'BackgroundColor','white',...
                "Padding",[0 0 0 0]);

            resourcesLocation = telloapplet.internal.Utility.getResourcesLocation();
            obj.WorkingAreaIconPath = fullfile(resourcesLocation, 'workingarea');
            obj.NavigationControlIconPath = fullfile(obj.WorkingAreaIconPath,'NavigationControls');
            obj.BatteryLevelIconPath = fullfile(obj.WorkingAreaIconPath,'BatteryLevel');
            obj.SignalStrengthIconPath = fullfile(obj.WorkingAreaIconPath,'SignalStrength');

            createLeftNavigationControlPanel(obj);
            drawnow limitrate
            createMiddleDataPanel(obj);
            drawnow limitrate
            createRightNavigationControlPanel(obj);
        end

        function createLeftNavigationControlPanel(obj)
            % Function to populate left, right, forward and back navigation
            % buttons

            % Create inner grid to lay out basic navigation buttons
            obj.BasicNavigationInnerGrid = uigridlayout(obj.NavigationPanelGrid,...
                'RowHeight',obj.BasicNavigationRowHeight,...
                'ColumnWidth',obj.BasicNavigationColumnWidth,...
                'RowSpacing',obj.BasicNavigationRowSpacing,...
                'ColumnSpacing',obj.BasicNavigationColumnSpacing,...
                'BackgroundColor',obj.NavigationGridBackground,...
                "Padding",[0 0 0 0]);
            obj.BasicNavigationInnerGrid.Layout.Row = 1;
            obj.BasicNavigationInnerGrid.Layout.Column = 1;

            % Create move left button
            obj.MoveLeftButton = uibutton(obj.BasicNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.MoveLeftButtonIcon),...
                "IconAlignment",'left',...
                "Text",obj.AppMessages.moveLeftButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.MoveLeftButton.Layout.Row = 3;
            obj.MoveLeftButton.Layout.Column = 2;
            obj.MoveLeftButton.Enable = false;

            % Create move forward button
            obj.MoveForwardButton = uibutton(obj.BasicNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.MoveForwardButtonIcon),...
                "IconAlignment",'top',...
                "Text",obj.AppMessages.moveForwardButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.MoveForwardButton.Layout.Row = 2;
            obj.MoveForwardButton.Layout.Column = 3;
            obj.MoveForwardButton.Enable = false;


            % Create move right button
            obj.MoveRightButton = uibutton(obj.BasicNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.MoveRightButtonIcon),...
                "IconAlignment",'right',...
                "Text",obj.AppMessages.moveRightButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.MoveRightButton.Layout.Row = 3;
            obj.MoveRightButton.Layout.Column = 4;
            obj.MoveRightButton.Enable = false;


            % Create move backward button
            obj.MoveBackButton = uibutton(obj.BasicNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.MoveBackButtonIcon),...
                "IconAlignment",'bottom',...
                "Text",obj.AppMessages.moveBackwardButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.MoveBackButton.Layout.Row = 4;
            obj.MoveBackButton.Layout.Column = 3;
            obj.MoveBackButton.Enable = false;
        end

        function createMiddleDataPanel(obj)
            % Function to populate battery level, signal strength and
            % emergency land button

            obj.EssentialDataInnerGrid = uigridlayout(obj.NavigationPanelGrid,...
                'RowHeight',obj.EssentialDataGridRowHeight,...
                'ColumnWidth',obj.EssentialDataGridColumnWidth,...
                'RowSpacing',obj.EssentialDataGridRowSpacing,...
                'ColumnSpacing',obj.EssentialDataGridColumnSpacing,...
                'BackgroundColor',obj.NavigationGridBackground);
            obj.EssentialDataInnerGrid.Layout.Row = 1;
            obj.EssentialDataInnerGrid.Layout.Column = 2;

            % Create battery level icon
            obj.BatteryLevelIcon = uiimage(obj.EssentialDataInnerGrid,...
                "ImageSource",fullfile(obj.BatteryLevelIconPath,obj.BatteryLowIcon),...
                "ScaleMethod",'fit',"HorizontalAlignment",'center');
            obj.BatteryLevelIcon.Layout.Row = 2;
            obj.BatteryLevelIcon.Layout.Column = 2;

            % Create label for battery level
            obj.BatteryValueLabel = uilabel(obj.EssentialDataInnerGrid,...
                "Text",obj.BatteryValue,...
                "HorizontalAlignment",'center',...
                "FontSize",obj.ValueFontSize,"FontWeight",'bold');
            obj.BatteryValueLabel.Layout.Row = 3;
            obj.BatteryValueLabel.Layout.Column = 2;

            obj.BatteryLevelLabel = uilabel(obj.EssentialDataInnerGrid,...
                "Text",obj.AppMessages.batteryLevelLabel,...
                "HorizontalAlignment",'center',"VerticalAlignment",'top',...
                "FontSize",obj.LabelFontSize);
            obj.BatteryLevelLabel.Layout.Row = 4;
            obj.BatteryLevelLabel.Layout.Column = 2;

            % Create signal strength icon
            obj.SignalStrengthIcon = uiimage(obj.EssentialDataInnerGrid,...
                "ImageSource",fullfile(obj.SignalStrengthIconPath,obj.NoSignalIcon),...
                "ScaleMethod",'fit',"HorizontalAlignment",'center');
            obj.SignalStrengthIcon.Layout.Row = 2;
            obj.SignalStrengthIcon.Layout.Column = 3;

            % Create labels for signal strength
            obj.SignalStrengthValueLabel = uilabel(obj.EssentialDataInnerGrid,...
                "Text",obj.SignalStrengthValue,...
                "HorizontalAlignment",'center',...
                "FontSize",obj.ValueFontSize,"FontWeight",'bold');
            obj.SignalStrengthValueLabel.Layout.Row = 3;
            obj.SignalStrengthValueLabel.Layout.Column = 3;

            obj.SignalStrengthLabel = uilabel(obj.EssentialDataInnerGrid,...
                "Text",obj.AppMessages.signalStrengthLabel,...
                "HorizontalAlignment",'center',"VerticalAlignment",'top',...
                "FontSize",obj.LabelFontSize);
            obj.SignalStrengthLabel.Layout.Row = 4;
            obj.SignalStrengthLabel.Layout.Column = 3;

            % Create Emergency Land Button
            obj.EmergencyLandButton = uibutton(obj.EssentialDataInnerGrid,...
                "Icon",fullfile(obj.WorkingAreaIconPath,obj.EmergencyLandButtonIcon),...
                "IconAlignment",'left',"BackgroundColor",obj.EmergencyButtonBackground,...
                "Text",obj.AppMessages.emergencyLandButtonText,...
                "FontWeight",'bold',"FontColor",obj.EmergencyButtonFontColor);
            obj.EmergencyLandButton.Layout.Row = 6;
            obj.EmergencyLandButton.Layout.Column = [1 4];
            obj.EmergencyLandButton.Enable = false;
        end

        function createRightNavigationControlPanel(obj)
            % Function to populate up, down, turn CW and CCW navigation
            % buttons

            obj.AdvancedNavigationInnerGrid = uigridlayout(obj.NavigationPanelGrid,...
                'RowHeight',obj.AdvancedNavigationRowHeight,...
                'ColumnWidth',obj.AdvancedNavigationColumnWidth,...
                'RowSpacing',obj.AdvancedNavigationRowSpacing,...
                'ColumnSpacing',obj.AdvancedNavigationColumnSpacing,...
                'BackgroundColor',obj.NavigationGridBackground,...
                "Padding",[0 0 0 0]);
            obj.AdvancedNavigationInnerGrid.Layout.Row = 1;
            obj.AdvancedNavigationInnerGrid.Layout.Column = 3;

            % Create turn ccw button
            obj.TurnCCWButton = uibutton(obj.AdvancedNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.TurnCCWButtonIcon),...
                "IconAlignment",'left',...
                "Text",obj.AppMessages.turnCCWButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.TurnCCWButton.Layout.Row = 3;
            obj.TurnCCWButton.Layout.Column = 1;
            obj.TurnCCWButton.Enable = false;

            % Create move up button
            obj.MoveUpButton = uibutton(obj.AdvancedNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.MoveUpButtonIcon),...
                "IconAlignment",'top',...
                "Text",obj.AppMessages.moveUpButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.MoveUpButton.Layout.Row = 2;
            obj.MoveUpButton.Layout.Column = 2;
            obj.MoveUpButton.Enable = false;

            % Create turn cw button
            obj.TurnCWButton = uibutton(obj.AdvancedNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.TurnCWButtonIcon),...
                "IconAlignment",'right',...
                "Text",obj.AppMessages.turnCWButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.TurnCWButton.Layout.Row = 3;
            obj.TurnCWButton.Layout.Column = 3;
            obj.TurnCWButton.Enable = false;

            % Create move down button
            obj.MoveDownButton = uibutton(obj.AdvancedNavigationInnerGrid,...
                "BackgroundColor",obj.NavigationButtonBacground,...
                "Icon",fullfile(obj.NavigationControlIconPath,obj.MoveDownButtonIcon),...
                "IconAlignment",'bottom',...
                "Text",obj.AppMessages.moveDownButtonText,...
                "FontColor",obj.NavigationButtonFontColor);
            obj.MoveDownButton.Layout.Row = 4;
            obj.MoveDownButton.Layout.Column = 2;
            obj.MoveDownButton.Enable = false;
        end
    end

    methods(Access=private)
        function populateNavigationSectionWithoutControls(obj)
            obj.ParentGridWithoutControl = uigridlayout(obj.ParentNavigationSectionPanel,...
                'RowHeight',obj.ParentGridRowHeight,...
                'ColumnWidth',obj.ParentGridColumnWidth,...
                'RowSpacing',obj.ParentGridRowSpacing,...
                'ColumnSpacing',obj.ParentGridColumnSpacing,...
                'BackgroundColor','white',...
                "Padding",[0 0 0 0]);

            obj.BatteryLevelInnerGrid = uigridlayout(obj.ParentGridWithoutControl,...
                'RowHeight',obj.BatteryLevelInnerGridRowHeight,...
                'ColumnWidth',obj.BatteryLevelInnerGridColumnWidth,...
                'RowSpacing',0,...
                'ColumnSpacing',5,...
                'BackgroundColor',obj.NavigationGridBackground);
            obj.BatteryLevelInnerGrid.Layout.Row = 1;
            obj.BatteryLevelInnerGrid.Layout.Column = 1;

            % Create battery level icon
            obj.BatteryLevelIcon = uiimage(obj.BatteryLevelInnerGrid,...
                "ImageSource",fullfile(obj.BatteryLevelIconPath,obj.BatteryLowIcon),...
                "ScaleMethod",'scaledown',"HorizontalAlignment",'right');
            obj.BatteryLevelIcon.Layout.Row = 1;
            obj.BatteryLevelIcon.Layout.Column = 1;

            % Create label for battery level
            obj.BatteryValueLabel = uilabel(obj.BatteryLevelInnerGrid,...
                "Text",obj.BatteryValue,...
                "HorizontalAlignment",'center',...
                "FontSize",obj.ValueFontSize,"FontWeight",'bold');
            obj.BatteryValueLabel.Layout.Row = 1;
            obj.BatteryValueLabel.Layout.Column = 2;

            obj.BatteryLevelLabel = uilabel(obj.BatteryLevelInnerGrid,...
                "Text",obj.AppMessages.batteryLevelLabel,...
                "HorizontalAlignment",'left',"VerticalAlignment",'center',...
                "FontSize",obj.LabelFontSize);
            obj.BatteryLevelLabel.Layout.Row = 1;
            obj.BatteryLevelLabel.Layout.Column = 3;


            % Create inner grid for signal strength
            obj.SignalStrengthInnerGrid = uigridlayout(obj.ParentGridWithoutControl,...
                'RowHeight',obj.SignalStrengthInnerGridRowHeight,...
                'ColumnWidth',obj.SignalStrengthInnerGridColumnWidth,...
                'RowSpacing',0,...
                'ColumnSpacing',5,...
                'BackgroundColor',obj.NavigationGridBackground);
            obj.SignalStrengthInnerGrid.Layout.Row = 1;
            obj.SignalStrengthInnerGrid.Layout.Column = 2;

            % Create signal strength icon
            obj.SignalStrengthIcon = uiimage(obj.SignalStrengthInnerGrid,...
                "ImageSource",fullfile(obj.SignalStrengthIconPath,obj.NoSignalIcon),...
                "ScaleMethod",'scaledown',"HorizontalAlignment",'right');
            obj.SignalStrengthIcon.Layout.Row = 1;
            obj.SignalStrengthIcon.Layout.Column = 1;

            % Create labels for signal strength
            obj.SignalStrengthValueLabel = uilabel(obj.SignalStrengthInnerGrid,...
                "Text",obj.SignalStrengthValue,...
                "HorizontalAlignment",'center',...
                "FontSize",obj.ValueFontSize,"FontWeight",'bold');
            obj.SignalStrengthValueLabel.Layout.Row = 1;
            obj.SignalStrengthValueLabel.Layout.Column = 2;

            obj.SignalStrengthLabel = uilabel(obj.SignalStrengthInnerGrid,...
                "Text",obj.AppMessages.signalStrengthLabel,...
                "HorizontalAlignment",'left',"VerticalAlignment",'center',...
                "FontSize",obj.LabelFontSize);
            obj.SignalStrengthLabel.Layout.Row = 1;
            obj.SignalStrengthLabel.Layout.Column = 3;


            % Create inner grid for emergency land button
            obj.EmergencyLandInnerGrid = uigridlayout(obj.ParentGridWithoutControl,...
                'RowHeight',obj.EmergencyLandInnerGridRowHeight,...
                'ColumnWidth',obj.EmergencyLandInnerGridColumnWidth,...
                'RowSpacing',0,...
                'ColumnSpacing',0,...
                'BackgroundColor',obj.NavigationGridBackground);
            obj.EmergencyLandInnerGrid.Layout.Row = 1;
            obj.EmergencyLandInnerGrid.Layout.Column = 3;

            % Create Emergency Land Button
            obj.EmergencyLandButton = uibutton(obj.EmergencyLandInnerGrid,...
                "Icon",fullfile(obj.WorkingAreaIconPath,obj.EmergencyLandButtonIcon),...
                "IconAlignment",'left',"BackgroundColor",obj.EmergencyButtonBackground,...
                "Text",obj.AppMessages.emergencyLandButtonText,...
                "FontWeight",'bold',"FontColor",obj.EmergencyButtonFontColor);
            obj.EmergencyLandButton.Layout.Row = 2;
            obj.EmergencyLandButton.Layout.Column = 2;
            obj.EmergencyLandButton.Enable = true;
        end

        function addWidgetEventListeners(obj)
            % All event listeners that need to be added to the toolstrip
            obj.MoveLeftButtonListener = obj.MoveLeftButton.listener('ButtonPushed',@(src,event)obj.handleMoveLeftButtonPushed());
            obj.MoveRightButtonListener = obj.MoveRightButton.listener('ButtonPushed',@(src,event)obj.handleMoveRightButtonPushed());
            obj.MoveForwardButtonListener = obj.MoveForwardButton.listener('ButtonPushed',@(src,event)obj.handleMoveForwardButtonPushed());
            obj.MoveBackButtonListener = obj.MoveBackButton.listener('ButtonPushed',@(src,event)obj.handleMoveBackButtonPushed());
            obj.MoveUpButtonListener = obj.MoveUpButton.listener('ButtonPushed',@(src,event)obj.handleMoveUpButtonPushed());
            obj.MoveDownButtonListener = obj.MoveDownButton.listener('ButtonPushed',@(src,event)obj.handleMoveDownButtonPushed());
            obj.TurnCCWButtonListener = obj.TurnCCWButton.listener('ButtonPushed',@(src,event)obj.handleTurnCCWButtonPushed());
            obj.TurnCWButtonListener = obj.TurnCWButton.listener('ButtonPushed',@(src,event)obj.handleTurnCWButtonPushed());
            obj.EmergencyLandButtonListener = obj.EmergencyLandButton.listener('ButtonPushed',@(src,event)obj.handleEmergencyLandButtonPushed());

        end
    end

    %% Set observable property values
    methods (Access=private)
        function handleMoveLeftButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedMoveLeft = true;
        end

        function handleMoveRightButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedMoveRight = true;
        end

        function handleMoveForwardButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedMoveForward = true;
        end

        function handleMoveBackButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedMoveBack = true;
        end

        function handleMoveUpButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedMoveUp = true;
        end

        function handleMoveDownButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedMoveDown = true;
        end

        function handleTurnCCWButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedTurnCCW = true;
        end

        function handleTurnCWButtonPushed(obj)
            obj.disableNavigationControls();
            obj.UserRequestedTurnCW = true;
        end

        function handleEmergencyLandButtonPushed(obj)
            % Show-up confirmation dialog for TelloEDU before abort
            % Tello executes land directly on Emergency land button press
            if strcmpi(obj.Mediator.DroneModelName,"TelloEDU")
                obj.createEmergencyLandDialog();
                obj.populateEmergencyLandDialog();
            elseif strcmpi(obj.Mediator.DroneModelName,"Tello")
                obj.disableNavigationControls();
                obj.UserRequestedLand = true;
            end
        end

        function handleEmergencyLandConfirmation(obj)
            obj.disableNavigationControls();
            obj.closeEmergencyLandDialog();
            obj.UserRequestedEmergencyLand = true;
        end

        function handleCancelButtonPushed(obj)
            obj.closeEmergencyLandDialog();
        end

        function handleShowControls(obj)
            % Function to unhide navigation control buttons
            obj.ParentNavigationSectionPanel.Layout.Row = obj.ShowControlsPosition{1};
            obj.ParentNavigationSectionPanel.Layout.Column = obj.ShowControlsPosition{2};
            populateNavigationSectionWithControls(obj);
            obj.HasControlsHidden = false;
            obj.UpdateSensorData = true;
        end

        function handleHideControls(obj)
            % Function to hide navigation control buttons
            obj.ParentNavigationSectionPanel.Layout.Row = obj.HideControlsPosition{1};
            obj.ParentNavigationSectionPanel.Layout.Column = obj.HideControlsPosition{2};
            populateNavigationSectionWithoutControls(obj);
            obj.HasControlsHidden = true;
            obj.UpdateSensorData = true;
        end

        function handleUpdateEssentialData(obj)
            % Function to update bettery level and signal strength data

            % Update battery level and icon
            obj.BatteryValueLabel.Text = string(obj.Mediator.BatteryLevel)+"%";
            obj.updateBatteryIcon(obj.Mediator.BatteryLevel);
            % Low battery warning when battery level goes below 20%
            if obj.Mediator.BatteryLevel < 20
                if ~obj.HasStateLanded && ~obj.LowBatteryWarningGiven
                    obj.handleLowBatteryWarning();
                elseif obj.HasStateLanded && ~obj.LowBatteryWarningGiven
                    obj.handleLowBatteryWarning();
                end
            end

            % Low battery lands drone automatically, notify to update icons
            % accordingly and add a "land" command in the MATLAB script
            if obj.Mediator.BatteryLevel < 15
                if ~obj.HasStateLanded && ~obj.BatteryLowNotified
                    obj.BatteryLow = true;
                end
            end

            % Update signal strength value and icon
            obj.SignalStrengthValueLabel.Text = obj.Mediator.SignalStrength;
            signalValStr = strsplit(obj.Mediator.SignalStrength,'%');
            signalStrengthVal = str2double(signalValStr{1});
            obj.updateSignalIcon(signalStrengthVal);
            % Trigger reconnection when signal strength drops below 10%
            if signalStrengthVal < 10 && ~obj.ReconnectOptionGiven
                obj.setShowReconnectInputDialog();
                obj.ReconnectOptionGiven = true;
            end
        end

        function handleTakeOff(obj)
            obj.EmergencyLandButton.Enable = true;
            obj.enableNavigationControls();
        end

        function handleLand(obj)
            obj.EmergencyLandButton.Enable = false;
            obj.disableNavigationControls();
        end

        function handleNavigationInProgress(obj)
            obj.disableNavigationControls();
        end

        function handleNavigationCompleted(obj)
            obj.enableNavigationControls();
        end

        function updateDronelandedState(obj)
            obj.HasStateLanded = obj.Mediator.DroneStateLanded;
        end

        function setShowReconnectInputDialog(obj)
            obj.ShowReconnectInputDialog = true;
        end
    end

    methods (Access=private)
        function updateBatteryIcon(obj, batteryLevel)
            % Function to update battery level icon depending on battery
            % level

            if batteryLevel >= 90 && batteryLevel <= 100
                obj.BatteryLevelIcon.ImageSource = fullfile(obj.BatteryLevelIconPath,obj.BatteryLevel100Icon);
            elseif batteryLevel >= 65 && batteryLevel < 90
                obj.BatteryLevelIcon.ImageSource = fullfile(obj.BatteryLevelIconPath,obj.BatteryLevel80Icon);
            elseif batteryLevel >= 45 && batteryLevel < 65
                obj.BatteryLevelIcon.ImageSource = fullfile(obj.BatteryLevelIconPath,obj.BatteryLevel60Icon);
            elseif batteryLevel >= 25 && batteryLevel < 45
                obj.BatteryLevelIcon.ImageSource = fullfile(obj.BatteryLevelIconPath,obj.BatteryLevel40Icon);
            elseif batteryLevel >= 10 && batteryLevel < 25
                obj.BatteryLevelIcon.ImageSource = fullfile(obj.BatteryLevelIconPath,obj.BatteryLowIcon);
            elseif batteryLevel < 10
                obj.BatteryLevelIcon.ImageSource = fullfile(obj.BatteryLevelIconPath,obj.BatteryCriticalIcon);
            end
        end

        function updateSignalIcon(obj, signalStrengthVal)
            % Function to update signal strength icon depending on signal
            % strength value

            if signalStrengthVal >= 90
                obj.SignalStrengthIcon.ImageSource = fullfile(obj.SignalStrengthIconPath,obj.SignalLevel100Icon);
            elseif signalStrengthVal >= 60 && signalStrengthVal < 90
                obj.SignalStrengthIcon.ImageSource = fullfile(obj.SignalStrengthIconPath,obj.SignalLevel75Icon);
            elseif signalStrengthVal >= 40 && signalStrengthVal < 60
                obj.SignalStrengthIcon.ImageSource = fullfile(obj.SignalStrengthIconPath,obj.SignalLevel50Icon);
            elseif signalStrengthVal >= 15 && signalStrengthVal < 40
                obj.SignalStrengthIcon.ImageSource = fullfile(obj.SignalStrengthIconPath,obj.SignalLevel25Icon);
            elseif signalStrengthVal < 15
                obj.SignalStrengthIcon.ImageSource = fullfile(obj.SignalStrengthIconPath,obj.NoSignalIcon);
            end
        end

        function enableNavigationControls(obj)
            % function to re-enable navigation buttons after navigation is
            % completed
            obj.MoveLeftButton.Enable = true;
            obj.MoveForwardButton.Enable = true;
            obj.MoveRightButton.Enable = true;
            obj.MoveBackButton.Enable = true;

            obj.MoveUpButton.Enable = true;
            obj.MoveDownButton.Enable = true;
            obj.TurnCCWButton.Enable = true;
            obj.TurnCWButton.Enable = true;

            obj.EmergencyLandButton.Enable = true;
        end

        function disableNavigationControls(obj)
            % function to disable navigation buttons

            obj.MoveLeftButton.Enable = false;
            obj.MoveForwardButton.Enable = false;
            obj.MoveRightButton.Enable = false;
            obj.MoveBackButton.Enable = false;

            obj.MoveUpButton.Enable = false;
            obj.MoveDownButton.Enable = false;
            obj.TurnCCWButton.Enable = false;
            obj.TurnCWButton.Enable = false;

            obj.EmergencyLandButton.Enable = false;
        end

        function calculateDlgPosition(obj)
            % Function to calculate dialog position
            screenSize = get(groot,'ScreenSize');
            left = (screenSize(3) - obj.DialogLeftPosition)/2;
            bottom = (screenSize(4) - obj.DialogBottomPosition)/2;
            obj.WarningDlgPosition = [left bottom obj.DialogLeftPosition obj.DialogBottomPosition];
        end

        function handleLowBatteryWarning(obj)
            % function to throw warning for low battery
            warningInfo.Title = obj.AppMessages.warningDlgTitle;
            if ~obj.HasStateLanded
                warningInfo.Message = obj.AppMessages.lowBatteryWarning;
            else
                warningInfo.Message = obj.AppMessages.lowBatteryDroneLandedWarning;
            end
            obj.calculateDlgPosition();
            obj.WarningDlg = warndlg(warningInfo.Message,warningInfo.Title,obj.WarningDlgPosition);

            obj.LowBatteryWarningGiven = true;
        end
    end

    methods(Access = private)
        function createEmergencyLandDialog(obj)
            % Function to create Emergency Land confirmation dialog

            % Create modal tab for Emergency Land
            screenSize = get(groot,'ScreenSize');
            left = (screenSize(3) - obj.EmergencyLandDialogLeftPosition)/2;
            bottom = (screenSize(4) - obj.EmergencyLandDialogBottomPosition)/2;

            obj.EmergencyLandDialogPosition = [left bottom obj.EmergencyLandDialogLeftPosition...
                obj.EmergencyLandDialogBottomPosition];

            % Create modal figure
            obj.EmergencyLandDialogFigure = uifigure("Position",...
                obj.EmergencyLandDialogPosition,...
                "WindowStyle","modal","Resize","off", ...
                "Name",obj.AppMessages.emergencyLandDialogTitle);

            obj.EmergencyLandDialogParentGrid = uigridlayout(obj.EmergencyLandDialogFigure,...
                "RowHeight",obj.EmergencyLandDialogParentGridRowHeight, ...
                "ColumnWidth",obj.EmergencyLandDialogParentGridColumnWidth);
        end

        function populateEmergencyLandDialog(obj)
            % Function to populate Emergency Land confirmation dialog

            obj.populateTextLabel();
            obj.populateButtons();
            % Add listeners to confirmation dialog buttons
            obj.ContinueEmergencyLandButtonListener = obj.ContinueEmergencyLandButton.listener('ButtonPushed',@(src,event)obj.handleEmergencyLandConfirmation());
            obj.CancelButtonListener = obj.CancelButton.listener('ButtonPushed',@(src,event)obj.handleCancelButtonPushed());
        end

        function populateTextLabel(obj)
            % Function to populate Emergency Land confirmation dialog icons
            % and warning text

            obj.EmergencyLandDialogInnerGrid = uigridlayout( ...
                obj.EmergencyLandDialogParentGrid,...
                "RowHeight",obj.EmergencyLandDialogInnerGridRowHeight, ...
                "ColumnWidth",obj.EmergencyLandDialogInnerGridColumnWidth);
            obj.EmergencyLandDialogInnerGrid.Layout.Row = 1;
            obj.EmergencyLandDialogInnerGrid.Layout.Column = 1;

            obj.EmergencyLandDialogIcon = uiimage(obj.EmergencyLandDialogInnerGrid, ...
                "ImageSource", ...
                fullfile(obj.WorkingAreaIconPath, obj.EmergencyLandButtonIcon), ...
                "ScaleMethod",'scaleup');
            obj.EmergencyLandDialogIcon.Layout.Row = [1 2];
            obj.EmergencyLandDialogIcon.Layout.Column = 1;

            obj.EmergencyLandDialogTextTitle = uilabel(obj.EmergencyLandDialogInnerGrid,...
                "Text",obj.AppMessages.emergencyLandDialogTextTitle, ...
                "FontWeight",'bold','VerticalAlignment','bottom');
            obj.EmergencyLandDialogTextTitle.Layout.Row = 1;
            obj.EmergencyLandDialogTextTitle.Layout.Column = 2;

            obj.EmergencyLandDialogTextLabel = uilabel(obj.EmergencyLandDialogInnerGrid,...
                "Text",obj.AppMessages.emergencyLandDialogText, ...
                'VerticalAlignment','top');
            obj.EmergencyLandDialogTextLabel.Layout.Row = 2;
            obj.EmergencyLandDialogTextLabel.Layout.Column = 2;
        end

        function populateButtons(obj)
            % Function to populate Emergency Land confirmation dialog
            % buttons

            obj.ButtonGrid = uigridlayout(obj.EmergencyLandDialogParentGrid,...
                "RowHeight",obj.ButtonGridRowHeight, ...
                "ColumnWidth",obj.ButtonGridColumnWidth, ...
                "Padding",[0 0 0 0]);
            obj.ButtonGrid.Layout.Row = 2;
            obj.ButtonGrid.Layout.Column = 1;

            obj.ContinueEmergencyLandButton = uibutton(obj.ButtonGrid, ...
                "Text",obj.AppMessages.emergencyLandButtonText);
            obj.ContinueEmergencyLandButton.Layout.Row = 1;
            obj.ContinueEmergencyLandButton.Layout.Column = 2;

            obj.CancelButton = uibutton(obj.ButtonGrid, ...
                "Text",obj.AppMessages.cancelButtonText);
            obj.CancelButton.Layout.Row = 1;
            obj.CancelButton.Layout.Column = 3;
        end

        function closeEmergencyLandDialog(obj)
            delete(obj.EmergencyLandDialogFigure);
        end
    end
end