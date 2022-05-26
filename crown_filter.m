function f = crown_filter(eye1, eye2, nose_up, nose_cent, base_image)
    
    % Get the crown png
    [filter, ~, alphadata] = imread('crown.png');

    % Calculating useful measures for the frame
    [n, m, ~] = size(base_image);
    left = 2*eye1 - eye2;
    right = eye2;
    width = norm(left-right); height = 0.8*width;
    angle = atand((left(2)-right(2))/(left(1)-right(1)));
    center = 1.3*eye1 - 0.3*eye2 + 2*nose_up - 2*nose_cent;

    % Points of interest
    pts = [center(1) - 0.5*width, center(2); ...
        center(1), center(2) - 0.5*height; ...
        center(1) + 0.5*width, center(2); ...
        center(1), center(2) + 0.5*height];
    
    % Rotated points
    pts = pts - center;
    tform = affine2d([ ...
        cosd(angle) sind(angle) 0;...
        -sind(angle) cosd(angle) 0; ...
        0 0 1]);
    t_pts = transformPointsForward(tform, pts);
    t_pts = center + t_pts;
    
    % Rotated crown and alphadata
    filt = imwarp(filter, tform); alpha = imwarp(alphadata, tform);

    % Starting the frame
    figure('visible', 'off');
    imshow(base_image); hold on
    filt_im = imshow(filt, ...
        'XData', [min(t_pts(:,1)) max(t_pts(:,1))], ...
        'YData', [min(t_pts(:,2)) max(t_pts(:,2))]);
    set(filt_im, 'AlphaData', alpha);
    axis([0 m 0 n]);
    hold off
    f = getframe(gcf).cdata;

end