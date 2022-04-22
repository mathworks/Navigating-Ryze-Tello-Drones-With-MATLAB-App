classdef ConfigureSettings < telloapplet.HelperClass
    % CONGIGURESETTINGS - Class that configures drone navigation settings

    % Distance - Relative distance(in m). Range: 0.2m - 5m (default = 0.2m)
    % Speed - The speed(in m/s) of move. Range: 0.1m/s - 1m/s (default = 0.4m/s)

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % App message texts
        AppMessages

        % Store parent figure position
        ParentFigurePosition

        % Setting dialogue top level structure
        ParentFigure
        ParentGrid
        RestoreDefaultGrid
        ButtonGrid

        % Distance settings structure
        DistanceSettingsInnerGrid
        DistanceTextsInnerGrid
        DistanceSlider
        DistanceTurnSectionDivider

        % Turn settings structure
        TurnSettingsInnerGrid
        TurnTextsInnerGrid
        TurnSlider
        TurnSpeedSectionDivider

        % Speed settings structure
        SpeedSettingsInnerGrid
        SpeedSlider
        SpeedTextsInnerGrid

        % Button placement grid
        ButtonsInnerGrid

        % Distance settings texts and value
        DistanceSettingsDescription
        DistanceSettingsLabel
        DistanceValueLabel

        % Turn settings texts and value
        TurnSettingsDescription
        TurnSettingsLabel
        TurnValueLabel

        % Speed settings texts and value
        SpeedSettingsDescription
        SpeedSettingsLabel
        SpeedValueLabel

        % Buttons and button listeners
        OkButton
        OkButtonListener
        RestoreDefaultButton
        RestoreDefaultButtonListener
        CancelButton
        CancelButtonListener
    end

    properties(Constant, Access=private)
        % Default navigation parameters
        DefaultNavigationDistance = 0.2;
        DefaultNavigationTurn = pi/2;
        DefaultNavigationSpeed = 0.4;

        % Navigation parameter units
        NavigationDistanceUnit = " m"
        TurnAngleUnit = " radian"
        NavigationSpeedUnit = " m/s"

        % Parent Grid dimensions
        ParentGridRowHeight = {'1x','0.03x','1x','0.03x','1x','0.4x','0.4x'}
        ParentGridColumnWidth = {'1x'}

        % Restore Defaults button grid dimension
        RestoreDefaultGridRowHieght = {'1x'}
        RestoreDefaultGridColumnWidth = {'1x','0.3x'}

        % OK/Cancel Button grid dimensions
        ButtonsGridRowHieght = {'1x'}
        ButtonsGridColumnWidt = {'1x','0.3x','0.3x'}

        % Inner grid dimensions
        InnerGridRowHeight = {'fit','fit'}
        InnerGridColumnWidth = {'0.2x','0.5x','1x'}

        % Distance slider parameters
        DistanceSliderLimits = [0.2 5]
        DistanceSliderMajorTicks = [0.2 1 2 3 4 5]
        DistanceSliderMajorTickLabels = ["0.2" "1" "2" "3" "4" "5"]
        DistanceSliderMinorTicks = [0.5 1.5 2.5 3.5 4.5]

        % Turn slider parameters
        TurnSliderLimits = [pi/4 pi]
        TurnSliderMajorTicks = [pi/4 pi/2 (3*pi/4) pi]
        TurnSliderMajorTickLabels = ["π/4" "π/2" "3π/4" "π"]

        % Speed slider parameters
        SpeedSliderLimits = [0.1 1]
        SpeedSliderMajorTicks = [0.1 0.4 0.7 1]
        SpeedSliderMajorTickLabels = ["0.1" "0.4" "0.7" "1"]
        SpeedSliderMinorTicks = [0.2 0.3 0.5 0.6 0.8 0.9]

        % Configuration settings dialog position relative to the screen
        % size
        DialogLeftPosition = 500
        DialogBottomPosition = 350

        % Background color for separator panels
        SeparatorPanelBackgroundColor = [0.72 0.72 0.72]

        % Padding for grid
        DefaultPadding = [0 0 0 0]
    end

    properties(SetObservable)
        % Navigation parameters other modules are observing
        NavigationDistanceValue
        NavigationTurnAngle
        NavigationSpeedValue
    end

    methods
        % Constructor
        function obj = ConfigureSettings(mediator, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.AppMessages = appMessages;

            % Initialize navigation parameters with default values
            if isempty(obj.NavigationDistanceValue)
                obj.NavigationDistanceValue = obj.DefaultNavigationDistance;
            end
            if isempty(obj.NavigationTurnAngle)
                obj.NavigationTurnAngle = obj.DefaultNavigationTurn;
            end
            if isempty(obj.NavigationSpeedValue)
                obj.NavigationSpeedValue = obj.DefaultNavigationSpeed;
            end
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserRequestedConfigureSettings', @(src, event)obj.handleConfigureSettingsRequest());
        end
    end

    % Methods to handle observable property callback
    methods(Access = private)
        function handleConfigureSettingsRequest(obj)
            obj.createDialog();
            obj.populateDialog();
        end
    end

    % Methods to handle widget listener callbacks
    methods(Access = private)
        function handleDistanceSliderValueChanged(obj,~,event)
            value = obj.DistanceSlider.Value;
            newSliderValue = obj.calculateNewValue(value, event);
            newDistance = sprintf('%0.1f', newSliderValue);
            obj.DistanceValueLabel.Text = {char(string(newDistance)+obj.NavigationDistanceUnit)};
            obj.RestoreDefaultButton.Enable = true;
        end

        function handleTurnSliderValueChanged(obj,~,event)
            value = obj.TurnSlider.Value;
            newSliderValue = obj.calculateNewValue(value, event);
            newTurnValue = telloapplet.internal.Utility.interpretTurnValue(newSliderValue);
            obj.TurnValueLabel.Text = {char(newTurnValue+obj.TurnAngleUnit)};
            obj.RestoreDefaultButton.Enable = true;
        end

        function handleSpeedSliderValueChanged(obj,~,event)
            value = obj.SpeedSlider.Value;
            newSliderValue = obj.calculateNewValue(value, event);
            newSpeed = sprintf('%0.1f', newSliderValue);
            obj.SpeedValueLabel.Text = string(newSpeed)+obj.NavigationSpeedUnit;
            obj.RestoreDefaultButton.Enable = true;
        end

        function newValue = calculateNewValue(~, value ,event)
            % determine which discrete option the current slider value is
            % closest to
            [majorTicksMinValue, majorTicksMinIdx] = min(abs(value - event.Source.MajorTicks(:)));

            [minorTicksMinValue, minorTicksMinIdx] = min(abs(value - event.Source.MinorTicks(:)));

            if isempty(minorTicksMinValue) || majorTicksMinValue < minorTicksMinValue
                % move the slider to that option
                event.Source.Value = event.Source.MajorTicks(majorTicksMinIdx);
                % Override the selected value if you plan on using it within this function
                newValue = event.Source.MajorTicks(majorTicksMinIdx);
            else
                event.Source.Value = event.Source.MinorTicks(minorTicksMinIdx);
                newValue = event.Source.MinorTicks(minorTicksMinIdx);
            end
        end

        function handleOkButtonPushed(obj)
            % Callback to apply navigation parameter settings
            if obj.NavigationDistanceValue ~= obj.DistanceSlider.Value
                obj.NavigationDistanceValue = obj.DistanceSlider.Value;
            end

            if obj.NavigationTurnAngle ~= obj.TurnSlider.Value
                obj.NavigationTurnAngle = obj.TurnSlider.Value;
            end

            if obj.NavigationSpeedValue ~= obj.SpeedSlider.Value
                obj.NavigationSpeedValue = obj.SpeedSlider.Value;
            end
            obj.closeDialog();
        end

        function handleRestoreDefaultButtonPushed(obj)
            % Callback to restore navigation parameters and slider to
            % default values when Restore Defaults button is clicked
            obj.NavigationDistanceValue = obj.DefaultNavigationDistance;
            obj.DistanceSlider.Value = obj.DefaultNavigationDistance;
            obj.DistanceValueLabel.Text = string(obj.DefaultNavigationDistance)...
                + obj.NavigationDistanceUnit;

            obj.NavigationTurnAngle = obj.DefaultNavigationTurn;
            obj.TurnSlider.Value = obj.DefaultNavigationTurn;
            obj.TurnValueLabel.Text = telloapplet.internal.Utility.interpretTurnValue...
                (obj.DefaultNavigationTurn) + obj.TurnAngleUnit;

            obj.NavigationSpeedValue = obj.DefaultNavigationSpeed;
            obj.SpeedSlider.Value = obj.DefaultNavigationSpeed;
            obj.SpeedValueLabel.Text = string(obj.DefaultNavigationSpeed)...
                + obj.NavigationSpeedUnit;
        end

        function handleCancelButtonPushed(obj)
            obj.closeDialog();
        end
    end

    methods(Access = private)
        function createDialog(obj)
            % Function to create configuring settings dialog

            % Create modal tab for configuring settings
            % Determine screen position for the modal dialog
            screenSize = get(groot,'ScreenSize');
            left = (screenSize(3) - obj.DialogLeftPosition)/2;
            bottom = (screenSize(4) - obj.DialogBottomPosition)/2;

            obj.ParentFigurePosition = [left bottom obj.DialogLeftPosition obj.DialogBottomPosition];

            % Create modal figure
            obj.ParentFigure = uifigure("Position",obj.ParentFigurePosition, ...
                "WindowStyle",'modal', "Resize",'off', ...
                "Name",obj.AppMessages.settingsConfigurationDialogTitle);

            obj.ParentGrid = uigridlayout(obj.ParentFigure,...
                "RowHeight",obj.ParentGridRowHeight,"ColumnWidth",obj.ParentGridColumnWidth);
        end

        function populateDialog(obj)
            % Function to populate configuration settings dialog
            obj.populateDistanceSettings();

            obj.DistanceTurnSectionDivider = obj.createSeparatorPanel(obj.ParentGrid);
            obj.DistanceTurnSectionDivider.Layout.Row = 2;
            obj.DistanceTurnSectionDivider.Layout.Column = 1;

            obj.populateTurnSettings();

            obj.TurnSpeedSectionDivider = obj.createSeparatorPanel(obj.ParentGrid);
            obj.TurnSpeedSectionDivider.Layout.Row = 4;
            obj.TurnSpeedSectionDivider.Layout.Column = 1;

            obj.populateSpeedSettings();
            drawnow limitrate

            obj.populateRestoreDefault();

            obj.populateButtons();

            obj.addWidgetEventListeners();
        end

        function populateDistanceSettings(obj)
            % Function to populate navigation distance related slider and
            % description
            obj.DistanceSettingsInnerGrid = obj.createInnerGrid(obj.ParentGrid);
            obj.DistanceSettingsInnerGrid.Layout.Row = 1;
            obj.DistanceSettingsInnerGrid.Layout.Column = 1;

            obj.DistanceSettingsDescription = uilabel(obj.DistanceSettingsInnerGrid,...
                "Text",obj.AppMessages.distanceSettingDescription);
            obj.DistanceSettingsDescription.Layout.Row = 1;
            obj.DistanceSettingsDescription.Layout.Column = [1 3];

            obj.DistanceSlider = uislider(obj.DistanceSettingsInnerGrid, ...
                "Limits",obj.DistanceSliderLimits,"MajorTicks",obj.DistanceSliderMajorTicks,...
                "MajorTickLabels",obj.DistanceSliderMajorTickLabels, ...
                "MinorTicks",obj.DistanceSliderMinorTicks,"Value",obj.NavigationDistanceValue);
            obj.DistanceSlider.Layout.Row = 2;
            obj.DistanceSlider.Layout.Column = 3;

            obj.DistanceTextsInnerGrid = obj.createTextInnerGrid(obj.DistanceSettingsInnerGrid);
            obj.DistanceTextsInnerGrid.Layout.Row = 2;
            obj.DistanceTextsInnerGrid.Layout.Column = 2;

            obj.DistanceSettingsLabel = uilabel(obj.DistanceTextsInnerGrid,...
                "Text",obj.AppMessages.distanceSettingLabel, ...
                "HorizontalAlignment",'right');
            obj.DistanceSettingsLabel.Layout.Row = 1;
            obj.DistanceSettingsLabel.Layout.Column = 2;

            navigationDistance = sprintf('%0.1f', obj.NavigationDistanceValue);
            obj.DistanceValueLabel = uilabel(obj.DistanceTextsInnerGrid,...
                "Text",{char(string(navigationDistance)+" m")},"HorizontalAlignment",'right');
            obj.DistanceValueLabel.Layout.Row = 2;
            obj.DistanceValueLabel.Layout.Column = 2;
        end

        function populateTurnSettings(obj)
            % Function to populate navigation turn related slider and
            % description
            obj.TurnSettingsInnerGrid = obj.createInnerGrid(obj.ParentGrid);
            obj.TurnSettingsInnerGrid.Layout.Row = 3;
            obj.TurnSettingsInnerGrid.Layout.Column = 1;

            obj.TurnSettingsDescription = uilabel(obj.TurnSettingsInnerGrid,...
                "Text",obj.AppMessages.turnSettingDescription);
            obj.TurnSettingsDescription.Layout.Row = 1;
            obj.TurnSettingsDescription.Layout.Column = [1 3];

            obj.TurnSlider = uislider(obj.TurnSettingsInnerGrid, ...
                "Limits",obj.TurnSliderLimits,"MajorTicks",obj.TurnSliderMajorTicks, ...
                "MajorTickLabels",obj.TurnSliderMajorTickLabels, ...
                "MinorTicks",[],"Value",obj.NavigationTurnAngle);
            obj.TurnSlider.Layout.Row = 2;
            obj.TurnSlider.Layout.Column = 3;

            obj.TurnTextsInnerGrid = obj.createTextInnerGrid(obj.TurnSettingsInnerGrid);
            obj.TurnTextsInnerGrid.Layout.Row = 2;
            obj.TurnTextsInnerGrid.Layout.Column = 2;

            obj.TurnSettingsLabel = uilabel(obj.TurnTextsInnerGrid,...
                "Text",obj.AppMessages.turnSettingLabel, ...
                "HorizontalAlignment",'right');
            obj.TurnSettingsLabel.Layout.Row = 1;
            obj.TurnSettingsLabel.Layout.Column = 2;

            turnAngle = telloapplet.internal.Utility.interpretTurnValue(obj.NavigationTurnAngle);
            obj.TurnValueLabel = uilabel(obj.TurnTextsInnerGrid,...
                "Text",{char(string(turnAngle)+" radian")},"HorizontalAlignment",'right');
            obj.TurnValueLabel.Layout.Row = 2;
            obj.TurnValueLabel.Layout.Column = 2;
        end

        function populateSpeedSettings(obj)
            % Function to populate navigation speed related slider and
            % description
            obj.SpeedSettingsInnerGrid = obj.createInnerGrid(obj.ParentGrid);
            obj.SpeedSettingsInnerGrid.Layout.Row = 5;
            obj.SpeedSettingsInnerGrid.Layout.Column = 1;

            obj.SpeedSettingsDescription = uilabel(obj.SpeedSettingsInnerGrid,...
                "Text",obj.AppMessages.speedSettingDescription);
            obj.SpeedSettingsDescription.Layout.Row = 1;
            obj.SpeedSettingsDescription.Layout.Column = [1 3];

            obj.SpeedSlider = uislider(obj.SpeedSettingsInnerGrid, ...
                "Limits",obj.SpeedSliderLimits,"MajorTicks",obj.SpeedSliderMajorTicks, ...
                "MajorTickLabels",obj.SpeedSliderMajorTickLabels, ...
                "MinorTicks",obj.SpeedSliderMinorTicks,"Value",obj.DefaultNavigationSpeed);
            obj.SpeedSlider.Layout.Row = 2;
            obj.SpeedSlider.Layout.Column = 3;

            obj.SpeedTextsInnerGrid = obj.createTextInnerGrid(obj.SpeedSettingsInnerGrid);
            obj.SpeedTextsInnerGrid.Layout.Row = 2;
            obj.SpeedTextsInnerGrid.Layout.Column = 2;

            obj.SpeedSettingsLabel = uilabel(obj.SpeedTextsInnerGrid,...
                "Text",obj.AppMessages.speedSettingLabel, ...
                "HorizontalAlignment",'right');
            obj.SpeedSettingsLabel.Layout.Row = 1;
            obj.SpeedSettingsLabel.Layout.Column = 2;

            navigationSpeed = sprintf('%0.1f', obj.DefaultNavigationSpeed);
            obj.SpeedValueLabel = uilabel(obj.SpeedTextsInnerGrid,...
                "Text",{char(string(navigationSpeed)+" m/s")},"HorizontalAlignment",'right');
            obj.SpeedValueLabel.Layout.Row = 2;
            obj.SpeedValueLabel.Layout.Column = 2;
        end

        function populateRestoreDefault(obj)
            % Function to populate Restore Defaults button
            obj.RestoreDefaultGrid = uigridlayout(obj.ParentGrid,...
                "RowHeight",obj.RestoreDefaultGridRowHieght, ...
                "ColumnWidth",obj.RestoreDefaultGridColumnWidth, ...
                "Padding",obj.DefaultPadding);
            obj.RestoreDefaultGrid.Layout.Row = 6;
            obj.RestoreDefaultGrid.Layout.Column = 1;

            obj.RestoreDefaultButton = uibutton(obj.RestoreDefaultGrid, ...
                "Text",obj.AppMessages.restoreDefaultButtonText);
            obj.RestoreDefaultButton.Layout.Row = 1;
            obj.RestoreDefaultButton.Layout.Column = 2;
        end

        function populateButtons(obj)
            % Function to populate "Ok" and "Cancel" button
            obj.ButtonGrid = uigridlayout(obj.ParentGrid,...
                "RowHeight",obj.ButtonsGridRowHieght, ...
                "ColumnWidth",obj.ButtonsGridColumnWidt, ...
                "Padding",obj.DefaultPadding);
            obj.ButtonGrid.Layout.Row = 7;
            obj.ButtonGrid.Layout.Column = 1;

            obj.OkButton = uibutton(obj.ButtonGrid, ...
                "Text",obj.AppMessages.okButtonText);
            obj.OkButton.Layout.Row = 1;
            obj.OkButton.Layout.Column = 2;

            obj.CancelButton = uibutton(obj.ButtonGrid, ...
                "Text",obj.AppMessages.cancelButtonText);
            obj.CancelButton.Layout.Row = 1;
            obj.CancelButton.Layout.Column = 3;
        end

        function closeDialog(obj)
            % Function to close configuration settings dialog
            delete(obj.ParentFigure);
        end

        function addWidgetEventListeners(obj)
            % All event listeners
            obj.DistanceSlider.ValueChangedFcn = @obj.handleDistanceSliderValueChanged;
            obj.TurnSlider.ValueChangedFcn = @obj.handleTurnSliderValueChanged;
            obj.SpeedSlider.ValueChangedFcn = @obj.handleSpeedSliderValueChanged;
            obj.OkButtonListener = obj.OkButton.listener('ButtonPushed',@(src,event)obj.handleOkButtonPushed());
            obj.RestoreDefaultButtonListener = obj.RestoreDefaultButton.listener('ButtonPushed',@(src,event)obj.handleRestoreDefaultButtonPushed());
            obj.CancelButtonListener = obj.CancelButton.listener('ButtonPushed',@(src,event)obj.handleCancelButtonPushed());
        end
    end

    % Utility methods
    methods (Access=private)
        function innerGrid = createInnerGrid(obj, parent)
            % Common implementation function for creating inner grids
            innerGrid = uigridlayout(parent,...
                "RowHeight",obj.InnerGridRowHeight,"ColumnWidth",obj.InnerGridColumnWidth, ...
                "Padding", obj.DefaultPadding);
        end

        function innerTextGrid = createTextInnerGrid(obj, parent)
            % Common implementation function for creating text inner grids
            innerTextGrid = uigridlayout(parent,...
                "RowHeight",{'fit','fit'},"ColumnWidth",{'fit'}, ...
                "Padding", obj.DefaultPadding);
        end

        function separatorPanel = createSeparatorPanel(obj, parent)
            % Common implementation function for creating separator panels
            separatorPanel = uipanel(parent, ...
                "BorderType","none", ...
                'BackgroundColor',obj.SeparatorPanelBackgroundColor);
        end
    end

end