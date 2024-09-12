%% ---------- Inputs ------------------------------------------------------

% Add all subfolders to path
addpath(genpath(fileparts(which(mfilename))))

% Image filepaths
C1_input_filepath = 'C1 Sample Photo IMG_4211.jpg';
C2_input_filepath = 'C2 Sample Photo IMG_4210.jpg';
C1_reference_filepath = 'C1 Downstream Reference IMG_7948.jpg';
C2_reference_filepath = 'C2 Downstream Reference IMG_7949.jpg';


%% ---------- Perform Image Alignment -------------------------------------

% Option 1: Align images by manually selecting known "Ground Control
% Points" (GCP) -- features that are stationary between the two photos

    % Required inputs:
    % registration_filetype -- '.png', '.jpg', etc.
    % selectMask            -- False
    % reference_photo_mask  -- []
    % unaligned_photo_mask  -- []
    % manualGCPFile         -- Text file containing a description of each
    %                          ground control point/feature to be used
    % reference_photo_GCP   -- ~
    % unaligned_photo_GCP   -- ~
    % 'DetectionMethod'     -- 'Manual'

% EXAMPLE (Uncomment to test):
% [I1_input_aligned, I1_registered_name] = stereoCam_alignImages(C1_reference_filepath, ...
%     C1_input_filepath, '.png', false, [], [], 'Sample GCP Point Names.txt', 'DetectionMethod', 'Manual');
% [I2_input_aligned, I2_registered_name] = stereoCam_alignImages(C2_reference_filepath, ...
%     C2_input_filepath, '.png', false, [], [], 'Sample GCP Point Names 2.txt', 'DetectionMethod', 'Manual');

% -------------------------------------------------------------------------

% Option 2: Align images by loading previously selected, known "Ground 
% Control Points" (GCP) -- features that are stationary between the two 
% photos

    % Required inputs:
    % registration_filetype -- '.png', '.jpg', etc.
    % selectMask            -- False
    % reference_photo_mask  -- []
    % unaligned_photo_mask  -- []
    % manualGCPFile         -- []
    % reference_photo_GCP   -- .mat file containing I1_selectedPoints
    %                          variable of reference photo's GCP
    % unaligned_photo_GCP   -- .mat file containing I1_selectedPoints
    %                          variable of unaligned photo's GCP
    % 'DetectionMethod'     -- 'Manual'

% EXAMPLE (Uncomment to test):
% [I1_input_aligned, I1_registered_name] = stereoCam_alignImages(C1_reference_filepath, ...
%     C1_input_filepath, '.png', false, [], [], [], 'EX C1 Downstream Reference IMG_7948_GCP.mat', ...
%     'EX C1 Sample Photo IMG_4211_GCP.mat', 'DetectionMethod', 'Manual');
% [I2_input_aligned, I2_registered_name] = stereoCam_alignImages(C2_reference_filepath, ...
%     C2_input_filepath, '.png', false, [], [], [], 'EX C2 Downstream Reference IMG_7949_GCP.mat', ...
%     'EX C2 Sample Photo IMG_4210_GCP.mat', 'DetectionMethod', 'Manual');

% -------------------------------------------------------------------------

% Option 3: Align images using an automatic feature detection method 

    % Required inputs:
    % registration_filetype -- '.png', '.jpg', etc.
    % selectMask            -- False
    % reference_photo_mask  -- ~
    % unaligned_photo_mask  -- ~
    % manualGCPFile         -- ~
    % reference_photo_GCP   -- ~
    % unaligned_photo_GCP   -- ~
    % 'DetectionMethod'     -- 'SIFT' (default), 'SURF', 'BRISK'

% EXAMPLE (Uncomment to test):
% [I1_input_aligned, I1_registered_name] = stereoCam_alignImages(C1_reference_filepath, ...
%     C1_input_filepath, '.png', false, 'DetectionMethod', 'SIFT');
% [I2_input_aligned, I2_registered_name] = stereoCam_alignImages(C2_reference_filepath, ...
%     C2_input_filepath, '.png', false, 'DetectionMethod', 'SIFT');

% -------------------------------------------------------------------------

% Option 4: Align images using an automatic feature detection method and
% remove the automatically detected features in a certain region by 
% selecting a mask

    % Required inputs:
    % registration_filetype -- '.png', '.jpg', etc.
    % selectMask            -- True
    % reference_photo_mask  -- ~
    % unaligned_photo_mask  -- ~
    % manualGCPFile         -- ~
    % reference_photo_GCP   -- ~
    % unaligned_photo_GCP   -- ~
    % 'DetectionMethod'     -- 'SIFT' (default), 'SURF', 'BRISK'

% EXAMPLE (Uncomment to test):
% [I1_input_aligned, I1_registered_name] = stereoCam_alignImages(C1_reference_filepath, ...
%     C1_input_filepath, '.png', true, 'DetectionMethod', 'SIFT');
% [I2_input_aligned, I2_registered_name] = stereoCam_alignImages(C2_reference_filepath, ...
%     C2_input_filepath, '.png', true, 'DetectionMethod', 'SIFT');

% -------------------------------------------------------------------------

% Option 5: Align images using an automatic feature detection method and
% remove the automatically detected features in a certain region using a
% previously selected polygon mask

    % Required inputs:
    % registration_filetype -- '.png', '.jpg', etc.
    % selectMask            -- False
    % reference_photo_mask  -- .mat file containing I1_maskedPoints
    %                          variable of reference photo's polygon 
    %                          mask's vertices
    % unaligned_photo_mask  -- .mat file containing I1_maskedPoints
    %                          variable of reference photo's polygon 
    %                          mask's vertices
    % manualGCPFile         -- ~
    % reference_photo_GCP   -- ~
    % unaligned_photo_GCP   -- ~
    % 'DetectionMethod'     -- 'SIFT' (default), 'SURF', 'BRISK'

% EXAMPLE (Uncomment to test):
% [I1_input_aligned, I1_registered_name] = stereoCam_alignImages(C1_reference_filepath, ...
%     C1_input_filepath, '.png', false, 'EX C1 Downstream Reference IMG_7948_mask.mat', ...
%     'EX C1 Sample Photo IMG_4211_mask.mat', 'DetectionMethod', 'SIFT');
% [I2_input_aligned, I2_registered_name] = stereoCam_alignImages(C2_reference_filepath, ...
%     C2_input_filepath, '.png', false, 'EX C2 Downstream Reference IMG_7949_mask.mat', ...
%     'EX C2 Sample Photo IMG_4210_mask.mat', 'DetectionMethod', 'SURF', ...
%     'SelectStrongest', 1);

% ------------------------------------------------------------------------

% The following settings were used to generate the example files:
% [I1_input_aligned, I1_registered_name] = stereoCam_alignImages(C1_reference_filepath, ...
%     C1_input_filepath, '.png', false, 'SelectStrongest', 0.4);
% [I2_input_aligned, I2_registered_name] = stereoCam_alignImages(C2_reference_filepath, ...
%     C2_input_filepath, '.png', false, 'SIFTContrastThreshold', 0.03, 'SelectStrongest', 0.5);

% Load the previously aligned example photos, comment to apply other 
% options/change the photographs used
I1_registered_name = 'EX C1 Sample Photo IMG_4211_registered.png';
I2_registered_name = 'EX C2 Sample Photo IMG_4210_registered.png';


%% ---------- Perform Stereo Calibration on Images ------------------------

[rawPoints3D, pointCloud_clean] = stereoCam_reconstructScene(I1_registered_name, ...
    I2_registered_name, [-100000 100000 -100000 100000 -100 50000]);