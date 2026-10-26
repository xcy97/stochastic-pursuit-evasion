%% =========================================================
% Fig2b: Spatial trajectories during the deceleration interval
%
% 目标轨迹：Run 4
% 时间范围：30 <= t <= 40
%
% 数据列格式：
% 第1列：时间 t
% 第2列：速度 v
% 第3列：逃逸者位置 x
% 第4列：逃逸者位置 y
% 第5列：追踪者位置 x
% 第6列：追踪者位置 y
%
% 保存位置：
% fig2b_chaser_path.png
%% =========================================================

clear;
clc;
close all;

%% ==================== 1. 文件路径 ====================

% 原始数据所在文件夹
dataDir = fullfile(fileparts(mfilename('fullpath')), 'data');

% 图片保存文件夹
outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

% 图片保存名称
outputFile = fullfile( ...
    outputDir, ...
    'fig2b_chaser_path.png');

if ~isfolder(outputDir)
    mkdir(outputDir);
end

if ~isfolder(dataDir)
    error('数据文件夹不存在：%s', dataDir);
end

%% ==================== 2. 用户设置 ====================

% 目标轨迹编号
TARGET_RUN = 4;

% 观察时间范围
ZOOM_TIME_RANGE = [30, 40];

% 文件名称格式
filePattern = 'speed_run%d.txt';

%% ==================== 3. 绘图参数 ====================

% 轨迹线宽
trajectoryWidth = 2.4;
chaserLineWidth = 1.0;

% 标记大小
startMarkerSize = 150;
endMarkerSize   = 260;
chaserPointSize = 28;

% 字号
labelSize         = 30;
tickSize          = 19;
legendSize        = 16;
colorbarLabelSize = 24;
colorbarTickSize  = 18;

% 坐标轴线宽
axisLineWidth = 1.7;

%% ==================== 4. 参数检查 ====================

if numel(ZOOM_TIME_RANGE) ~= 2 || ...
        ZOOM_TIME_RANGE(1) >= ZOOM_TIME_RANGE(2)

    error('ZOOM_TIME_RANGE必须写成[startTime, endTime]。');

end

%% ==================== 5. 读取目标轨迹 ====================

fileName = sprintf(filePattern, TARGET_RUN);
filePath = fullfile(dataDir, fileName);

if ~isfile(filePath)
    error('未找到目标轨迹文件：%s', filePath);
end

rawData = readmatrix(filePath);

if size(rawData, 2) < 6
    error('目标轨迹文件少于6列：%s', fileName);
end

% 删除前6列中包含NaN或Inf的无效行
validRows = all(isfinite(rawData(:, 1:6)), 2);
targetData = rawData(validRows, :);

if isempty(targetData)
    error('目标轨迹文件中没有有效数据：%s', fileName);
end

%% ==================== 6. 提取目标轨迹数据 ====================

tAll = targetData(:, 1);

evaderX = targetData(:, 3);
evaderY = targetData(:, 4);

chaserX = targetData(:, 5);
chaserY = targetData(:, 6);

% 截取指定时间范围
timeMask = ...
    tAll >= ZOOM_TIME_RANGE(1) & ...
    tAll <= ZOOM_TIME_RANGE(2);

if ~any(timeMask)

    error( ...
        '指定时间范围内没有数据：[%.2f, %.2f]', ...
        ZOOM_TIME_RANGE(1), ...
        ZOOM_TIME_RANGE(2));

end

tZoom = tAll(timeMask);

evaderXZoom = evaderX(timeMask);
evaderYZoom = evaderY(timeMask);

chaserXZoom = chaserX(timeMask);
chaserYZoom = chaserY(timeMask);

%% ==================== 7. 创建图形 ====================

% 与fig2a保持相同的画布尺寸
fig = figure( ...
    'Units', 'pixels', ...
    'Position', [180, 100, 1100, 700], ...
    'Color', 'w', ...
    'Renderer', 'painters');

ax = axes(fig);

hold(ax, 'on');
box(ax, 'on');

%% ==================== 8. 绘制逃逸者轨迹 ====================

% 逃逸者轨迹
hEvader = plot(ax, ...
    evaderXZoom, ...
    evaderYZoom, ...
    '--', ...
    'Color', [0.15, 0.60, 0.20], ...
    'LineWidth', trajectoryWidth, ...
    'DisplayName', 'Evader Trajectory');

% 逃逸者起点
hStart = scatter(ax, ...
    evaderXZoom(1), ...
    evaderYZoom(1), ...
    startMarkerSize, ...
    'o', ...
    'MarkerFaceColor', [0.15, 0.60, 0.20], ...
    'MarkerEdgeColor', [0.05, 0.30, 0.10], ...
    'LineWidth', 1.5, ...
    'DisplayName', 'Start');

% 逃逸者终点
% 图中和图例均使用黑色五角星
hEnd = scatter(ax, ...
    evaderXZoom(end), ...
    evaderYZoom(end), ...
    endMarkerSize, ...
    'p', ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k', ...
    'LineWidth', 1.2, ...
    'DisplayName', 'End');

%% ==================== 9. 绘制追踪者轨迹 ====================

% 灰色辅助连接线
plot(ax, ...
    chaserXZoom, ...
    chaserYZoom, ...
    '-', ...
    'Color', [0.65, 0.65, 0.65], ...
    'LineWidth', chaserLineWidth, ...
    'HandleVisibility', 'off');

