% Convenience script for deleting app data (except processed_data) that has 
% been set in the current session with setappdata().
%
% Author: Elliot Tuck
% Date: 20170808
function deleteAppData()
    % NOTE: storing app data in a variable before getting field names seems
    % to drastically boost performance - not sure why
    appdata = getappdata(0);
    names = fieldnames(appdata);
    for k = 1:length(names)
        if (~isequal(names{k}, 'processed_data'))
            rmappdata(0, names{k});
        end
    end
end