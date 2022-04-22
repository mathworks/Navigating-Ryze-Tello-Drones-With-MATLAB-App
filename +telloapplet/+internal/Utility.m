classdef Utility < handle
    % UTILITY - Utility class for the Ryze Tello Navigator app

    % Copyright 2022 The MathWorks, Inc.

    methods(Static)

        function resourcesLocation = getResourcesLocation()
            % Function to get the resource location for app icons
            [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
            appRootLocation = fullfile(pathstr, '..','..');
            resourcesLocation = fullfile(appRootLocation, 'resources');
        end

        function status = isVariablePresentInBaseWorkspace(variableName)
            % Function to determine if a variable name already exists
            % in the base workspace
            status = ismember(variableName, evalin('base','who'));
        end

        function status = isValidVariableName(variableName)
            % Function to determine if the selected variable name is valid
            status = isvarname(variableName);
        end

        function [varName, newVarSuffix] = getNextVarName(varNamePrefix,varNameSuffix)
            % Function to get the next variable name for recording and
            % image capture
            VarNameValid = false;
            while ~VarNameValid
                varName = varNamePrefix + num2str(varNameSuffix);
                if telloapplet.internal.Utility.isValidVariableName(varName) &&...
                        ~telloapplet.internal.Utility.isVariablePresentInBaseWorkspace(varName)
                    VarNameValid = true;
                    newVarSuffix = varNameSuffix;
                end
                varNameSuffix = varNameSuffix + 1;
            end
        end

        function output = removeHyperlinks(input)
            % Utility function to remove hyperlinks from error message
            output = regexprep(input,'</?a(|\s+[^>]+)>','');
        end

        function appMessages = getAppMessageTexts()
            % Function to get button texts and error message texts from the
            % XML file
            [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
            appMessages = readstruct(fullfile(pathstr, 'AppMessageTexts.xml'));
        end

        function turnValue = interpretTurnValue(inputTurnValue)
            % Function to interpret turn value and convert into a string

            switch inputTurnValue
                case pi/4
                    turnValue = "π/4";
                case pi/2
                    turnValue = "π/2";
                case 3*pi/4
                    turnValue = "3π/4";
                case pi
                    turnValue = "π";
            end
        end

    end
end
