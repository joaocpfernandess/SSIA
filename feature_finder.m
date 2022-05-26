function [ftrs_extracted, rect_to_pts, found] = feature_finder(x, y, boxed_face, ftrs, feature)
    % This function extracts the desired facial feature and its
    % corresponding features. It only searches within the face region.

    % Often, more than one instance of each feature is detected. If so, we
    % progressively erode the pic until the 'most likely' feature emerges
    merge_level = 1;
    feature_Detector = vision.CascadeObjectDetector(feature, ...
        'MergeThreshold', merge_level);
    feature_location = step(feature_Detector, boxed_face);
    
    % Assuring only one instance is detected
    while size(feature_location, 1) > 1
        merge_level = merge_level + 1;
        feature_Detector = vision.CascadeObjectDetector(feature, ...
        'MergeThreshold', merge_level);
        feature_location = step(feature_Detector, boxed_face);
    end
    
    % No feature detected
    if size(feature_location, 1) == 0
        ftrs_extracted = [];
        rect_to_pts = [];
        found = 0;
        return
    end
    
    % Translating the coordinates to align with the original image
    feature_location(1) = y + feature_location(1); feature_location(2) = x + feature_location(2);

    % Extracting only the specific features
    rect_to_pts = bbox2points(feature_location);
    ftrs_extracted = ftrs(inpolygon(ftrs(:,1), ftrs(:,2), ...
        rect_to_pts(:,1), rect_to_pts(:,2)), :);
    
    % If no trackable points are found, we assume the feature wasn't found
    found = ~isempty(ftrs_extracted);
end