%% =========================================================
% Fig7e: Capture time distribution histogram
% N = 14, D = 2.154430
%
% 统一统计逻辑：
% 1. 显示中间99.6%的有效样本
% 2. 统一使用100个等宽分箱
% 3. 截取后的样本用于PDF直方图
% 4. 均值使用全部有效样本计算
%
% 保存位置：
% fig7e_N=14,D=2.154430.png
%% =========================================================

clear;
clc;
close all;

%% ==================== 1. 文件路径 ====================

% 数据文件路径
filePath = fullfile(fileparts(mfilename('fullpath')), 'data', 'fig7e_capture_times.txt');

% 图片保存文件夹
outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

% 图片保存名称
outputFile = fullfile( ...
    outputDir, ...
    'fig7e_N=14,D=2_154430.png');

if ~isfolder(outputDir)
    mkdir(outputDir);
end

if exist(filePath, 'file') ~= 2
    error('找不到数据文件，请检查路径：\n%s', filePath);
end

%% ==================== 2. 绘图参数 ====================

% 与fig7a、fig7b、fig7c、fig7d保持一致
outputBins = 100;

labelSize  = 30;
tickSize   = 22;
legendSize = 18;
textSize   = 18;

axisLineWidth = 1.5;

%% ==================== 3. 读取数据 ====================

rawData = load(filePath);

fprintf('\n读取到的数据尺寸：%d 行 × %d 列\n', ...
    size(rawData, 1), size(rawData, 2));

% 避免将多列数据错误拼接
if isvector(rawData)

    data = rawData(:);

else

    % 如果文件包含多列，默认最后一列为捕获时间
    data = rawData(:, end);

    fprintf('检测到多列数据，使用最后一列作为捕获时间。\n');

end

% 删除NaN和Inf
data = data(isfinite(data));

if isempty(data)
    error('文件中没有有效数值。');
end

%% ==================== 4. 数据预处理 ====================

% 使用负值比例判断是否为对数数据
negativeRatio = mean(data < 0);

if negativeRatio >= 0.90

    fprintf('检测到大部分数据为负，按对数捕获时间进行 exp() 还原。\n');

    CT = exp(data);

else

    fprintf('检测到原始捕获时间数据。\n');

    % 原始时间数据中，负值视为无效值
    CT = data(data >= 0);

end

% 再次清洗数据
CT = CT(isfinite(CT) & CT >= 0);

if isempty(CT)
    error('数据清洗后没有有效捕获时间。');
end

% 排序
CT = sort(CT);

%% ==================== 5. 计算统计量 ====================

% 均值基于全部有效样本计算
meanVal   = mean(CT);
medianVal = median(CT);

% 分位数
q002 = prctile(CT, 0.2);
q01  = prctile(CT, 1);
q50  = prctile(CT, 50);
q99  = prctile(CT, 99);
q998 = prctile(CT, 99.8);

fprintf('\n捕获时间统计：\n');
fprintf('样本量       = %d\n', numel(CT));
fprintf('最小值       = %.8f\n', min(CT));
fprintf('0.2%%分位数   = %.8f\n', q002);
fprintf('1%%分位数     = %.8f\n', q01);
fprintf('中位数       = %.8f\n', q50);
fprintf('均值         = %.8f\n', meanVal);
fprintf('99%%分位数    = %.8f\n', q99);
fprintf('99.8%%分位数  = %.8f\n', q998);
fprintf('最大值       = %.8f\n\n', max(CT));

%% ==================== 6. 统一显示范围与绘图样本 ====================

% 与fig7c保持一致：
% 截取0.2%至99.8%分位数之间的中间99.6%样本
displayMin = q002;
displayMax = q998;

displayRange = displayMax - displayMin;

if displayRange <= eps

    displayRange = max(abs(displayMax), 1) * 0.1;

end

% 横坐标左右各保留约4%的空间
xLower = max(0, displayMin - 0.04 * displayRange);
xUpper = displayMax + 0.04 * displayRange;

% 用于绘制直方图的样本
CTplot = CT(CT >= displayMin & CT <= displayMax);

if isempty(CTplot)
    error('分位数截取后没有可用于绘图的数据。');
end

fprintf('绘图使用样本量：%d，占完整样本的 %.2f%%\n', ...
    numel(CTplot), ...
    100 * numel(CTplot) / numel(CT));

fprintf('横坐标显示范围：[%.8f, %.8f]\n\n', ...
    xLower, xUpper);

%% ==================== 7. 创建图形 ====================

fig = figure( ...
    'Position', [180, 100, 1100, 700], ...
    'Color', 'w', ...
    'Renderer', 'painters');

ax = axes(fig);

hold(ax, 'on');
box(ax, 'on');

%% ==================== 8. 绘制直方图 ====================

% 在当前显示范围内统一划分100个等宽分箱
binEdges = linspace( ...
    xLower, ...
    xUpper, ...
    outputBins + 1);

h = histogram(ax, ...
    CTplot, ...
    binEdges, ...
    'Normalization', 'pdf', ...
    'FaceColor', [0.83, 0.83, 0.83], ...
    'EdgeColor', 'k', ...
    'LineWidth', 0.5, ...
    'FaceAlpha', 0.9, ...
    'DisplayName', 'Simulation Data');

