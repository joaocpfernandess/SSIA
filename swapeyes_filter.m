function f = swapeyes_filter(eye1, eye2, base_image)
    
    % Base measures
    angle = atand((eye1(2)-eye2(2))/(eye1(1)-eye2(1)));
    eyes = floor([eye1; eye2]);
    dist = norm(eyes(1,:) - eyes(2,:));
    rect_size = [0.5*dist 0.4*dist];
    
    % Points of interest
    pts1 = [eyes(1,1) + 0.5*rect_size(1), eyes(1,2);...
        eyes(1,1) - 0.5*rect_size(1), eyes(1,2);...
        eyes(1,1), eyes(1,2) + 0.5*rect_size(2);...
        eyes(1,1), eyes(1,2) - 0.5*rect_size(2)];
    pts2 = [eyes(2,1) + 0.5*rect_size(1), eyes(2,2);...
        eyes(2,1) - 0.5*rect_size(1), eyes(2,2);...
        eyes(2,1), eyes(2,2) + 0.5*rect_size(2);...
        eyes(2,1), eyes(2,2) - 0.5*rect_size(2);];
    
    % Rotation matrix
    tform = affine2d([ ...
        cosd(angle) sind(angle) 0;...
        -sind(angle) cosd(angle) 0; ...
        0 0 1]);                
    
    % Rotated points
    t_pts1 = transformPointsForward(tform, pts1 - eyes(1,:)) + eyes(1,:);
    t_pts2 = transformPointsForward(tform, pts2 - eyes(2,:)) + eyes(2,:);
    
    % Ellipse parameters
    a = norm(t_pts1(1,:) - t_pts1(2,:))/2; b = norm(t_pts1(3,:) - t_pts1(4,:))/2;
    
    % Regions of interest
    [roi1_x, roi1_y] = meshgrid(floor(min(t_pts1(:,2))):floor(max(t_pts1(:,2))),...
        floor(min(t_pts1(:,1))):floor(max(t_pts1(:,1))));
    [roi2_x, roi2_y] = meshgrid(floor(min(t_pts2(:,2))):floor(max(t_pts2(:,2))),...
        floor(min(t_pts2(:,1))):floor(max(t_pts2(:,1))));
    
    % List of coordinates
    coord1 = [roi1_y(:), roi1_x(:)] - eyes(1,:);
    coord2 = [roi2_y(:), roi2_x(:)] - eyes(2,:);
    
    % Ellipses in the original image
    ellip1 = floor(coord1((coord1(:,1).^2*cosd(angle)+coord1(:,2).^2*sind(angle))/a^2 + ...
        (coord1(:,1).^2*sind(angle)+coord1(:,2).^2*cosd(angle))/b^2 < 1, :)) + eyes(1,:);
    ellip2 = floor(coord2((coord2(:,1).^2*cosd(angle)+coord2(:,2).^2*sind(angle))/a^2 + ...
        (coord2(:,1).^2*sind(angle)+coord2(:,2).^2*cosd(angle))/b^2 < 1, :)) + eyes(2,:);
    
    % Creating the overlapping image
    [n, m, z] = size(base_image);
    alphaaa = zeros([n, m]);
    paste_image = zeros([n,m,z]);
    
    % Setting alpha data and new image
    for j = 1:size(ellip1, 1)
        alphaaa(ellip1(j,2), ellip1(j,1)) = 1;
        paste_image(ellip1(j,2), ellip1(j,1),:) = base_image(ellip2(j,2), ellip2(j,1),:); 
    end
    for j = 1:size(ellip2, 1)
        alphaaa(ellip2(j,2), ellip2(j,1)) = 1;
        paste_image(ellip2(j,2), ellip2(j,1),:) = base_image(ellip1(j,2), ellip1(j,1),:); 
    end
    
    % Transform the new image to uint8
    paste_image = cast(paste_image, 'uint8');

    figure('visible', 'off');
    set(gca,'ydir','reverse')
    imshow(base_image); hold on
    b = imshow(paste_image);
    set(b,'alphadata',alphaaa); hold off
    f = getframe(gcf).cdata;

end