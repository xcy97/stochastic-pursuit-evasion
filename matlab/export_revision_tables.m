function export_revision_tables(outputDir)
% Optional export. With no argument, choose a folder in a dialog.
% Calling reproduce_tables.m alone does not save any files.
if nargin<1 || isempty(outputDir)
    outputDir=uigetdir(pwd,'Choose a folder for the five CSV and LaTeX tables');
    if isequal(outputDir,0),fprintf('Export cancelled. No files written.\n');return;end
end
if ~isfolder(outputDir),mkdir(outputDir);end
pack=revision_tables(false);bs=char(92);
for j=1:numel(pack)
    x=pack(j);writetable(x.data,fullfile(outputDir,[x.name '.csv']));
    fid=fopen(fullfile(outputDir,[x.name '.tex']),'w','n','UTF-8');
    assert(fid>=0,'Cannot open output table file.');cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,'%s\n',[bs 'begin{tabular}{' x.latexColumns '}']);
    fprintf(fid,'%s\n',[bs 'toprule']);
    fprintf(fid,'%s\n',[strjoin(x.latexHeader,' & ') ' ' bs bs]);
    fprintf(fid,'%s\n',[bs 'midrule']);
    for k=1:size(x.rows,1),fprintf(fid,'%s\n',[strjoin(x.rows(k,:),' & ') ' ' bs bs]);end
    fprintf(fid,'%s\n',[bs 'bottomrule']);fprintf(fid,'%s\n',[bs 'end{tabular}']);
    clear cleanup;
end
fprintf('Five CSV and five LaTeX tables written to %s\n',outputDir);
end
