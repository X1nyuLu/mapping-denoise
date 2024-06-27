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
file_path = 'XY sample52.txt'; % 请在此修改文件路径
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
bg_zero_integer = nearest_last_zero_integer(croped_bg_size);

if bg_zero_integer ~= croped_bg_size
    m_bg = mean(origin_bg, 2);
    origin_bg = [origin_bg m_bg.*ones(size(origin_bg, 1), bg_zero_integer-croped_bg_size)];
end

fprintf('ALRMA start for bg');
[recon_bg, ~, ~] = ALRMA(origin_bg, 10, 1:1600, 5, 50, 1e-5, 0.05);

recon_bg = recon_bg(:, 1:croped_bg_size);

croped_target_size = size(origin_target, 2);
target_zero_integer = nearest_last_zero_integer(croped_target_size);

if target_zero_integer ~= croped_target_size
    m_target = mean(origin_target, 2);
    origin_target = [origin_target m_target.*ones(size(origin_target, 1), target_zero_integer-croped_target_size)];
end

fprintf('ALRMA start for target');
[recon_target, ~, ~] = ALRMA(origin_target, 10, 1:1600, 5, 50, 1e-5, 0.05);
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

%% Process all points in target region

% Initialize matrices to store results
processed_target_spectra = zeros(size(recon_target));

% Loop over each target point
for i = 1:size(recon_target, 2)
    recon_spectrum = recon_target(:, i);
    
    % Process the spectrum
    processed_spectrum = recon_spectrum ./ squeeze(mean(origin_bg, 2)); % Example processing
    % Store the results
    processed_target_spectra(:, i) = processed_spectrum;
end

%%
% Plot the 随机 6 processed spectra
% figure('Position', [100, 100, 1800, 600]);
% for i = 1:6
%     subplot(2, 3, i);
%     plot(wavenumber, processed_target_spectra(:, 100+i), 'LineWidth', 1.5);
%     title(['Processed Target Spectrum ' num2str(i)]);
%     xlabel('Raman shift (cm^{-1})');
%     ylabel('Intensity');
% end

%% 分区拟合(寻峰)
% 。。。
% wavenumber_max_list = [];
% for i = 1:size(recon_target, 2)
%     processed_target_spectra_i = processed_target_spectra(:, i);
%     intensity_range_i = processed_target_spectra_i(croped_id_right:croped_id_left);
%     [max_intensity, max_index] = max(intensity_range_i);
%     wavenumber_max_i = wavenumber(croped_id_right + max_index - 1);
%     wavenumber_max_list = [wavenumber_max_list, wavenumber_max_i];
% end

%% 可视化峰位置的mapping
% 。。。