%% ==================== 9. 设置横坐标范围 ====================

xlim(ax, [xLower, xUpper]);

%% ==================== 10. 自动设置横坐标刻度 ====================

% 目标为大约6个主要刻度区间
targetXStep = (xUpper - xLower) / 6;

xMagnitude = 10 ^ floor(log10(targetXStep));
xResidual  = targetXStep / xMagnitude;

if xResidual <= 1

    xStep = 1 * xMagnitude;

elseif xResidual <= 2

    xStep = 2 * xMagnitude;

elseif xResidual <= 2.5

    xStep = 2.5 * xMagnitude;

elseif xResidual <= 5

    xStep = 5 * xMagnitude;

else

    xStep = 10 * xMagnitude;

end

xTickStart = ceil(xLower / xStep) * xStep;
xTickEnd   = floor(xUpper / xStep) * xStep;

xTickValues = xTickStart:xStep:xTickEnd;

% 防止自动刻度为空或太少
if numel(xTickValues) < 2

    xTickValues = linspace(xLower, xUpper, 6);

end

xticks(ax, xTickValues);

% 根据横坐标刻度间隔确定小数位数
if xStep >= 1

    xDigits = 0;

elseif xStep >= 0.1

    xDigits = 1;

elseif xStep >= 0.01

    xDigits = 2;

elseif xStep >= 0.001

    xDigits = 3;

else

    xDigits = 4;

end

xFormat = sprintf('%%.%df', xDigits);

xTickLabels = arrayfun( ...
    @(x) sprintf(xFormat, x), ...
    xTickValues, ...
    'UniformOutput', false);

xticklabels(ax, xTickLabels);

% 横坐标刻度水平显示
xtickangle(ax, 0);

%% ==================== 11. 自动设置纵坐标 ====================

yMaxData = max(h.Values);

if isempty(yMaxData) || ...
        ~isfinite(yMaxData) || ...
        yMaxData <= 0

    error('直方图柱高无效，请检查数据。');

end

% 顶部保留15%的空间
targetYMax  = 1.15 * yMaxData;
targetYStep = targetYMax / 5;

yMagnitude = 10 ^ floor(log10(targetYStep));
yResidual  = targetYStep / yMagnitude;

if yResidual <= 1

    yStep = 1 * yMagnitude;

elseif yResidual <= 2

    yStep = 2 * yMagnitude;

elseif yResidual <= 2.5

    yStep = 2.5 * yMagnitude;

elseif yResidual <= 5

    yStep = 5 * yMagnitude;

else

    yStep = 10 * yMagnitude;

end

yUpper = ceil(targetYMax / yStep) * yStep;

ylim(ax, [0, yUpper]);

yTickValues = 0:yStep:yUpper;

yticks(ax, yTickValues);

% 根据纵坐标刻度间隔确定小数位数
if yStep >= 1

    yDigits = 0;

elseif yStep >= 0.1

    yDigits = 1;

elseif yStep >= 0.01

    yDigits = 2;

else

    yDigits = 3;

end

yFormat = sprintf('%%.%df', yDigits);

yTickLabels = arrayfun( ...
    @(y) sprintf(yFormat, y), ...
    yTickValues, ...
    'UniformOutput', false);

% 隐藏纵坐标原点处的0
% 避免与横坐标原点标签重复
if ~isempty(yTickLabels)
    yTickLabels{1} = '';
end

yticklabels(ax, yTickLabels);

%% ==================== 12. 坐标轴格式 ====================

ax.FontName   = 'Times New Roman';
ax.FontSize   = tickSize;
ax.FontWeight = 'bold';

ax.LineWidth  = axisLineWidth;
ax.TickDir    = 'in';
ax.TickLength = [0.015, 0.015];
ax.Layer      = 'top';

% 关闭次刻度和次网格
ax.XMinorTick = 'off';
ax.YMinorTick = 'off';
ax.XMinorGrid = 'off';
ax.YMinorGrid = 'off';

%% ==================== 13. 网格设置 ====================

grid(ax, 'on');

ax.GridLineStyle = '--';
ax.GridAlpha     = 0.35;

%% ==================== 14. 坐标轴名称 ====================

xlabel(ax, '\bf\it T', ...
    'Interpreter', 'tex', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize);

% 不显示纵坐标名称
ylabel(ax, '');



%% ==================== 17. 调整图形布局 ====================

ax.Position = [0.11, 0.14, 0.84, 0.78];

hold(ax, 'off');

%% ==================== 18. 保存高清图片 ====================

exportgraphics(fig, ...
    outputFile, ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

%% ==================== 19. 输出提示 ====================

fprintf('\nFig7e绘制完成。\n');
fprintf('完整有效样本量：%d\n', numel(CT));
fprintf('绘图使用样本量：%d\n', numel(CTplot));
fprintf('完整样本均值：%.6f\n', meanVal);
fprintf('完整样本中位数：%.6f\n', medianVal);
fprintf('绘图范围：[%.6f, %.6f]\n', xLower, xUpper);
fprintf('横坐标刻度间隔：%.6f\n', xStep);
fprintf('纵坐标刻度间隔：%.6f\n', yStep);
fprintf('分箱数量：%d\n', outputBins);
fprintf('图片保存为：\n%s\n\n', outputFile);
