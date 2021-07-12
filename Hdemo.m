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
%dataset = 'tennis';
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
noise = 0;      %1 for impulse noise; 0 for clean video
noise_level = 0.2;  %Bernoulli-p of impulse noise

[Yreg,Ytrue,Ynoisy,mask,height,width] = homographyStitch(VIDEOPATH,isRGB,scale,noise,noise_level);

% Normalize the data to be in [0 1] range
Ytrue = Ytrue - min(min(min(min(Ytrue))));
Ytrue = Ytrue / max(max(max(max(Ytrue))));

Ynoisy = Ynoisy - min(min(min(min(Ynoisy))));
Ynoisy = Ynoisy / max(max(max(max(Ynoisy))));




