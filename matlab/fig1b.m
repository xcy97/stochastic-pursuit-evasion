%% 10条猎犬速度轨迹图——小论文高清版（D=0.05, S=1.0）
clear;
clc;
close all;

%% ==================== 1. 文件路径 ====================

% 原始数据所在文件夹
dataDir = fullfile(fileparts(mfilename('fullpath')), 'data');

% 图片保存文件夹
outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

% 图片保存名称
outputFile = fullfile(outputDir, 'fig1b_D005_S1.png');

% 如果图片保存文件夹不存在，则自动创建
if ~isfolder(outputDir)
    mkdir(outputDir);
end

% 检查数据文件夹
if ~isfolder(dataDir)
    error('数据文件夹不存在：%s', dataDir);
end

%% ==================== 2. 参数设置 ====================

numRuns = 10;          % 轨迹数量

window = 101;          % Savitzky-Golay平滑窗口
polyOrder = 3;         % 多项式阶数

curveWidth = 2.2;      % 曲线宽度
labelSize = 30;        % 横纵坐标名称字号
tickSize = 19;         % 坐标刻度数字字号
legendSize = 16;       % 图例字号

% 平滑窗口必须为奇数
if mod(window, 2) == 0
    error('平滑窗口 window 必须是奇数。');
end

% 平滑窗口必须大于多项式阶数
if window <= polyOrder
    error('window 必须大于 polyOrder。');
end

%% ==================== 3. 创建图形 ====================

fig = figure( ...
    'Position', [180, 100, 1100, 680], ...
    'Color', 'w', ...
    'Renderer', 'painters');

ax = axes(fig);

hold(ax, 'on');
box(ax, 'on');

%% ==================== 4. 设置10条曲线颜色 ====================

% 与Python中matplotlib的tab10颜色基本一致
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

%% ==================== 5. 读取数据并绘图 ====================

validCount = 0;

for i = 1:numRuns

    % 构造每一次运行对应的文件名
    fileName = sprintf( ...
        'D=0.05,S=1.0speed_run%d.txt', i);

    filePath = fullfile(dataDir, fileName);

    % 检查文件是否存在
    if ~isfile(filePath)
        warning('未找到文件，已跳过：%s', filePath);
        continue;
    end

    % 读取txt数据
    data = readmatrix(filePath);

    % 检查是否至少包含两列
    if size(data, 2) < 2
        warning('文件少于两列，已跳过：%s', fileName);
        continue;
    end

    % 删除前两列中含NaN或Inf的无效行
    validRows = ...
        isfinite(data(:, 1)) & isfinite(data(:, 2));

    data = data(validRows, :);

    if isempty(data)
        warning('文件中没有有效数据：%s', fileName);
        continue;
    end

    % 第一列为时间，第二列为速度
    t = data(:, 1);
    v = data(:, 2);

    %% Savitzky-Golay平滑

    if length(v) >= window

        % 优先使用Signal Processing Toolbox中的sgolayfilt
        if exist('sgolayfilt', 'file') == 2

            vSmooth = sgolayfilt( ...
                v, polyOrder, window);

        else

            % 没有Signal Processing Toolbox时使用替代方法
            vSmooth = smoothdata( ...
                v, 'sgolay', window);

        end

    else

        % 数据长度不足时不进行平滑
        vSmooth = v;

        warning( ...
            '%s的数据点少于%d，未进行平滑。', ...
            fileName, window);

    end

    %% 绘制曲线

    plot(ax, t, vSmooth, ...
        'Color', tab10(i, :), ...
        'LineWidth', curveWidth, ...
        'DisplayName', sprintf('Run %d', i));

    validCount = validCount + 1;

end

% 如果没有读取到任何文件，则停止运行
if validCount == 0
    error(['没有成功读取任何轨迹文件，' ...
           '请检查数据路径和文件名称。']);
end

%% ==================== 6. 横纵坐标名称 ====================

% 横坐标：加粗、斜体的小写t
xlabel(ax, 't', ...
    'Interpreter', 'none', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize, ...
    'FontWeight', 'bold', ...
    'FontAngle', 'italic');

% 纵坐标：‖V₁(t)‖
% 使用单个范数符号字符和Unicode下标，避免字符之间出现额外空隙
ylabel(ax, '‖V₁(t)‖', ...
    'Interpreter', 'none', ...
    'FontName', 'Times New Roman', ...
    'FontSize', labelSize, ...
    'FontWeight', 'bold', ...
    'FontAngle', 'italic');

%% ==================== 7. 坐标轴设置 ====================

% 坐标轴字体
ax.FontName = 'Times New Roman';

% 坐标刻度数字放大
ax.FontSize = tickSize;

% 坐标刻度数字加粗
ax.FontWeight = 'bold';

% 坐标轴边框加粗
ax.LineWidth = 1.7;

% 刻度朝向图内
ax.TickDir = 'in';

% 增大刻度线长度
ax.TickLength = [0.015, 0.015];

% 让坐标轴显示在线条和网格上方
ax.Layer = 'top';

%% ==================== 8. 网格设置 ====================

grid(ax, 'on');

% 网格线样式
ax.GridLineStyle = '--';

% 主网格透明度
ax.GridAlpha = 0.30;

% 次网格透明度
ax.MinorGridAlpha = 0.15;

%% ==================== 9. 图例设置 ====================

lgd = legend(ax, ...
    'Location', 'southeast', ...
    'NumColumns', 2, ...
    'FontSize', legendSize, ...
    'Interpreter', 'none');

% 图例字体
lgd.FontName = 'Times New Roman';

% 图例文字加粗
lgd.FontWeight = 'bold';

% 显示图例边框
lgd.Box = 'on';

% 图例边框加粗
lgd.LineWidth = 1.3;

%% ==================== 10. 调整图形布局 ====================

% 坐标范围先自动贴合数据
axis(ax, 'tight');

% ---------- 统一坐标刻度间隔 ----------
% 横坐标每隔0.5
% 纵坐标每隔0.2
xStep = 0.5;
yStep = 0.2;

% 横纵坐标下限统一从0开始
xMin = 0;
yMin = 0;

% 上限自动向上取整到指定步长的整数倍
xMax = ceil(ax.XLim(2) / xStep) * xStep;
yMax = ceil(ax.YLim(2) / yStep) * yStep;

% 设置坐标范围
xlim(ax, [xMin, xMax]);
ylim(ax, [yMin, yMax]);

% 设置刻度位置
xticks(ax, xMin:xStep:xMax);
yticks(ax, yMin:yStep:yMax);

% 调整绘图区位置，给横纵坐标名称留出空间
ax.Position = [0.12, 0.14, 0.84, 0.80];

hold(ax, 'off');

%% ==================== 11. 保存高清图片 ====================

% 按照600 dpi导出PNG图片
exportgraphics(fig, outputFile, ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

%% ==================== 12. 输出提示 ====================

fprintf('\n绘图完成，共绘制%d条轨迹。\n', validCount);
fprintf('图片已经保存为：\n%s\n\n', outputFile);
