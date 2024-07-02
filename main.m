%% 加载数据

clc; clear;
file_path = 'XY sample71.txt';      % 请在此修改文件路径
cropped_wavenumber = [1800, 2000];   % 请在输入裁切的拉曼位移

demo_target_x = 11;                 % 请在输入待展示的像素坐标（目标区域）
demo_target_y = 19;                 % 请在输入待展示的像素坐标（目标区域）

demo_bg_x = 13;                     % 请在输入待展示的像素坐标（背景区域）
demo_bg_y = 34;                     % 请在输入待展示的像素坐标（背景区域）

num_clusters = 8;                   % 请在输入聚类中心的个数

data = importdata(file_path);
wavenumber = data(1, 3:end);
position = data(:, 1:2);


% 计算 size_x 和 size_y
size_y = length(unique(data(2:end, 1)));
size_x = length(unique(data(2:end, 2)));

% 计算波数的裁切坐标
cropped_id_left = find(wavenumber > cropped_wavenumber(1));
cropped_id_left = cropped_id_left(end);

cropped_id_right = find(wavenumber < cropped_wavenumber(end));
cropped_id_right = cropped_id_right(1);


origin_matrix = data(2:end, 3:end);
origin_matrix = despike2(origin_matrix)';

fprintf('聚类中...');
[pro_matrix, ~, ~] = ALRMA(origin_matrix, size_x, 1:1600, 5, 100, 1e-5, 0.05);
[pro_matrix, ~] = airPLS(pro_matrix');
pro_matrix = pro_matrix';
pro_hsi = reshape(pro_matrix, [], size_x, size_y);
pro_img = mean(pro_hsi(cropped_id_right:cropped_id_left, :, :), 1);

origin_hsi = reshape(origin_matrix, [], size_x, size_y);


origin_img = mean(origin_hsi(cropped_id_right:cropped_id_left, :, :), 1);
origin_img = squeeze(origin_img);

%% 聚类

rng(1); % random seed
[idx, cluster_cores] = kmeans(reshape(pro_img, [], 1), num_clusters);
[~, sort_order] = sort(cluster_cores);
sorted_idx = zeros(size(idx));
for i = 1:num_clusters
    sorted_idx(idx == sort_order(i)) = i;
end
idx_img = reshape(sorted_idx, size_x, size_y);



set(0,'defaultfigurecolor','w') 
figure;
subplot(221); imagesc(origin_img);  title 'raw'; colorbar;
subplot(222); imagesc(idx_img); title 'K-means clustering (k=4)'; colorbar;

bg_idx = input("请输入当作背景的聚类中心编号(例如1，或者[1,2,3]): ");
target_idx = input("请输入当作目标的聚类中心编号(例如1，或者[1,2,3]): ");

origin_bg = origin_matrix(:, ismember(idx, bg_idx));
origin_target = origin_matrix(:, ismember(idx, target_idx));

subplot(223); plot(wavenumber, mean(origin_bg, 2)); title 'averaged spectrum of background zone'; xlabel('Raman shift (cm^{-1})');
subplot(224); plot(wavenumber, mean(origin_target, 2)); title 'averaged spectrum of target zone'; xlabel('Raman shift (cm^{-1})');

%% 降噪

cropped_bg_size = size(origin_bg, 2);
bg_zero_integer = nearest_last_zero_integer(cropped_bg_size);

if bg_zero_integer ~= cropped_bg_size
    m_bg = mean(origin_bg, 2);
    origin_bg = [origin_bg m_bg.*ones(size(origin_bg, 1), bg_zero_integer-cropped_bg_size)];
end

fprintf('对背景区域降噪...');
[recon_bg, ~, ~] = ALRMA(origin_bg, 10, 1:1600, 3, 50, 1e-5, 0.05);

recon_bg = recon_bg(:, 1:cropped_bg_size);

cropped_target_size = size(origin_target, 2);
target_zero_integer = nearest_last_zero_integer(cropped_target_size);

if target_zero_integer ~= cropped_target_size
    m_target = mean(origin_target, 2) ;
    origin_target = [origin_target m_target.*ones(size(origin_target, 1), target_zero_integer-cropped_target_size)];
end

fprintf('对目标区域降噪...');
[recon_target, ~, ~] = ALRMA(origin_target, 10, 1:1600, 3, 50, 1e-5, 0.05);
recon_target = recon_target(:, 1:cropped_target_size);

recon_matrix = (origin_matrix);
recon_matrix(:, ismember(idx, target_idx)) = recon_target;
recon_matrix(:, ismember(idx, bg_idx)) = recon_bg;
recon_hsi = reshape(recon_matrix, 1600, size_x, size_y);

figure;
subplot(221); 
plot(wavenumber, origin_hsi(:, demo_target_y, demo_target_x), 'Color', 'b'); hold on; 
plot(wavenumber, recon_hsi(:, demo_target_y, demo_target_x), 'Color', 'r', 'LineWidth', 2); title 'one pixel within target zone'; xlabel('Raman shift (cm^{-1})');

subplot(222); 
plot(wavenumber, origin_hsi(:, demo_bg_y, demo_bg_x), 'Color', 'b'); hold on; 
plot(wavenumber, recon_hsi(:, demo_bg_y, demo_bg_x), 'Color', 'r'); title 'one pixel within background zone'; xlabel('Raman shift (cm^{-1})');

subplot(223);
plot(wavenumber, mean(origin_bg, 2), 'Color', 'b', 'LineWidth', 2); hold on; 
plot(wavenumber, mean(recon_bg, 2), 'Color', 'r', 'LineWidth', 0.5); title 'averaged spectrum of background zone'; xlabel('Raman shift (cm^{-1})');

subplot(224);
plot(wavenumber, mean(origin_target, 2), 'Color', 'b', 'LineWidth', 2); hold on; 
plot(wavenumber, mean(recon_target, 2), 'Color', 'r', 'LineWidth', 0.5); title 'averaged spectrum of target zone'; xlabel('Raman shift (cm^{-1})');


%% 除以背景的平均谱


figure('Position', [100, 100, 1800, 600]);
subplot(231); plot(wavenumber, origin_hsi(:, demo_target_y, demo_target_x)); xlabel('Raman shift (cm^{-1})'); title 'raw spectrum within target zone';
subplot(232); plot(wavenumber, recon_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(recon_bg, 2))); xlabel('Raman shift (cm^{-1})');
subplot(233); plot(wavenumber, origin_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})');


subplot(234); plot(wavenumber, origin_hsi(:, demo_bg_y, demo_bg_x)); xlabel('Raman shift (cm^{-1})'); title 'raw spectrum within background zone';
subplot(235); plot(wavenumber, recon_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(recon_bg, 2))); xlabel('Raman shift (cm^{-1})');
subplot(236); plot(wavenumber, origin_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); hold on; plot(wavenumber, recon_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(origin_bg, 2))); xlabel('Raman shift (cm^{-1})'); 

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
%     intensity_range_i = processed_target_spectra_i(cropped_id_right:cropped_id_left);
%     [max_intensity, max_index] = max(intensity_range_i);
%     wavenumber_max_i = wavenumber(cropped_id_right + max_index - 1);
%     wavenumber_max_list = [wavenumber_max_list, wavenumber_max_i];
% end

%% 可视化峰位置的mapping
% 。。。

