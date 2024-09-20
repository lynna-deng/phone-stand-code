function [transI2_cropped, I2_registered_name] = stereoCam_alignImages(reference_photo, ...
    unaligned_photo, registration_filetype, useMask, reference_photo_mask, ...
    unaligned_photo_mask, manualGCPFile, reference_photo_GCP, ...
    unaligned_photo_GCP, options)

    % STEREOCAM_ALIGNIMAGES

    % PURPOSE: Function for aligning a citizen science photograph to a
    % calibrated reference photograph.

    % INPUTS: 
    %   reference_photo: Filepath of calibrated reference image
    %   unaligned_photo: Filepath of unaligned citizen science image
    %   registration_filetype: File extension for aligned image
    %   useMask: True if a mask is to be used, false if not

    % Additional optional inputs for photo feature detection
    %   reference_photo_mask: Filepath of .mat file containing previously
    %   selected mask for reference photo (optional input)
    %   unaligned_photo_mask: Filepath of .mat file containing previously
    %   selected mask for unaligned photo (optional input)
    %   manualGCPFile: Filepath of csv file containing descriptions of
    %   keypoints for manual selection (optional input)
    %   reference_photo_GCP: Filepath of .mat file containing previously
    %   selected GCP for reference photo (optional input)
    %   unaligned_photo_GCP: Filepath of .mat file containing previously
    %   selected GCP for unaligned photo (optional input)

    % Additional options inputs for photo feature detection
    %   DetectionMethod: Feature detection method; SIFT, SURF, BRISK and
    %   manual GCP selection currently supported
    %   SIFTContrastThreshold: Threshold for contrast of strongest SIFT
    %   features; increase for fewer features
    %   SURFMetricThreshold: Threshold for strongest SURF feautres;
    %   increase for fewer features 
    %   BRISKMinContrast: Minimum intensity difference for BRISK features;
    %   increase for fewer features
    %   BRISKMinquality: Minimum accepted quality of corners for BRISK
    %   features; increase for fewer features
    %   SelectStrongest: Proportion of detected features used; decrease for
    %   fewer features

    % OUTPUTS:
    %   transI2_cropped: Aligned image
    %   I2_registered_name: Aligned image's file name
    
    % Last modified: September 9, 2024

    % ---------- Argument validation --------------------------------------

    arguments
        reference_photo string
        unaligned_photo string
        registration_filetype string
        useMask logical
        reference_photo_mask string = []
        unaligned_photo_mask string = []
        manualGCPFile string = []
        reference_photo_GCP string = []
        unaligned_photo_GCP string = []
        options.DetectionMethod (1,:) char {mustBeMember(options.DetectionMethod,{'SIFT', 'SURF', 'BRISK', 'Manual'})} = 'SIFT'
        options.SIFTContrastThreshold double = 0.02
        options.SURFMetricThreshold double = 100
        options.BRISKMinContrast double = 0.5
        options.BRISKMinquality double = 0.2
        options.SelectStrongest double = 0.5
    end

    % ---------- Load and prepare images -------------------------------
    
    % Load images
    I1 = imread(reference_photo);
    I2 = imread(unaligned_photo);
    
    % Isolate filename
    [~, I1_filename, ~] = fileparts(reference_photo);
    [~, I2_filename, ~] = fileparts(unaligned_photo);
    
    % Convert to grayscale
    I1_gray = im2gray(I1);
    I2_gray = im2gray(I2);
    
    % ---------- Detect features ---------------------------------------
    if options.DetectionMethod == "SURF"
        
        % Detect SURF features across full images
        I1_keypoints = detectSURFFeatures(I1_gray, 'MetricThreshold', options.SURFMetricThreshold);
        I2_keypoints = detectSURFFeatures(I2_gray, 'MetricThreshold', options.SURFMetricThreshold);
    
    elseif options.DetectionMethod == "BRISK"

        % Detect BRISK features across full images
        I1_keypoints = detectBRISKFeatures(I1_gray, 'MinContrast', options.BRISKMinContrast, 'Minquality', options.BRISKMinquality);
        I2_keypoints = detectBRISKFeatures(I2_gray, 'MinContrast', options.BRISKMinContrast, 'Minquality', options.BRISKMinquality);
    
    elseif options.DetectionMethod == "Manual" && ~isempty(manualGCPFile) ...
        && isempty(reference_photo_GCP) && ~isempty(unaligned_photo_GCP)
        
        % Manually select only reference photo's GCP
        
        % Open txt file containing list of features
        manualGCPFileID = fopen(manualGCPFile, 'r');

        % Read in each line as a feature and add to a string array
        manualGCPFeatures = textscan(manualGCPFileID, '%s', 'Delimiter', '\n');
        manualGCPFeatures = manualGCPFeatures{1, 1};
        
        % Manually select keypoints across reference photo
        I1_keypoints = stereoCam_manualSelectKeypoints(I1, append(I1_filename, '_GCP'), manualGCPFeatures);

        % Load in input photo's GCP
        I2_GCP_file = load(unaligned_photo_GCP);
        I2_keypoints = I2_GCP_file.I1_selectedPoints;

    elseif options.DetectionMethod == "Manual" && ~isempty(manualGCPFile) ...
        && ~isempty(reference_photo_GCP) && isempty(unaligned_photo_GCP)

        % Manually select only input photo's GCP
        
        % Open txt file containing list of features
        manualGCPFileID = fopen(manualGCPFile, 'r');

        % Read in each line as a feature and add to a string array
        manualGCPFeatures = textscan(manualGCPFileID, '%s', 'Delimiter', '\n');
        manualGCPFeatures = manualGCPFeatures{1, 1};
        
        % Manually select keypoints across input photo
        I2_keypoints = stereoCam_manualSelectKeypoints(I2, append(I2_filename, '_GCP'), manualGCPFeatures);

        % Load in reference photo's GCP
        I1_GCP_file = load(reference_photo_GCP);
        I1_keypoints = I1_GCP_file.I1_selectedPoints;

    elseif options.DetectionMethod == "Manual" && ~isempty(reference_photo_GCP) ...
        && ~isempty(unaligned_photo_GCP)
        
        % Load previously selected GCP for both photos
        I1_GCP_file = load(reference_photo_GCP);
        I2_GCP_file = load(unaligned_photo_GCP);
        I1_keypoints = I1_GCP_file.I1_selectedPoints;
        I2_keypoints = I2_GCP_file.I1_selectedPoints;

    elseif options.DetectionMethod == "Manual" && ~isempty(manualGCPFile)
        
        % Manually select both photos' GCP

        % Open txt file containing list of features
        manualGCPFileID = fopen(manualGCPFile, 'r');

        % Read in each line as a feature and add to a string array
        manualGCPFeatures = textscan(manualGCPFileID, '%s', 'Delimiter', '\n');
        manualGCPFeatures = manualGCPFeatures{1, 1};

        % Manually select keypoints across full images
        I1_keypoints = stereoCam_manualSelectKeypoints(I1, append(I1_filename, '_GCP'), manualGCPFeatures);
        I2_keypoints = stereoCam_manualSelectKeypoints(I2, append(I2_filename, '_GCP'), manualGCPFeatures);
    
    else
                
        options.DetectionMethod = "SIFT";

        % Detect SIFT features across full images
        I1_keypoints = detectSIFTFeatures(I1_gray, 'ContrastThreshold', options.SIFTContrastThreshold);
        I2_keypoints = detectSIFTFeatures(I2_gray, 'ContrastThreshold', options.SIFTContrastThreshold);

    end
    
    % ---------- Select mask and remove features in mask ----------------------
    
    if ~isempty(reference_photo_mask) && ~isempty(unaligned_photo_mask)
        % Load previously selected mask points

        flag = 2;
        I1_maskPoints_file = load(reference_photo_mask);
        I2_maskPoints_file = load(unaligned_photo_mask);
        I1_maskPoints = I1_maskPoints_file.I1_maskedPoints;
        I2_maskPoints = I2_maskPoints_file.I1_maskedPoints;
    
        % Extract only keypoints outside mask
        inPolygon = inpolygon(I1_keypoints.Location(:, 1), I1_keypoints.Location(:, 2), ...
            I1_maskPoints(:, 1), I1_maskPoints(:, 2));
        I1_maskedkeypoints = I1_keypoints(~inPolygon);
    
        inPolygon = inpolygon(I2_keypoints.Location(:, 1), I2_keypoints.Location(:, 2), ...
            I2_maskPoints(:, 1), I2_maskPoints(:, 2));
        I2_maskedkeypoints = I2_keypoints(~inPolygon);

    elseif ~isempty(reference_photo_mask) && isempty(unaligned_photo_mask)
        % Reference photo mask provided, need to select input photo mask

        flag = 3;

        % Load previously selected mask points
        I1_maskPoints_file = load(reference_photo_mask);
        I1_maskPoints = I1_maskPoints_file.I1_maskedPoints;

        % Select input photo mask
        I2_maskPoints = stereoCam_manualSelectMask(I2, append(I2_filename, '_mask'), 100);
    
        % Extract only keypoints outside mask
        inPolygon = inpolygon(I1_keypoints.Location(:, 1), I1_keypoints.Location(:, 2), ...
            I1_maskPoints(:, 1), I1_maskPoints(:, 2));
        I1_maskedkeypoints = I1_keypoints(~inPolygon);
    
        inPolygon = inpolygon(I2_keypoints.Location(:, 1), I2_keypoints.Location(:, 2), ...
            I2_maskPoints(:, 1), I2_maskPoints(:, 2));
        I2_maskedkeypoints = I2_keypoints(~inPolygon);

    elseif isempty(reference_photo_mask) && ~isempty(unaligned_photo_mask)
        % Need to select reference photo mask, input photo mask provided

        flag = 4;

        % Load previously selected mask points
        I2_maskPoints_file = load(unaligned_photo_mask);
        I2_maskPoints = I2_maskPoints_file.I1_maskedPoints;

        % Select reference photo mask
        I1_maskPoints = stereoCam_manualSelectMask(I1, append(I1_filename, '_mask'), 100);
    
        % Extract only keypoints outside mask
        inPolygon = inpolygon(I1_keypoints.Location(:, 1), I1_keypoints.Location(:, 2), ...
            I1_maskPoints(:, 1), I1_maskPoints(:, 2));
        I1_maskedkeypoints = I1_keypoints(~inPolygon);
    
        inPolygon = inpolygon(I2_keypoints.Location(:, 1), I2_keypoints.Location(:, 2), ...
            I2_maskPoints(:, 1), I2_maskPoints(:, 2));
        I2_maskedkeypoints = I2_keypoints(~inPolygon);
        
    elseif useMask == true

        flag = 5;

        % Select I1 and I2 mask points
        I1_maskPoints = stereoCam_manualSelectMask(I1, append(I1_filename, '_mask'), 100);
        I2_maskPoints = stereoCam_manualSelectMask(I2, append(I2_filename, '_mask'), 100);

        % Extract only keypoints outside mask
        inPolygon = inpolygon(I1_keypoints.Location(:, 1), I1_keypoints.Location(:, 2), ...
            I1_maskPoints(:, 1), I1_maskPoints(:, 2));
        I1_maskedkeypoints = I1_keypoints(~inPolygon);

        inPolygon = inpolygon(I2_keypoints.Location(:, 1), I2_keypoints.Location(:, 2), ...
            I2_maskPoints(:, 1), I2_maskPoints(:, 2));
        I2_maskedkeypoints = I2_keypoints(~inPolygon);

    else

        flag = 6;

        % No masking
        I1_maskedkeypoints = I1_keypoints;
        I2_maskedkeypoints = I2_keypoints;

    end
    
    if options.DetectionMethod == "Manual"
        % ---------- Use all manual points to compute transformation ------
        I1_matchedPoints_inliers.Location = I1_keypoints;
        I2_matchedPoints_inliers.Location = I2_keypoints;

        % Estimate transformation
        tform = estgeotform2d(I2_matchedPoints_inliers.Location, I1_matchedPoints_inliers.Location, 'projective');
        [I2_transformedPoints(:, 1), I2_transformedPoints(:, 2)]  = transformPointsForward(tform, I2_matchedPoints_inliers.Location(:, 1), I2_matchedPoints_inliers.Location(:, 2));

    else
        % ---------- Use only features with highest contrast --------------
        I1_maskedkeypoints = selectStrongest(I1_maskedkeypoints, round(options.SelectStrongest*length(I1_maskedkeypoints)));
        I2_maskedkeypoints = selectStrongest(I2_maskedkeypoints, round(options.SelectStrongest*length(I2_maskedkeypoints)));
        

        % ---------- Initial feature match --------------------------------
    
        % Extract feature descriptors
        [I1_features, I1_maskedkeypoints] = extractFeatures(I1_gray, I1_maskedkeypoints);
        [I2_features, I2_maskedkeypoints] = extractFeatures(I2_gray, I2_maskedkeypoints);
        
        % Match features
        indexPairs = matchFeatures(I1_features, I2_features, 'Unique', true);
        
        % Retrieve matches
        I1_matchedPoints = I1_maskedkeypoints(indexPairs(:, 1), :);
        I2_matchedPoints = I2_maskedkeypoints(indexPairs(:, 2), :);
        
        
        % ---------- Compute inliers --------------------------------------
        
        % Estimation of fundamental matrix with RANSAC algorithm (for robust
        % estimation)
        [~, inliers] = estimateFundamentalMatrix(I1_matchedPoints.Location, I2_matchedPoints.Location, 'Method', 'RANSAC', 'NumTrials', 10000, 'DistanceThreshold', 0.1);
        
        % Extract inlier points based on RANSAC
        I1_matchedPoints_inliers = I1_matchedPoints(inliers, :);
        I2_matchedPoints_inliers = I2_matchedPoints(inliers, :);

        % ---------- Compute transformation based on inliers only -----------------
        % Estimate transformation
        tform = estgeotform2d(I2_matchedPoints_inliers, I1_matchedPoints_inliers, 'projective');
        [I2_transformedPoints(:, 1), I2_transformedPoints(:, 2)]  = transformPointsForward(tform, I2_matchedPoints_inliers.Location(:, 1), I2_matchedPoints_inliers.Location(:, 2));

    end
        
    % Apply transformation to second image to align it with first image
    I2_auto = imwarp(I2, tform);
    
    
    % ---------- Prepare for adding borders -----------------------------------
    
    % Calculate new "origin" (1, 1) and corners of transformed second 
    % image, check for rotations, as vertical images may not be read in as 
    % vertical
    if tform.A(1, 2) < 0 && tform.A(2, 1) > 0 && abs(tform.A(1, 2)) > abs(tform.A(1, 1)) ...
            && abs(tform.A(1, 2)) > abs(tform.A(2, 2)) && abs(tform.A(2, 1)) > abs(tform.A(1, 1)) ...
            && abs(tform.A(2, 1)) > abs(tform.A(2, 2))
        % 90 degree counterclockwise rotation was applied
        [transformed_topright(1,1), transformed_topright(1,2)] = transformPointsForward(tform, 1, 1);
        [transformed_bottomright(1,1), transformed_bottomright(1,2)] = transformPointsForward(tform, size(I2, 2), 1);
        [transformed_origin(1,1), transformed_origin(1,2)] = transformPointsForward(tform, 1, size(I2, 1));
        [transformed_bottomleft(1,1), transformed_bottomleft(1,2)] = transformPointsForward(tform, size(I2, 2), size(I2, 1));

    elseif tform.A(1, 1) < 0 && tform.A(2, 2) < 0 && abs(tform.A(1, 1)) > abs(tform.A(1, 2)) ...
            && abs(tform.A(1, 1)) > abs(tform.A(2, 1)) && abs(tform.A(2, 2)) > abs(tform.A(1, 2)) ...
            && abs(tform.A(2, 2)) > abs(tform.A(2, 1))
        % 180 degree counterclockwise rotation was applied
        [transformed_bottomright(1,1), transformed_bottomright(1,2)] = transformPointsForward(tform, 1, 1);
        [transformed_bottomleft(1,1), transformed_bottomleft(1,2)] = transformPointsForward(tform, size(I2, 2), 1);
        [transformed_topright(1,1), transformed_topright(1,2)] = transformPointsForward(tform, 1, size(I2, 1));
        [transformed_origin(1,1), transformed_origin(1,2)] = transformPointsForward(tform, size(I2, 2), size(I2, 1));

    elseif tform.A(1, 2) > 0 && tform.A(2, 1) < 0 && abs(tform.A(1, 2)) > abs(tform.A(1, 1)) ...
            && abs(tform.A(1, 2)) > abs(tform.A(2, 2)) && abs(tform.A(2, 1)) > abs(tform.A(1, 1)) ...
            && abs(tform.A(2, 1)) > abs(tform.A(2, 2))
        % 270 degree counterclockwise rotation was applied
        [transformed_bottomleft(1,1), transformed_bottomleft(1,2)] = transformPointsForward(tform, 1, 1);
        [transformed_origin(1,1), transformed_origin(1,2)] = transformPointsForward(tform, size(I2, 2), 1);
        [transformed_bottomright(1,1), transformed_bottomright(1,2)] = transformPointsForward(tform, 1, size(I2, 1));
        [transformed_topright(1,1), transformed_topright(1,2)] = transformPointsForward(tform, size(I2, 2), size(I2, 1));

    else
        % No rotation
        [transformed_origin(1,1), transformed_origin(1,2)] = transformPointsForward(tform, 1, 1);
        [transformed_topright(1,1), transformed_topright(1,2)] = transformPointsForward(tform, size(I2, 2), 1);
        [transformed_bottomleft(1,1), transformed_bottomleft(1,2)] = transformPointsForward(tform, 1, size(I2, 1));
        [transformed_bottomright(1,1), transformed_bottomright(1,2)] = transformPointsForward(tform, size(I2, 2), size(I2, 1));

    end

    transformed_origin = round(transformed_origin);
    transformed_topright = round(transformed_topright);
    transformed_bottomleft = round(transformed_bottomleft);
    
    % Create shifted x and y axes
    [num_rows, num_columns, ~] = size(I2_auto);
    
    if transformed_origin(1) < transformed_bottomleft(1)
        x_min = transformed_origin(1);
    else 
        x_min = transformed_bottomleft(1);
    end
    
    if transformed_origin(2) < transformed_topright(2)
        y_min = transformed_origin(2);
    else 
        y_min = transformed_topright(2);
    end
        
    I1_width = size(I1, 2);
    I1_height = size(I1, 1);

    I1_photo_xdata = 1:I1_width;
    I1_photo_ydata = 1:I1_height;

    trans_photo_xdata = x_min:num_columns + x_min;
    trans_photo_ydata = y_min:num_rows + y_min;
    
    
    % ---------- Add borders --------------------------------------------------
    
    % Adding borders of white around images such that they are the same size
    % and can be superimposed
     
    I1_padded = I1;
    transI2_padded = I2_auto;

    % figure();
    % imshow(I1_padded, 'XData', I1_photo_xdata, 'YData', I1_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    % legend({'I1 matchedPoints'})    
    % 
    % figure();
    % imshow(transI2_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'go');
    % legend({'I2 transformedPoints'})  
    
    % Left padding
    left_offset = trans_photo_xdata(1) - 1;
    left_border = abs(left_offset);
    
    if left_offset < 0
        % Transformed I2 bigger than I1, add left padding to I1
        I1_padded(:, 1 + left_border:end + left_border, :) = I1_padded;
        I1_padded(:, 1:left_border, :) = 0;

        I1_photo_xdata = [I1_photo_xdata(1) - left_border:I1_photo_xdata(1) - 1, I1_photo_xdata];
    
    elseif left_offset > 0
        % Transformed I1 bigger than I2, add left padding to I2
        transI2_padded(:, 1 + left_border:end + left_border, :) = transI2_padded;
        transI2_padded(:, 1:left_border, :) = 0;
    
        trans_photo_xdata = [trans_photo_xdata(1) - left_border:trans_photo_xdata(1) - 1, trans_photo_xdata];
    
    end
    
    % figure();
    % imshow(I1_padded, 'XData', I1_photo_xdata, 'YData', I1_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    % legend({'I1 matchedPoints'})    
    % 
    % figure();
    % imshow(transI2_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'go');
    % legend({'I2 transformedPoints'})  
    
    % Right padding
    right_offset = trans_photo_xdata(end) - 1;
    right_border = abs(right_offset - I1_width);
    
    if right_offset > I1_width
        % Transformed I2 bigger than I1, add right padding to I1
        I1_padded(:, end:end + right_border, :) = 0;

        I1_photo_xdata = [I1_photo_xdata, I1_photo_xdata(end) + 1:I1_photo_xdata(end) + 1 + right_border];
    
    elseif right_offset < I1_width
        % Transformed I1 bigger than I2, add right padding to I2
        transI2_padded(:, end:end + right_border, :) = 0;
    
        trans_photo_xdata = [trans_photo_xdata, trans_photo_xdata(end) + 1:trans_photo_xdata(end) + 1 + right_border];
    
    end
    
    % figure();
    % imshow(I1_padded, 'XData', I1_photo_xdata, 'YData', I1_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    % legend({'I1 matchedPoints'})    
    % 
    % figure();
    % imshow(transI2_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'go');
    % legend({'I2 transformedPoints'})  
    
    
    % Top padding
    top_offset = trans_photo_ydata(1) - 1;
    top_border = abs(top_offset);
    
    if top_offset < 0
        % Transformed I2 bigger than I1, add top padding to I1
        I1_padded(1 + top_border:end + top_border, :, :) = I1_padded;
        I1_padded(1:top_border, :, :) = 0;

        I1_photo_ydata = [I1_photo_ydata(1) - top_border:I1_photo_ydata(1) - 1, I1_photo_ydata];
    
    elseif top_offset > 0
        % Transformed I1 bigger than I2, add top padding to I2
        transI2_padded(1 + top_border:end + top_border, :, :) = transI2_padded;
        transI2_padded(1:top_border, :, :) = 0;
    
        trans_photo_ydata = [trans_photo_ydata(1) - top_border:trans_photo_ydata(1) - 1, trans_photo_ydata];
    
    end

    % figure();
    % imshow(I1_padded, 'XData', I1_photo_xdata, 'YData', I1_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    % legend({'I1 matchedPoints'})    
    % 
    % figure();
    % imshow(transI2_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    % axis on;
    % grid on;
    % hold on;
    % plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'go');
    % legend({'I2 transformedPoints'})  
    
    % Bottom padding
    bottom_offset = trans_photo_ydata(end) - 1;
    bottom_border = abs(bottom_offset - I1_height);
    
    if bottom_offset > I1_height
        % Transformed I2 bigger than I1, add bottom padding to I1
        I1_padded(end:end + bottom_border, :, :) = 0;

        I1_photo_ydata = [I1_photo_ydata, I1_photo_ydata(end) + 1:I1_photo_ydata(end) + 1 + bottom_border];
    
    elseif bottom_offset < I1_height
        % Transformed I1 bigger than I2, add bottom padding to I2
        transI2_padded(end:end + bottom_border, :, :) = 0;
    
        trans_photo_ydata = [trans_photo_ydata, trans_photo_ydata(end) + 1:trans_photo_ydata(end) + 1 + bottom_border];
    
    end

    figure();
    imshow(I1_padded, 'XData', I1_photo_xdata, 'YData', I1_photo_ydata);
    axis on;
    grid on;
    hold on;
    plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    legend({'I1 matchedPoints'})    

    figure();
    imshow(transI2_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    axis on;
    grid on;
    hold on;
    plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'go');
    legend({'I2 transformedPoints'})  
    
    
    % ---------- Crop transformed image ---------------------------------------
    
    % Crop padded transformed image so that it can be applied in
    % stereo-calibrated system
    
    transI2_cropped = transI2_padded(find(trans_photo_ydata == 1):find(trans_photo_ydata == 1) + I1_height - 1, find(trans_photo_xdata == 1):find(trans_photo_xdata == 1) + I1_width - 1, :);
    
    crop_photo_xdata = 1:I1_width;
    crop_photo_ydata = 1:I1_height;
    
    
    % ---------- Plot ---------------------------------------------------------
    
    % Superimpose the images as an anaglyph
    % The padded image 1 is shown in red
    % The padded and transformed image 2 is shown in cyan
    anaglyph_fig = figure();
    anaglyph = stereoAnaglyph(I1_padded, transI2_padded);
    imshow(anaglyph, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    axis on;
    grid on;
    hold on
    plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    hold on
    plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'gx');
    hold on
    title('Aligned Images, Full')
    hold on
    legend({'I1 selectedPoints', 'I2 transformedPoints'})
    plot([I1_matchedPoints_inliers.Location(:, 1) I2_transformedPoints(:, 1)]', ...
        [I1_matchedPoints_inliers.Location(:, 2) I2_transformedPoints(:, 2)]', 'Color', 'y', 'HandleVisibility', 'off');
    
    % The original image 1 is shown in red
    % The cropped, padded, and transformed image 2 is shown in cyan
    anaglyph_fig_2 = figure();
    anaglyph_2 = stereoAnaglyph(I1, transI2_cropped);
    imshow(anaglyph_2, 'XData', crop_photo_xdata, 'YData', crop_photo_ydata);
    axis on;
    grid on;
    hold on
    title('Aligned Images, Cropped to Usable Portion')
    hold on
    
    % Display the befores and afters of images 1 and 2
    indiv_fig = figure();
    subplot(2, 2, 1)
    imshow(I1);
    hold on
    plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    hold on
    if useMask == true || (~isempty(reference_photo_mask) && ~isempty(unaligned_photo_mask))
        plot(I1_maskPoints(:, 1), I1_maskPoints(:, 2), 'y.')
        hold on
        fill(I1_maskPoints(:, 1), I1_maskPoints(:, 2), 'y', 'FaceAlpha', 0.3, 'EdgeColor', 'y')
    end
    title('Original Image 1')
    axis on;
    
    subplot(2, 2, 2)
    imshow(I2);
    hold on
    plot(I2_matchedPoints_inliers.Location(:, 1), I2_matchedPoints_inliers.Location(:, 2), 'ro');
    hold on
    if useMask == true || (~isempty(reference_photo_mask) && ~isempty(unaligned_photo_mask))
        plot(I2_maskPoints(:, 1), I2_maskPoints(:, 2), 'y.')
        hold on
        fill(I2_maskPoints(:, 1), I2_maskPoints(:, 2), 'y', 'FaceAlpha', 0.3, 'EdgeColor', 'y')
    end
    title('Original Image 2')
    axis on;
    
    subplot(2, 2, 3)
    imshow(I1_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    hold on
    plot(I1_matchedPoints_inliers.Location(:, 1), I1_matchedPoints_inliers.Location(:, 2), 'ro');
    title('Shifted Image 1')
    axis on;
    
    subplot(2, 2, 4)
    imshow(transI2_padded, 'XData', trans_photo_xdata, 'YData', trans_photo_ydata);
    hold on
    plot(I2_transformedPoints(:, 1), I2_transformedPoints(:, 2), 'ro');
    title('Shifted and Transformed Image 2')
    axis on;
    
    
    % ---------- Save images --------------------------------------------------
    
    [~, I2_filename, ~] = fileparts(unaligned_photo);
    I2_registered_name = append(fileparts(which(mfilename)), '\', I2_filename, '_registered', registration_filetype);
    
    imwrite(transI2_cropped, I2_registered_name);

end 