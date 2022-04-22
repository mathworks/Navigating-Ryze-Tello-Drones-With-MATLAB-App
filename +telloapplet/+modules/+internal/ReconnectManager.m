classdef ReconnectManager < telloapplet.HelperClass
    % RECONNECTMANAGER - Class that handles reconnection request

    % Copyright 2022 The MathWorks, Inc.
    properties(Access=private)
        % App message texts
        AppMessages

        % Reconnection dialog structure elements
        ParentFigurePosition
        ParentFigure
        ParentGrid
        ReconnectionGrid
        ButtonGrid

        % Reconnection text label
        ReconnectionTextLabel

        % Buttons in Reconnection dialog
        ReconnectButton
        CancelButton
        % Button listeners
        ReconnectButtonListener
        CancelButtonListener

        % Icon paths
        DroneIconPath
        ReconnectIcon
    end

    properties(Constant, Access=private)
        % Grid dimensions
        ParentGridRowHeight = {'1x','0.3x'}
        ParentGridColumnWidth = {'1x'}
        ReconnectionGridRowHeight = {'1x'}
        ReconnectionGridColumnWidth = {'0.3x','1x'}
        ButtonGridRowHeight = {'1x'}
        ButtonGridColumnWidth = {'1x','0.5x','0.5x'}
        ButtonGridPadding = [0 0 0 0]

        % Reconnection dialog position
        DialogLeftPosition = 400
        DialogBottomPosition = 150

        % Icon for Reconnection dialog
        ErrorIcon = 'Error_36.svg'
    end

    properties(SetObservable)
        % Notify Ryze Tello Manager to reconnect
        UserRequestedReconnect
        % Notify to destroy app when reconnection fails or user chooses to
        % cancel reconnection
        RequestToDestroyApp
    end

    methods
        % Constructor
        function obj = ReconnectManager(mediator, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.AppMessages = appMessages;

        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('ShowReconnectInputDialog', @(src, event)obj.handleReconnectInputRequest());
        end
    end

    methods(Access = private)
        function handleReconnectInputRequest(obj)
            % Function to show Reconnection dialog

            obj.createDialog();
            obj.populateDialog();
        end

        function handleReconnectButtonPushed(obj)
            % Function to handle Reconnection workflow

            % Make Reconnect and Cancel buttons disable and change the
            % dialog title to give a feedback to the user that Reconnection
            % is in progress
            obj.ReconnectButton.Enable = false;
            obj.CancelButton.Enable = false;
            obj.ParentFigure.Name = obj.AppMessages.reconnectionProgressTitle;

            % Notify RyzeTelloManager to reconnect
            obj.UserRequestedReconnect = true;

            % Close Reconnection dialog
            delete(obj.ParentFigure);
        end

        function handleCancelButtonPushed(obj)
            obj.closeDialog();
        end
    end

    methods(Access = private)
        function createDialog(obj)
            % Function to create Reconnection dialog

            % Create modal tab for reconnection
            % Determine screen position for the modal dialog
            screenSize = get(groot,'ScreenSize');
            left = (screenSize(3) - obj.DialogLeftPosition)/2;
            bottom = (screenSize(4) - obj.DialogBottomPosition)/2;

            obj.ParentFigurePosition = [left bottom obj.DialogLeftPosition obj.DialogBottomPosition];

            % Create modal figure
            obj.ParentFigure = uifigure("Position",obj.ParentFigurePosition,...
                "WindowStyle","modal","Resize","off", ...
                "Name",obj.AppMessages.reconnectionDialogTitle);

            obj.ParentGrid = uigridlayout(obj.ParentFigure,...
                "RowHeight",obj.ParentGridRowHeight, ...
                "ColumnWidth",obj.ParentGridColumnWidth);
        end

        function populateDialog(obj)
            % Function to populate Reconnection dialog
            resourcesLocation = telloapplet.internal.Utility.getResourcesLocation();
            obj.DroneIconPath = fullfile(resourcesLocation, 'workingarea');
            obj.populateTextLabel();
            obj.populateButtons();
            obj.addWidgetEventListeners();
        end

        function populateTextLabel(obj)
            % Function to populate Reconnection text label
            obj.ReconnectionGrid = uigridlayout(obj.ParentGrid,...
                "RowHeight",obj.ReconnectionGridRowHeight, ...
                "ColumnWidth",obj.ReconnectionGridColumnWidth);
            obj.ReconnectionGrid.Layout.Row = 1;
            obj.ReconnectionGrid.Layout.Column = 1;

            obj.ReconnectIcon = uiimage(obj.ReconnectionGrid, ...
                "ImageSource",fullfile(obj.DroneIconPath, obj.ErrorIcon));
            obj.ReconnectIcon.Layout.Row = 1;
            obj.ReconnectIcon.Layout.Column = 1;

            obj.ReconnectionTextLabel = uilabel(obj.ReconnectionGrid,...
                "Text",obj.AppMessages.reconnectLabelText);
            obj.ReconnectionTextLabel.Layout.Row = 1;
            obj.ReconnectionTextLabel.Layout.Column = 2;
        end

        function populateButtons(obj)
            % Function to populate Reconnect/Cancel buttons

            obj.ButtonGrid = uigridlayout(obj.ParentGrid,...
                "RowHeight",obj.ButtonGridRowHeight, ...
                "ColumnWidth",obj.ButtonGridColumnWidth, ...
                "Padding",obj.ButtonGridPadding);
            obj.ButtonGrid.Layout.Row = 2;
            obj.ButtonGrid.Layout.Column = 1;

            obj.ReconnectButton = uibutton(obj.ButtonGrid, ...
                "Text",obj.AppMessages.reconnectButtonText);
            obj.ReconnectButton.Layout.Row = 1;
            obj.ReconnectButton.Layout.Column = 2;

            obj.CancelButton = uibutton(obj.ButtonGrid, ...
                "Text",obj.AppMessages.cancelButtonText);
            obj.CancelButton.Layout.Row = 1;
            obj.CancelButton.Layout.Column = 3;
        end

        function closeDialog(obj)
            % Function to close Reconnection dialog and destroy the app if
            % user chooses to cancel reconnection
            delete(obj.ParentFigure);
            obj.RequestToDestroyApp = true;
        end

        function addWidgetEventListeners(obj)
            % All event listeners
            obj.ReconnectButtonListener = obj.ReconnectButton.listener('ButtonPushed',@(src,event)obj.handleReconnectButtonPushed());
            obj.CancelButtonListener = obj.CancelButton.listener('ButtonPushed',@(src,event)obj.handleCancelButtonPushed());
        end
    end
end