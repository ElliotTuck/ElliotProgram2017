function data = E200_load_data(pathstr, varargin)
% E200_LOAD_DATA  Convert original, binary data into a new file format and load 
% into memory
%   DATA = E200_LOAD_DATA(FILENAME) converts FILENAME 
%   into the new file format and loads it into memory.
% 
% Inputs:
%	FILENAME:	Relative or absolute location of
%               a directory, scan, or filenames.mat file
%
% Outputs:
%	DATA:		E200 data structure


	% Get valid parts of filename to use
	if nargin > 1
		expstr = varargin{1};
	else
		expstr = 'E200';
	end
	[dir_beg, dir_mid, filename, data_source_type] = ...
        get_valid_filename(pathstr, expstr);
	
	% Full path to file to load
	loadpath = fullfile(dir_beg, dir_mid, filename);

	% Split filename into root, extension
	[~, filename_rt, filename_ext] = fileparts(filename);
	filename_final = [filename_rt '_processed' filename_ext];

	% Processed file info
    % NOTE: looks like filesep could be used here to eliminate some code
	processed_file_dir = fullfile(dir_beg, dir_mid);
    if isunix
        processed_file_dir = regexprep(processed_file_dir, ...
            'nas/nas-li20-pm0.', 'processed_data');
    elseif ispc
       	processed_file_dir = regexprep(processed_file_dir, ...
            'nas\\nas-li20-pm0.', 'processed_data');
    else
        error('Some new computer; good luck.');
    end

	processed_file_path = fullfile(processed_file_dir, filename_final);

	% Get the hostname of the computer.
	isfs20_bool = isfs20();
	
	% Run certain things depending on which machine you're on.
	% facet-srv20 gets special treatment: no files saved!
	exist_type = exist(processed_file_path);
	already_exists = (exist_type == 2 || exist_type == 7);
    switch data_source_type
        case '2015'
            if isfs20_bool
                % data = E200_gather_data(loadpath);
                load(loadpath)
            else
                % if the file doesn't exist, create it.
                if already_exists
                    load(processed_file_path);
                    fullpath = regexprep(dir_mid, 'nas.nas-li20-pm0.', ...
                        'processed_data');
                    [~, file_id] = strtok(fullpath, expstr);
                    data.VersionInfo.originalpath = ['processed_data/' file_id];
                    return;
                else
                    load(loadpath);
                    % Path to save final mat files
                    savepath = fullfile(processed_file_dir, [filename_rt ...
                        '_processed_files']);
                    data = E200_convert_images(data, savepath);
                end
                % info that this comes from a HDD
                data.VersionInfo.remotefiles.dat = true;
                data.VersionInfo.remotefiles.comment = ['Indicates whether ' ...
                    'files are stored on a remote disk ' ...
                    '(and getpref(''FACET_data'',''prefix'') should be used.'];
                data.VersionInfo.originalfilename = filename_final;
                fullpath = regexprep(dir_mid, 'nas.nas-li20-pm0.', ...
                    'processed_data');
                [~, file_id] = strtok(fullpath, expstr);
                data.VersionInfo.originalpath = ['processed_data/' file_id];
                data.VersionInfo.loadrequest = pathstr;           
                data = save_data(data,processed_file_path, false);
            end
        case '2014'
            if isfs20_bool
                % data = E200_gather_data(loadpath);
                load(loadpath)
            else
                % if the file doesn't exist, create it.
                if already_exists
                    load(processed_file_path);
                    fullpath = regexprep(dir_mid, 'nas.nas-li20-pm0.', ...
                        'processed_data');
                    [~, file_id] = strtok(fullpath, expstr);
                    data.VersionInfo.originalpath = ['processed_data/' file_id];
                    return;
                else
                    load(loadpath);
                    % path to save final mat files
                    savepath = fullfile(processed_file_dir, [filename_rt ...
                        '_processed_files']);
                    data = E200_convert_images(data, savepath);
                    % info that this comes from a HDD
                    data.VersionInfo.remotefiles.dat = true;
                    data.VersionInfo.remotefiles.comment = ...
                        ['Indicates whether files are stored on a remote ' ...
                        'disk (and getpref(''FACET_data'',''prefix'')) ' ...
                        'should be used.'];
                    data.VersionInfo.originalfilename = filename_final;
                    fullpath = regexprep(dir_mid, 'nas.nas-li20-pm0.', ...
                        'processed_data');
                    [~, file_id] = strtok(fullpath, expstr);
                    data.VersionInfo.originalpath = ['processed_data/' file_id];
                    data.VersionInfo.loadrequest = pathstr;           
                    % REMOVED: (temporary) data = save_data_2014(data, processed_file_path, false);
                end
            end         	
        case '2013'
            if isfs20_bool
                data = E200_gather_data_2013(loadpath);
            else
                % if the file doesn't exist, create it.
                if already_exists
                    load(processed_file_path);
                    fullpath = regexprep(dir_mid, 'nas.nas-li20-pm0.', ...
                        'processed_data');
                    [~, file_id] = strtok(fullpath, expstr);
                    data.VersionInfo.originalpath = ['processed_data/' file_id];
                    return;
                else
                    % path to save final mat files
                    savepath = fullfile(processed_file_dir, [filename_rt ...
                        '_processed_files']);
                    data = E200_gather_data_2013(loadpath);
                    data = E200_convert_images(data, savepath);
                end
            end

            % info that this comes from a HDD
            data.VersionInfo.remotefiles.dat = true;
            data.VersionInfo.remotefiles.comment = ['Indicates whether ' ...
                'files are stored on a remote disk ' ...
                '(and getpref(''FACET_data'',''prefix'') should be used.'];
            data.VersionInfo.originalfilename = filename_final;
            fullpath = regexprep(dir_mid, 'nas.nas-li20-pm0.', ...
                'processed_data');
            [~, file_id] = strtok(fullpath, expstr);
            data.VersionInfo.originalpath = ['processed_data/' file_id];
            data.VersionInfo.loadrequest = pathstr;

            if ~isfs20_bool && ~already_exists
                data = save_data(data,processed_file_path,false);
            end
        otherwise
            error('Shouldn''t get here!!!');
    end
end
