classdef GenerateScriptManager < telloapplet.HelperClass
    % GENERATESCRIPTMANAGER - Class that manages the script generation
    % workflow Ryze Tello Navigator app.

    % Copyright 2022 The MathWorks, Inc.

    properties(Hidden)
        % Mediator handle
        Mediator

        % App message texts
        AppMessages

        % Handle to device info
        DeviceInfo

        % Utility class used for script generation.
        ScriptGeneratorHelper

        % Additional parameters required to generate the script.
        CommandLog = strings([1,3])
        NavigationDistance = 0.2
        TurnAngle = pi/2
        NavigationSpeed = 0.1

        % Image variable name
        CurrentImageVarName
        ImageVarNamePrefix = "img"
        ImageVarNameSuffix = 0

        % Workspace variable name to save recorded data and duration to
        % record
        WorkspaceVarName
        Duration

        % Variable names referenced in the script that should be cleared.
        VarsToBeCleared = {}
        RecordCustomNames = {}

        % Variable to track and close the the try/catch block for
        % navigation commands
        TryAdded = false

    end

    properties (Constant, Access=private)
        % Object names in the generated script
        RyzeObjName = "ryzeObj"
        CameraObjName = "cameraObj"
    end

    methods
        function obj = GenerateScriptManager(mediator, deviceInfo, appMessages)
            % Call the superclass constructor.
            obj@telloapplet.HelperClass(mediator);

            obj.Mediator = mediator;
            obj.DeviceInfo = deviceInfo;
            obj.AppMessages = appMessages;

            % Construct the script generation utility object.
            obj.ScriptGeneratorHelper = telloapplet.HelperClass(mediator);

            obj.updateImageVarName();
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            % Function to subscribe to mediator events
            obj.subscribe('UserRequestedCodeGen', @(src, event)obj.generateScript());
            obj.subscribe('CurrentWorkspaceVarName', @(src, event)obj.handleWorkspaceVarEdit(event.AffectedObject.CurrentWorkspaceVarName));
            obj.subscribe('CurrentDuration', @(src, event)obj.handleDurationEdit(event.AffectedObject.CurrentDuration));

            obj.subscribe('NavigationDistanceValue', @(src, event)obj.updateNavigationDistance());
            obj.subscribe('NavigationTurnValue', @(src, event)obj.updateTurnAngle());
            obj.subscribe('NavigationSpeedValue', @(src, event)obj.updateNavigationSpeed());

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

            obj.subscribe('BatteryLow', @(src, event)obj.handleLand());
        end

        function generateScript(obj)
            % Generate script that replicates the results achieved in the
            % Ryze Tello Navigator app.

            % Generate title for the script.
            obj.generateTitle();

            % Generate introduction section.
            obj.generateIntro();

            % Generate Navigation Section.
            obj.generateInitializationCode();

            % Generate Navigation Section.
            obj.generateNavigationCode();

            % Generate code to clean up variables.
            obj.generateCleanUpCode();

            % Output the generated script into an MLX-file.
            obj.outputGeneratedScript();
        end
    end

    %% Callback functions for observable properties
    methods (Access=private)
        function updateNavigationDistance(obj)
            obj.NavigationDistance = obj.Mediator.NavigationDistanceValue;
        end

        function updateTurnAngle(obj)
            obj.TurnAngle = obj.Mediator.NavigationTurnValue;
        end

        function updateNavigationSpeed(obj)
            obj.NavigationSpeed = obj.Mediator.NavigationSpeedValue;
        end

        function handleTakeOff(obj)
            if isequal(obj.CommandLog,strings([1,3]))
                obj.CommandLog(1,1) = "takeoff";
            else
                obj.CommandLog(end+1,:) = ["takeoff","",""];
            end
        end

        function handleLand(obj)
            obj.CommandLog(end+1,:) = ["land","",""];
        end

        function handleAbort(obj)
            obj.CommandLog(end+1,:) = ["abort","",""];
        end

        function handleMoveLeft(obj)
            obj.CommandLog(end+1,:) = ["moveleft",string(obj.NavigationDistance),string(obj.NavigationSpeed)];
        end

        function handleMoveForward(obj)
            obj.CommandLog(end+1,:) = ["moveforward",string(obj.NavigationDistance),string(obj.NavigationSpeed)];
        end

        function handleMoveRight(obj)
            obj.CommandLog(end+1,:) = ["moveright",string(obj.NavigationDistance),string(obj.NavigationSpeed)];
        end

        function handleMoveBack(obj)
            obj.CommandLog(end+1,:) = ["moveback",string(obj.NavigationDistance),string(obj.NavigationSpeed)];
        end

        function handleMoveUp(obj)
            obj.CommandLog(end+1,:) = ["moveup",string(obj.NavigationDistance),string(obj.NavigationSpeed)];
        end

        function handleMoveDown(obj)
            obj.CommandLog(end+1,:) = ["movedown",string(obj.NavigationDistance),string(obj.NavigationSpeed)];
        end

        function handleTurnCCW(obj)
            turnAngle = obj.InterpretTurnValue(obj.TurnAngle);
            obj.CommandLog(end+1,:) = ["turn",("-" + turnAngle),""];
        end

        function handleTurnCW(obj)
            turnAngle = obj.InterpretTurnValue(obj.TurnAngle);
            obj.CommandLog(end+1,:) = ["turn",turnAngle,""];
        end

        function handleSnapshot(obj)
            if isequal(obj.CommandLog,strings([1,3]))
                obj.CommandLog(1,:) = ["snapshot",obj.CameraObjName,""];
            else
                obj.CommandLog(end+1,:) = ["snapshot",obj.CameraObjName,""];
            end
        end
    end

    methods(Access = private)
        function generateTitle(obj)
            % Generate title for the script.

            % Clear any text left behind in the utility object.
            obj.ScriptGeneratorHelper.clearText();

            scriptTitle = obj.AppMessages.scriptTitle + char(datetime);
            obj.ScriptGeneratorHelper.addSectionHeader(scriptTitle);

            obj.ScriptGeneratorHelper.addNewLine();
        end

        function generateIntro(obj)
            % Generate introduction section.

            sectionHeader = obj.AppMessages.introSectionHeader;
            obj.ScriptGeneratorHelper.addSectionHeader(sectionHeader);

            sectionComment = obj.AppMessages.introSectionComment;
            obj.ScriptGeneratorHelper.addComment(sectionComment);

            obj.ScriptGeneratorHelper.addNewLine();
        end

        function generateInitializationCode(obj)
            % Generate code for initializing drone and camera objects

            sectionHeader = obj.AppMessages.createRyzeObjectSectionHeader;
            obj.ScriptGeneratorHelper.addSectionHeader(sectionHeader);

            sectionComment = obj.AppMessages.createRyzeObjectSectionComment;
            obj.ScriptGeneratorHelper.addComment(sectionComment);

            codeLine = sprintf('%s = ryze("%s");', obj.RyzeObjName ,obj.DeviceInfo.DeviceID);

            obj.ScriptGeneratorHelper.addCodeLine(codeLine);

            obj.ScriptGeneratorHelper.addNewLine();

            codeLine = sprintf('%s = camera(%s);', obj.CameraObjName ,obj.RyzeObjName);

            obj.ScriptGeneratorHelper.addCodeLine(codeLine);

            obj.ScriptGeneratorHelper.addNewLine();

            % Add the channel object to the list of variables to be cleared at the end of the script.
            obj.VarsToBeCleared = [obj.VarsToBeCleared {obj.RyzeObjName, obj.CameraObjName}];

        end

        function generateNavigationCode(obj)
            % Generate equivalent code for app navigation actions

            sectionHeader = obj.AppMessages.navigationSectionHeader;
            obj.ScriptGeneratorHelper.addSectionHeader(sectionHeader);

            sectionComment = obj.AppMessages.navigationSectionComment;
            obj.ScriptGeneratorHelper.addComment(sectionComment);

            if strcmpi(obj.CommandLog(1,1),"")
                % No navigation commands yet executed
                return;
            end

            commandLogArrSize = size(obj.CommandLog);


            for idx = 1:commandLogArrSize(1)
                obj.ScriptGeneratorHelper.insertSpaces(4);
                switch obj.CommandLog(idx,1)
                    case "takeoff"
                        codeLine = "try";
                        obj.ScriptGeneratorHelper.addCodeLine(codeLine);
                        obj.ScriptGeneratorHelper.addNewLine();
                        obj.TryAdded = true;
                        codeLine = sprintf('%s(%s);', obj.CommandLog(idx,1),obj.RyzeObjName);
                    case "land"
                        codeLine = sprintf('%s(%s);', obj.CommandLog(idx,1),obj.RyzeObjName);
                    case "abort"
                        codeLine = sprintf('%s(%s);', obj.CommandLog(idx,1),obj.RyzeObjName);
                    case "turn"
                        codeLine = sprintf('%s(%s,%s);', obj.CommandLog(idx,1),obj.RyzeObjName,obj.CommandLog(idx,2));
                    case "snapshot"
                        codeLine = sprintf('%s = %s(%s);', obj.CurrentImageVarName,obj.CommandLog(idx,1),obj.CameraObjName);
                        obj.updateImageVarName();
                    otherwise
                        codeLine = sprintf('%s(%s, "Distance", %s,"Speed", %s, "WaitUntilDone",false);', ...
                            obj.CommandLog(idx,1),obj.RyzeObjName,obj.CommandLog(idx,2),obj.CommandLog(idx,2));
                end
                obj.ScriptGeneratorHelper.addCodeLine(codeLine);
            end

            % Close the try/catch block if TakeOff was executed earlier
            if obj.TryAdded 
                obj.ScriptGeneratorHelper.addNewLine()
                codeLine = "catch";
                obj.ScriptGeneratorHelper.addCodeLine(codeLine);
                obj.ScriptGeneratorHelper.addNewLine()
    
                obj.ScriptGeneratorHelper.insertSpaces(4);
                codeLine = sprintf('land(%s);',obj.RyzeObjName);
                obj.ScriptGeneratorHelper.addCodeLine(codeLine);
                obj.ScriptGeneratorHelper.addNewLine();
    
                codeLine = "end";
                obj.ScriptGeneratorHelper.addCodeLine(codeLine);
                obj.ScriptGeneratorHelper.addNewLine()
            end
        end

        function generateCleanUpCode(obj)
            % Generate code to clean up variables.

            sectionHeader = obj.AppMessages.cleanUpSectionHeader;
            obj.ScriptGeneratorHelper.addSectionHeader(sectionHeader);

            sectionComment = obj.AppMessages.cleanUpSectionComment;
            obj.ScriptGeneratorHelper.addComment(sectionComment);

            codeLine = sprintf('clear %s %s', obj.RyzeObjName, obj.CameraObjName);
            obj.ScriptGeneratorHelper.addCodeLine(codeLine);

            obj.ScriptGeneratorHelper.addNewLine();
        end

        function outputGeneratedScript(obj)
            % Output the generated script into an MLX-file.

            obj.ScriptGeneratorHelper.createMLXFile();
            obj.ScriptGeneratorHelper.clearText();
            obj.VarsToBeCleared = {};
            obj.RecordCustomNames = {};
        end

        function handleWorkspaceVarEdit(obj,value)
            obj.WorkspaceVarName = value;
        end

        function handleDurationEdit(obj,value)
            obj.Duration = value;
        end
    end

    methods(Access=private)
        function updateImageVarName(obj)
            % Update image variable names in the script
            [obj.CurrentImageVarName, obj.ImageVarNameSuffix] =...
                telloapplet.internal.Utility.getNextVarName(...
                obj.ImageVarNamePrefix, (obj.ImageVarNameSuffix+1));
        end

        function turnValue = InterpretTurnValue(~,inputTurnValue)
            % Function to interpret turn value and convert into a string

            switch inputTurnValue
                case pi/4
                    turnValue = "pi/4";
                case pi/2
                    turnValue = "pi/2";
                case 3*pi/4
                    turnValue = "3pi/4";
                case pi
                    turnValue = "pi";
            end
        end
    end

end
