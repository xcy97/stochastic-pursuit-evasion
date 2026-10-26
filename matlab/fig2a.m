%% =========================================================
% Fig2a: Global evolution of the chaser speed
%
% 数据文件：
% speed_run1.txt 至 speed_run10.txt
%
% 保存位置：
% fig2a_speed_drop.png
%
% 说明：
% 1. Run 4 为目标轨迹，使用红色加粗显示
% 2. 横坐标为 t
% 3. 纵坐标为 ‖V₁(t)‖
% 4. 图片内部不添加(a)，由LaTeX子图环境生成
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
    'fig2a_speed_drop.png');

if ~isfolder(outputDir)
    mkdir(outputDir);
end

if ~isfolder(dataDir)
    error('数据文件夹不存在：%s', dataDir);
end

%% ==================== 2. 用户设置 ====================

% 需要重点分析的目标轨迹编号
TARGET_RUN = 4;

% 文件名称格式
filePattern = 'speed_run%d.txt';

% 轨迹数量
numRuns = 10;

%% ==================== 3. 绘图参数 ====================

% Savitzky-Golay平滑参数
window = 101;
polyOrder = 3;

% 曲线宽度
normalCurveWidth = 1.8;
targetCurveWidth = 3.0;

% 字号
labelSize  = 30;
tickSize   = 19;
legendSize = 16;

% 坐标轴线宽
axisLineWidth = 1.7;

%% ==================== 4. 参数检查 ====================

if TARGET_RUN < 1 || TARGET_RUN > numRuns
    error('TARGET_RUN必须位于1至%d之间。', numRuns);
end

if mod(window, 2) == 0
    error('平滑窗口window必须是奇数。');
end

if window <= polyOrder
    error('window必须大于polyOrder。');
end

%% ==================== 5. 创建图形 ====================

% 与fig2b使用完全一致的画布尺寸
fig = figure( ...
    'Units', 'pixels', ...
    'Position', [180, 100, 1100, 700], ...
    'Color', 'w', ...
    'Renderer', 'painters');

ax = axes(fig);

hold(ax, 'on');
box(ax, 'on');

%% ==================== 6. tab10配色 ====================

tab10 = [
     31, 119, 180
    255, 127,  14
     44, 160,  44
    214,  39,  40
    148, 103, 189
    140,  86,  75
    227, 119, 194
    127, 127, 127
    188, 189,  34
     23, 190, 207
] / 255;

%% ==================== 7. 读取并绘制10条速度轨迹 ====================

% 保存曲线句柄，保证图例顺序为Run 1至Run 10
lineHandles = gobjects(numRuns, 1);

% 保存目标曲线句柄
targetLine = gobjects(1);

validCount = 0;

for i = 1:numRuns

    %% 构造文件路径

    fileName = sprintf(filePattern, i);
    filePath = fullfile(dataDir, fileName);

    if ~isfile(filePath)
        warning('未找到文件，已跳过：%s', filePath);
        continue;
    end

    %% 读取数据

    data = readmatrix(filePath);

    if size(data, 2) < 2
        warning('文件少于2列，已跳过：%s', fileName);
        continue;
    end

    % 删除时间和速度列中含NaN或Inf的行
    validRows = ...
        isfinite(data(:, 1)) & ...
        isfinite(data(:, 2));

    data = data(validRows, :);

    if isempty(data)
        warning('文件中没有有效数据，已跳过：%s', fileName);
        continue;
    end

    % 第一列为时间，第二列为速度
    t = data(:, 1);
    v = data(:, 2);

    %% Savitzky-Golay平滑

    if length(v) >= window

        if exist('sgolayfilt', 'file') == 2

            vSmooth = sgolayfilt( ...
                v, ...
                polyOrder, ...
                window);

        else

            vSmooth = smoothdata( ...
                v, ...
                'sgolay', ...
                window);

        end

    else

        vSmooth = v;

        warning( ...
            '%s的数据点少于%d，未进行平滑。', ...
            fileName, ...
            window);

    end

    %% 设置曲线颜色和宽度

    if i == TARGET_RUN

        % 目标轨迹：红色加粗
        plotColor = [0.8500, 0.1000, 0.1000];
        lineWidth = targetCurveWidth;
        labelText = sprintf('Run %d (Target)', i);

    else

        % 其他轨迹：tab10配色
        plotColor = tab10(i, :);
        lineWidth = normalCurveWidth;
        labelText = sprintf('Run %d', i);

    end

    %% 绘制曲线

    lineHandles(i) = plot(ax, ...
        t, ...
        vSmooth, ...
        'Color', plotColor, ...
        'LineWidth', lineWidth, ...
        'DisplayName', labelText);

    if i == TARGET_RUN
        targetLine = lineHandles(i);
    end

    validCount = validCount + 1;

