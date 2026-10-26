%% =========================================================
% Fig8: Mean capture time versus noise intensity
%
% 参数组：第一类参数
%
% 保存位置：
% fig8_mean_ct_vs_noise.png
%% =========================================================

clear;
clc;
close all;

%% ==================== 1. 文件路径 ====================

% 数据文件路径
filePath = fullfile(fileparts(mfilename('fullpath')), 'data', 'fig8_mean_times.txt');

% 图片保存文件夹
outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

% 图片保存名称
outputFile = fullfile( ...
    outputDir, ...
    'fig8_mean_ct_vs_noise.png');

if ~isfolder(outputDir)
    mkdir(outputDir);
end

if exist(filePath, 'file') ~= 2
    error('找不到数据文件，请检查路径：\n%s', filePath);
end

%% ==================== 2. 读取数据 ====================

data = load(filePath);

fprintf('\n读取到的数据尺寸：%d 行 × %d 列\n', ...
    size(data, 1), size(data, 2));

% 文件应至少包含8列：
% D、N=1、N=2、N=3、N=5、N=11、N=17、N=32
if size(data, 2) < 8
    error(['数据文件列数不足。\n' ...
           '当前文件包含%d列，但至少需要8列。'], ...
           size(data, 2));
end

%% ==================== 3. 提取数据 ====================

noise  = data(:, 1);

CT_N1  = data(:, 2);
CT_N2  = data(:, 3);
CT_N3  = data(:, 4);
CT_N5  = data(:, 5);
CT_N11 = data(:, 6);
CT_N17 = data(:, 7);
CT_N32 = data(:, 8);

%% ==================== 4. 数据清洗 ====================

% 对数坐标不能包含0、负值、NaN或Inf
validMask = ...
    isfinite(noise)  & noise  > 0 & ...
    isfinite(CT_N1)  & CT_N1  > 0 & ...
    isfinite(CT_N2)  & CT_N2  > 0 & ...
    isfinite(CT_N3)  & CT_N3  > 0 & ...
    isfinite(CT_N5)  & CT_N5  > 0 & ...
    isfinite(CT_N11) & CT_N11 > 0 & ...
    isfinite(CT_N17) & CT_N17 > 0 & ...
    isfinite(CT_N32) & CT_N32 > 0;

noise  = noise(validMask);

CT_N1  = CT_N1(validMask);
CT_N2  = CT_N2(validMask);
CT_N3  = CT_N3(validMask);
CT_N5  = CT_N5(validMask);
CT_N11 = CT_N11(validMask);
CT_N17 = CT_N17(validMask);
CT_N32 = CT_N32(validMask);

if isempty(noise)
    error('数据清洗后没有可用于对数坐标绘图的有效数据。');
end

% 按噪声强度从小到大排序
[noise, sortIndex] = sort(noise);

CT_N1  = CT_N1(sortIndex);
CT_N2  = CT_N2(sortIndex);
CT_N3  = CT_N3(sortIndex);
CT_N5  = CT_N5(sortIndex);
CT_N11 = CT_N11(sortIndex);
CT_N17 = CT_N17(sortIndex);
CT_N32 = CT_N32(sortIndex);

%% ==================== 5. 绘图参数 ====================

labelSize  = 30;
tickSize   = 22;
legendSize = 20;

lineWidth = 2.2;
markerSize = 8;
axisLineWidth = 1.5;

% 与前面图形风格一致的颜色
colors = [
    0.0000, 0.4470, 0.7410
    0.8500, 0.3250, 0.0980
    0.9290, 0.6940, 0.1250
    0.4940, 0.1840, 0.5560
    0.4660, 0.6740, 0.1880
    0.3010, 0.7450, 0.9330
    0.6350, 0.0780, 0.1840
];

%% ==================== 6. 创建图形 ====================

fig = figure( ...
    'Position', [180, 100, 1100, 850], ...
    'Color', 'w', ...
    'Renderer', 'painters');

ax = axes(fig);

hold(ax, 'on');
box(ax, 'on');

%% ==================== 7. 绘制曲线 ====================

