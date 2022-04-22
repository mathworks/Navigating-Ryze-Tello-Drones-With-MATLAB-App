classdef SensorDataSectionManager < telloapplet.HelperClass
    % SENSORDATASECTIONMANAGER - Class that manages placing drone sensor
    % data and pre-flight check status and updating drone sensor data

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % App message texts
        AppMessages

        % Parent Grid and panel
        ParentGrid
        ParentSensorSectionPanel

        % PreFlight Check Icon and structure elements
        FlightCheckIcon
        FlightCheckInnerPanel
        FlightCheckInnerGrid
        FlightCheckTextLabel

        % Icon path
        WorkingAreaIconPath

        % Sensor data showing panel structure elements
        SeparatorPanel
        SensorPanelGrid

        % Orientation data showing structure elements
        YawInnerGrid
        YawTextLabel
        YawValueLabel
        YawValue = ''
        PitchInnerGrid
        PitchTextLabel
        PitchValueLabel
        PitchValue = ''
        RollTextLabel
        RollInnerGrid
        RollValueLabel
        RollValue = ''

        % Speed data showing structure elements
        XAxisSpeedInnerGrid
        XAxisSpeedLabel
        XAxisSpeedValueLabel
        XAxisSpeedValue = ''
        YAxisSpeedInnerGrid
        YAxisSpeedLabel
        YAxisSpeedValueLabel
        YAxisSpeedValue = ''
        ZAxisSpeedInnerGrid
        ZAxisSpeedLabel
        ZAxisSpeedValueLabel
        ZAxisSpeedValue = ''

        % Height data showing structure elements
        HeightInnerGrid
        HeightLabel
        HeightValueLabel
        HeightValue = ''
    end

    properties(Access=private)
        % Sensor panel layout parameters
        RowHeight = {'0.75x','0.03x','1x','1x','1x'}
        ColumnWidth = {'1x','1x','1x'}
        RowSpacing = 2
        ColumnSpacing = 5

        % Inner grid dimensions
        FlightCheckInnerGridRowHeight = {'1x'}
        FlightCheckInnerGridColumnWidth = {'0.25x','0.75x'}
        SensorDataInnerGridRowHeight = {'1x','1x'}
        SensorDataInnerGridColumnWidth = {'1x'}

        % Widget placements
        FlighCheckIconPosition = {1,1}
        SeparatorPanelPosition = {1,3}

        % Icons
        FlightCheckIncompleteIcon = "Warning_16.svg";
        FlightCheckSuccessIcon = "Success_16.svg";
        FlightCheckFailureIcon = "Error_16.svg";

        SensorValueFontSize = 18
        SensorDataLabelFontSize = 14

        % Panel background colors
        SensorPanelBackground = 'white'
        SeparatorPanelBackground = [0.72 0.72 0.72]
    end

    methods
        % Constructor
        function obj = SensorDataSectionManager(mediator, parentGrid, position, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.ParentGrid = parentGrid;
            obj.Mediator = mediator;
            obj.AppMessages = appMessages;

            % Create pin table area table and position it in the grid
            % Create pin table panel
            obj.ParentSensorSectionPanel = uipanel(obj.ParentGrid);
            obj.ParentSensorSectionPanel.Layout.Row = position{1};
            obj.ParentSensorSectionPanel.Layout.Column = position{2};

            populateSensorDataPane(obj);
            drawnow limitrate
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UpdateSensorData', @(src, event)obj.handleSensorDataUpdate());
            obj.subscribe('PreFlightCheckComplete', @(src, event)obj.updatePreFlightCheckIcon());
        end
    end

    methods (Access=private)
        function populateSensorDataPane(obj)
            % Function to populate PreFligh Check status and Sensor Data
            % area

            obj.SensorPanelGrid = uigridlayout(obj.ParentSensorSectionPanel,...
                'RowHeight',obj.RowHeight,...
                'ColumnWidth',obj.ColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);

            createFlightCheckStatusSection(obj);

            obj.SeparatorPanel = uipanel(obj.SensorPanelGrid, ...
                "BorderType","none", ...
                'BackgroundColor',obj.SeparatorPanelBackground);
            obj.SeparatorPanel.Layout.Row = 2;
            obj.SeparatorPanel.Layout.Column = [1 3];

            createSensorDataSection(obj);
        end

        function createFlightCheckStatusSection(obj)
            % Function to create PreFlight Check status area

            obj.FlightCheckInnerPanel = uipanel(obj.SensorPanelGrid, ...
                "BorderType","none");
            obj.FlightCheckInnerPanel.Layout.Row = 1;
            obj.FlightCheckInnerPanel.Layout.Column = [1 3];

            obj.FlightCheckInnerGrid = uigridlayout(obj.FlightCheckInnerPanel,...
                'RowHeight',obj.FlightCheckInnerGridRowHeight,...
                'ColumnWidth',obj.FlightCheckInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);

            resourcesLocation = telloapplet.internal.Utility.getResourcesLocation();
            obj.WorkingAreaIconPath = fullfile(resourcesLocation, 'workingarea');

            obj.FlightCheckIcon = uiimage(obj.FlightCheckInnerGrid);
            obj.FlightCheckIcon.ImageSource = fullfile(obj.WorkingAreaIconPath,obj.FlightCheckIncompleteIcon);
            obj.FlightCheckIcon.ScaleMethod = 'scaledown';
            obj.FlightCheckIcon.Layout.Row = 1;
            obj.FlightCheckIcon.Layout.Column = 1;
            obj.FlightCheckIcon.HorizontalAlignment = 'right';

            obj.FlightCheckTextLabel = uilabel(obj.FlightCheckInnerGrid);
            obj.FlightCheckTextLabel.HorizontalAlignment = 'left';
            obj.FlightCheckTextLabel.Layout.Row = 1;
            obj.FlightCheckTextLabel.Layout.Column = 2;
            obj.FlightCheckTextLabel.FontSize = 12;
            obj.FlightCheckTextLabel.FontWeight = 'bold';
            obj.FlightCheckTextLabel.Text = obj.AppMessages.preFlightIncompleteText;
        end

        function createSensorDataSection(obj)
            % Function to create Orientation, Speed and Height data section

            % Yaw Field
            % Yaw inner grid
            obj.YawInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.YawInnerGrid.Layout.Row = 3;
            obj.YawInnerGrid.Layout.Column = 1;
            % Yaw Value label
            obj.YawValueLabel = uilabel(obj.YawInnerGrid,'Text',{obj.YawValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom',...
                'Tooltip',obj.AppMessages.yawTooltip);
            obj.YawValueLabel.Layout.Row = 1;
            obj.YawValueLabel.Layout.Column = 1;
            % Yaw text label
            obj.YawTextLabel = uilabel(obj.YawInnerGrid, ...
                "Text",obj.AppMessages.yawDataLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize, ...
                "Tooltip",obj.AppMessages.yawTooltip);
            obj.YawTextLabel.Layout.Row = 2;
            obj.YawTextLabel.Layout.Column = 1;

            % Pitch Text Label
            % Pitch inner grid
            obj.PitchInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.PitchInnerGrid.Layout.Row = 3;
            obj.PitchInnerGrid.Layout.Column = 2;
            % Pitch Value label
            obj.PitchValueLabel = uilabel(obj.PitchInnerGrid,'Text',{obj.PitchValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom',...
                'Tooltip',obj.AppMessages.pitchTooltip);
            obj.PitchValueLabel.Layout.Row = 1;
            obj.PitchValueLabel.Layout.Column = 1;
            % Pitch text label
            obj.PitchTextLabel = uilabel(obj.PitchInnerGrid, ...
                "Text",obj.AppMessages.pitchDataLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize, ...
                "Tooltip",obj.AppMessages.pitchTooltip);
            obj.PitchTextLabel.Layout.Row = 2;
            obj.PitchTextLabel.Layout.Column = 1;

            % Roll Text label
            % Roll inner grid
            obj.RollInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.RollInnerGrid.Layout.Row = 3;
            obj.RollInnerGrid.Layout.Column = 3;
            % Roll Value label
            obj.RollValueLabel = uilabel(obj.RollInnerGrid,'Text',{obj.RollValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom',...
                'Tooltip',obj.AppMessages.rollTooltip);
            obj.RollValueLabel.Layout.Row = 1;
            obj.RollValueLabel.Layout.Column = 1;
            % Roll text label
            obj.RollTextLabel = uilabel(obj.RollInnerGrid, ...
                "Text",obj.AppMessages.rollDataLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize, ...
                "Tooltip",obj.AppMessages.rollTooltip);
            obj.RollTextLabel.Layout.Row = 2;
            obj.RollTextLabel.Layout.Column = 1;

            % X-Axis Speed Label
            % X-Axis Speed inner grid
            obj.XAxisSpeedInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.XAxisSpeedInnerGrid.Layout.Row = 4;
            obj.XAxisSpeedInnerGrid.Layout.Column = 1;
            % X-Axis Speed Value label
            obj.XAxisSpeedValueLabel = uilabel(obj.XAxisSpeedInnerGrid, ...
                'Text',{obj.XAxisSpeedValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom');
            obj.XAxisSpeedValueLabel.Layout.Row = 1;
            obj.XAxisSpeedValueLabel.Layout.Column = 1;
            % X-Axis Speed label
            obj.XAxisSpeedLabel = uilabel(obj.XAxisSpeedInnerGrid, ...
                "Text",obj.AppMessages.xAxisSpeedLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize);
            obj.XAxisSpeedLabel.Layout.Row = 2;
            obj.XAxisSpeedLabel.Layout.Column = 1;

            % Y-Axis Speed Label
            % Y-Axis Speed inner grid
            obj.YAxisSpeedInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.YAxisSpeedInnerGrid.Layout.Row = 4;
            obj.YAxisSpeedInnerGrid.Layout.Column = 2;
            % Y-Axis Speed Value label
            obj.YAxisSpeedValueLabel = uilabel(obj.YAxisSpeedInnerGrid, ...
                'Text',{obj.YAxisSpeedValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom');
            obj.YAxisSpeedValueLabel.Layout.Row = 1;
            obj.YAxisSpeedValueLabel.Layout.Column = 1;
            % Y-Axis Speed label
            obj.YAxisSpeedLabel = uilabel(obj.YAxisSpeedInnerGrid, ...
                "Text",obj.AppMessages.yAxisSpeedLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize);
            obj.YAxisSpeedLabel.Layout.Row = 2;
            obj.YAxisSpeedLabel.Layout.Column = 1;

            % Z-Axis Speed Label
            % Z-Axis Speed inner grid
            obj.ZAxisSpeedInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.ZAxisSpeedInnerGrid.Layout.Row = 4;
            obj.ZAxisSpeedInnerGrid.Layout.Column = 3;
            % Z-Axis Speed Value label
            obj.ZAxisSpeedValueLabel = uilabel(obj.ZAxisSpeedInnerGrid, ...
                "Text",{obj.ZAxisSpeedValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom');
            obj.ZAxisSpeedValueLabel.Layout.Row = 1;
            obj.ZAxisSpeedValueLabel.Layout.Column = 1;
            % Z-Axis Speed label
            obj.ZAxisSpeedLabel = uilabel(obj.ZAxisSpeedInnerGrid, ...
                "Text",obj.AppMessages.zAxisSpeedLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize);
            obj.ZAxisSpeedLabel.Layout.Row = 2;
            obj.ZAxisSpeedLabel.Layout.Column = 1;

            % Height Label
            % Height inner grid
            obj.HeightInnerGrid = uigridlayout(obj.SensorPanelGrid,...
                'RowHeight',obj.SensorDataInnerGridRowHeight,...
                'ColumnWidth',obj.SensorDataInnerGridColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.SensorPanelBackground);
            obj.HeightInnerGrid.Layout.Row = 5;
            obj.HeightInnerGrid.Layout.Column = 1;
            % Height Speed Value label
            obj.HeightValueLabel = uilabel(obj.HeightInnerGrid, ...
                'Text',{obj.HeightValue},...
                "FontSize",obj.SensorValueFontSize,"FontWeight",'bold',...
                'HorizontalAlignment','center','VerticalAlignment','bottom');
            obj.HeightValueLabel.Layout.Row = 1;
            obj.HeightValueLabel.Layout.Column = 1;
            % Height Speed label
            obj.HeightLabel = uilabel(obj.HeightInnerGrid, ...
                "Text",obj.AppMessages.heightLabel, ...
                "HorizontalAlignment",'center',"VerticalAlignment",'top', ...
                "FontSize",obj.SensorDataLabelFontSize, ...
                "Tooltip",obj.AppMessages.heightTooltip);
            obj.HeightLabel.Layout.Row = 2;
            obj.HeightLabel.Layout.Column = 1;
        end
    end

    methods (Access=private)
        function handleSensorDataUpdate(obj)
            % Callback to update sensor data periodically

            % Update orientation data with sensitivity of 2 digits after
            % decimal point
            obj.YawValue = sprintf('%0.2f', obj.Mediator.Orientation(1));
            obj.YawValueLabel.Text = {char(string(obj.YawValue))};
            obj.PitchValue = sprintf('%0.2f', obj.Mediator.Orientation(2));
            obj.PitchValueLabel.Text = {char(string(obj.PitchValue))};
            obj.RollValue = sprintf('%0.2f', obj.Mediator.Orientation(3));
            obj.RollValueLabel.Text = {char(string(obj.RollValue))};

            % Update speed data with sensitivity of 2 digits after
            % decimal point
            obj.XAxisSpeedValue = sprintf('%0.2f', obj.Mediator.Speed(1));
            obj.XAxisSpeedValueLabel.Text = {char(string(obj.XAxisSpeedValue))};
            obj.YAxisSpeedValue = sprintf('%0.2f', obj.Mediator.Speed(2));
            obj.YAxisSpeedValueLabel.Text = {char(string(obj.YAxisSpeedValue))};
            obj.ZAxisSpeedValue = sprintf('%0.2f', obj.Mediator.Speed(3));
            obj.ZAxisSpeedValueLabel.Text = {char(string(obj.ZAxisSpeedValue))};

            % Update height data
            obj.HeightValueLabel.Text = {char(string(obj.Mediator.Height))};
        end

        function updatePreFlightCheckIcon(obj)
            % Callback to update the PreFlight Check status and icon after
            % PreFlight Check is complete

            if obj.Mediator.preFlightCheckSuccessful
                obj.FlightCheckIcon.ImageSource = fullfile(obj.WorkingAreaIconPath,obj.FlightCheckSuccessIcon);
            else
                obj.FlightCheckIcon.ImageSource = fullfile(obj.WorkingAreaIconPath,obj.FlightCheckFailureIcon);
            end
            obj.FlightCheckTextLabel.Text = obj.AppMessages.preFlightCompleteText;
        end
    end
end