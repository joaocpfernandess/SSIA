function [cent_eye1, cent_eye2, ftrs_eye1, ftrs_eye2] = eyes_aux(rect_to_pts_e, ftrs_eyes)
    % This function divides the eyes rectangle into thirds; each eye is
    % looked at each end, meaning the third in the middle is ignored (it
    % sits on the nose, not on the actual eyes)

    % Finding the dividing points
    lim1 = min(rect_to_pts_e(:,1))+round((1/3)*(max(rect_to_pts_e(:,1))-min(rect_to_pts_e(:,1))));
    lim2 = min(rect_to_pts_e(:,1))+round((2/3)*(max(rect_to_pts_e(:,1))-min(rect_to_pts_e(:,1))));

    % Isolating each section
    eye1 = [min(rect_to_pts_e(:,1)), min(rect_to_pts_e(:,2)); ...
        lim1, min(rect_to_pts_e(:,2)); ...
        lim1, max(rect_to_pts_e(:,2)); ...
        min(rect_to_pts_e(:,1)), max(rect_to_pts_e(:,2))];
    eye2 = [max(rect_to_pts_e(:,1)), min(rect_to_pts_e(:,2)); ...
        lim2, min(rect_to_pts_e(:,2)); ...
        lim2, max(rect_to_pts_e(:,2)); ...
        max(rect_to_pts_e(:,1)), max(rect_to_pts_e(:,2))];
    
    % Finding features in each eye
    ftrs_eye1 = ftrs_eyes(inpolygon(ftrs_eyes(:,1), ftrs_eyes(:,2), eye1(:,1), eye1(:,2)), :);
    ftrs_eye2 = ftrs_eyes(inpolygon(ftrs_eyes(:,1), ftrs_eyes(:,2), eye2(:,1), eye2(:,2)), :);
    
    % Computing the key points with the features
    cent_eye1 = mean(ftrs_eye1, 1); cent_eye2 = mean(ftrs_eye2, 1);

end