plot(ax, noise, CT_N1, ...
    '-o', ...
    'Color', colors(1, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', '\itN\rm = 1');

plot(ax, noise, CT_N2, ...
    '-s', ...
    'Color', colors(2, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', '\itN\rm = 2');

plot(ax, noise, CT_N3, ...
    '-^', ...
    'Color', colors(3, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', '\itN\rm = 3');

plot(ax, noise, CT_N5, ...
    '-d', ...
    'Color', colors(4, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', '\itN\rm = 5');

plot(ax, noise, CT_N11, ...
    '-v', ...
    'Color', colors(5, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', '\itN\rm = 11');

plot(ax, noise, CT_N17, ...
    '-p', ...
    'Color', colors(6, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize + 1, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', '\itN\rm = 17');

plot(ax, noise, CT_N32, ...
    '-*', ...
    'Color', colors(7, :), ...
    'LineWidth', lineWidth, ...
    'MarkerSize', markerSize + 4, ...
    'DisplayName', '\itN\rm = 32');

%% ==================== 8. 设置对数坐标 ====================

set(ax, ...
    'XScale', 'log', ...
    'YScale', 'log');

%% ==================== 9. 坐标轴范围 ====================

% 与原Python代码保持一致
xlim(ax, [1e-3, 1e2]);
ylim(ax, [1e-2, 3e2]);

%% ==================== 10. 主刻度设置 ====================

xTickValues = [
    1e-3
    1e-2
    1e-1
    1e0
    1e1
    1e2
];

yTickValues = [
    1e-2
    1e-1
    1e0
    1e1
    1e2
];

ax.XTick = xTickValues;
ax.YTick = yTickValues;

% 使用10的幂次形式
ax.XTickLabel = {
    '10^{-3}'
    '10^{-2}'
    '10^{-1}'
    '10^{0}'
    '10^{1}'
    '10^{2}'
};

ax.YTickLabel = {
    '10^{-2}'
    '10^{-1}'
    '10^{0}'
    '10^{1}'
    '10^{2}'
};

%% ==================== 11. 坐标轴格式 ====================

ax.FontName   = 'Times New Roman';
ax.FontSize   = tickSize;
ax.FontWeight = 'bold';

ax.LineWidth  = axisLineWidth;
ax.TickDir    = 'in';
ax.TickLength = [0.015, 0.015];
ax.Layer      = 'top';

% 显示对数坐标次刻度
ax.XMinorTick = 'on';
ax.YMinorTick = 'on';

%% ==================== 12. 网格设置 ====================

grid(ax, 'on');

% 主网格
ax.GridLineStyle = '--';
ax.GridAlpha = 0.35;

% 次网格
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.20;

%% ==================== 13. 坐标轴标签 ====================

xlabel(ax, '\bf\it D', ...
    'Interpreter', 'tex', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize);

% 注意：角标使用大写N
ylabel(ax, '\bf\it \langle T_N \rangle', ...
    'Interpreter', 'tex', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize);

%% ==================== 14. 图例 ====================

% 放在左下角，避免遮挡右侧上升的曲线
lgd = legend(ax, ...
    'Location', 'southwest', ...
    'Interpreter', 'tex');

lgd.FontName   = 'Times New Roman';
lgd.FontSize   = legendSize;
lgd.FontWeight = 'bold';

lgd.Box       = 'on';
lgd.LineWidth = 1.3;
lgd.Color     = 'white';

%% ==================== 15. 调整布局 ====================

ax.Position = [0.13, 0.12, 0.82, 0.83];

hold(ax, 'off');

%% ==================== 16. 保存高清图片 ====================

exportgraphics(fig, ...
    outputFile, ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

%% ==================== 17. 输出提示 ====================

fprintf('\nFig8绘制完成。\n');
fprintf('有效噪声点数量：%d\n', numel(noise));
fprintf('横坐标范围：[1e-3, 1e2]\n');
fprintf('纵坐标范围：[1e-2, 3e2]\n');
fprintf('图片保存为：\n%s\n\n', outputFile);
