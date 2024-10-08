function NID_plot2d(ax_fig,data, probeSets, ylimit)

% NR_plot2d is a universal 2-d interpolated map plot function
% input:
%   data: data to plot
%   probeSets: probe configuration
%   ylim
% init
    if nargin < 3 || ( nargin >= 3 && isempty(ylimit)) % 'auto',
        y_upper=max(abs(data(:)));
        y_lower=min(abs(data(:)));
    else
        y_upper=ylimit(2); 
        y_lower=ylimit(1);
    end
    y_absmax=max([abs(y_upper),abs(y_lower)]);
    texts{length(data)}=0;
    for i=1:length(data)
        texts{i}=num2str(i);
    end
% should be adjusted later    
% main process
    for probeSetid = 1:length(probeSets)
%         axes1= subplot(1,length(probeSets), probeSetid);
        axes1 = ax_fig(probeSetid);
        probesetting=probeSets{probeSetid}.probeSet;
    	%init    
        rowlr=getleftright(sum(probesetting>1000,2));
        collr=getleftright(sum(probesetting>1000,1));
        probesetting=probesetting(rowlr(1):rowlr(2),collr(1):collr(2));
        % mapping = topomap(data, probesetting);
        mapping = topomap(data, probesetting);
        % draw imagesc
        imagesc(mapping,'Parent',axes1,[-y_absmax,y_absmax]);
        colormap(axes1,jet);
%         colorbar_handles = colorbar('SouthOutside','peer',axes1);
%         colorbar('SouthOutside');
        %set(axes1, 'Visible','off');
        set(axes1,'XTick',[],'YTick',[]);
%         title(axes1, ['ProbeSet : ', num2str(probeSetid)]);
%         daspect(axes1, [1 1 1]);
        % channel text
        [xy,xyid]=findxy(probesetting);  
        xy(:,1)=xy(:,1)*size(mapping,2)/size(probesetting,2)-size(mapping,2)/size(probesetting,2)/2;
        xy(:,2)=xy(:,2)*size(mapping,1)/size(probesetting,1)-size(mapping,1)/size(probesetting,1)/2;
        text(xy(:,1),xy(:,2),texts(xyid),'Parent',axes1,'HorizontalAlignment','center'); 
    end
end
function [xy,xyid]=findxy(probesetting)
    xy=[];
    xyid=[];
    for rowi = 1:size(probesetting,1)
        for coli = 1:size(probesetting,2)
            if(probesetting(rowi,coli)>1000)
                xy(end+1,:)=[coli,rowi];
                xyid(end+1)=probesetting(rowi,coli)-1000;
            end
        end
    end
end
function lr=getleftright(array)
    lr=[length(array),1];
    for i=1:length(array)
        if(array(i)>0)
            lr(1)=i;
            break;
        end
    end
    for i=length(array):-1:1
        if(array(i)>0)
            lr(2)=i;
            break;
        end
    end
end
function mapping = topomap(data, probesetting)
% probesetting fill in
    %origin
    map=zeros(size(probesetting));
    for i = 1:length(data)
        map(find(probesetting==1000+i))=data(i);
    end
    % Nearest-neighour interpolation
    direct=[0,1;0,-1;-1,0;1,0];
    for rowi = 1:size(map,1)
        for coli = 1:size(map,2)
            if(map(rowi,coli)~=0) continue; end
            tot=0;
            toti=0;
            for i = 1:4
                r=rowi+direct(i,1);
                c=coli+direct(i,2);
                if (inside(r,c,size(map)))
                    tot=tot+map(r,c);
                    toti=toti+1;
                end
            end
            map(rowi,coli)=tot/toti;
        end
    end
% map extend
    mapping=interp2(map,4,'cubic');
end

function ok=inside(r,c,sz)
    ok=1;
    if(r<1 || c<1)ok=0;end
    if(r>sz(1) || c>sz(2)) ok=0; end
end