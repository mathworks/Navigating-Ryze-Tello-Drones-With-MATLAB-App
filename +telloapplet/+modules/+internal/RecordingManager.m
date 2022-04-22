classdef RecordingManager < telloapplet.HelperClass
    % RECORDINGMANAGER - Class that manages recording and storing video
    % data

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % App message texts
        AppMessages
        % Reference to RyzeTelloManager
        RyzeTelloManager

        % Recording variable name prefix and suffix
        RecordingVarNamePrefix = "recording"
        RecordingVarNameSuffix = 1
        % Recording duration, gets updated as per user input, default being
        % 10s
        RecordingDuration = 10

        % Flag to monitor while recording
        ContinueRecording = true
        % User input recording variable name
        UserRequestedVarName
    end

    properties(SetObservable)
        % Current recording variable name to show up
        CurrentRecordingVarName = "recording1"
        % Recording process completion notification
        RecordingCompleted
    end

    methods
        % Constructor
        function obj = RecordingManager(mediator, ryzeTelloManager, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            obj.Mediator = mediator;
            obj.RyzeTelloManager = ryzeTelloManager;
            obj.AppMessages = appMessages;
        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserInputRecordingVarName', @(src, event)obj.updateUserInputRecordingVarName());
            obj.subscribe('CurrentRecordingDuration', @(src, event)obj.updateRecordingDuration());
            obj.subscribe('UserRequestedStartRecording', @(src, event)obj.recordVideo());
            obj.subscribe('UserRequestedStopRecording', @(src, event)obj.stopRecording());
            obj.subscribe('RecordingError', @(src, event)obj.stopRecording());
        end
    end

    methods(Access=private)
        function updateUserInputRecordingVarName(obj)
            % Update recording variable name as per the user input
            obj.CurrentRecordingVarName = obj.Mediator.UserInputRecordingVarName;
            obj.RecordingVarNamePrefix = obj.CurrentRecordingVarName;
            obj.UserRequestedVarName = true;
        end

        function updateRecordingDuration(obj)
            obj.RecordingDuration = obj.Mediator.CurrentRecordingDuration;
        end

        function recordVideo(obj)
            % Function responsible for recording video

            % Flag to monitor while recording
            obj.ContinueRecording = true;
            idx = 1;
            t = tic;
            elapsedTime = toc(t);
            while obj.ContinueRecording &&...
                    elapsedTime < obj.RecordingDuration
                % Continue recording till the recording duration if there
                % is no indication to stop by ContinueRecording flag

                % Get frames from RyzeTelloManager and store
                image  = obj.RyzeTelloManager.getLatestFrame();
                if ~isempty(image)
                    frames(:,:,:,idx) = image;
                end
                idx = idx+1;
                elapsedTime = toc(t);
                % drawnow limitrate or pause was not giving way for other
                % drone functionalities
                drawnow
            end
            if telloapplet.internal.Utility.isVariablePresentInBaseWorkspace(obj.CurrentRecordingVarName)
                obj.updateRecordingVarName();
            end
            % Store captured frames in base MATLAB workspace
            assignin('base',obj.CurrentRecordingVarName,frames);
            obj.updateRecordingVarName();
            obj.RecordingCompleted = true;
        end

        function stopRecording(obj)
            % Function to stop recording when stop recording button is
            % pressed in the toolstrip
            obj.ContinueRecording = false;
        end
    end

    methods(Access = private)
        function updateRecordingVarName(obj)
            % Function to update recording variable name

            if obj.UserRequestedVarName
                obj.RecordingVarNameSuffix = 1;
                obj.UserRequestedVarName = false;
            end
            [obj.CurrentRecordingVarName, obj.RecordingVarNameSuffix] =...
                telloapplet.internal.Utility.getNextVarName(...
                obj.RecordingVarNamePrefix, obj.RecordingVarNameSuffix);
        end
    end
end