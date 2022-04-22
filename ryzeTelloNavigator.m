function ryzeTelloNavigator(varargin)
% Function to launch the Ryze Tello Navigator app.

% Copyright 2022 The MathWorks, Inc.

AppMessages = telloapplet.internal.Utility.getAppMessageTexts();

% Check for unsupported platform
if ~(ismac || ispc)
    error(AppMessages.unsupportedPlatform);
end

try
    % Check if the support package is installed
    fullpathToUtility = which('ryzelist');
    if isempty(fullpathToUtility)
        % Support package not installed
        error(AppMessages.spkgNotInstalled);
    else
        % Launch the ryzetellonavigator app
        telloapplet.LaunchRyzeTelloNavigator();
    end
catch e
    throwAsCaller(e);
end
end