classdef WorkingAreaManager < telloapplet.HelperClass...
        & telloapplet.modules.internal.ErrorSource
    %  WOKRINGAREAMANAGER - Module that manages the components that resides
    %  in the Applet space or working area of the Ryze Tello Navigator app.

    %   This module manages the creation of the components that resides in
    %   the Applet space

    % Copyright 2022 The MathWorks, Inc.

    properties(Access = private)
        % Handle to the mediator module
        Mediator
        % App related message texts
        AppMessages
        % Handle to the app's root window
        RootWindow

        % Parent UI app grid
        ParentGrid

        % Drone object handle
        RyzeTelloManager

        % Manager modules for the working area sections for
        % video preview, navigation, sensor data, logging commands and
        % navigation using keyboard
        VideoPreviewManager
        SensorDataSectionManager
        NavigationSectionManager
        CommandLogManager
        KeyboardNavigationController
    end

    %% Constant properties used throughout the class
    properties(Constant, Access=private)

        % Applet space layout parameters
        RowHeight = {'1x','1x','1x','1x','1x','1x','1x','0.15x'}
        ColumnWidth = {'1x',5,'0.4x'}
        RowSpacing = 10
        ColumnSpacing = 5
        Padding = [10 2 10 10]

        % Widget placements
        VideoFeedPanelShowControlsPosition = {[1 5] ; 1}
        VideoFeedPanelHideControlsPosition = {[1 6] ; 1}
        SensorDataPanelPosition = {[1 4] ; 3}
        CommandLogPanelPosition = {[5 7] ; 3}
        NavigationalPanelShowControlsPosition = {[6 7] ; 1}
        NavigationalPanelHideControlsPosition = {7 ; 1}
    end

    %% Public methods
    methods
        % Constructor
        function obj = WorkingAreaManager(mediator,rootWindow, ...
                ryzeTelloManager, appMessages)
            % Call the superclass constructor
            obj@telloapplet.HelperClass(mediator);

            obj.Mediator = mediator;
            obj.RootWindow = rootWindow;
            obj.AppMessages = appMessages;

            obj.RyzeTelloManager = ryzeTelloManager;

            % Create ParentGrid- the uigridlayout that contains all components
            % of the applet space, including several
            % nested uigridlayouts.
            obj.ParentGrid = uigridlayout(obj.RootWindow,...
                'RowHeight',obj.RowHeight,...
                'ColumnWidth',obj.ColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing,...
                'Padding', obj.Padding);

            % Create and place widgets in the working area
            try

                obj.NavigationSectionManager = telloapplet.modules.internal.NavigationSectionManager(obj.Mediator,...
                    obj.ParentGrid, obj.NavigationalPanelShowControlsPosition,...
                    obj.NavigationalPanelHideControlsPosition, obj.AppMessages);

                obj.SensorDataSectionManager = telloapplet.modules.internal.SensorDataSectionManager(obj.Mediator,...
                    obj.ParentGrid, obj.SensorDataPanelPosition, obj.AppMessages);

                obj.CommandLogManager = telloapplet.modules.internal.CommandLogManager(obj.Mediator,...
                    obj.ParentGrid, obj.CommandLogPanelPosition, obj.AppMessages);
                drawnow limitrate

                obj.KeyboardNavigationController = telloapplet.modules.internal.KeyboardNavigationController(...
                    mediator, rootWindow, obj.AppMessages);

                obj.VideoPreviewManager = telloapplet.modules.internal.VideoPreviewManager(obj.Mediator,...
                    obj.ParentGrid, obj.RyzeTelloManager,...
                    obj.VideoFeedPanelShowControlsPosition,...
                    obj.VideoFeedPanelHideControlsPosition, obj.AppMessages);

            catch err
                obj.setErrorObjProperty(err);
            end
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserClickedViewPinout', @(src, event)obj.handlePinoutLaunch());
        end

        function delete(~)

        end
    end
end
