%% Introduction

% 目前的流程如下：
% 1. 利用聚类分割出不同的区域
% 2. 计算背景区域的平均谱
% 3. 对target区域做一次去噪
% 4. 相除（each spectrum_targt / averaged spectrum_background）

% 此外，根据绘图，峰位置偏差极小，感觉是可以忽略的
% 唯一有风险的地方在于，聚类不能完美地勾勒出所有的目标物
% 导致有些包含目标物的pixel被遗漏，而这部分pixel是不会被降噪的

% 注：我发现去噪前后的平均背景光谱差距很小


%% load data

clc; clear;
file_path = 'xy sample 52.txt';

data = importdata(file_path);
wavenumber = data(1, 3:end);
position = data(:, 1:2);

origin_matrix = data(2:end, 3:end);
origin_matrix = despike2(origin_matrix)';
origin_hsi = reshape(origin_matrix, [], 40, 25);

origin_img = mean(origin_hsi, 1);
origin_img = squeeze(origin_img);

%% get the clusters

num_clusters = 4;
rng(1); % random seed
[idx, ~] = kmeans(reshape(origin_img, [], 1), num_clusters);
idx_img = reshape(idx, 40, []);

origin_bg = origin_matrix(:, (idx==3)|(idx==2));
origin_target = origin_matrix(:, idx==4);

set(0,'defaultfigurecolor','w') 
figure;
subplot(221); imagesc(origin_img);  title 'raw'; colorbar;
subplot(222); imagesc(idx_img); title 'K-means clustering (k=4)'; colorbar;
subplot(223); plot(wavenumber, mean(origin_bg, 2)); title 'averaged spectrum of background zone'; xlabel('Raman shift (cm^{-1})');
subplot(224); plot(wavenumber, mean(origin_target, 2)); title 'averaged spectrum of target zone'; xlabel('Raman shift (cm^{-1})');

%% select the background and target


[recon_bg, ~, ~] = ALRMA(origin_bg, 19, 1:1600, 5, 100, 1e-5, 0.05);
[recon_target, ~, ~] = ALRMA(origin_target, 28, 1:1600, 5, 50, 1e-5, 0.05);

recon_matrix = zeros(size(origin_matrix));
recon_matrix(:, (idx==3)|(idx==2)) = recon_bg;
recon_matrix(:, idx==4) = recon_target;
recon_matrix(:, idx==1) = origin_matrix(:, idx==1);
recon_hsi = reshape(recon_matrix, 1600, 40, []);

figure;
subplot(221); 
plot(wavenumber, origin_hsi(:, 11, 22), 'Color', 'b'); hold on; 
plot(wavenumber, recon_hsi(:, 11, 22), 'Color', 'r', 'LineWidth', 2); title 'one pixel within target zone'; xlabel('Raman shift (cm^{-1})');

subplot(222); 
plot(wavenumber, origin_hsi(:, 12, 11), 'Color', 'b'); hold on; 
plot(wavenumber, recon_hsi(:, 12, 11), 'Color', 'r', 'LineWidth', 2); title 'one pixel within background zone'; xlabel('Raman shift (cm^{-1})');

subplot(223);
plot(wavenumber, mean(origin_bg, 2), 'Color', 'b', 'LineWidth', 2); hold on; 
plot(wavenumber, mean(recon_bg, 2), 'Color', 'r', 'LineWidth', 0.5); title 'averaged spectrum of background zone'; xlabel('Raman shift (cm^{-1})');

subplot(224);
plot(wavenumber, mean(origin_target, 2), 'Color', 'b', 'LineWidth', 2); hold on; 
plot(wavenumber, mean(recon_target, 2), 'Color', 'r', 'LineWidth', 0.5); title 'averaged spectrum of target zone'; xlabel('Raman shift (cm^{-1})');


%% demonstrate target / background


figure('Position', [100, 100, 1800, 600]);
subplot(231); plot(wavenumber, origin_hsi(:, 11, 22)); xlabel('Raman shift (cm^{-1})'); title 'raw spectrum within target zone';
subplot(232); plot(wavenumber, recon_hsi(:, 11, 22) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, 11, 22) ./ squeeze(mean(recon_bg, 2))); xlabel('Raman shift (cm^{-1})');
subplot(233); plot(wavenumber, origin_hsi(:, 11, 22) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, 11, 22) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})');


subplot(234); plot(wavenumber, origin_hsi(:, 12, 11)); xlabel('Raman shift (cm^{-1})'); title 'raw spectrum within background zone';
subplot(235); plot(wavenumber, recon_hsi(:, 12, 11) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, 12, 11) ./ squeeze(mean(recon_bg, 2))); xlabel('Raman shift (cm^{-1})');
subplot(236); plot(wavenumber, origin_hsi(:, 12, 11) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, 12, 11) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); 

%% 分区拟合
% 。。。

%% 可视化峰位置的mapping
% 。。。
