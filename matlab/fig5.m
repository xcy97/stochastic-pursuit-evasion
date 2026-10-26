%% 图5：捕获成功率热力图
% 输出图片：
% fig5_success_rate_heatmap.png

clear;
clc;
close all;

%% ==================== 1. 文件路径 ====================

% 图片保存文件夹
outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

% 图片保存名称
outputFile = fullfile( ...
    outputDir, ...
    'fig5_success_rate_heatmap.png');

% 如果保存文件夹不存在，则自动创建
if ~isfolder(outputDir)
    mkdir(outputDir);
end

%% ==================== 2. 原始数据 ====================

% 噪声强度
noise_D = [
     0.004642
     0.010000
     0.021544
     0.046416
     0.100000
     0.215443
     0.464159
     1.000000
     2.154430
     4.641590
    10.000000
    17.782800
    31.622800
];

% Hounds数量
N_hounds = [1, 3, 8, 14, 25];

% 捕获成功率矩阵
successMatrix = [
    0.87762, 0.99982, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    1.00000, 1.00000, 1.00000, 1.00000, 1.00000
    0.99967, 0.99992, 1.00000, 1.00000, 1.00000
    0.99348, 0.99834, 0.99966, 0.99993, 0.99999
    0.96139, 0.99002, 0.99809, 0.99953, 0.99990
];

[nRows, nCols] = size(successMatrix);

% 检查数据维度
if length(noise_D) ~= nRows
    error('noise_D的长度与成功率矩阵行数不一致。');
end

if length(N_hounds) ~= nCols
    error('N_hounds的长度与成功率矩阵列数不一致。');
end

%% ==================== 3. 绘图参数 ====================

labelSize     = 30;   % 坐标轴名称字号
tickSize      = 19;   % 刻度字号
cellTextSize  = 14;   % 单元格数字字号
cbarTickSize  = 17;   % colorbar刻度字号
cbarLabelSize = 24;   % colorbar标题字号

axisLineWidth = 1.7;
cellLineWidth = 1.2;
colorbarWidth = 1.3;

%% ==================== 4. 创建图形 ====================

fig = figure( ...
    'Position', [180, 80, 1000, 900], ...
    'Color', 'w', ...
    'Renderer', 'painters');

ax = axes(fig);
hold(ax, 'on');
box(ax, 'on');

%% ==================== 5. 绘制热力图主体 ====================

imagesc(ax, successMatrix);

% 第一行显示在最上方
set(ax, 'YDir', 'reverse');

% 设置颜色范围
cMin = min(successMatrix(:));
cMax = max(successMatrix(:));
caxis(ax, [cMin, cMax]);

%% ==================== 6. 设置YlGnBu配色 ====================

ylgnbuAnchors = [
    255, 255, 217
    237, 248, 177
    199, 233, 180
    127, 205, 187
     65, 182, 196
     29, 145, 192
     34,  94, 168
     12,  44, 132
] / 255;

anchorIndex = 1:size(ylgnbuAnchors, 1);
queryIndex = linspace(1, size(ylgnbuAnchors, 1), 256);

ylgnbuMap = interp1( ...
    anchorIndex, ...
    ylgnbuAnchors, ...
    queryIndex, ...
    'pchip');

ylgnbuMap = min(max(ylgnbuMap, 0), 1);
colormap(ax, ylgnbuMap);

%% ==================== 7. 设置坐标轴刻度 ====================

ax.XTick = 1:nCols;
ax.YTick = 1:nRows;

ax.XTickLabel = arrayfun( ...
    @(x) sprintf('%d', x), ...
    N_hounds, ...
    'UniformOutput', false);

ax.YTickLabel = arrayfun( ...
    @(x) sprintf('%.6f', x), ...
    noise_D, ...
    'UniformOutput', false);

%% ==================== 8. 坐标轴格式 ====================

ax.FontName = 'Times New Roman';
ax.FontSize = tickSize;
ax.FontWeight = 'bold';

ax.LineWidth = axisLineWidth;
ax.TickDir = 'in';
ax.TickLength = [0.010, 0.010];
ax.Layer = 'top';

grid(ax, 'off');

%% ==================== 9. 横纵坐标名称 ====================

% 这里只保留 N 和 D
xlabel(ax, '\bf\it N', ...
    'Interpreter', 'tex', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize);

ylabel(ax, '\bf\it D', ...
    'Interpreter', 'tex', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize);

%% ==================== 10. 绘制单元格边界 ====================

for x = 0.5 : 1 : (nCols + 0.5)
    plot(ax, ...
        [x, x], ...
        [0.5, nRows + 0.5], ...
        'Color', [1, 1, 1], ...
        'LineWidth', cellLineWidth, ...
        'HandleVisibility', 'off');
end

for y = 0.5 : 1 : (nRows + 0.5)
    plot(ax, ...
        [0.5, nCols + 0.5], ...
        [y, y], ...
        'Color', [1, 1, 1], ...
        'LineWidth', cellLineWidth, ...
        'HandleVisibility', 'off');
end

xlim(ax, [0.5, nCols + 0.5]);
ylim(ax, [0.5, nRows + 0.5]);

%% ==================== 11. 添加单元格数值 ====================

for i = 1:nRows
    for j = 1:nCols

        value = successMatrix(i, j);

        valueNorm = (value - cMin) / (cMax - cMin + eps);

        if valueNorm >= 0.55
            textColor = [1, 1, 1];
        else
            textColor = [0, 0, 0];
        end

        text(ax, ...
            j, ...
            i, ...
            sprintf('%.5f', value), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Times New Roman', ...
            'FontSize', cellTextSize, ...
            'FontWeight', 'bold', ...
            'Color', textColor);
    end
end

%% ==================== 12. 添加Colorbar ====================

cb = colorbar(ax);

cb.FontName = 'Times New Roman';
cb.FontSize = cbarTickSize;
cb.FontWeight = 'bold';
cb.LineWidth = colorbarWidth;
cb.TickDirection = 'in';

% 简化后的标题
cb.Label.String = 'Success Rate';
cb.Label.FontName = 'Times New Roman';
cb.Label.FontSize = cbarLabelSize;
cb.Label.FontWeight = 'bold';

%% ==================== 13. 调整图形布局 ====================

ax.Position = [0.20, 0.11, 0.61, 0.84];

hold(ax, 'off');

%% ==================== 14. 保存高清图片 ====================

exportgraphics(fig, ...
    outputFile, ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

%% ==================== 15. 输出提示 ====================

fprintf('\n图5绘制完成。\n');
fprintf('热力图矩阵大小：%d行 × %d列\n', nRows, nCols);
fprintf('单元格数值保留5位小数。\n');
fprintf('图片已经保存为：\n%s\n\n', outputFile);
