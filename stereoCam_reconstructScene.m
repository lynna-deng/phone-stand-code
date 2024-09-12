function [rawPoints3D, pointCloud_clean] = stereoCam_reconstructScene(C1_registered_filename, ...
    C2_registered_filename, roi)

    % STEREOCAM_RECONSTRUCTSCENE

    % PURPOSE: Applies calibration to a pair of aligned images, outputting
    % a 3D reconstruction. 

    % INPUTS: 
    %   C1_registered_filename: File name of the C1 aligned photograph
    %   C2_registered_filename: File name of the C2 aligned photograph
    %   roi: Region of interest, formatted [x_min, x_max, y_min, y_max,
    %   z_min, z_max)

    % OUTPUTS:
    %   rawPoints3D: All reconstructed points
    %   pointCloud_clean: All reconstructed points in region of interest
    
    % Last modified: September 12, 2024

    % ---------- Arguments ------------------------------------------------
    arguments
        C1_registered_filename string
        C2_registered_filename string
        roi (1, 6) = [-100000 100000 -100000 100000 -100 50000]
    end

    % Load aligned images
    TI1 = imread(C1_registered_filename);
    TI2 = imread(C2_registered_filename);
    
    % Load stereo parameters
    stereoParams_mat = load("calibrated_stereoParams.mat");
    stereoParams = stereoParams_mat.stereoParams;
    
    % Rectify images using stereo calibration
    [TJ1, TJ2, reprojectionMatrix] = rectifyStereoImages(TI1, TI2, stereoParams);
    
    % Display rectified images
    figure();
    anaglyph = stereoAnaglyph(TJ1, TJ2);
    imshow(anaglyph)
    
    % Compute disparity map
    disparityMap = disparitySGM(im2gray(TJ1), im2gray(TJ2), "DisparityRange", [0 128], "UniquenessThreshold", 20);
    figure();
    imshow(disparityMap, [0, 64], 'InitialMagnification', 50);
    title("Disparity Map")
    colormap jet
    colorbar
    
    % Reconstruct 3D scene
    rawPoints3D = reconstructScene(disparityMap, reprojectionMatrix);
    figure();
    ptCloud = pointCloud(rawPoints3D, Color=TJ1);
    pcshow(ptCloud)
    
    % Clean up point cloud to only include points with reasonable distance
    indices = findPointsInROI(ptCloud, roi);
    pointCloud_clean = select(ptCloud, indices);
    
    figure();
    pcshow(pointCloud_clean)

end