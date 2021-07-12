close all
clear
clc
addpath('mine/');

% Load Panoramic Video Data

rng(1);


%$SET THE VIDEO PATH - change this to point to the dataset!

video_path = 'C:/Users/rodri/OneDrive/Desktop/PanGAEAonline/';


%%Choose a video

% dataset = 'dog-gooses/';
dataset = 'horsejump-high';
% dataset = 'horsejump-low';
% dataset = 'lucia';
% dataset = 'paragliding';
% dataset = 'swing';
% dataset = 'tennis';
% dataset = 'flamingo';
% dataset = 'paragliding-launch';
% dataset = 'stroller';
% dataset = 'car-roundabout';
% dataset = 'car-shadow';
% dataset = 'hockey';
% dataset = 'blackswan';
% dataset = 'dance-jump';
% dataset = 'hike';
% dataset = 'bmx-trees';
% dataset = 'dance-twirl';

VIDEOPATH = strcat(video_path,dataset,'/');

%Also change below path!
video_path_truth = 'C:/Users/rodri/OneDrive/Desktop/PanGAEAonline/Annotations/';
VIDEOPATH_TRUTH = strcat(video_path_truth,dataset,'/');

scale = 0.25;   %resolution
isRGB = 1;          %1 for RGB; 0 for grayscale

[Yreg,mask,height,width] = homographyStitchFOR2(VIDEOPATH,isRGB,scale);





