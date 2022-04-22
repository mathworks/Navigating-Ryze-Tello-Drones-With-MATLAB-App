classdef VideoPreviewManager < telloapplet.HelperClass
    % VIDEOPREVIEWMANAGER - Class that manages viewing camera feed on
    % Applet space

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % App message texts
        AppMessages

        % Video Preview area structure elements
        ParentGrid
        VideoPreviewPanel
        VideoPreviewGrid
        VideoPreviewAxes

        % Video Preview area dimensions based on navigation controls shown
        % or hidden
        ShowControlsPosition
        HideControlsPosition

        % Preview image handle
        PreviewImageHandle

        % Reference to Ryze Tello Manager for previewing
        RyzeTelloManager

        % Video resolution of the camera
        VideoResolution
    end

    properties(Access=private)
        % Video preview grid layout parameters
        RowHeight = {'1x'}
        ColumnWidth = {'1x'}
        RowSpacing = 0
        ColumnSpacing = 0
        padding = [0 0 0 0]
    end

    methods
        % Constructor
        function obj = VideoPreviewManager(mediator, parentGrid,...
                ryzeTelloManager, showControlsPosition, hideControlsPosition, ...
                appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.ParentGrid = parentGrid;
            obj.Mediator = mediator;
            obj.RyzeTelloManager = ryzeTelloManager;
            obj.ShowControlsPosition = showControlsPosition;
            obj.HideControlsPosition = hideControlsPosition;
            obj.AppMessages = appMessages;

            % Create video preview panel
            obj.VideoPreviewPanel = uipanel(obj.ParentGrid);
            obj.VideoPreviewPanel.Layout.Row = obj.ShowControlsPosition{1};
            obj.VideoPreviewPanel.Layout.Column = obj.ShowControlsPosition{2};

            % Get the camera resolution from mediator property
            resolution = split(obj.Mediator.ImageResolution, 'x');
            obj.VideoResolution = str2double(resolution);

            populateVideoPreview(obj);

            obj.RyzeTelloManager.updatePreviewImageHandle(obj.PreviewImageHandle);
            drawnow limitrate
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserClickedShowControls', @(src, event)obj.handleShowControls());
            obj.subscribe('UserClickedHideControls', @(src, event)obj.handleHideControls());
        end
    end

    methods (Access=private)
        function populateVideoPreview(obj)
            % Function to populate the Video Preview area

            obj.VideoPreviewGrid = uigridlayout(obj.VideoPreviewPanel,...
                'RowHeight',obj.RowHeight,...
                'ColumnWidth',obj.ColumnWidth,...
                'RowSpacing',obj.RowSpacing,...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'Padding',obj.padding,...
                'BackgroundColor','black');

            obj.VideoPreviewAxes = axes(obj.VideoPreviewGrid,...
                "XLim",[0 5],"XTick",[],"YTick",[],...
                "Color",'black');
            obj.VideoPreviewAxes.Layout.Row = 1;
            obj.VideoPreviewAxes.Layout.Column = 1;
            drawnow limitrate

            obj.PreviewImageHandle = image(obj.VideoPreviewAxes, ...
                zeros(obj.VideoResolution(1),obj.VideoResolution(2),3,'uint8'));

            setVideoFeedLimit(obj, obj.VideoResolution);

            obj.VideoPreviewAxes.Visible = 'off';
            obj.VideoPreviewAxes.Padding = 'compact';
            disableDefaultInteractivity(obj.VideoPreviewAxes);
            obj.VideoPreviewAxes.Interactions = [];
            axtoolbar(obj.VideoPreviewAxes, {});
        end

        function setVideoFeedLimit(obj, limits)
            % Set video preview limits based on resolution passed as limits

            set(obj.VideoPreviewAxes, 'XLim', [0 limits(1)]);
            set(obj.PreviewImageHandle, 'XData', [0.5 limits(1)-0.5]);
            set(obj.VideoPreviewAxes, 'YLim', [0 limits(2)]);
            set(obj.PreviewImageHandle, 'YData', [0.5 limits(2)-1]);
            set(obj.VideoPreviewAxes, 'DataAspectRatio', [1 1 1])
        end
    end

    methods(Access=private)
        function handleShowControls(obj)
            % Resize Video Preview area when navigation controls are shown

            obj.VideoPreviewPanel.Layout.Row = obj.ShowControlsPosition{1};
            obj.VideoPreviewPanel.Layout.Column = obj.ShowControlsPosition{2};
        end

        function handleHideControls(obj)
            % Resize Video Preview area when navigation controls are hidden

            obj.VideoPreviewPanel.Layout.Row = obj.HideControlsPosition{1};
            obj.VideoPreviewPanel.Layout.Column = obj.HideControlsPosition{2};
        end
    end

end