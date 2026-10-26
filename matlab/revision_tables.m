function pack = revision_tables(showResults)
% Recreate the five manuscript tables from local revision_data CSV files.
% No files are written by this function. Run reproduce_tables.m to inspect.
if nargin<1,showResults=true;end
root=fileparts(mfilename('fullpath'));td=fullfile(root,'revision_data');
assert(isfolder(td),'Keep revision_data beside these MATLAB files.');
pack=struct('name',{},'title',{},'data',{},'rows',{},'latexHeader',{},'latexColumns',{});
for n=[3 4]
    g=readtable(fullfile(td,sprintf('fig%d_main.csv',n)));rows=cell(height(g),5);
    for j=1:height(g)
        val='---';if isfinite(g.mean(j)),val=sprintf('%.6f',g.mean(j));end
        rows(j,:)={sprintf('%.6f',g.D(j)),sprintf('%d',g.Tmax(j)),sprintf('%d',g.captured(j)),sprintf('%d',g.censored(j)),val};
    end
    names={'D','Tmax','Captured','Uncaptured','Sample_mean'};
    head={'$D$','$T_{\max}$','Captured','Uncaptured','Sample mean'};
    pack(end+1)=make(sprintf('table%d_capture_statistics',n-2),sprintf('Table %d: Figure %d capture statistics',n-2,n),rows,names,head,'rrrrr');
end
s=readtable(fullfile(td,'step_means.csv'));d=readtable(fullfile(td,'step_paired_differences.csv'));rows=cell(4,8);
for k=1:4
    g=sortrows(s(s.case_id==k,:),'h','descend');x=d(d.case_id==k & d.h_test>5e-5,:);
    assert(height(g)==3 && height(x)==1,'Time-step table case is incomplete.');
    rows(k,:)={sprintf('%g',g.mu(1)),sprintf('%g',g.a(1)),sprintf('%.6f',g.D(1)),...
        sprintf('%.4f',g.mean(1)),sprintf('%.4f',g.mean(2)),sprintf('%.4f',g.mean(3)),...
        sprintf('%.2f',x.percent),sprintf('[%.2f, %.2f]',x.percent_ci_low,x.percent_ci_high)};
end
pack(end+1)=make('tableA1_steps','Table A.1: time-step comparison',rows,...
    {'mu','a','D','Mean_h1e4','Mean_h1e5','Mean_h1e6','delta_h_percent','CI95_percent'},...
    {'$\mu$','$a$','$D$','$\overline T_{10^{-4}}$','$\overline T_{10^{-5}}$','$\overline T_{10^{-6}}$','$\delta_h$ (\%)','95\% interval'},'rrrrrrrr');
m=readtable(fullfile(td,'model_means.csv'));d=readtable(fullfile(td,'model_paired_differences.csv'));
rows=cell(6,9);effects=cell(6,6);
for k=1:6
    g=sortrows(m(m.case_id==k,:),'model');assert(height(g)==3,'Three-model table case is incomplete.');
    c=g(strcmp(g.model,'C'),:);assert(height(c)==1);
    prefix={sprintf('%g',g.mu(1)),sprintf('%g',g.a(1)),sprintf('%.6f',g.D(1))};
    relative=100*(c.mean-c.analytic)/c.analytic;
    rows(k,:)=[prefix,{sprintf('%.4f',g.mean(1)),sprintf('%.4f',g.mean(2)),sprintf('%.4f',g.mean(3)),...
        sprintf('[%.2f, %.2f]',c.ci_low,c.ci_high),sprintf('%.4f',c.analytic),sprintf('%.2f',relative)}];
    comparisons={'A_minus_B','B_minus_C','A_minus_C'};values=cell(1,3);
    for j=1:3
        x=d(d.case_id==k & strcmp(d.comparison,comparisons{j}),:);assert(height(x)==1);
        values{j}=sprintf('%.2f [%.2f, %.2f]',x.percent_of_A,x.percent_ci_low,x.percent_ci_high);
    end
    effects(k,:)=[prefix,values];
end
pack(end+1)=make('tableA2_model_means','Table A.2: model means and analytical prediction',rows,...
    {'mu','a','D','A','B','C','C_CI95','T_analytic','epsilon_C_percent'},...
    {'$\mu$','$a$','$D$','A','B','C','C 95\% interval','$T_{\mathrm{an}}$','$\varepsilon_C$ (\%)'},'rrrrrrrrr');
pack(end+1)=make('tableA3_model_effects','Table A.3: paired effects of the approximations',effects,...
    {'mu','a','D','delta_AB_percent_CI95','delta_BC_percent_CI95','delta_AC_percent_CI95'},...
    {'$\mu$','$a$','$D$','$\delta_{AB}$','$\delta_{BC}$','$\delta_{AC}$'},'rrrccc');
if showResults
    for j=1:numel(pack)
        fprintf('\n%s\n',pack(j).title);disp(pack(j).data);
    end
    fprintf('Five tables are ready. No files were saved.\n');
end
end
function x=make(name,title,rows,names,head,cols)
x=struct('name',name,'title',title,'data',cell2table(rows,'VariableNames',names),...
    'rows',{rows},'latexHeader',{head},'latexColumns',cols);
end
