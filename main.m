%% 加载数据

clc; clear;
file_path = 'XY sample52.txt';      % 请在此修改文件路径
cropped_wavenumber = [1800, 2000];   % 请在输入裁切的拉曼位移

demo_target_x = 12;                 % 请在输入待展示的像素坐标（目标区域）
demo_target_y = 25;                 % 请在输入待展示的像素坐标（目标区域）

demo_bg_x = 4;                     % 请在输入待展示的像素坐标（背景区域）
demo_bg_y = 15;                     % 请在输入待展示的像素坐标（背景区域）

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

bg_idx = input("请输入当作背景的聚类中心编号(例如[1]，或者[1,2,3]): ");
target_idx = input("请输入当作目标的聚类中心编号(例如[1]，或者[1,2,3]): ");

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

% fprintf('对背景区域降噪...');
% [recon_bg, ~, ~] = ALRMA(origin_bg, 10, 1:1600, 1, 50, 1e-5, 0.05);
% 
% recon_bg = recon_bg(:, 1:cropped_bg_size);
% 
recon_bg = origin_bg(:, 1:cropped_bg_size);


cropped_target_size = size(origin_target, 2);
target_zero_integer = nearest_last_zero_integer(cropped_target_size);

if target_zero_integer ~= cropped_target_size
    m_target = mean(origin_target, 2) ;
    origin_target = [origin_target m_target.*ones(size(origin_target, 1), target_zero_integer-cropped_target_size)];
end

fprintf('对目标区域降噪...');
[recon_target, ~, ~] = ALRMA(origin_target, 10, 1:1600, 2, 50, 1e-5, 0.05);
recon_target = recon_target(:, 1:cropped_target_size);

recon_matrix = (origin_matrix);
recon_matrix(:, ismember(idx, target_idx)) = recon_target;
recon_matrix(:, ismember(idx, bg_idx)) = recon_bg;
recon_hsi = reshape(recon_matrix, 1600, size_x, size_y);

%% 全图像素点谱图除以背景的平均谱

recon_matrix_allpixels = recon_matrix ./ squeeze(mean(origin_bg, 2));
recon_matrix_allpixels_hsi = reshape(recon_matrix_allpixels, [], size_x, size_y);
recon_matrix_allpixels_img = squeeze(mean(recon_matrix_allpixels_hsi(cropped_id_right:cropped_id_left, :, :), 1));

set(0,'defaultfigurecolor','w') 
figure;
subplot(221); imagesc(recon_matrix_allpixels_img);  title 'all pixels / mean(origin spec)'; colorbar;

%%
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


%% 自选取点除以背景的平均谱


figure('Position', [100, 100, 1800, 600]);

subplot(231);
plot(wavenumber, origin_hsi(:, demo_target_y, demo_target_x));
xlabel('Raman shift (cm^{-1})');
title 'raw spectrum within target zone';

subplot(232);
plot(wavenumber, recon_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2)));
xlabel('Raman shift (cm^{-1})');
title 'recon target pixel spec ./ mean(origin bg spec)';

subplot(233);
plot(wavenumber, origin_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2)));
xlabel('Raman shift (cm^{-1})'); 
title 'origin target pixel spec ./ mean(origin bg spec)';hold on;
% plot(wavenumber, recon_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2)));
% xlabel('Raman shift (cm^{-1})');

subplot(234);
plot(wavenumber, origin_hsi(:, demo_bg_y, demo_bg_x));
xlabel('Raman shift (cm^{-1})');
title 'raw spectrum within background zone';

subplot(235);
plot(wavenumber, recon_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(origin_bg, 2)));
xlabel('Raman shift (cm^{-1})');
title 'recon bg pixel spec ./ mean(origin bg spec)';

subplot(236);
plot(wavenumber, origin_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(origin_bg, 2)));
xlabel('Raman shift (cm^{-1})'); 
title 'origin bg pixel spec ./ mean(origin bg spec)';hold on;
% plot(wavenumber, recon_hsi(:, demo_bg_y, demo_bg_x) ./ squeeze(mean(origin_bg, 2)));
% xlabel('Raman shift (cm^{-1})');

%% 峰拟合

peak_data = recon_hsi(:, demo_target_y, demo_target_x) ./ squeeze(mean(origin_bg, 2));
peak_data = peak_data(cropped_id_right:cropped_id_left);
spec = peak_data;
x = wavenumber(cropped_id_right:cropped_id_left)';

% spec = sgolayfilt(spec, 5, 15);


[~, max_index] = findpeaks(spec, 'SortStr', 'descend', 'NPeaks', 1);

peak_X = x(max_index);
peak_y = spec(max_index);

half_max_height = (peak_y - min(spec)) / 2 + min(spec);
left_index = find(spec(1:max_index) <= half_max_height, 1, 'last');
right_index = find(spec(max_index:end) <= half_max_height, 1, 'first') + max_index - 1;
FWHM = x(right_index) - x(left_index);

init_sigma = FWHM / (2 * sqrt(2 * log(2))); 
init_para = [peak_X, peak_y - min(spec), init_sigma, peak_y - min(spec), FWHM / 2, min(spec)];


options = optimset('Display', 'off');
[popt_mixed, ~] = lsqcurvefit(@mixed_gaussian_lorentzian, init_para, x, spec, [], [], options);

% 显示拟合参数
disp(['Peak X: ', num2str(peak_X), ' cm^{-1}']);
disp(['Peak Y: ', num2str(peak_y), ' 相对强度']);
disp(['FWHM: ', num2str(- FWHM)]);
disp('拟合参数:');
disp(popt_mixed);

figure;
subplot(2, 1, 1);
plot(x, spec, 'r'); 
title('Raw spec at [1800,2000]');
xlabel('Raman shift (cm^{-1})');
ylabel('Intensity');

subplot(2, 1, 2);
plot(x, spec, 'r', x, mixed_gaussian_lorentzian(popt_mixed, x), 'g'); 
title('Fitting spec');
xlabel('Raman shift (cm^{-1})');
ylabel('Intensity');
legend('Raw data', 'Fitted curve');


%%  保存文件

fid=fopen('XY sample52_processed.txt','wt');    % 设置文件保存名字
recon_matrix_T = recon_matrix';
recon_matrix_T = [wavenumber;recon_matrix_T];
recon_matrix_T = [position,recon_matrix_T];

[m, n] = size(recon_matrix_T);
for i=1:1:m
    for j=1:1:n
       if j==n
         fprintf(fid,'%g\n',recon_matrix_T(i,j));
      else
        fprintf(fid,'%g\t',recon_matrix_T(i,j));
       end
    end
end
fclose(fid);

%% 只保存recon_target区域，其余归零

[m, n] = size(origin_matrix); 
recon_special = zeros(m, n);
recon_special(:, ismember(idx, target_idx)) = recon_target;

recon_special_T = recon_special';
recon_special_T = [wavenumber;recon_special_T];
recon_special_T = [position,recon_special_T];

fid=fopen('XY sample52_recontarget.txt','wt');  % 设置文件保存名字

[p,q] = size(recon_special_T);
for i=1:1:p
    for j=1:1:q
       if j==q
         fprintf(fid,'%g\n',recon_special_T(i,j));
      else
        fprintf(fid,'%g\t',recon_special_T(i,j));
       end
    end
end
fclose(fid);

