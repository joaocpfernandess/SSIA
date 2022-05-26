function f = dog_filter(eye1, eye2, mouth1, mouth2, nose_cent, nose_up, base_image)

    % Getting the dog filter
    [filter, ~, alphadata] = imread('dogfilter_notongue.png');

    % Calculating useful measures for the frame
    [n, m, ~] = size(base_image);
    up = 3*nose_up - 2*nose_cent;
    down = mean([mouth1; mouth2]);
    center = mean([up; down]); height = norm(up-down);
    left = 2.4*eye1 - 1.4*nose_cent;
    right = 2.4*eye2 - 1.4*nose_cent;
    width = norm(left-right);
    angle = atand((left(2)-right(2))/(left(1)-right(1)));
    
    % Points of interest
    pts = [center(1) - 0.65*width, center(2); ...
        center(1), center(2) - 0.7*height; ...
        center(1) + 0.65*width, center(2); ...
        center(1), center(2) + 0.5*height];
    
    % Rotated points
    pts = pts - center;
    tform = affine2d([ ...
        cosd(angle) sind(angle) 0;...
        -sind(angle) cosd(angle) 0; ...
        0 0 1]);
    t_pts = transformPointsForward(tform, pts);
    t_pts = t_pts + center;
    
    % Rotated filter and alphadata
    filt = imwarp(filter, tform); alpha = imwarp(alphadata, tform);

    % Starting the frame
    figure('visible', 'off');
    set(gca,'ydir','reverse')
    imshow(base_image); hold on
    filt_im = imshow(filt, ...
        'XData', [min(t_pts(:,1)) max(t_pts(:,1))],...
        'YData', [min(t_pts(:,2)) max(t_pts(:,2))]);
    set(filt_im, 'AlphaData', alpha);
    axis([0 m 0 n]); hold off

    f = getframe(gcf).cdata;

end