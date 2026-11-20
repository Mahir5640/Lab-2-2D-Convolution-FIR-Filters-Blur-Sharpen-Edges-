%% Lab 2 — 2D Convolution & FIR Filters


close all;
clear;
clc;

labFolder = fileparts(mfilename('fullpath'));
outputFolder = fullfile(labFolder, 'lab2_figures');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

%% Load and prepare the image

if exist('peppers.png', 'file')
    I0 = imread('peppers.png');
    imageSource = 'peppers.png';
elseif exist('cameraman.tif', 'file')
    I0 = imread('cameraman.tif');
    imageSource = 'cameraman.tif';
else
    [x, y] = meshgrid(linspace(0, 1, 320), linspace(0, 1, 240));
    I0 = 0.15 + 0.60 * x;
    I0((x - 0.35).^2 + (y - 0.55).^2 < 0.18^2) = 0.85;
    I0(y < 0.25 & x < 0.35) = 0.65;
    I0(y < 0.25 & x > 0.80) = 0.95;
    imageSource = 'synthetic grayscale image';
end

if size(I0, 3) == 3
    I0 = rgb2gray(I0);
end
I = im2double(I0);
fprintf('Input: %s | Size: %d x %d\n', imageSource, size(I, 1), size(I, 2));

%% 1) Delta image and impulse response

delta = zeros(101, 101);
center = 51;
delta(center, center) = 1;

h_box3 = ones(3, 3) / 9;
response = conv2(delta, h_box3, 'same');

% Crop around the impulse so the 3-by-3 response is visible.
window = center-3:center+3;
fig = figure('Color', 'white', 'Position', [100 100 850 350]);
tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
imagesc(-3:3, -3:3, delta(window, window));
axis image;
colorbar;
xlabel('Column offset');
ylabel('Row offset');
title('Unit impulse');

nexttile;
imagesc(-3:3, -3:3, response(window, window));
axis image;
colorbar;
xlabel('Column offset');
ylabel('Row offset');
title('3 x 3 average impulse response');

exportgraphics(fig, fullfile(outputFolder, '01-impulse.png'), 'Resolution', 150);

%% 2) Low-pass filtering and separability

h_box7 = ones(7, 7) / 49;
sigma = 1.2;
g = fspecial('gaussian', [1 7], sigma);
h_gauss = g' * g;

I_box3 = imfilter(I, h_box3, 'replicate', 'conv');
I_box7 = imfilter(I, h_box7, 'replicate', 'conv');
I_gauss = imfilter(I, h_gauss, 'replicate', 'conv');

% Apply the same Gaussian in two 1D passes.
horizontalPass = imfilter(I, g, 'replicate', 'conv');
I_gauss_sep = imfilter(horizontalPass, g', 'replicate', 'conv');
gaussianError = max(abs(I_gauss(:) - I_gauss_sep(:)));
fprintf('Gaussian 2D vs two 1D passes, max difference: %.3g\n', gaussianError);

savePanels(outputFolder, '02-low-pass', ...
    {I, I_box3, I_box7, I_gauss_sep}, ...
    {'Original', '3 x 3 box', '7 x 7 box', 'Gaussian, two 1D passes'});

%% 3) Unsharp masking

I_blur = I_gauss_sep;
detail = I - I_blur;
gain = 1.0;
I_sharp = min(max(I + gain * detail, 0), 1);

savePanels(outputFolder, '03-unsharp', ...
    {I, I_blur, signedView(detail), I_sharp}, ...
    {'Original', 'Gaussian blur', 'Signed detail mask', 'Sharpened'});

%% 4) Sobel and Laplacian edges

% Gx measures change across columns. Gy measures change across rows.
h_sobel_x = [-1 0 1; -2 0 2; -1 0 1] / 8;
h_sobel_y = h_sobel_x';

Gx = imfilter(I, h_sobel_x, 'replicate', 'corr');
Gy = imfilter(I, h_sobel_y, 'replicate', 'corr');
Gmag = hypot(Gx, Gy);

h_lap = fspecial('laplacian', 0.2);
I_lap = imfilter(I, h_lap, 'replicate', 'conv');

savePanels(outputFolder, '04-edges', ...
    {signedView(Gx), signedView(Gy), mat2gray(Gmag), signedView(I_lap)}, ...
    {'Sobel Gx', 'Sobel Gy', 'Gradient magnitude', 'Signed Laplacian'});

%% 5) Correlation vs convolution

% Use matching zero padding when comparing conv2 and imfilter.
C1 = conv2(I, h_box3, 'same');
C2 = imfilter(I, h_box3, 0, 'conv', 'same');
boxError = max(abs(C1(:) - C2(:)));
fprintf('Box conv2 vs imfilter, max difference: %.3g\n', boxError);

% A Sobel kernel demonstrates the effect of rotating the kernel.
sobelCorr = imfilter(I, h_sobel_x, 'replicate', 'corr');
sobelConv = imfilter(I, h_sobel_x, 'replicate', 'conv');
flipError = max(abs(sobelCorr(:) + sobelConv(:)));
fprintf('Sobel correlation + convolution, max absolute residual: %.3g\n', ...
    flipError);

savePanels(outputFolder, '05-kernel-flip', ...
    {signedView(sobelCorr), signedView(sobelConv), ...
     mat2gray(abs(sobelCorr - sobelConv))}, ...
    {'Sobel correlation', 'Sobel convolution', 'Absolute difference'});

%% 6) Boundary handling

I_rep = imfilter(I, h_box7, 'replicate', 'conv');
I_sym = imfilter(I, h_box7, 'symmetric', 'conv');
I_cir = imfilter(I, h_box7, 'circular', 'conv');

% The 7-by-7 kernel reaches three pixels beyond a pixel's center.
% Magnify part of the top-left corner to make boundary effects visible.
rows = 1:min(24, size(I, 1));
cols = 1:min(32, size(I, 2));
repCrop = imresize(I_rep(rows, cols), 8, 'nearest');
symCrop = imresize(I_sym(rows, cols), 8, 'nearest');
cirCrop = imresize(I_cir(rows, cols), 8, 'nearest');

savePanels(outputFolder, '06-boundaries', ...
    {repCrop, symCrop, cirCrop}, ...
    {'Replicate', 'Symmetric', 'Circular'});

fprintf('Figures saved in %s\n', outputFolder);

%% Display helpers

function displayed = signedView(values)
    % Map zero to mid-gray and preserve the sign of the response.
    peak = max(abs(values(:)));
    if peak == 0
        displayed = 0.5 * ones(size(values));
    else
        displayed = 0.5 + 0.5 * values / peak;
    end
end

function savePanels(outputFolder, fileName, images, labels)
    fig = figure('Color', 'white', 'Position', [100 100 1200 360]);
    tiledlayout(1, numel(images), 'Padding', 'compact', 'TileSpacing', 'compact');

    for k = 1:numel(images)
        nexttile;
        imshow(images{k}, [0 1]);
        title(labels{k});
    end

    exportgraphics(fig, fullfile(outputFolder, [fileName '.png']), ...
        'Resolution', 150);
end