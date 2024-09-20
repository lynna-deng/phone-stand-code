function I1_maskedPoints = stereoCam_manualSelectMask(I1, mat_filename, max_points)
    
    % STEREOCAM_MANUALSELECTMASK

    % PURPOSE: Function for selecting the corners of a mask polygon such
    % that features detected within the mask are not used for image
    % alignment. Allows for flexibility with temporal changes that may
    % confuse alignment algorithm.

    % INPUTS: 
    %   I1: Loaded image file to create mask for
    %   mat_filename: Name of .mat file when saving mask points
    %   max_points: Maximum number of points to select, 100 by default

    % OUTPUTS:
    %   I1_maskedPoints: Nx2 matrix of mask points' x, y coordinates
    
    % Last modified: September 9, 2024

    % ---------- Arguments ------------------------------------------------
    arguments
        I1 uint8
        mat_filename string
        max_points uint32
    end

    % ---------- Open image -----------------------------------------------
    figure();
    imshow(I1);
    
    % ---------- Initialize variables -------------------------------------
    key_pressed = 0;
    ii = 0;
    I1_maskedPoints = zeros(max_points, 2);
    
    % ---------- Begin selection ------------------------------------------
    while key_pressed ~= 1

        title("Click any key to enable selection, then left-click to select a point.");

        ii = ii + 1;
        
        % Allow zooming until a key is pressed
        zoom on;
        pause()
        zoom off;
        
        % Store and plot selected point
        I1_maskedPoints(ii, :) = ginput(1);
        hold on
        plot(I1_maskedPoints(ii, 1), I1_maskedPoints(ii, 2), 'go', 'markerfacecolor', 'g', 'markersize', 3);
        
        % Plot line connecting to adjacent points
        if ii > 1
            plot([I1_maskedPoints(ii - 1, 1); I1_maskedPoints(ii, 1)], ...
                [I1_maskedPoints(ii - 1, 2); I1_maskedPoints(ii, 2)], 'Color', 'g');
        end 
        zoom out
        
        % Allow user to continue masking or to finish selection
        title("Click 'b' to finish. Click any other key to continue.");
        key_pressed = waitforbuttonpress;

        if key_pressed == 1
            keyChar = get(gcf, 'CurrentCharacter');
            key_pressed = 0;

            if strcmpi(keyChar, 'b')
                % disp('Enter key pressed! Ending...')
                key_pressed = 1;
            end
        end
    end
    
    % ---------- Remove all unused rows -----------------------------------
    I1_maskedPoints_nonzero_rows = any(I1_maskedPoints, 2);
    I1_maskedPoints = I1_maskedPoints(I1_maskedPoints_nonzero_rows, :);
    
    % ---------- Save maskedPoints as .mat file ---------------------------
    save(append(mat_filename, ".mat"), 'I1_maskedPoints');

end