function apply_filter(ftrs_list, frames_list, filter_type, output_name)
    % This is the main function to apply the filters

    % Input:
    % ftrs_list: The array of structures obtained from features_video.m
    % frames_list: The array of frames obtained from features_video.m
    % filter_type: Type of filter to apply
    %       HAS TO BE ONE OF THE FOLLOWING:
    %       {'dog', 'crazyeyes', 'crown', 'bigeyes', 'swapeyes'}
    % output_name: Name of the output file containing the filtered video

    % Output: a video titled (output_name) is saved into the computer with
    % the selected filter

    if nargin < 4
        output_name = 'output.avi';
    end
    possible_filters = ["dog", "crazyeyes", "crown", "bigeyes", "swapeyes"];
    if ~ismember(filter_type, possible_filters)
        error(strcat("filter_type must be one of the following: ", strjoin(possible_filters)))
    end

    n_frames = size(frames_list, 4);
    
    % Video writer
    video = VideoWriter(output_name); 
    open(video);
    
    % --- DOG FILTER ---
    if strcmp(filter_type, 'dog')
        for i=1:n_frames
            if all(~isnan([ftrs_list(i).nose_up, ftrs_list(i).nose_cent, ...
                ftrs_list(i).mouth_edge1, ftrs_list(i).mouth_edge2, ...
                ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2]))
                
                f = dog_filter(ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2,...
                    ftrs_list(i).mouth_edge1, ftrs_list(i).mouth_edge2,...
                    ftrs_list(i).nose_cent, ftrs_list(i).nose_up, frames_list(:,:,:,i));
            else
                f = frames_list(:,:,:,i);
            end
            writeVideo(video,f);
        end
    
    % --- CRAZY EYES FILTER ---
    elseif strcmp(filter_type, 'crazyeyes')
        for i=1:n_frames
            if all(~isnan([ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2]))
                f = crazyeyes_filter(ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2, ...
                    frames_list(:,:,:,i));
            else
                f = frames_list(:,:,:,i);
            end
            writeVideo(video,f);
        end
    
    % --- CROWN FILTER ---
    elseif strcmp(filter_type, 'crown')
        for i=1:n_frames
            if all(~isnan([ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2,...
                    ftrs_list(i).nose_up, ftrs_list(i).nose_cent]))
                f = crown_filter(ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2,...
                    ftrs_list(i).nose_up, ftrs_list(i).nose_cent, frames_list(:,:,:,i));
            else
                f = frames_list(:,:,:,i);
            end
            writeVideo(video,f);
        end
    
    % --- BIG EYES FILTER ---
    elseif strcmp(filter_type, 'bigeyes')
        for i=1:n_frames
            if all(~isnan([ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2]))
                f = bigeyes_filter(ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2, frames_list(:,:,:,i));
            else
                f = frames_list(:,:,:,i);
            end
            writeVideo(video,f);
        end
    
    % --- SWAP EYES FILTER ---
    elseif strcmp(filter_type, 'swapeyes')
        for i=1:n_frames
            if all(~isnan([ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2]))
                f = swapeyes_filter(ftrs_list(i).cent_eye1, ftrs_list(i).cent_eye2, frames_list(:,:,:,i));
            else
                f = frames_list(:,:,:,i);
            end
            writeVideo(video,f);
        end
        
    end
    close(video);
end
