classdef CommandLogManager < telloapplet.HelperClass
    % COMMANDLOGMANAGER - Class that manages logging commands in the
    % command log table

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % App message texts
        AppMessages

        % Parent Grid for the pin table area
        ParentGrid

        % Command log placement
        CommandLogPanel
        CommandLogInnerGrid
        CommandLogTable
        CommandLogUI

        % Navigation parameters
        NavigationDistance = 0.2
        NavigationTurnAngle = pi/2


    end

    properties(Access = private, Constant)
        % Pre-defined table size for logging commands
        CommandLogTableSize = [1 3]
        % Pre-defined variable types for command log table
        CommandLogTablevarTypes = {'datetime','string','string'}

        % Column widths of the Command Log table
        UITableColumnWidth = {'4x','3x','3x'}
    end

    methods
        % Constructor
        function obj = CommandLogManager(mediator, parentGrid, position, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.ParentGrid = parentGrid;
            obj.Mediator = mediator;
            obj.AppMessages = appMessages;

            % Create pin table area table and position it in the grid
            % Create pin table panel
            obj.CommandLogPanel = uipanel(obj.ParentGrid,"BorderType","none");
            obj.CommandLogPanel.Layout.Row = position{1};
            obj.CommandLogPanel.Layout.Column = position{2};

            % Create and place command logging table in Applet space
            createCommandLog(obj);
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events

            % Drone navigation related callbacks
            obj.subscribe('DroneExecutedTakeOff', @(src, event)obj.handleTakeOff());
            obj.subscribe('DroneExecutedLand', @(src, event)obj.handleLand());
            obj.subscribe('DroneExecutedAbort', @(src, event)obj.handleAbort());

            obj.subscribe('DroneExecutedMoveLeft', @(src, event)obj.handleMoveLeft());
            obj.subscribe('DroneExecutedMoveRight', @(src, event)obj.handleMoveRight());
            obj.subscribe('DroneExecutedMoveForward', @(src, event)obj.handleMoveForward());
            obj.subscribe('DroneExecutedMoveBack', @(src, event)obj.handleMoveBack());
            obj.subscribe('DroneExecutedMoveUp', @(src, event)obj.handleMoveUp());
            obj.subscribe('DroneExecutedMoveDown', @(src, event)obj.handleMoveDown());
            obj.subscribe('DroneExecutedTurnCCW', @(src, event)obj.handleTurnCCW());
            obj.subscribe('DroneExecutedTurnCW', @(src, event)obj.handleTurnCW());
            obj.subscribe('DroneExecutedSnapshot', @(src, event)obj.handleSnapshot());

            % Callbacks to update navigation distance and turn angle based
            % on ConfigureSettings module's variables
            obj.subscribe('NavigationDistanceValue', @(src, event)obj.updateNavigationDistance());
            obj.subscribe('NavigationTurnValue', @(src, event)obj.updateTurnAngle());

        end
    end

    methods (Access=private)
        function createCommandLog(obj)
            % Create and place command logging table in Applet space
            obj.CommandLogInnerGrid = uigridlayout(obj.CommandLogPanel,...
                'RowHeight',{'1x'},"ColumnWidth",{'1x'},...
                'RowSpacing',0,'ColumnSpacing',0,...
                'Padding',[0 0 0 0]);

            obj.CommandLogTable = [];

            obj.CommandLogUI = uitable(obj.CommandLogInnerGrid,...
                "ColumnWidth",obj.UITableColumnWidth,...
                'ColumnEditable',false,"SelectionType","row",...
                "ColumnName",...
                {obj.AppMessages.commandLogTimeColumn,...
                obj.AppMessages.commandLogCommandColumn,...
                obj.AppMessages.commandLogValueColumn});
            obj.CommandLogUI.Layout.Row = 1;
            obj.CommandLogUI.Layout.Column = [1 3];
            drawnow limitrate
            tableStyle = uistyle('HorizontalAlignment','left');
            addStyle(obj.CommandLogUI,tableStyle);
            drawnow limitrate
        end
    end

    % Methods to observable property callbacks
    methods (Access=private)
        function updateNavigationDistance(obj)
            % Update move distance depending on change in ConfigureSettings
            % module
            obj.NavigationDistance = obj.Mediator.NavigationDistanceValue;
        end

        function updateTurnAngle(obj)
            % Update turn angle depending on change in ConfigureSettings
            % module
            obj.NavigationTurnAngle = obj.Mediator.NavigationTurnAngle;
        end

        function handleTakeOff(obj)
            if isempty(obj.CommandLogTable)
                % Handle command logging when take-off is the first command
                % in the table
                obj.CommandLogTable = table('Size',obj.CommandLogTableSize,...
                    'VariableTypes',obj.CommandLogTablevarTypes);

                obj.CommandLogTable(1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                    "takeoff",""};
            else
                obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                    "takeoff",""};
            end
            obj.updateCommandLogUI();
        end

        function handleLand(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "land",""};
            obj.updateCommandLogUI();
        end

        function handleAbort(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "abort",""};
            obj.updateCommandLogUI();
        end

        function handleMoveLeft(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "moveleft",string(obj.NavigationDistance)};
            obj.updateCommandLogUI();
        end

        function handleMoveForward(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "moveforward",string(obj.NavigationDistance)};
            obj.updateCommandLogUI();
        end

        function handleMoveRight(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "moveright",string(obj.NavigationDistance)};
            obj.updateCommandLogUI();
        end

        function handleMoveBack(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "moveback",string(obj.NavigationDistance)};
            obj.updateCommandLogUI();
        end

        function handleMoveUp(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "moveup",string(obj.NavigationDistance)};
            obj.updateCommandLogUI();
        end

        function handleMoveDown(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "movedown",string(obj.NavigationDistance)};
            obj.updateCommandLogUI();
        end

        function handleTurnCCW(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "turn",...
                telloapplet.internal.Utility.interpretTurnValue(obj.Mediator.NavigationTurnAngle)};
            obj.updateCommandLogUI();
        end

        function handleTurnCW(obj)
            obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                "turn",("-" + ...
                telloapplet.internal.Utility.interpretTurnValue(obj.Mediator.NavigationTurnAngle))};
            obj.updateCommandLogUI();
        end

        function handleSnapshot(obj)
            if isempty(obj.CommandLogTable)
                % Handle command logging when snapshot is the first command
                % in the table
                obj.CommandLogTable = table('Size',obj.CommandLogTableSize,...
                    'VariableTypes',obj.CommandLogTablevarTypes);

                obj.CommandLogTable(1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                    "snapshot",""};
            else
                obj.CommandLogTable(end+1,:) = {datetime('now','Format','dd/MM/uuuu HH:mm:ss'),...
                    "snapshot",""};
            end
            obj.updateCommandLogUI();
        end

        function updateCommandLogUI(obj)
            % Update the command log table UO to reflect the new entry
            obj.CommandLogUI.Data = obj.CommandLogTable;
            scroll(obj.CommandLogUI,'bottom');
            drawnow limitrate
        end
    end
end