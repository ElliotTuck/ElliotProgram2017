% READ
% This is an edited version of load_noiseless_images to be compatible with
% ImgTestGui and related code. 
% load_noiseless_images
% This script loads the jth image of ith stack and it is such a common block
% in all programs that I am saving this as a script, 
% I have removed this from the moviemaker script.
function set_app_data = load_noiseless_images_15_edited(curr_image, app_data, set_app_data)
    background_checked = app_data.background_checked;
    skip_background_verification = app_data.skip_background_verification;
    prefix = app_data.prefix;
    image_struc = app_data.image_struc;
    bend_struc = app_data.bend_struc;
    date_str = app_data.date_str;
    linearize = app_data.linearize;
    load_linearize_ROI = app_data.load_linearize_ROI;
    scale_adjustment = app_data.scale_adjustment;
    DC_offset = app_data.DC_offset;
    show_noise_sample = app_data.show_noise_sample;
    remove_xrays = app_data.remove_xrays;
    camera = app_data.camera;
    data = app_data.data;

    if(linearize && load_linearize_ROI)
        background_checked = 0;
    end

    if ~background_checked
        % TODO: Check that this code works with a QS-scan like DAQ
        bkgrndstr = fullfile(prefix, image_struc.background_dat{curr_image});
        % note: in 2014, backgrounds were saved as mat
        assert(strcmp(image_struc.background_format(1), 'mat'), ...
            'unexpected background format')
        background = load(bkgrndstr);
        noise = background.img;
        set_app_data.noise = noise;

        original_size = size(noise);
        original_vertsize = original_size(1);
        original_horizsize = original_size(2);

        switch camera.noise_region
            case 'top'
                sample_vector = [1, camera.sample_vert_width, 1, ...
                    camera.sample_horiz_width];
                set_app_data.sample_vector = sample_vector;
            case 'bottom'
                sample_vector = [original_vertsize - camera.sample_vert_width, ...
                    original_vertsize, original_horizsize - ...
                    camera.sample_horiz_width, original_horizsize];
                set_app_data.sample_vector = sample_vector;
            otherwise
                error('haven''t written this part yet')
        end

        if ~skip_background_verification
            % check noise is really just noise
            figure(1)
            imagesc(noise)
            if show_noise_sample
                rectangle('Position', sample_vector([3 1 4 2]), 'EdgeColor', ...
                    'w', 'LineWidth', 3, 'LineStyle', '-');
            end
            if exist('draw_ROI', 'var')
                rectangle('Position', draw_ROI, 'LineWidth', 2, 'LineStyle', '--');
            end
            set(gca, 'CLim', [100, 500]);
            acceptable_noise = questdlg('Is this noise acceptable?', ...
                'Background Noise');
            switch acceptable_noise
                case 'Yes'
                    set_app_data.skip_background_verification = 1;
                case 'No'
                    background_saved_path = [outputdir 'background src/' ...
                        date_str '_' camera.name '.mat'];    
                    if exist(background_saved_path, 'file')
                        background_content = load(background_saved_path);
                        noise = background_content.img;
                        set_app_data.noise = noise;
                    else
                        error('noise is unacceptable. Program ends')
                    end
                    set_app_data.skip_background_verification = 1;
                otherwise
                    error('Noise is unacceptable. Program ends')
            end
            close(1)
        end

        X_ORIENT = image_struc.X_ORIENT(1);
        set_app_data.X_ORIENT = X_ORIENT;
        Y_ORIENT = image_struc.Y_ORIENT(1);
        set_app_data.Y_ORIENT = Y_ORIENT;

        % noise on CMOS_FAR is different than SYAG, so I made this flag explicit
        % here
        if strcmp(camera.name, 'CMOS_FAR')
            if X_ORIENT
                noise = fliplr(noise);
                set_app_data.noise = noise;
            end
            if Y_ORIENT
                noise = flipud(noise);
                set_app_data.noise = noise;
            end
        end

        if camera.rotate_noise
            noise = rot90(noise);
            set_app_data.noise = noise;
        end

        % The noise scaling happens with the original size of the noise, but the
        % cropped image is the one that is modified in the rest of the program
        original_noise = noise;
        set_app_data.original_noise = original_noise;
        if exist('draw_ROI', 'var')
            noise = imcrop(noise, draw_ROI);
            set_app_data.noise = noise;
        end

        image_size = size(noise);
        vertsize = image_size(1);
        horizsize = image_size(2);
        resolution = image_struc.RESOLUTION(1);
        set_app_data.image_size = image_size;
        set_app_data.vertsize = vertsize;
        set_app_data.horizsize = horizsize;
        set_app_data.resolution = resolution;

        if resolution == 4.65
            resolution = 8.81;
            warning(['Resolution was incorrectly set to 4.65um; using ' ...
                num2str(resolution) 'um instead.']);
        end

        % create the energy scale for the entire image, even parts that will be
        % hidden
        % This parameter might be useful for non-standard bends
        % data.raw.scalars.LI20_LGPS_3330_BDES.dat{1}
        %         [energy_ticks,energy_pixel,energy_calib_vector]=...
        %             cher_y_tick(camera,vertsize,1,vertsize,zero_Gev_px,...
        %             image_struc.RESOLUTION(1));
        if camera.energy_camera
            theta0 = 6e-3 * camera.dipole_bend;
            % adjust pixel location of initial energy to ROI (if needed)
            if (data.raw.images.(camera.name).ROI_Y(1) ~= camera.default_ROI_Y)
                camera.zero_Gev_px = camera.zero_Gev_px + camera.default_ROI_Y - ...
                   data.raw.images.(camera.name).ROI_Y(1);
            end
            if exist('draw_ROI','var')
                camera.zero_Gev_px = camera.zero_Gev_px - draw_ROI(2);
            end
            energy_calib_vector = get_energy_curve(camera.name, vertsize, ...
                camera.zero_Gev_px, resolution, theta0);
            set_app_data.energy_calib_vector = energy_calib_vector;
            if linearize
                % in linearizing the image, the pixel numbers of the image are
                % preserved
                [linear_energy_scale, linear_noise] = linearize_image(noise, ...
                    energy_calib_vector);
                [energy_ticks, energy_pixel] = cher_y_tick(camera.name, ...
                    vertsize, linear_energy_scale);
                set_app_data.energy_pixel = energy_pixel;
                set_app_data.energy_ticks = energy_ticks;
            else
                [energy_ticks, energy_pixel] = cher_y_tick(camera.name, ...
                    vertsize, energy_calib_vector);
                set_app_data.energy_pixel = energy_pixel;
                set_app_data.energy_ticks = energy_ticks;
            end    
        end

        % if this is not reset, the energy vector for the next bend will
        % not be produced
        if (~isfield(bend_struc, 'variable_bend') || ~bend_struc.variable_bend)
            set_app_data.background_checked = 1;
        end
    end

    X_ORIENT = image_struc.X_ORIENT(1);
    Y_ORIENT = image_struc.Y_ORIENT(1);

    % curr_image is the index that is used to load image instead of j, because
    % in a scan, all images are stacked into one single cell array (see
    % multi_box_image_extract script)

    loadstr = fullfile(prefix, image_struc.dat{curr_image});
    this_image = getProcessedImage(loadstr);
    if (isempty(this_image))
        % process the image
        this_image = imread(loadstr);
        image_UID = image_struc.UID(curr_image);

        if X_ORIENT
            this_image = fliplr(this_image);
        end
        if Y_ORIENT
            this_image = flipud(this_image);
        end

        % CMOS_far needed to be rotated to look "normal". On an individual
        % basis this should be determined and noise should be compensated
        if camera.rotate_image
            this_image = rot90(this_image);
        end

        original_image = this_image;
        if exist('draw_ROI', 'var')
            % TODO: only do analysis on the ROI. i.e. cut the noise, cut the image to
            % the ROI of the noise might not match the ROI of the image
            this_image = imcrop(this_image, draw_ROI);
        end

        % scale background and subtract. These variables are determined in the
        % load_camera_config script
        sample_vector = set_app_data.sample_vector;
        original_noise = set_app_data.original_noise;
        image_sample = sum(sum(original_image(sample_vector(1):sample_vector(2), ...
            sample_vector(3):sample_vector(4))));
        BG_sample = sum(sum(original_noise(sample_vector(1):sample_vector(2), ...
            sample_vector(3):sample_vector(4))));
        noise = set_app_data.noise;
        scale = image_sample / BG_sample;
        this_image = this_image - noise * scale * scale_adjustment;

        if remove_xrays
            this_image = RemoveXRays(this_image);
        end

        % removes DC offset in noise; defaults to noise sample if DC_sample not set
        if DC_offset
            if exist('DC_sample','var')
                this_image = this_image - ...
                    mean2(this_image(DC_sample(2):(DC_sample(4) + DC_sample(2)), ...
                    DC_sample(1):(DC_sample(3) + DC_sample(1))));
            else
                this_image = this_image - ...
                    mean2(this_image(sample_vector(1):sample_vector(2), ...
                    sample_vector(3):sample_vector(4)));
            end
        end

        if camera.energy_camera
            if linearize
                energy_calib_vector = getappdata(0, 'energy_calib_vector');
                [linear_energy_scale, this_image] = linearize_image(this_image, ...
                    energy_calib_vector);
                set_app_data.linear_energy_scale = linear_energy_scale;
            else
                this_image = double(this_image);
            end
        end

        set_app_data.this_image = this_image;

        % save the processed image in processed_data
        set_app_data = saveProcessedImage(curr_image, this_image, app_data, set_app_data);
    end

    % update current version of 'this_image'
    set_app_data.this_image = this_image;
end