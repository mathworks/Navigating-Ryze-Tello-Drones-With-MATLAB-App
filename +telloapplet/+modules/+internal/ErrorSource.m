classdef ErrorSource < handle
    % ERRORSOURCE - Any Ryze Tello Navigator app modules that could be a
    % source of error should inherit from this class. This class provides
    % the property 'ErrorObj' to which the 'Error Display Manager' module
    % is listening to.

    % Copyright 2022 The MathWorks, Inc.

    properties (SetObservable)
        % Property that stores error info and triggers showing error dialog
        ErrorObj
    end

    methods
        function setErrorObjProperty(obj, errObj)
            % Function to set error object
            obj.ErrorObj = errObj;
        end
    end
end