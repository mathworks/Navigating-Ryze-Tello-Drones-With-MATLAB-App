classdef ErrorDialogManager < telloapplet.HelperClass
    % ERRORDISPLAYMANAGER - Module that is responsible for displaying the
    % Error dialogs within the Ryze Tello Navigator app

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=private)
        % errordlg object and position
        ErrorDlg
        ErrorDlgPosition
        AppMessages
    end

    properties(Access=private,Constant)
        % Error dialog dimensions
        DialogLeftPosition = 500
        DialogBottomPosition = 300
    end

    methods
        function obj = ErrorDialogManager(mediator, appMessages)
            % Call the superclass constructors
            obj@telloapplet.HelperClass(mediator);

            obj.AppMessages = appMessages;
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('ErrorObj', @(src, event)obj.showErrorDialog(event.AffectedObject.ErrorObj));
        end
    end

    methods(Access=private)
        function showErrorDialog(obj, errObj)
            % Function to show error dialog
            errorInfo.Title = obj.AppMessages.errorDlgTitle;
            errorInfo.Message = telloapplet.internal.Utility.removeHyperlinks(errObj.message);
            errorInfo.Message = errObj.message;
            obj.calculateErrorDlgPosition();
            obj.ErrorDlg = errordlg(errorInfo.Message,errorInfo.Title,obj.ErrorDlgPosition);
        end
    end

    methods(Access=private)
        function calculateErrorDlgPosition(obj)
            % Function to calculate error dialog position
            screenSize = get(groot,'ScreenSize');
            left = (screenSize(3) - obj.DialogLeftPosition)/2;
            bottom = (screenSize(4) - obj.DialogBottomPosition)/2;
            obj.ErrorDlgPosition = [left bottom obj.DialogLeftPosition obj.DialogBottomPosition];
        end
    end
end