end

%% ==================== 8. 检查绘图结果 ====================

if validCount == 0
    error(['没有成功读取任何速度轨迹文件，' ...
           '请检查数据路径和文件名称。']);
end

% 将目标轨迹移动到最上层
if isgraphics(targetLine)
    uistack(targetLine, 'top');
end

%% ==================== 9. 横纵坐标名称 ====================

% 横坐标：小写t，加粗、斜体
xlabel(ax, 't', ...
    'Interpreter', 'none', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize, ...
    'FontWeight', 'bold', ...
    'FontAngle', 'italic');

% 纵坐标：‖V₁(t)‖
ylabel(ax, '‖V₁(t)‖', ...
    'Interpreter', 'none', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize, ...
    'FontWeight', 'bold', ...
    'FontAngle', 'italic');

%% ==================== 10. 坐标轴范围和刻度 ====================

xlim(ax, [0, 50]);
xticks(ax, 0:5:50);

ylim(ax, [0, 2.5]);
yticks(ax, 0:0.5:2.5);

% 防止科学计数法
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 0;

%% ==================== 11. 坐标轴格式 ====================

ax.FontName   = 'Times New Roman';
ax.FontSize   = tickSize;
ax.FontWeight = 'bold';

ax.LineWidth  = axisLineWidth;
ax.TickDir    = 'in';
ax.TickLength = [0.015, 0.015];
ax.Layer      = 'top';

% 不显示次刻度和次网格
ax.XMinorTick = 'off';
ax.YMinorTick = 'off';
ax.XMinorGrid = 'off';
ax.YMinorGrid = 'off';

%% ==================== 12. 网格设置 ====================

grid(ax, 'on');

ax.GridLineStyle = '--';
ax.GridAlpha     = 0.30;

%% ==================== 13. 图例 ====================

validHandles = lineHandles(isgraphics(lineHandles));

lgd = legend(ax, ...
    validHandles, ...
    'Location', 'southeast', ...
    'NumColumns', 2, ...
    'FontSize', legendSize, ...
    'Interpreter', 'none');

lgd.FontName   = 'Times New Roman';
lgd.FontWeight = 'bold';
lgd.Box        = 'on';
lgd.LineWidth  = 1.3;
lgd.Color      = 'white';

%% ==================== 14. 统一图形布局 ====================

% 与fig2b保持完全相同的底部位置和绘图区高度
% fig2a没有颜色条，因此可以使用更大的横向宽度
ax.Position = [0.11, 0.14, 0.84, 0.80];

hold(ax, 'off');

%% ==================== 15. 保存高清图片 ====================

exportgraphics(fig, ...
    outputFile, ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

%% ==================== 16. 输出提示 ====================

fprintf('\nFig2a绘制完成。\n');
fprintf('成功读取%d条速度轨迹。\n', validCount);
fprintf('目标轨迹：Run %d\n', TARGET_RUN);
fprintf('画布尺寸：1100 × 700像素\n');
fprintf('图片保存位置：\n%s\n\n', outputFile);
