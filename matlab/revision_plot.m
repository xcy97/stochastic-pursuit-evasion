function f = revision_plot(whichFigure, visibility)
% Draw one final-revision figure from revision_data beside this file.
% No simulation, automatic export, or manuscript modification is performed.
% Entry scripts: fig3.m, fig4.m, fig6.m, figA1a.m, figA1b.m.
if nargin<2, visibility=get(groot,'DefaultFigureVisible'); end
root=fileparts(mfilename('fullpath')); td=fullfile(root,'revision_data');
assert(isfolder(td),'Keep revision_data beside these MATLAB files.');
key=lower(char(whichFigure));
blue=[31 119 180]/255;red=[214 39 40]/255;green=[44 160 44]/255;orange=[.85 .325 .098];
if any(strcmp(key,{'fig3','fig4'}))
    n=str2double(key(end));
    th=readtable(fullfile(td,sprintf('fig%d_theory.csv',n)));
    main=readtable(fullfile(td,sprintf('fig%d_main.csv',n)));
    fine=readtable(fullfile(td,sprintf('fig%d_fine.csv',n)));
    f=figure('Visible',visibility,'Name',sprintf('Figure %d - current revision',n),...
        'NumberTitle','off','Tag',['revision_' key],'Color','w','Units','centimeters','Position',[2 2 17.5 12.8]);
    ax=axes(f,'Position',[.14 .15 .83 .81]);hold(ax,'on');
    h1=loglog(ax,th.D,th.mean,'-','Color',blue,'LineWidth',2.1);
    ok=main.captured==1000;
    h2=loglog(ax,main.D(ok),main.mean(ok),'o','Color',red,'MarkerFaceColor',red,'MarkerSize',7.5,'LineStyle','none');
    h3=errorbar(ax,fine.D,fine.mean,fine.mean-fine.ci_low,fine.ci_high-fine.mean,'s',...
        'Color',green,'MarkerFaceColor',green,'MarkerSize',6.8,'LineStyle','none','LineWidth',1.3,'CapSize',6);
    setup(ax);xlim(ax,[.0008 50]);
    if n==3,ylim(ax,[1 1e10]);loc='northeast';else,ylim(ax,[2.8 150]);loc='northwest';end
    lg=legend(ax,[h1 h2 h3],{'Theory (N = 1)','Simulation (\Deltat = 10^{-4})',...
        'Simulation (\Deltat = 10^{-6})'},'Location',loc,'FontName','Times New Roman',...
        'FontWeight','bold','FontSize',12,'Interpreter','tex','Box','on');lg.EdgeColor='k';
elseif any(strcmp(key,{'figa1a','figa1b'}))
    mu=3;n=3;if strcmp(key,'figa1b'),mu=30;n=4;end
    m=readtable(fullfile(td,'model_means.csv'));th=readtable(fullfile(td,sprintf('fig%d_theory.csv',n)));
    f=figure('Visible',visibility,'Name',sprintf('Figure A.1 - mu = %g',mu),...
        'NumberTitle','off','Tag',['revision_' key],'Color','w','Units','centimeters','Position',[2 2 15.5 12.8]);
    ax=axes(f,'Position',[.16 .15 .80 .81]);hold(ax,'on');use=th.D>=.015;
    hh=gobjects(1,4);hh(1)=loglog(ax,th.D(use),th.mean(use),'-','Color',blue,'LineWidth',2);
    names={'A','B','C'};cl={red,green,orange};marks={'o','^','s'};
    for j=1:3
        r=m(m.mu==mu & strcmp(m.model,names{j}),:);r=sortrows(r,'D');
        hh(j+1)=errorbar(ax,r.D,r.mean,r.mean-r.ci_low,r.ci_high-r.mean,marks{j},...
            'Color',cl{j},'MarkerFaceColor',cl{j},'MarkerSize',7,'LineWidth',1.3,'LineStyle','none','CapSize',5);
    end
    setup(ax);xlim(ax,[.015 55]);if mu==3,ylim(ax,[4 260]);else,ylim(ax,[2.8 220]);end
    legend(ax,hh,{'Theory (N = 1)','Model A','Model B','Model C'},'Location','northwest',...
        'FontName','Times New Roman','FontWeight','bold','FontSize',12,'Interpreter','tex','Box','on');
elseif strcmp(key,'fig6')
    t=readtable(fullfile(td,'fig6_hybrid_elapsed.csv'));
    corrected=t.old_hybrid+(1-t.capture_rate).*t.Tmax;
    assert(all(abs(corrected-t.hybrid_mean)<1e-8),'Figure 6 elapsed-time correction does not match the saved results.');
    t.hybrid_mean=corrected;
    f=figure('Visible',visibility,'Name','Figure 6 - current hybrid estimates',...
        'NumberTitle','off','Tag','revision_fig6','Color','w','Units','centimeters','Position',[2 2 17.5 12.8]);
    ax=axes(f,'Position',[.15 .15 .81 .81]);hold(ax,'on');
    colors=[0 .447 .741;.85 .325 .098;.929 .694 .125;.494 .184 .556;.466 .674 .188];
    marks={'o','s','^','d','*'};ns=[1 3 8 14 25];h=gobjects(1,5);
    for j=1:5
        r=sortrows(t(t.N==ns(j),:),'D');
        h(j)=loglog(ax,r.D,r.hybrid_mean,'-','Marker',marks{j},'Color',colors(j,:),...
            'LineWidth',1.5,'MarkerSize',6.5);
    end
    set(ax,'XScale','log','YScale','log','FontName','Times New Roman','FontWeight','bold',...
        'FontSize',15,'LineWidth',1.3,'Box','on','TickDir','in','XGrid','on','YGrid','on',...
        'XMinorGrid','off','YMinorGrid','off','GridLineStyle','--','GridColor',[.5 .5 .5],'GridAlpha',.6);
    xlabel(ax,'D','FontName','Times New Roman','FontAngle','italic','FontWeight','bold','FontSize',22);
    ylabel(ax,'\langle T_N\rangle','Interpreter','tex','FontName','Times New Roman',...
        'FontAngle','italic','FontWeight','bold','FontSize',22);
    xlim(ax,[.0035 45]);ylim(ax,[.01 1000]);
    legend(ax,h,arrayfun(@(n)sprintf('N = %d',n),ns,'UniformOutput',false),'Location','southwest',...
        'FontName','Times New Roman','FontSize',12,'FontWeight','bold','Box','on');
else
    error('Choose fig3, fig4, fig6, figA1a, or figA1b.');
end
drawnow;
fprintf('%s displayed. Inputs: %s\n',whichFigure,td);
fprintf('No files were saved. The figure window remains open.\n');
end
function setup(ax)
set(ax,'XScale','log','YScale','log','FontName','Times New Roman','FontWeight','bold',...
    'FontSize',15,'LineWidth',1.4,'Box','on','TickDir','in','XGrid','on','YGrid','on',...
    'XMinorGrid','off','YMinorGrid','off','GridLineStyle','--','GridColor',[.5 .5 .5],'GridAlpha',.6,...
    'TickLabelInterpreter','tex');
xlabel(ax,'D','FontName','Times New Roman','FontAngle','italic','FontWeight','bold','FontSize',22);
ylabel(ax,'\langle T_1\rangle','Interpreter','tex','FontName','Times New Roman',...
    'FontAngle','italic','FontWeight','bold','FontSize',22);
end
