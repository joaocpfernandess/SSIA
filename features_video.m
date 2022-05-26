function [FaceStatsList, FramesList] = features_video(vid_name, show, plot_ftrs, out_name)
    % This is the main function to detect and save the features and frames

    % Input:
    % vid_name: name of the video to analyze (in mp4 format)
    % show: boolean variable to decide whether to show or not the video
    %       tracking the features (True if yes, False if no)
    % plot_ftrs: boolean variable to decide whether to plot or not the
    %            number of tracked features from each facial feature
    % out_name: name of the output video (in .avi format)

    % Output:
    % FaceStatsList: an array of structures, each containing the positions
    %                of the key points to be used when applying filters
    % FramesList: the complete array of frames of the video, in order to
    %             avoid reading over in video format again
    % An output video titled (out_name) is saved onto the computer
    % after executing the function

    if nargin < 4; out_name = 'output.avi'; end
    if nargin < 3; plot_ftrs = 0; end
    if nargin < 2; show = 1; end

    % Reading the video and first frame
    vid = VideoReader(vid_name);
    vid_Frame = readFrame(vid);
    
    [location_face, boxed_face] = face_finder(vid_Frame);
    
    % Extracting useful measures
    y = location_face(1); x = location_face(2);
    face_width = location_face(4); face_height = location_face(3);
    
    % Detecting features
    surf_ftrs = detectSURFFeatures(boxed_face,'MetricThreshold', 300);
    brisk_ftrs = detectBRISKFeatures(boxed_face, 'MinContrast', 0.1, 'MinQuality', 0.25);
    mineigen_ftrs = detectMinEigenFeatures(boxed_face);
    mineigen_ftrs = mineigen_ftrs.selectStrongest(30);
    mser_ftrs = detectMSERFeatures(boxed_face, 'ThresholdDelta', 4, ...
        'MaxAreaVariation', 0.3, 'RegionAreaRange',[100 100000]);
    
    % Geometrically transform the face (so it captures rotated or inverted)
    rect_to_pts_f = bbox2points(location_face(1,:));
    n_features = [0, 0, 0, 0]; n_frames = 1;
    
    % Defining the initial feature points
    surf_points = [y+round(surf_ftrs.Location(:,1)), x+round(surf_ftrs.Location(:,2))];
    brisk_points = [y+round(brisk_ftrs.Location(:,1)), x+round(brisk_ftrs.Location(:,2))];
    mineigen_points = [y+round(mineigen_ftrs.Location(:,1)), x+round(mineigen_ftrs.Location(:,2))];
    ftrs_face = [surf_points; brisk_points; mineigen_points];
    n_features(1) = size(ftrs_face, 1);
    
    % Finding eyes and eye features
    [ftrs_eyes, rect_to_pts_e, found_eyes] = ...
        feature_finder(x, y, boxed_face, ftrs_face, 'eyepairsmall');
    n_features(2) = size(ftrs_eyes, 1);
    
    % Small change to ensure a mouth isn't detected on the eyes
    % (seemed to be a common problem)
    boxed_face_mouth = boxed_face;
    if found_eyes
        boxed_face_mouth((min(rect_to_pts_e(:,2))-x):(max(rect_to_pts_e(:,2))-x), ...
            (min(rect_to_pts_e(:,1))-y):(max(rect_to_pts_e(:,1))-y)) = 0;
    end
    
    % Finding mouth and mouth features
    [ftrs_mouth, rect_to_pts_m, found_mouth] = ...
        feature_finder(x, y, boxed_face_mouth, ftrs_face, 'mouth');
    n_features(3) = size(ftrs_mouth, 1);
    
    % Finding nose and nose features
    [ftrs_nose, rect_to_pts_n, found_nose] = ...
        feature_finder(x, y, boxed_face, ftrs_face, 'nose');
    n_features(4) = size(ftrs_nose, 1);
    
    max_error = 100;
    key_ftrs = [];
    current_ftrs = [];

    % Extracting 'stats'
    if found_eyes
        [FaceStats.cent_eye1, FaceStats.cent_eye2] = eyes_aux(rect_to_pts_e, ftrs_eyes);
        key_ftrs = [key_ftrs; FaceStats.cent_eye1; FaceStats.cent_eye2]; 
        current_ftrs = [current_ftrs; "cent_eye1"; "cent_eye2"];
        eyes_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
        initialize(eyes_tracker, ftrs_eyes, vid_Frame)
    end
    
    if found_mouth
        FaceStats.mouth_edge1 = ftrs_mouth(ftrs_mouth(:,1)==min(ftrs_mouth(:,1)),:);
        FaceStats.mouth_edge1 = FaceStats.mouth_edge1(1,:);
        FaceStats.mouth_edge2 = ftrs_mouth(ftrs_mouth(:,1)==max(ftrs_mouth(:,1)),:);
        FaceStats.mouth_edge2 = FaceStats.mouth_edge2(1,:);
        FaceStats.mouth_cent = mean([FaceStats.mouth_edge1; FaceStats.mouth_edge2]);
        key_ftrs = [key_ftrs; FaceStats.mouth_edge1; FaceStats.mouth_edge2; FaceStats.mouth_cent];
        current_ftrs = [current_ftrs; "mouth_edge1"; "mouth_edge2"; "mouth_cent"];
        mouth_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
        initialize(mouth_tracker, ftrs_mouth, vid_Frame)
    end
    
    if found_nose
        FaceStats.nose_cent = mean(ftrs_nose);
        key_ftrs = [key_ftrs; FaceStats.nose_cent];
        current_ftrs = [current_ftrs; "nose_cent"];
        if found_eyes
            FaceStats.nose_up = mean([FaceStats.cent_eye1; FaceStats.cent_eye2]);
            key_ftrs = [key_ftrs; FaceStats.nose_up];
            current_ftrs = [current_ftrs; "nose_up"];
        end
        if found_mouth
            FaceStats.chin = 2.5*FaceStats.mouth_cent-1.5*FaceStats.nose_cent;
            key_ftrs = [key_ftrs; FaceStats.chin];
            current_ftrs = [current_ftrs; "chin"];
        end
        nose_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
        initialize(nose_tracker, ftrs_nose, vid_Frame)
    end
    
    % Initialize the tracking objects
    face_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
    initialize(face_tracker, ftrs_face, vid_Frame)
    
    if ~isempty(key_ftrs)
        key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
        initialize(key_tracker, key_ftrs, vid_Frame)
    end
    
    % Creating the video reader
    left = 0; bottom = 0; 
    [height, width, ~] = size(vid_Frame);
    vid_player = vision.VideoPlayer('Position', [left bottom width height]);
    
    % Creating the video writer
    out_vid = VideoWriter(out_name);
    open(out_vid)
    
    % Creating the frame loop
    prev_face = ftrs_face;
    prev_eyes = ftrs_eyes;
    prev_mouth = ftrs_mouth;
    prev_nose = ftrs_nose;
    prev_keys = key_ftrs;
    max_dist = max(size(vid_Frame)/20);
    
    FaceStatsList = [];
    FramesList = [];
    fields = ["cent_eye1", "cent_eye2", "mouth_edge1", "mouth_edge2",...
            "nose_cent", "nose_up", "chin"];

    while hasFrame(vid)
        n_frames = n_frames + 1;
        
        % Reading the frame and creating a 'track' frame (a frame where we
        % can safely place markers and polygons without affecting the
        % tracking in the original image)
        vid_Frame = readFrame(vid);
        track_Frame = vid_Frame;
        add_features = [0, 0, 0, 0];

        % Tracking face
        [ftrs_face, isFound_f] = step(face_tracker, vid_Frame);
        new_face = ftrs_face(isFound_f, :); old_face = prev_face(isFound_f, :);
        add_features(1) = size(new_face, 1);
    
        % Face transformation
        if size(new_face, 1) >= 2
            % Finding the transformation
            [transformed_rectangle_f] = ...
                estimateGeometricTransform2D(old_face, new_face, 'similarity', 'MaxDistance', max_dist);
            rect_to_pts_f = transformPointsForward(transformed_rectangle_f, rect_to_pts_f);
            
            % Reshaping the rectangle
            reshaped_rect_f = reshape(rect_to_pts_f', 1, []);
            
            % Placing face markers
            track_Frame = insertShape(track_Frame, 'Polygon', reshaped_rect_f, 'LineWidth', 2);
            track_Frame = insertMarker(track_Frame, new_face, '+', 'Color', 'White');
            
            % Moving a step with the detector
            prev_face = new_face;
            setPoints(face_tracker, prev_face);
        end
        
        % Eyes transformation
        if found_eyes
            % Tracking eyes
            [ftrs_eyes, isFound_e] = step(eyes_tracker, vid_Frame);
            new_eyes = ftrs_eyes(isFound_e, :); old_eyes = prev_eyes(isFound_e, :);
            add_features(2) = size(new_eyes, 1);
            % Eyes transformation
            if size(new_eyes, 1) >= 2
                try
                    % Finding the transformation
                    [transformed_rectangle_e] = ...
                        estimateGeometricTransform2D(old_eyes, new_eyes, 'similarity', 'MaxDistance', max_dist);
                    rect_to_pts_e = transformPointsForward(transformed_rectangle_e, rect_to_pts_e);
                    
                    % Reshaping
                    reshaped_rect_e = reshape(rect_to_pts_e', 1, []);
                    % Adding markers
                    track_Frame = insertShape(track_Frame, 'Polygon', reshaped_rect_e, 'LineWidth', 2);
                    track_Frame = insertMarker(track_Frame, new_eyes, '+', 'Color', 'Green');
                    
                    % Advancing the tracker object
                    prev_eyes = new_eyes;
                    setPoints(eyes_tracker, prev_eyes);
                catch
                    % This 'catch' happens if the computer can't compute a
                    % transformation: we assume the features are lost and
                    % delete them
                    key_ftrs = key_ftrs(current_ftrs ~= "cent_eye1" & current_ftrs ~= "cent_eye2",:);
                    current_ftrs = setdiff(current_ftrs, ["cent_eye1"; "cent_eye2"], 'stable');
                    if isempty(current_ftrs)
                        current_ftrs = [];
                    end
                    found_eyes = 0;
                    if ~isempty(key_ftrs)
                        % Reinitializing the key points tracker (happens
                        % every time a key point is added or removed)
                        prev_keys = key_ftrs;
                        key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                        initialize(key_tracker, key_ftrs, vid_Frame)
                    end
                end
            else
                % If not enough points are found, we restart
                found_eyes = 0;
            end
        else
            % If eyes are not detected, search again
            [location_face, boxed_face] = face_finder(vid_Frame);
            y = location_face(1); x = location_face(2);
            % Finding eyes
            [ftrs_eyes, rect_to_pts_e, found_eyes] = ...
                feature_finder(x, y, boxed_face, ftrs_face, 'eyepairsmall');
            if found_eyes
                [FaceStats.cent_eye1, FaceStats.cent_eye2, ftrs_eye1, ftrs_eye2] = eyes_aux(rect_to_pts_e, ftrs_eyes);
                % If there are no trackable points, we assume they
                % weren't found at all
                if isempty(ftrs_eye1) || isempty(ftrs_eye2)    
                    found_eyes = 0;
                end
            end
            if found_eyes
                % Restarting the eye tracker
                prev_eyes = ftrs_eyes;
                eyes_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(eyes_tracker, ftrs_eyes, vid_Frame)
                % Key tracker must be restarted if new features are found
                key_ftrs = [key_ftrs; FaceStats.cent_eye1; FaceStats.cent_eye2]; 
                current_ftrs = [current_ftrs; "cent_eye1"; "cent_eye2"];
                prev_keys = key_ftrs;
                key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(key_tracker, key_ftrs, vid_Frame)
            end
        end
    
        % Mouth transformation
        if found_mouth
            % Tracking the mouth
            [ftrs_mouth, isFound_m] = step(mouth_tracker, vid_Frame);
            new_mouth = ftrs_mouth(isFound_m, :); old_mouth = prev_mouth(isFound_m, :);
            add_features(3) = size(new_mouth, 1);
            if size(new_mouth, 1) >= 2
                try
                    % Estimating the transformation
                    [transformed_rectangle_m] = ...
                        estimateGeometricTransform2D(old_mouth, new_mouth, 'similarity', 'MaxDistance', max_dist);
                    rect_to_pts_m = transformPointsForward(transformed_rectangle_m, rect_to_pts_m);
                    % Reshaping
                    reshaped_rect_m = reshape(rect_to_pts_m', 1, []);
                    % Adding markers
                    track_Frame = insertShape(track_Frame, 'Polygon', reshaped_rect_m, 'LineWidth', 2);
                    track_Frame = insertMarker(track_Frame, new_mouth, '+', 'Color', 'Red');
                    % Advancing the tracker
                    prev_mouth = new_mouth;
                    setPoints(mouth_tracker, prev_mouth);
                catch
%                     bugou = 1
                    % If no transformation is found, remove from key points
                    % and search again
                    key_ftrs = key_ftrs(current_ftrs ~= "mouth_edge1" & current_ftrs ~= "mouth_edge2"...
                        & current_ftrs ~= "mouth_cent",:);
                    current_ftrs = setdiff(current_ftrs, ["mouth_edge1"; "mouth_edge2"; "mouth_cent"], 'stable');
                    if isempty(current_ftrs)
                        current_ftrs = [];
                    end
                    found_mouth = 0;
                    if ~isempty(key_ftrs)
                        prev_keys = key_ftrs;
                        key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                        initialize(key_tracker, key_ftrs, vid_Frame)
                    end
                end
            else
                % Not enough features were found to track
                found_mouth = 0;
            end
        else
            % Searching for the features again
            [location_face, boxed_face] = face_finder(vid_Frame);
            y = location_face(1); x = location_face(2);
            boxed_face_mouth = boxed_face;
            % Precautious step to ensure mouth isn't detected in the eye
            if found_eyes
                boxed_face_mouth((min(floor(rect_to_pts_e(:,2)))-x):(max(floor(rect_to_pts_e(:,2)))-x), ...
                    (min(floor(rect_to_pts_e(:,1)))-y):(max(floor(rect_to_pts_e(:,1)))-y)) = 0;
            end
            % Finding area and trackable points
            [ftrs_mouth, rect_to_pts_m, found_mouth] = ...
                feature_finder(x, y, boxed_face_mouth, ftrs_face, 'mouth');
            if found_mouth
                % Calculating key points
                prev_mouth = ftrs_mouth;
                FaceStats.mouth_edge1 = ftrs_mouth(ftrs_mouth(:,1)==min(ftrs_mouth(:,1)),:);
                FaceStats.mouth_edge1 = FaceStats.mouth_edge1(1,:);
                FaceStats.mouth_edge2 = ftrs_mouth(ftrs_mouth(:,1)==max(ftrs_mouth(:,1)),:);
                FaceStats.mouth_edge2 = FaceStats.mouth_edge2(1,:);
                FaceStats.mouth_cent = mean([FaceStats.mouth_edge1; FaceStats.mouth_edge2]);
                % Adding the key points and restarting the mouth and key tracker
                key_ftrs = [key_ftrs; FaceStats.mouth_edge1; FaceStats.mouth_edge2; FaceStats.mouth_cent];
                current_ftrs = [current_ftrs; "mouth_edge1"; "mouth_edge2"; "mouth_cent"];
                mouth_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(mouth_tracker, ftrs_mouth, vid_Frame)
                prev_keys = key_ftrs;
                key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(key_tracker, key_ftrs, vid_Frame)
            end
        end
        
        % Nose transformation
        if found_nose
            % Adding the key point that relies on the eyes as well, also
            % restarting the key tracker in this case
            if ~isfield(FaceStats, 'nose_up')
                FaceStats.nose_up = mean([FaceStats.cent_eye1; FaceStats.cent_eye2]);
                key_ftrs = [key_ftrs; FaceStats.nose_up];
                prev_keys = key_ftrs;
                key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(key_tracker, key_ftrs, vid_Frame)
            end
            % Tracking nose
            [ftrs_nose, isFound_n] = step(nose_tracker, vid_Frame);
            new_nose = ftrs_nose(isFound_n, :); old_nose = prev_nose(isFound_n, :);
            add_features(4) = size(new_nose, 1);
            if size(new_nose, 1) >= 2
                try
                    % Estimating transformation
                    [transformed_rectangle_n] = ...
                        estimateGeometricTransform2D(old_nose, new_nose, 'similarity', 'MaxDistance', max_dist);
                    rect_to_pts_n = transformPointsForward(transformed_rectangle_n, rect_to_pts_n);
                    % Reshaping
                    reshaped_rect_n = reshape(rect_to_pts_n', 1, []);
                    % Adding markers
                    track_Frame = insertShape(track_Frame, 'Polygon', reshaped_rect_n, 'LineWidth', 2);
                    track_Frame = insertMarker(track_Frame, new_nose, '+', 'Color', 'Yellow');
                    % Advancing the tracker
                    prev_nose = new_nose;
                    setPoints(nose_tracker, prev_nose);
                catch
                    % No transformation found
                    key_ftrs = key_ftrs(current_ftrs ~= "nose_cent" & current_ftrs ~= "nose_up",:);
                    current_ftrs = setdiff(current_ftrs, ["nose_cent", "nose_up"], 'stable');
                    if isempty(current_ftrs)
                        current_ftrs = [];
                    end
                    found_nose = 0;
                    if ~isempty(key_ftrs)
                        prev_keys = key_ftrs;
                        key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                        initialize(key_tracker, key_ftrs, vid_Frame)
                    end
                end
            else
                % Not enough features found
                found_nose = 0;
            end
        else
            % Searching the nose again
            [location_face, boxed_face] = face_finder(vid_Frame);
            y = location_face(1); x = location_face(2);
            [ftrs_nose, rect_to_pts_n, found_nose] = ...
                feature_finder(x, y, boxed_face, ftrs_face, 'nose');
            if found_nose
                % If found, add the key point and restart the trackers
                prev_nose = ftrs_nose;
                FaceStats.nose_cent = mean(ftrs_nose, 1);
                key_ftrs = [key_ftrs; FaceStats.nose_cent];
                if found_eyes && ~isfield(FaceStats, 'nose_up')
                    FaceStats.nose_up = mean(FaceStats.cent_eyes);
                    key_ftrs = [key_ftrs; FaceStats.nose_up];
                end
                nose_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(nose_tracker, ftrs_nose, vid_Frame)
                prev_keys = key_ftrs;
                key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(key_tracker, key_ftrs, vid_Frame)
            end
        end
    
        % Key transformation
        if ~isempty(key_ftrs)
            % Tracking the keys

            [key_ftrs, isFound_k] = step(key_tracker, vid_Frame);
            i = 1; j = 1; S.type = '.';
            % Assigning the keys in the FaceStats struct
            while i <= length(current_ftrs)
                S.subs = current_ftrs(i);
                if isFound_k(j)
                    FaceStats = subsasgn(FaceStats, S, key_ftrs(i,:));
                    i = i + 1;
                else
                    FaceStats = subsasgn(FaceStats, S, NaN);
                    current_ftrs = current_ftrs([1:i-1,i+1:length(current_ftrs)]);
                    if isempty(current_ftrs)
                        current_ftrs = [];
                    end
                end
                j = j + 1;
            end

            % Tracked keys
            new_keys = key_ftrs(isFound_k, :); 
            % Keys transformation
            if size(new_keys, 1) >= 2
                % Adding markers
                track_Frame = insertMarker(track_Frame, new_keys, '+', 'Color', 'White', 'size',10);
                if all(isfield(FaceStats, {'cent_eye1','cent_eye2','nose_cent','nose_up'})) &&...
                        all(~isnan([FaceStats.cent_eye1, FaceStats.cent_eye2, ...
                        FaceStats.nose_cent, FaceStats.nose_up]))
                    % Adding custom markers
                    my_points = [2.*FaceStats.cent_eye1 - FaceStats.nose_cent; ...
                        2.*FaceStats.cent_eye2 - FaceStats.nose_cent; ...
                        2.8.*FaceStats.nose_up - 1.8.*FaceStats.nose_cent];
                    track_Frame = insertMarker(track_Frame, my_points, '+', 'Color', 'magenta', 'size',10);
                end
                % Advancing the tracker
                prev_keys = new_keys;
                setPoints(key_tracker, prev_keys);
            end    
        end
        
        % Displaying the tracked image (with the markers)
        if show
            step(vid_player, track_Frame)
        end
        
        % Filling out the unidentified key points with NaN
        for f = fields
            if ~isfield(FaceStats, f)
                S.type = '.'; S.subs = f;
                FaceStats = subsasgn(FaceStats, S, NaN);
            end
        end
        
        % In case of having no key eyes detected, assume they were lost
        if any(isnan([FaceStats.cent_eye1, FaceStats.cent_eye2]))
            key_ftrs = key_ftrs(current_ftrs ~= "cent_eye1" & current_ftrs ~= "cent_eye2",:);
            current_ftrs = setdiff(current_ftrs, ["cent_eye1"; "cent_eye2"], 'stable');
            if isempty(current_ftrs)
                current_ftrs = [];
            end
            found_eyes = 0;
            if ~isempty(key_ftrs)
                prev_keys = key_ftrs;
                key_tracker = vision.PointTracker('MaxBidirectionalError', max_error);
                initialize(key_tracker, key_ftrs, vid_Frame)
            end
        end
        
        % Reporting the results from the frame into the array of structures
        FaceStatsList = [FaceStatsList, FaceStats];
        FramesList = cat(4,FramesList,vid_Frame);
        n_features = [n_features; add_features];

        % Write the marked framed into the output video
        writeVideo(out_vid,track_Frame);
        
    end
    % End the video player
    release(vid_player);
    
    % Plotting the number fo tracked features in each frame
    if plot_ftrs
        x = 1:n_frames;
        figure(1)
        f = plot(x, n_features(:,1)); hold on; m_f = sprintf("Face");
        e = plot(x, n_features(:,2)); m_e = sprintf("Eyes");
        m = plot(x, n_features(:,3)); m_m = sprintf("Mouth");
        n = plot(x, n_features(:,4)); m_n = sprintf("Nose");
        xlabel('Frame'); ylabel('# features');
        title(strcat('Tracked features - ', vid_name));
        legend({m_f, m_e, m_m, m_n}); axis([0 n_frames+1 0 max(max(n_features))+5])
        hold off
    end

end

