function report=verify_reproduction()
% Execute every figure entry and verify the five manuscript table dimensions.
% Run from MATLAB with this folder on the path. No stochastic simulation runs.
root=fileparts(mfilename('fullpath'));previous=pwd;
oldVisible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@()restore(previous,oldVisible));
cd(root);addpath(root);set(groot,'DefaultFigureVisible','off');
entries={'fig1a','fig1b','fig1c','fig1d','fig2a','fig2b','fig3','fig4','fig5','fig6',...
 'fig7a','fig7b','fig7c','fig7d','fig7e','fig8','fig9a','fig9b','fig9c','fig9d','fig9e','figA1a','figA1b'};
for k=1:numel(entries)
 fprintf('CHECK_ENTRY %s\n',entries{k});one_entry(entries{k});
 assert(~isempty(findall(groot,'Type','figure')),'No figure generated: %s',entries{k});
 close all;
end
pack=revision_tables(false);actual=arrayfun(@(x)height(x.data),pack);
assert(isequal(actual,[15,15,4,6,6]),'Unexpected numerical table sizes');
report=struct('MATLAB',version,'panels_tested',numel(entries),'table_rows',actual,...
 'prctile_available',exist('prctile','file')>0,'sgolayfilt_available',exist('sgolayfilt','file')>0);
fprintf('PASS: 23 figure entries and five numerical tables.\n');
end
function one_entry(name)
% Isolate legacy scripts that clear variables in their caller's workspace.
run([name,'.m']);
end
function restore(folder,visible)
cd(folder);set(groot,'DefaultFigureVisible',visible);
end
