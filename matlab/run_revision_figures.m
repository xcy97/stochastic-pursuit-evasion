% 一次显示返修更新的图3、图4、图6及附录图A.1的两个面板。
% 不调用旧图9a程序，不自动保存图片，不重新模拟。
revisionFolder=fileparts(mfilename('fullpath'));
addpath(revisionFolder);
revisionKeys={'fig3','fig4','fig6','figA1a','figA1b'};
for revisionIndex=1:numel(revisionKeys)
    revision_plot(revisionKeys{revisionIndex});
end
fprintf('Five revision figure windows are ready. No files were saved.\n');
