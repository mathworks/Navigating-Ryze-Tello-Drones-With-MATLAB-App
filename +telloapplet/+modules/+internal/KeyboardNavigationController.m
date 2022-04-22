classdef KeyboardNavigationController < telloapplet.HelperClass

    % KEYBOARDNAVIGATIONCONTROLLER - Class that controls navigation using
    % keyboard keys

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % Mediator handle
        Mediator
        % App message texts
        AppMessages
        % Storing the root window figure handle
        RootWindowFigureHandle
        % Drone land state
        HasStateLanded
    end

    properties(SetObservable)
        % Properties to notify enabling/disabling widgets before take-off
        % and after landing the drone
        PrepareToTakeOff
        PostLandSettings

        % Property to notify disabling navigation buttons while navigation
        % using keyboard key is in progress
        UserRequestedNavigate

        % Properties to notify keyboard keypresses
        UserPressedSpaceForTakeOff
        UserPressedSpaceForLand
        UserPressedA
        UserPressedW
        UserPressedD
        UserPressedS
        UserPressedLeft
        UserPressedUp
        UserPressedRight
        UserPressedDown
    end

    methods
        % Constructor
        function obj = KeyboardNavigationController(mediator, rootWindowPanel, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            % Save references
            rootWindowGrid = rootWindowPanel.Parent;
            obj.RootWindowFigureHandle = rootWindowGrid.Parent;
            obj.Mediator = mediator;
            obj.AppMessages = appMessages;

            obj.enableKeyboardNavigation();

            obj.updateDronelandedState();

        end

        function subscribeToMediatorProperties(obj,~,~)
            % Function to subscribe to mediator events
            obj.subscribe('UserRequestedDisableKeyboard', @(src, event)obj.disableKeyboardNavigation());
            obj.subscribe('UserRequestedEnableKeyboard', @(src, event)obj.enableKeyboardNavigation());
            obj.subscribe('DroneStateLanded', @(src, event)obj.updateDronelandedState());
        end
    end

    methods (Access=private)
        function enableKeyboardNavigation(obj)
            % Provision to enable keyboard based navigation
            obj.RootWindowFigureHandle.KeyPressFcn = @obj.handleNavigationKeyPress;
        end

        function disableKeyboardNavigation(obj)
            % Provision to disable keyboard based navigation
            obj.RootWindowFigureHandle.KeyPressFcn = [];
        end

        function updateDronelandedState(obj)
            % Update drone landed state
            obj.HasStateLanded = obj.Mediator.DroneStateLanded;
        end

        function handleNavigationKeyPress(obj,~,keyData)
            % Callback for keyboard key presses

            % Detect and notify key press
            switch keyData.Key
                case 'space'
                    if obj.HasStateLanded
                        % Notify toolstrip manager to disable specific
                        % widgets before taking off
                        obj.PrepareToTakeOff = true;
                        % Notify RyeTelloManager to take-off the drone
                        obj.UserPressedSpaceForTakeOff = true;
                    else
                        % Notify RyeTelloManager to land the drone
                        obj.UserPressedSpaceForLand = true;
                        % Notify toolstrip manager to enable all
                        % widgets after landing
                        obj.PostLandSettings = true;
                    end
                case 'a'
                    % Notify NavigationManager to disable navigation
                    % buttons
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to move left
                    obj.UserPressedA = true;
                case 'w'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to move forward
                    obj.UserPressedW = true;
                case 'd'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to move right
                    obj.UserPressedD = true;
                case 's'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to move back
                    obj.UserPressedS = true;
                case 'leftarrow'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to turn counter clockwise
                    obj.UserPressedLeft = true;
                case 'uparrow'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to move up
                    obj.UserPressedUp = true;
                case 'rightarrow'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to turn clockwise
                    obj.UserPressedRight = true;
                case 'downarrow'
                    obj.UserRequestedNavigate = true;
                    % Notify RyeTelloManager to move down
                    obj.UserPressedDown = true;
            end
        end
    end

end