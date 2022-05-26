function f = crazyeyes_filter(eye1, eye2, base_image)
    
    % Getting the crazy eyes png
    [filter, ~, alphadata] = imread('crazyeyes.png');

    % Calculating useful measures for the frame
    [n, m, ~] = size(base_image);
    left = 1.5*eye1 - 0.5*eye2;
    right = 1.5*eye2 - 0.5*eye1;
    width = norm(left-right); height = 0.5*width;
    angle = atand((left(2)-right(2))/(left(1)-right(1)));
    center = mean([eye1; eye2]);

    % Points of interest
    pts = [center(1) - 0.5*width, center(2); ...
        center(1), center(2) - 0.5*height; ...
        center(1) + 0.5*width, center(2); ...
        center(1), center(2) + 0.5*height];

    % Rotating the points
    pts = pts - center;
    tform = affine2d([ ...
        cosd(angle) sind(angle) 0;...
        -sind(angle) cosd(angle) 0; ...
        0 0 1]);
    t_pts = transformPointsForward(tform, pts);
    t_pts = center + t_pts;
    
    % Rotating the eyes and alphadata
    filt = imwarp(filter, tform); alpha = imwarp(alphadata, tform);
    
    % Starting the frame
    figure('visible', 'off');
    set(gca,'ydir','reverse')
    imshow(base_image); hold on
    filt_im = imshow(filt, ...
        'XData', [min(t_pts(:,1)) max(t_pts(:,1))], ...
        'YData', [min(t_pts(:,2)) max(t_pts(:,2))]);
    set(filt_im, 'AlphaData', alpha);
    axis([0 m 0 n]); hold off 
    
    f = getframe(gcf).cdata;

end