%% Introduction

% 目前的流程如下：
% 1. 利用聚类分割出不同的区域
% 2. 计算背景区域的平均谱
% 3. 对target区域做一次去噪
% 4. 所有pixel除以背景区域的平均谱（each spectrum_targt / averaged spectrum_background）

% 待开发的功能：
% # 分别拟合300-400和1800-2000cm-1处的信号，以获取谱峰的拉曼位移和强度等信息
% # 根据拟合出的拉曼位移和强度信息绘制成像图
% # 其他......

% 注：
% * 根据绘图，峰位置偏差极小，感觉是可以忽略的
% * 我发现去噪前后的平均背景光谱差距很小
% * 唯一有风险的地方在于，聚类不能完美地勾勒出所有的目标物，导致有些包含目标物的pixel被遗漏，而这部分pixel是不会被降噪的

%% 加载数据

clc; clear;
file_path = 'xy sample 52.txt'; % 请在此修改文件路径
size_x = 40; % 请在输入成像的尺寸信息
size_y = 25; % 请在输入成像的尺寸信息
croped_wavenumber = [1800, 2000];


data = importdata(file_path);
wavenumber = data(1, 3:end);
position = data(:, 1:2);

origin_matrix = data(2:end, 3:end);

if size_x * size_y ~= size(origin_matrix, 1)
    error '尺寸设置错误，请检查传入的尺寸'
end

origin_matrix = despike2(origin_matrix)';
origin_hsi = reshape(origin_matrix, [], size_x, size_y);

croped_id_left = find(wavenumber > croped_wavenumber(1));
croped_id_left = croped_id_left(end);

croped_id_right = find(wavenumber < croped_wavenumber(end));
croped_id_right = croped_id_right(1);

origin_img = mean(origin_hsi(croped_id_right:croped_id_left, :, :), 1);
origin_img = squeeze(origin_img);

%% 聚类

num_clusters = 4;
rng(1); % random seed
[idx, ~] = kmeans(reshape(origin_img, [], 1), num_clusters);
idx_img = reshape(idx, size_x, size_y);

origin_bg = origin_matrix(:, (idx==3)|(idx==2));
origin_target = origin_matrix(:, idx==4);

set(0,'defaultfigurecolor','w') 
figure;
subplot(221); imagesc(origin_img);  title 'raw'; colorbar;
subplot(222); imagesc(idx_img); title 'K-means clustering (k=4)'; colorbar;
subplot(223); plot(wavenumber, mean(origin_bg, 2)); title 'averaged spectrum of background zone'; xlabel('Raman shift (cm^{-1})');
subplot(224); plot(wavenumber, mean(origin_target, 2)); title 'averaged spectrum of target zone'; xlabel('Raman shift (cm^{-1})');

%% select the background and target

croped_bg_size = size(origin_bg, 2);
bg_factors = prime_factors(croped_bg_size);

if bg_factors(end) == croped_bg_size
    origin_bg = [origin_bg zeros(size(origin_bg, 1), 1)];
    bg_factors = prime_factors(size(origin_bg, 2));
end

if size(bg_factors, 2) > 2
    bg_factor = bg_factors(end)*bg_factors(end-1);
else
    bg_factor = bg_factors(end);
end

[recon_bg, ~, ~] = ALRMA(origin_bg, bg_factor, 1:1600, 5, 50, 1e-5, 0.05);
recon_bg = recon_bg(:, 1:croped_bg_size);

croped_target_size = size(origin_target, 2);
target_factors = prime_factors(size(origin_target, 2));

if target_factors(end) == croped_target_size
    origin_target = [origin_target zeros(size(origin_target, 1), 1)];
    target_factors = prime_factors(size(origin_target, 2));
end

if size(target_factors, 2) > 2
    target_factor = target_factors(end)*target_factors(end-1);
else
    target_factor = target_factors(end);
end

[recon_target, ~, ~] = ALRMA(origin_target, target_factor, 1:1600, 5, 50, 1e-5, 0.05);
recon_target = recon_target(:, 1:croped_target_size);

recon_matrix = zeros(size(origin_matrix));
recon_matrix(:, (idx==3)|(idx==2)) = recon_bg;
recon_matrix(:, idx==4) = recon_target;
recon_matrix(:, idx==1) = origin_matrix(:, idx==1);
recon_hsi = reshape(recon_matrix, 1600, size_x, size_y);

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


%% 除以背景的平均谱


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
