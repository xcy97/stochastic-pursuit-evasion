% 复现论文的五张数值表，不需要Python，不自动保存文件。
% 结果显示在命令窗口，并放入右侧工作区；双击变量即可查看表格。
revisionFolder=fileparts(mfilename('fullpath'));
addpath(revisionFolder);
revisionTablePack=revision_tables(true);
for revisionIndex=1:numel(revisionTablePack)
    assignin('base',revisionTablePack(revisionIndex).name,revisionTablePack(revisionIndex).data);
end
fprintf('Double-click table1_capture_statistics, table2_capture_statistics, or tableA1/A2/A3 variables in Workspace.\n');
