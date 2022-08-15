# SSIA
Code used for the Spatial Statistics and Image Analysis

Project title: Augmented Reality filters: facial feature tracking and augmentation

There should be 10 .m files in total in this repo.
The two main ones are:

features_video.m -> The file that returns the video with all the correspondent features tracked \\
apply_filter.m -> The file that returns the video with the selected filter applied to it

All instructions for input and output are specified in each file, as well as properly commented code in order to understand each step of the program.

As for the remaining files, they are used throughtout the two main files as auxiliary functions, in order to mantain the scripts readable, and need not to be run individually. These files are:

face_finder.m -> Script that detects a face in a frame
feature_finder.m -> Script that detects other facial features within a face
eyes_aux.m -> Auxiliary function to calculate additional measures for the eyes
XXXXX_filter.m -> Applying the 'XXXXX' filter to each frame. There are 5 files of this kind ('dog', 'crazyeyes', 'crown', 'bigeyes', 'swapeyes')
