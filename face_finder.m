function [location_face, boxed_face] = face_finder(image)

    face_Detector = vision.CascadeObjectDetector();

    % Assuring only one face is detected by eroding the picture
    r = 0;
    struct_elem = strel("disk", r);
    eroded_frame = imerode(image, struct_elem);
    location_face = step(face_Detector, eroded_frame);
    while size(location_face, 1) > 1 && r < 30
        r = r + 2;
        struct_elem = strel("disk", r);
        eroded_frame = imerode(image, struct_elem);
        location_face = step(face_Detector, eroded_frame);
    end
    
    if size(location_face, 1) == 0
        error('No face detected');
    end
    
    location_face = step(face_Detector, eroded_frame);

    y = location_face(1); x = location_face(2);
    face_width = location_face(4); face_height = location_face(3);

    boxed_face = rgb2gray(image(x:x+face_width, y:y+face_height,:));

end