% 追踪者轨迹彩色散点
hChaser = scatter(ax, ...
    chaserXZoom, ...
    chaserYZoom, ...
    chaserPointSize, ...
    tZoom, ...
    'filled', ...
    'DisplayName', 'Chaser Path');

hChaser.MarkerFaceAlpha = 0.90;
hChaser.MarkerEdgeAlpha = 0.90;

%% ==================== 10. 构造plasma颜色表 ====================

plasmaAnchors = [
    0.0504, 0.0298, 0.5280
    0.4176, 0.0006, 0.6584
    0.6928, 0.1651, 0.5645
    0.8814, 0.3925, 0.3832
    0.9883, 0.6523, 0.2114
    0.9400, 0.9752, 0.1313
];

anchorIndex = 1:size(plasmaAnchors, 1);

queryIndex = linspace( ...
    1, ...
    size(plasmaAnchors, 1), ...
    256);

plasmaMap = interp1( ...
    anchorIndex, ...
    plasmaAnchors, ...
    queryIndex, ...
    'pchip');

% 防止颜色值超出[0,1]
plasmaMap = min(max(plasmaMap, 0), 1);

colormap(ax, plasmaMap);

%% ==================== 11. 设置颜色范围 ====================

if min(tZoom) < max(tZoom)

    caxis(ax, [min(tZoom), max(tZoom)]);

else

    caxis(ax, ...
        [min(tZoom) - 0.5, ...
         max(tZoom) + 0.5]);

end

%% ==================== 12. 坐标轴名称 ====================

xlabel(ax, 'X', ...
    'Interpreter', 'none', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize, ...
    'FontWeight', 'bold', ...
    'FontAngle', 'italic');

ylabel(ax, 'Y', ...
    'Interpreter', 'none', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize, ...
    'FontWeight', 'bold', ...
    'FontAngle', 'italic');

%% ==================== 13. 坐标轴格式 ====================

ax.FontName   = 'Times New Roman';
ax.FontSize   = tickSize;
ax.FontWeight = 'bold';

ax.LineWidth  = axisLineWidth;
ax.TickDir    = 'in';
ax.TickLength = [0.015, 0.015];
ax.Layer      = 'top';

% 防止显示科学计数法
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 0;

% 关闭次刻度和次网格
ax.XMinorTick = 'off';
ax.YMinorTick = 'off';
ax.XMinorGrid = 'off';
ax.YMinorGrid = 'off';

%% ==================== 14. 网格设置 ====================

grid(ax, 'on');

ax.GridLineStyle = '--';
ax.GridAlpha     = 0.30;

%% ==================== 15. 坐标范围和比例 ====================

% 自动贴合轨迹
axis(ax, 'tight');

% 保证X轴和Y轴的单位长度一致
axis(ax, 'equal');

ax.XTickMode = 'auto';
ax.YTickMode = 'auto';

%% ==================== 16. 图例 ====================

% 显式指定图例顺序
lgd = legend(ax, ...
    [hEvader, hStart, hEnd, hChaser], ...
    {'Evader Trajectory', ...
     'Start', ...
     'End', ...
     'Chaser Path'}, ...
    'Location', 'southeast', ...
    'FontSize', legendSize, ...
    'Interpreter', 'none');

lgd.FontName   = 'Times New Roman';
lgd.FontWeight = 'bold';
lgd.Box        = 'on';
lgd.LineWidth  = 1.3;
lgd.Color      = 'white';

%% ==================== 17. 添加颜色条 ====================

cb = colorbar(ax);

cb.FontName      = 'Times New Roman';
cb.FontSize      = colorbarTickSize;
cb.FontWeight    = 'bold';
cb.LineWidth     = 1.3;
cb.TickDirection = 'in';

% 颜色条标签：小写t，加粗、斜体
cb.Label.String      = 't';
cb.Label.Interpreter = 'none';
cb.Label.FontName    = 'Times New Roman';
cb.Label.FontSize    = colorbarLabelSize;
cb.Label.FontWeight  = 'bold';
cb.Label.FontAngle   = 'italic';
cb.Label.Rotation    = 90;

% 不手动设置cb.Label.Position
% 让MATLAB自动将t放置在刻度数字右侧，避免与35重合

%% ==================== 18. 统一图形布局 ====================

% 必须在axis equal、legend和colorbar创建之后设置
drawnow;

% 固定坐标轴位置
% 使用较窄的坐标轴区域，以适应axis equal形成的近方形绘图区
ax.Position = [0.20, 0.14, 0.50, 0.80];

% colorbar紧靠主图
cb.Position = [0.695, 0.14, 0.025, 0.80];

% 重新刷新，确保位置生效
drawnow;

hold(ax, 'off');

%% ==================== 19. 保存高清图片 ====================

exportgraphics(fig, ...
    outputFile, ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

%% ==================== 20. 输出提示 ====================

fprintf('\nFig2b绘制完成。\n');
fprintf('目标轨迹：Run %d\n', TARGET_RUN);

fprintf('观察时间范围：[%.2f, %.2f]\n', ...
    ZOOM_TIME_RANGE(1), ...
    ZOOM_TIME_RANGE(2));

fprintf('画布尺寸：1100 × 700像素\n');
fprintf('图片保存位置：\n%s\n\n', outputFile);
