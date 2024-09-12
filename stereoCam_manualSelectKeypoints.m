function I1_selectedPoints = stereoCam_manualSelectKeypoints(I1, mat_filename, GCP_point_names)

    % Preallocate matrix selectedPoints with x, y in each row
    numPoints = length(GCP_point_names);
    I1_selectedPoints = zeros(numPoints, 2);
    
    figure
    imshow(I1);
    
    for ii = 1:numPoints
        title(append('GCP ', num2str(ii), ' of ', num2str(numPoints), ': Digitize ', GCP_point_names(ii)));
            % See the x, y, RGB values of the image as the cursor moves
            hPixelInfo = impixelinfo();
            % set(hPixelInfo, 'Unit', 'Normalized', 'Position', [.45 .96 .2 .1]);
            set(hPixelInfo, 'Unit', 'Normalized', 'Position', [5 1 300 20]);
    
        zoom on;
        pause()
        zoom off;
    
        I1_selectedPoints(ii, :) = ginput(1);
        hold on
        plot(I1_selectedPoints(ii, 1), I1_selectedPoints(ii, 2),'go', 'markerfacecolor', 'g', 'markersize', 3);
        zoom out
    end
    
    close

    % ---------- Save maskedPoints as .mat file ---------------------------
    save(append(mat_filename, ".mat"), 'I1_selectedPoints');

end