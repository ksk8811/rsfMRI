function [V, P, fcallback]=conn_mesh_display_multi(filenameSURF,filenameVOL,FSfolder,sphplots,connplots,facealpha,position,defaultcolors,defaultfilepath,Vrange,domask,dosub)
global CONN_gui;
persistent data;
if nargin>0&&isstruct(filenameSURF),data=filenameSURF;return;end

THR=nan;%3.56;%2.20%4.7;%5.18;%nan;
if nargin<1||(isempty(filenameSURF)&&~ischar(filenameSURF)), filenameSURF=spm_select(1,'image','Select a file'); end
if nargin<2||(isempty(filenameVOL)&&~ischar(filenameVOL)), filenameVOL=spm_select(1,'image','Select a file'); end
if nargin<3||isempty(FSfolder), FSfolder=fullfile(fileparts(which('conn')),'utils','surf'); end
if nargin<4, sphplots=[]; end
if nargin<5, connplots=[]; end
if nargin<6||isempty(facealpha), facealpha=1; end
if nargin<7||isempty(position), position=[-1,0,0];end
if nargin<8||isempty(defaultcolors), defaultcolors={[1,.1,.1],[.1,.1,1]}; end
if nargin<9||isempty(defaultfilepath), defaultfilepath=pwd; end
if nargin<10, Vrange=[]; end
if nargin<11||isempty(domask), domask=true; end
if nargin<12||isempty(dosub), dosub=isempty(filenameSURF); end
inputparams={filenameSURF,filenameVOL,FSfolder,sphplots,connplots,facealpha,position,defaultcolors,defaultfilepath,Vrange,domask,dosub}; 

fcallback=@(control,varargin)conn_mesh_display_refresh([],[],control,varargin{:});

hmsg=conn_msgbox('Initializing. Please wait...');
if isempty(data), 
    files={'white','cortex','pial.smoothed','inflated','subcortical'};
    for nfiles=1:numel(files)
        data.rend{nfiles}=conn_surf_readsurf(fullfile(FSfolder,[files{nfiles},'.surf']));
    end
    data.curv{3}{1}=sign(conn_freesurfer_read_curv(fullfile(FSfolder,'lh.curv.paint')));
    data.curv{3}{2}=sign(conn_freesurfer_read_curv(fullfile(FSfolder,'rh.curv.paint')));
    data.curv{3}=cell2mat(data.curv{3});
    data.curv{1}=zeros(size(data.curv{3}));
    data.curv{2}=zeros(size(data.curv{3}));
    data.curv{4}=2*data.curv{3};
    a=spm_vol(fullfile('/Users/k.siudakrzywicka/Desktop/tools/conn','utils','surf','mask.surface.brainmask.nii'));
    data.mask=spm_read_vols(a);
    data.mask=reshape(data.mask,[],2);
end
state.selectedsurface=2;
state.defaultfilepath=defaultfilepath;
V = {};
if ~isempty(filenameSURF)
    state.selectedsurface=3;
    for curr_surf=1:length(filenameSURF)
        a=spm_vol(filenameSURF{curr_surf});
        filepath=fileparts(filenameSURF{curr_surf});
        if ~isempty(filepath), state.defaultfilepath=filepath; end
        if isequal(a.dim,conn_surf_dims(8).*[1 1 2])
            V{curr_surf}=spm_read_vols(a);
            V{curr_surf}=reshape(V,[],2);
        else
            V{curr_surf}=conn_surf_extract(filenameSURF{curr_surf},{fullfile(FSfolder,'lh.pial.surf'),fullfile(FSfolder,'rh.pial.surf'),fullfile(FSfolder,'lh.mid.surf'),fullfile(FSfolder,'rh.mid.surf'),fullfile(FSfolder,'lh.white.surf'),fullfile(FSfolder,'rh.white.surf')}); % use this for smoother display
            %V=conn_surf_extract(filenameSURF,{fullfile(FSfolder,'lh.mid.surf'),fullfile(FSfolder,'rh.mid.surf')});                                                                                                                                          % use this for accurate values 
            V{curr_surf}=cell2mat(V{curr_surf});
            maskV=isnan(V{curr_surf})|(V{curr_surf}==0);
            V{curr_surf}(maskV)=0;
            V{curr_surf}=sum(reshape(V{curr_surf},[],2,3),3)./max(1,sum(reshape(~maskV,[],2,3),3));                                                                                                                                                                                % use this for smoother display
            %V=sum(reshape(V,[],2,1),3)./max(1,sum(reshape(~maskV,[],2,1),3));                                                                                                                                                                               % use this for accurate values 
        end
    end
    state.reducedpatch=1;
else
    V=zeros(size(data.curv{1}));
    state.reducedpatch=2;
end
if ~isempty(filenameVOL)
    state.selectedsurface=1;
    pVOL1=conn_surf_volume(filenameVOL,0,0,[],1,1,0);
    pVOL2=conn_surf_volume(filenameVOL,0,0,[],1,1,1);
    filepath=fileparts(filenameVOL);
    if ~isempty(filepath), state.defaultfilepath=filepath; end
else
    pVOL1=[];
    pVOL2=[];
end

if false,
% if nargout>1,
    P=data.rend{state.selectedsurface};
% elseif ~nargout,
elseif true,    
    P=[];
    if ~isnan(THR), V=V.*(V>THR); end
    if any(V{1}(:)<0)&&any(V{1}(:)>0), 
        %V=sign(V); 
        dotwosided=true; 
    else
        dotwosided=false; 
    end
    global_show = []; % Accumulate mask for smoothing.
    Vrange = cell(length(filenameSURF),1);
    for curr_surf=1:length(filenameSURF)
        show=~isnan(V{curr_surf})&V{curr_surf}~=0;
        if isempty(global_show)
            global_show = show;
        else
            global_show = global_show | show;
        end
        V{curr_surf}(~show)=0;
        if ~isempty(Vrange{curr_surf})
            if sign(Vrange{curr_surf}(1))*sign(Vrange{curr_surf}(end))==-1, dotwosided=true; Vrange{curr_surf}=[min(Vrange{curr_surf}) 0 max(Vrange{curr_surf})]; 
            else dotwosided=false; Vrange{curr_surf}=sort(Vrange{curr_surf}([1 end]));
            end
        else
            if dotwosided
                Vrange{curr_surf}=[min(V{curr_surf}(show)) 0 max(V{curr_surf}(show))];
            elseif any(V{curr_surf}(show)),
    %             if any(show&V>0), Vrange=[0 max(V(show))];
    %             else              Vrange=[min(V(show)) 0];
    %             end
                global SAMI_conn_max_t_val;
                global SAMI_conn_min_t_val;
                if isempty(SAMI_conn_max_t_val)
                    if any(show&V{curr_surf}>0), Vrange{curr_surf}=[0 max(V{curr_surf}(show))];
                    else                         Vrange{curr_surf}=[min(V{curr_surf}(show)) 0];
                    end
                else
                    if any(any(show&V{curr_surf}>0)), Vrange{curr_surf}=[SAMI_conn_min_t_val{curr_surf} SAMI_conn_max_t_val{curr_surf}];
                    else                              Vrange{curr_surf}=[-SAMI_conn_max_t_val{curr_surf} -SAMI_conn_min_t_val{curr_surf}];
                    end                
                end
            else Vrange{curr_surf}=[];
            end
        end
        if numel(Vrange{curr_surf})>2
            m1=show&V{curr_surf}>0;V{curr_surf}(m1)=V{curr_surf}(m1)/abs(Vrange{curr_surf}(3));
            m1=show&V{curr_surf}<0;V{curr_surf}(m1)=V{curr_surf}(m1)/abs(Vrange{curr_surf}(1));
            V{1}(show)=max(-1,min(1, V{curr_surf}(show) ));
        elseif numel(Vrange{curr_surf})==2&&Vrange{curr_surf}(2)>0, V{curr_surf}(show)=max(0,min(1, (V{curr_surf}(show)-Vrange{curr_surf}(1))/(Vrange{curr_surf}(2)-Vrange{curr_surf}(1)) ));
        elseif numel(Vrange{curr_surf})==2&&Vrange{curr_surf}(1)<0, V{curr_surf}(show)=max(-1,min(0, (V{curr_surf}(show)-Vrange{curr_surf}(2))/(Vrange{curr_surf}(2)-Vrange{curr_surf}(1)) ));
        end
    end
    
%     cdat=cellfun(@(x)conn_bsxfun(@times,1-.15*x,shiftdim([.7,.65,.6],-1)),data.curv,'uni',0);%cdat=cellfun(@(x)conn_bsxfun(@times,.75-.04*x,shiftdim([1,.9,1],-1)),data.curv,'uni',0);
    % SAMI
    % This change makes the cervature contrast smaller, to adapt to conn17e
    cdat=cellfun(@(x)conn_bsxfun(@times,1-.05*x,shiftdim([.7,.65,.6],-1)),data.curv,'uni',0);%cdat=cellfun(@(x)conn_bsxfun(@times,.75-.04*x,shiftdim([1,.9,1],-1)),data.curv,'uni',0);
    % For Flo, temporary change
%     cdat=cellfun(@(x)conn_bsxfun(@times,1-.3*x,shiftdim([1,1,1],-1)),data.curv,'uni',0);%cdat=cellfun(@(x)conn_bsxfun(@times,.75-.04*x,shiftdim([1,.9,1],-1)),data.curv,'uni',0);

    
%     global sami_color_hack;
%     sami_color_hack = false;
%     if sami_color_hack
%         global sami_tmp_gradient_neg;
%         global sami_tmp_gradient_pos;
%         sami_tmp_gradient_neg=repmat(1-linspace(1,0,128)'.^2,[1,3]).*colorGradient([0 0 0], [0 1 0], 128)+repmat(linspace(1,0,128)'.^2,[1,3])*.1;
%         sami_tmp_gradient_pos=repmat(1-linspace(1,0,128)'.^2,[1,3]).*colorGradient([0 0 0], [0 1 0], 128)+repmat(linspace(1,0,128)'.^2,[1,3])*.1;
%     else
%         sami_tmp_gradient_neg = hot(128); % default.
%     end
%     cmap2=repmat(1-linspace(1,0,128)'.^2,[1,3]).*sami_tmp_gradient_neg+repmat(linspace(1,0,128)'.^2,[1,3])*.1;
                   % Move the black           % Initial gradient    % Add shading
    cmap2=repmat(1-linspace(1,0,128)'.^2,[1,3]).*hot(128)+repmat(linspace(1,0,128)'.^2,[1,3])*.1; % Create the gradient
    cmap2=cmap2(33:end,:); % Remove the black bottom
    cmap2=[fliplr(flipud(cmap2));cmap2];  % Add negative by flipping axis (R->B)

%     if sami_color_hack
%     cmap2=[flipud(sami_tmp_gradient_neg(33:end,:));sami_tmp_gradient_pos(33:end,:)];
%     else
        
%     end
%     cmap2=[fliplr(flipud(cmap2));cmap2];

    global SAMI_conn_colorgradiants;
    global SAMI_map_alphas;

    emph=0.9;
    
    for curr_map=1:length(filenameSURF)
        
        curr_color=SAMI_conn_colorgradiants{curr_map};
        cmap2=repmat(1-linspace(1,0,128)'.^2,[1,3]).*curr_color+repmat(linspace(1,0,128)'.^2,[1,3])*.1;
        cmap2=cmap2(33:end,:);
        cmap2=[fliplr(flipud(cmap2));cmap2];
        
        cdat2{curr_map}=max(0,min(1, ind2rgb(round((size(cmap2,1)+1)/2+emph*96*V{curr_map}),cmap2)));
        alpha=0.8;
%         alpha=SAMI_map_alphas{curr_map};
%         cdat=cellfun(@(x)conn_bsxfun(@times,1-alpha*(V{curr_map}~=0),x) + conn_bsxfun(@times,alpha*(V{curr_map}~=0),cdat2{curr_map}),cdat,'uni',0);  % SAMI - Data projected.. 
        cdat=cellfun(@(x)conn_bsxfun(@times,1-alpha*(V{curr_map}~=0),x) + conn_bsxfun(@times,alpha*(V{curr_map}~=0),cdat2{curr_map}),cdat,'uni',0);  % SAMI - Data projected.. 
    end

    if domask, cdat=cellfun(@(x)conn_bsxfun(@times,data.mask,x)+conn_bsxfun(@times,~data.mask,shiftdim(.6*[1 1 1],-1)),cdat,'uni',0); end
            
    smoothing=1;
%     smoothing=4;
    for n1=1:2
        A=spm_mesh_adjacency(data.rend{1}(n1));
        A=double(speye(size(A,1))|A);
        Ax=sparse(1:size(A,1),1:size(A,1),1./max(eps,sum(A,2)))*A;
        mask=sqrt(max(0,double(global_show(:,n1))));
        for n=1:smoothing,mask=Ax*mask;end; mask=mask/max(eps,max(mask(:)));
        mask=2*min(mask,1-mask);
        Ax=sparse(1:size(A,1),1:size(A,1),1-mask)+sparse(1:size(A,1),1:size(A,1),mask./max(eps,sum(A,2)))*A;
        for n=1:5*smoothing,for n2=1:numel(cdat), cdat{n2}(:,n1,:)=Ax*permute(cdat{n2}(:,n1,:),[1 3 2]);end;end
    end
            
    if ishandle(hmsg), delete(hmsg); end
%     state.hfig=figure('numbertitle','off','color',[.2,.6,.7],'menubar','none','render','opengl');
    % Sami - black background
    state.hfig=figure('numbertitle','off','color',[1.0,1.0,1.0],'menubar','none','render','opengl');
    if ~isempty(filenameSURF{1}), set(state.hfig,'name',['conn 3d display: ',filenameSURF{1}]); else set(state.hfig,'name','conn 3d display'); end
    state.hax=axes('parent',state.hfig);
    state.facealpha=facealpha;
    state.cdat=cdat; 
    state.selected_vertices={1:size(data.rend{1}(1).vertices,1), CONN_gui.refs.surf.default2reduced};
    state.selected_faces={data.rend{1}(1).faces, CONN_gui.refs.surf.spherereduced.faces};
%     state.patch(1)=patch(data.rend{state.selectedsurface}(1),'facevertexcdata',permute(state.cdat{state.selectedsurface}(:,1,:),[1 3 2]),'facecolor','interp','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','facealpha',state.facealpha);
%     state.patch(2)=patch(data.rend{state.selectedsurface}(2),'facevertexcdata',permute(state.cdat{state.selectedsurface}(:,2,:),[1 3 2]),'facecolor','interp','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','facealpha',state.facealpha);
    state.patch(1)=patch(struct('vertices',data.rend{state.selectedsurface}(1).vertices(state.selected_vertices{state.reducedpatch},:),'faces',state.selected_faces{state.reducedpatch}),'parent',state.hax,...
        'facevertexcdata',permute(state.cdat{state.selectedsurface}(state.selected_vertices{state.reducedpatch},1,:),[1 3 2]),'facecolor','interp','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','facealpha',state.facealpha,'backfacelighting','unlit');
    state.patch(2)=patch(struct('vertices',data.rend{state.selectedsurface}(2).vertices(state.selected_vertices{state.reducedpatch},:),'faces',state.selected_faces{state.reducedpatch}),'parent',state.hax,...
        'facevertexcdata',permute(state.cdat{state.selectedsurface}(state.selected_vertices{state.reducedpatch},2,:),[1 3 2]),'facecolor','interp','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','facealpha',state.facealpha);
    state.subpatch(1)=patch(data.rend{end}(1),'facecolor',.6*[1 1 1],'edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','facealpha',state.facealpha,'parent',state.hax);
    state.subpatch(2)=patch(data.rend{end}(2),'facecolor',.6*[1 1 1],'edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','facealpha',state.facealpha,'parent',state.hax);
    if ~dosub, set(state.subpatch,'visible','off'); end
    state.facealphablob=1;
    if ~isempty(pVOL1)
        state.patchblob1=patch(pVOL1(1),'facecolor','r','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','parent',state.hax);
        state.patchblob2=patch(pVOL1(2),'facecolor','r','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','parent',state.hax);
    else state.patchblob1=[]; state.patchblob2=[]; 
    end
    if ~isempty(pVOL2)
        state.patchblob3=patch(pVOL2(1),'facecolor','b','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','parent',state.hax);
        state.patchblob4=patch(pVOL2(2),'facecolor','b','edgecolor','none','alphadatamapping','none','FaceLighting', 'phong','parent',state.hax);
    else state.patchblob3=[]; state.patchblob4=[]; 
    end
    axis(state.hax,'equal'); 
    axis(state.hax,'off'); 
    view(state.hax,position);
    set(state.hax,'units','norm','position',[0,0,1,1]);
    state.light=[light light];set(state.light,'position',position,'visible','on','color',.5*[1 1 1]);    
    tgca=state.hax;
    % Sami    
    global SAMI_conn_no_colorbar;    
    if SAMI_conn_no_colorbar
        state.colorbar=[];
    else    
        if dotwosided, 
    %         axes('units','norm','position',[.95 .1 .04 .8]);
            axes('units','norm','position',[.95 .1 .04 .8]);
            temp=imagesc(max(0,min(1, ind2rgb(round((size(cmap2,1)+1)/2+emph*96*linspace(-1,1,128)'),cmap2))));
            set(gca,'YColor','w','ydir','normal','ytick',[.5,64.5,128.5],'yticklabel',arrayfun(@(x)num2str(x,'%.2f'),Vrange{1},'uni',0),'xtick',[],'box','off'); % SAMI - changed the color to white
            state.colorbar=[gca temp];
        elseif any(Vrange{1}>0)
            axes('units','norm','position',[.95 .1 .04 .8]);
            temp=imagesc(max(0,min(1, ind2rgb(round((size(cmap2,1)+1)/2+emph*96*linspace(0,1,128)'),cmap2))));
    %         set(gca,'ydir','normal','ytick',[.5,128.5],'yticklabel',arrayfun(@(x)num2str(x,'%.2f'),Vrange,'uni',0),'xtick',[],'box','off');
            set(gca,'YColor','w','ydir','normal','ytick',[.5,128.5],'yticklabel',arrayfun(@(x)num2str(x,'%.2f'),Vrange{1},'uni',0),'xtick',[],'box','off'); % SAMI - changed the color to white
            state.colorbar=[gca temp];
        elseif any(Vrange{1}<0)
            axes('units','norm','position',[.95 .1 .04 .8]);
            temp=imagesc(max(0,min(1, ind2rgb(round((size(cmap2,1)+1)/2+emph*96*linspace(-1,0,128)'),cmap2))));
            set(gca,'YColor','w','ydir','normal','ytick',[.5,128.5],'yticklabel',arrayfun(@(x)num2str(x,'%.2f'),Vrange{1},'uni',0),'xtick',[],'box','off'); % SAMI - changed the color to white
            state.colorbar=[gca temp];
        else 
            state.colorbar=[];
        end
    end

    set(state.colorbar,'visible','on');
    axes(tgca);
    state.sphplots=[];
    state.sphplots_x=[];
    state.sphplots_txt=[];
    if ~isempty(sphplots)
        if ~isstruct(sphplots), sphplots=struct('sph_xyz',sphplots); end
        if ~isfield(sphplots,'sph_c'), sphplots.sph_c=ones(size(sphplots.sph_xyz,1),3); end
        if ~isfield(sphplots,'sph_r'), sphplots.sph_r=5*ones(size(sphplots.sph_xyz,1),1); end
        if ~iscell(sphplots.sph_c), sphplots.sph_c=num2cell(sphplots.sph_c,2); end
        [x,y,z]=sphere(32);
        hold on;
        for n1=1:size(sphplots.sph_xyz,1),
            cdata=.6+.4*(sphplots.sph_xyz(n1,1)*x+sphplots.sph_xyz(n1,2)*y+sphplots.sph_xyz(n1,3)*z)/sqrt(sum(abs(sphplots.sph_xyz(n1,:)).^2));
            %cdata=max(0,min(1,bsxfun(@plus,cdata,shiftdim(sphplots.sph_c{n1}(:),-2)) ));
            cdata=conn_bsxfun(@times,cdata,shiftdim(sphplots.sph_c{n1}(:),-2));
            state.sphplots(n1)=surf(state.hax,sphplots.sph_xyz(n1,1)+sphplots.sph_r(n1)*x,sphplots.sph_xyz(n1,2)+sphplots.sph_r(n1)*y,sphplots.sph_xyz(n1,3)+sphplots.sph_r(n1)*z,zeros(size(x)),'cdata',cdata,'edgecolor','none');
            state.sphplots_x(n1)=sphplots.sph_xyz(n1,1);
            if isfield(sphplots,'sph_names')
                state.sphplots_txt(n1)=text(sphplots.sph_xyz(n1,1)-sphplots.sph_r(n1),sphplots.sph_xyz(n1,2)-sphplots.sph_r(n1),sphplots.sph_xyz(n1,3)+sphplots.sph_r(n1),sphplots.sph_names{n1},'interpreter','none','visible','off','parent',state.hax);
            end
        end
        hold off;
    end
    if ~isempty(connplots)
        hold(state.hax,'on');
        [x,y,z]=cylinder([1,1],20);
        xyz=[x(:),y(:),z(:)]';
        state.connplots=zeros(max(size(connplots)));
        done=false(max(size(connplots)));
        for n1=1:size(connplots,1)
            for n2=1:size(connplots,2)
                if n1~=n2&&~isnan(connplots(n1,n2))&&connplots(n1,n2)~=0, 
                    if (~done(n2,n1)&&~done(n1,n2))||abs(connplots(n1,n2))>abs(connplots(n2,n1)),
                        done(n1,n2)=true;
                        xx=sphplots.sph_xyz([n1,n2],:);
                        dx=xx(2,:)-xx(1,:);%dx=dx./repmat(max(eps,sqrt(sum(abs(dx).^2,2))),[1,3]);
                        ndx=null(dx(1,:));
                        txyz=reshape(xyz'*[(0+2*abs(connplots(n1,n2)))*ndx,dx(1,:)']',2,size(x,2),3);
                        state.connplots(n1,n2)=mesh(state.hax,xx(1,1)+txyz(:,:,1),xx(1,2)+txyz(:,:,2),xx(1,3)+txyz(:,:,3),'edgecolor','none');
                        %state.connplots(n1,n2)=plot3(xx(:,1)+dx(:,1).*9,xx(:,2)+dx(:,2).*9,xx(:,3)+dx(:,3).*9,'r-','linewidth',round(1+1*abs(connplots(n1,n2))));
                        if connplots(n1,n2)>0, set(state.connplots(n1,n2),'facecolor',defaultcolors{1});
                        else set(state.connplots(n1,n2),'facecolor',defaultcolors{2});
                        end
                        set(state.connplots(n1,n2),'userdata',[ndx dx(1,:)'/sqrt(sum(dx(1,:).^2))]);
                    end
                end
            end
        end
        hold off;
    else
        state.connplots=[];%zeros(numel(state.sphplots));
    end
    lighting phong;
    material dull;
    
    hc=state.hfig;
    hc1=uimenu(hc,'Label','View');
    uimenu(hc1,'Label','Left view','callback',{@conn_mesh_display_refresh,'view',[-1,0,0],[],0},'tag','view');
    uimenu(hc1,'Label','Right view','callback',{@conn_mesh_display_refresh,'view',[1,0,0],[],0},'tag','view');
    uimenu(hc1,'Label','Left medial view','callback',{@conn_mesh_display_refresh,'view',[1,0,0],[1,0,.5],-1},'tag','view');
    uimenu(hc1,'Label','Right medial view','callback',{@conn_mesh_display_refresh,'view',[-1,0,0],[-1,0,.5],1},'tag','view');
    uimenu(hc1,'Label','Anterior view','callback',{@conn_mesh_display_refresh,'view',[0,1,0],[],0},'tag','view');
    uimenu(hc1,'Label','Posterior view','callback',{@conn_mesh_display_refresh,'view',[0,-1,0],[],0},'tag','view');
    uimenu(hc1,'Label','Superior view','callback',{@conn_mesh_display_refresh,'view',[0,-.01,1],[],0},'tag','view');
    uimenu(hc1,'Label','Inferior view','callback',{@conn_mesh_display_refresh,'view',[0,-.01,-1],[],0},'tag','view');
    hc1=uimenu(hc,'Label','Surfaces');
    thdl=[uimenu(hc1,'Label','White matter','callback', {@conn_mesh_display_refresh,'brain',1},'tag','brain');
          uimenu(hc1,'Label','Cortical surface','callback',{@conn_mesh_display_refresh,'brain',2},'tag','brain');
          uimenu(hc1,'Label','Semi-inflated surface','callback',{@conn_mesh_display_refresh,'brain',3},'tag','brain');
          uimenu(hc1,'Label','Inflated surface','callback',{@conn_mesh_display_refresh,'brain',4},'tag','brain')];
    set(thdl,'checked','off');set(thdl(state.selectedsurface),'checked','on');
    thdl=[uimenu(hc1,'Label','High-resolution brain surface','separator','on','callback',{@conn_mesh_display_refresh,'brain',[],1},'tag','res');
          uimenu(hc1,'Label','Low-resolution brain surface','callback',{@conn_mesh_display_refresh,'brain',[],2},'tag','res')];
    set(thdl,'checked','off');set(thdl(state.reducedpatch),'checked','on');
    hc2=uimenu(hc1,'Label','Brain surface transparency','separator','on');
    thdl=[]; 
    for n1=0:.1:.9,thdl=[thdl,uimenu(hc2,'Label',num2str(1-n1),'callback',{@conn_mesh_display_refresh,'brain_transparency',n1},'tag','brain_transparency')]; end
    thdl=[thdl,uimenu(hc1,'Label','Brain surface opaque','callback',{@conn_mesh_display_refresh,'brain_transparency',1},'tag','brain_transparency')];
    set(thdl,'checked','off');set(thdl(max(1,min(numel(thdl),1+round(state.facealpha*10)))),'checked','on');
%     thdl=[uimenu(hc1,'Label','Brain surface subcortical mask on','callback',{@conn_mesh_display_refresh,'mask','on'});
%           uimenu(hc1,'Label','Brain surface subcortical mask off','callback',{@conn_mesh_display_refresh,'mask','off'})];
%     set(thdl,'checked','off');set(thdl(2-(domask>0)),'checked','on');
    if ~isempty(pVOL1)||~isempty(pVOL2)
        hc2=uimenu(hc1,'Label','Activation surface transparency','separator','on');
        thdl=[];
        for n1=0:.1:.9,thdl=[thdl,uimenu(hc2,'Label',num2str(1-n1),'callback',{@conn_mesh_display_refresh,'act_transparency',n1},'tag','act_transparency')]; end
        thdl=[thdl,uimenu(hc1,'Label','activation surface opaque','callback',{@conn_mesh_display_refresh,'act_transparency',1},'tag','act_transparency')];
        set(thdl,'checked','off');set(thdl(max(1,min(numel(thdl),1+round(state.facealphablob*10)))),'checked','on');
    end
    thdl=[uimenu(hc1,'Label','Subcortical reference on','separator','on','callback',{@conn_mesh_display_refresh,'sub','on'},'tag','sub');
          uimenu(hc1,'Label','Subcortical reference off','callback',{@conn_mesh_display_refresh,'sub','off'},'tag','sub')];
    set(thdl,'checked','off');set(thdl(2-(dosub>0)),'checked','on');
    if ~isempty(state.sphplots)&&any(any(state.sphplots))||~isempty(state.sphplots_txt)&&any(any(state.sphplots_txt))||~isempty(state.connplots)&&any(any(state.connplots~=0))
        hc0=uimenu(hc,'Label','ROIs');
    end
    if ~isempty(state.sphplots)&&any(any(state.sphplots))
        hc1=uimenu(hc0,'Label','Spheres');
        uimenu(hc1,'Label','Increase size','callback',{@conn_mesh_display_refresh,'spheres',1.25});
        uimenu(hc1,'Label','Decrease size','callback',{@conn_mesh_display_refresh,'spheres',1/1.25});
    end
    if ~isempty(state.sphplots_txt)&&any(any(state.sphplots_txt))
        hc1=uimenu(hc0,'Label','Labels');
        uimenu(hc1,'Label','Labels on','callback',{@conn_mesh_display_refresh,'labels',1},'tag','labels');
        uimenu(hc1,'Label','Labels off','callback',{@conn_mesh_display_refresh,'labels',0},'tag','labels','checked','on');
    end
    if ~isempty(state.connplots)&&any(any(state.connplots~=0))
        hc1=uimenu(hc0,'Label','Lines');
        uimenu(hc1,'Label','Increase thickness','callback',{@conn_mesh_display_refresh,'lines',1.5});
        uimenu(hc1,'Label','Decrease thickness','callback',{@conn_mesh_display_refresh,'lines',1/1.5});
    end
    hc1=uimenu(hc,'Label','Effects');
    uimenu(hc1,'Label','normal','callback',{@conn_mesh_display_refresh,'material','dull'},'tag','material','checked','on');
    uimenu(hc1,'Label','emphasis','callback',{@conn_mesh_display_refresh,'material',[.1 .75 .5 1 .5]},'tag','material');
    uimenu(hc1,'Label','sketch','callback',{@conn_mesh_display_refresh,'material',[.1 1 1 .25 0]},'tag','material');
    uimenu(hc1,'Label','shiny','callback',{@conn_mesh_display_refresh,'material',[.3 .6 .9 20 1]},'tag','material');
    uimenu(hc1,'Label','metal','callback',{@conn_mesh_display_refresh,'material',[.3 .3 1 25 .5]},'tag','material');
    uimenu(hc1,'Label','flat','callback',{@conn_mesh_display_refresh,'material',[]},'tag','material');
    uimenu(hc1,'Label','bright','callback',{@conn_mesh_display_refresh,'light',.8},'separator','on','tag','light');  
    uimenu(hc1,'Label','medium','callback',{@conn_mesh_display_refresh,'light',.5},'tag','light','checked','on');  
    uimenu(hc1,'Label','dark','callback',{@conn_mesh_display_refresh,'light',.2},'tag','light');  
    uimenu(hc1,'Label','white background','callback',{@conn_mesh_display_refresh,'background',[1 1 1]},'separator','on','tag','background');
    uimenu(hc1,'Label','black background','callback',{@conn_mesh_display_refresh,'background',[0 0 0]},'tag','background');
    uimenu(hc1,'Label','color background','callback',{@conn_mesh_display_refresh,'background',[.2 .6 .7]},'tag','background','checked','on');
    if ~isempty(state.colorbar)
        uimenu(hc1,'Label','colorbar on','callback',{@conn_mesh_display_refresh,'colorbar','on'},'separator','on','tag','colorbar');
        uimenu(hc1,'Label','colorbar off','callback',{@conn_mesh_display_refresh,'colorbar','off'},'tag','colorbar','checked','on');
        uimenu(hc1,'Label','rescale colorbar','callback',{@conn_mesh_display_refresh,'colorbar','rescale'});
    end
    hc1=uimenu(hc,'Label','Print');
    uimenu(hc1,'Label','current view','callback',{@conn_mesh_display_refresh,'print',1});
    uimenu(hc1,'Label','4-view mosaic','callback',{@conn_mesh_display_refresh,'print',2});
    uimenu(hc1,'Label','4-view column','callback',{@conn_mesh_display_refresh,'print',3});
    uimenu(hc1,'Label','4-view row','callback',{@conn_mesh_display_refresh,'print',4});
    uimenu(hc1,'Label','8-view mosaic','callback',{@conn_mesh_display_refresh,'print',5});
    set(gcf,'userdata',state);%'uicontextmenu',hc,
    set(rotate3d,'ActionPostCallback',{@conn_mesh_display_refresh,'position'});
    set(rotate3d,'enable','on');
    %rotate3d on;
end

    function conn_mesh_display_refresh(hObject,eventdata,option,varargin)
          if numel(hObject)==1&&ishandle(hObject)&&~isempty(get(hObject,'tag'))
            str=get(hObject,'tag');
            set(findobj(get(hObject,'parent'),'tag',str),'checked','off');
            set(hObject,'checked','on');
        end
        switch(option)
            case 'view'
                v=varargin{1};
                if numel(varargin)>1&&~isempty(varargin{2}), vl=varargin{2}; else vl=v; end
                if numel(varargin)>2&&~isempty(varargin{3}), side=varargin{3}; else side=0; end
                view(v); 
                % Sami
%                 set(state.light,'position',-vl); 
                set(state.light,'position',vl); 
                set(state.patch,'visible','off'); 
                set(state.subpatch,'visible','off'); 
                set(state.sphplots,'visible','off');
                set(state.connplots(state.connplots~=0),'visible','off');
                set([state.patchblob1 state.patchblob2 state.patchblob3 state.patchblob4],'visible','off');
                if side<=0, 
                    set(state.patch(1),'visible','on'); 
                    if dosub, set(state.subpatch(1),'visible','on'); end
                    set(state.sphplots(state.sphplots_x<=5),'visible','on');
                    if ~isempty(state.connplots), temp=state.connplots(state.sphplots_x<=5,state.sphplots_x<=5);set(temp(temp~=0),'visible','on'); end
                    set([state.patchblob1 state.patchblob3],'visible','on');
                end
                if side>=0, 
                    set(state.patch(2),'visible','on'); 
                    if dosub, set(state.subpatch(2),'visible','on'); end
                    set(state.sphplots(state.sphplots_x>=-5),'visible','on');
                    if ~isempty(state.connplots), temp=state.connplots(state.sphplots_x>=-5,state.sphplots_x>=-5); set(temp(temp~=0),'visible','on'); end
                    set([state.patchblob2 state.patchblob4],'visible','on');
                end
                if side==0, set(state.connplots(state.connplots~=0),'visible','on'); end
            case 'brain'
                N=1;
                if numel(varargin)>0&&~isempty(varargin{1}), N=10; newselected=varargin{1}; else newselected=state.selectedsurface; end
                if numel(varargin)>1&&~isempty(varargin{2}), state.reducedpatch=varargin{2}; end
                str=get(state.hfig,'name'); 
                if N>1, 
                    set(state.hfig,'name','press <spacebar> to stop'); 
                    set(state.hfig,'currentcharacter','0');
                end
                for n1=1:N, 
                    if N>1&&isequal(get(state.hfig,'CurrentCharacter'),' '), break; end; 
                    for n2=1:2, 
                        set(state.patch(n2),'vertices',(N-n1)/N*data.rend{state.selectedsurface}(n2).vertices(state.selected_vertices{state.reducedpatch},:)+n1/N*data.rend{newselected}(n2).vertices(state.selected_vertices{state.reducedpatch},:),...
                            'faces',state.selected_faces{state.reducedpatch},...
                            'facevertexcdata',permute((N-n1)/N*state.cdat{state.selectedsurface}(state.selected_vertices{state.reducedpatch},n2,:)+n1/N*state.cdat{newselected}(state.selected_vertices{state.reducedpatch},n2,:),[1 3 2])); 
                    end
                    drawnow; 
                end
                state.selectedsurface=newselected; 
                set(state.hfig,'name',str);
            case 'spheres'
                scale=varargin{1};
                for n=1:numel(state.sphplots), 
                    set(state.sphplots(n),{'xdata','ydata','zdata'},cellfun(@(x)mean(x(:))+scale*(x-mean(x(:))),get(state.sphplots(n),{'xdata','ydata','zdata'}),'uni',0)); 
                end
            case 'labels'
                if varargin{1}, str='on'; else str='off'; end
                set(state.sphplots_txt,'visible',str);
            case 'lines'
                scale=varargin{1};
                for n=find(state.connplots(:)'~=0), 
                    xyz=get(state.connplots(n),{'xdata','ydata','zdata'}); 
                    xyz2=reshape(cat(3,xyz{:}),[],3); 
                    B=get(state.connplots(n),'userdata'); 
                    xyz2=conn_bsxfun(@plus,mean(xyz2,1),conn_bsxfun(@minus,xyz2,mean(xyz2,1))*B*diag([scale scale 1])*B'); 
                    set(state.connplots(n),{'xdata','ydata','zdata'},cellfun(@(x)reshape(x,size(xyz{1})),num2cell(xyz2,1),'uni',0)); 
                end
            case 'material'
                str=varargin{1};
                if isempty(str), set(state.light,'visible','off');
                else
                    set(state.light,'visible','on');
                    material(str);
                end
            case 'light'
                scale=varargin{1};
                set(state.light,'color',scale*[1 1 1]);
            case 'background'
                str=varargin{1};
                set(state.hfig,'color',str);
            case 'brain_transparency'
                scale=varargin{1};
                state.facealpha=max(eps,scale);
                set([state.patch state.subpatch],'facealpha',state.facealpha); 
            case 'act_transparency'
                scale=varargin{1};
                state.facealphablob=max(eps,scale);
                set([state.patchblob1 state.patchblob2 state.patchblob3 state.patchblob4],'facealpha',state.facealphablob);
            case 'mask',
                tdomask=strcmp(varargin{1},'on');
                if domask~=tdomask
                    tinputparams=inputparams;
                    tinputparams{11}=tdomask;
                    conn_mesh_display(tinputparams{:});
                end
            case 'sub',
                dosub=varargin{1};
                set(state.subpatch,'visible','off');
                if strcmp(get(state.patch(1),'visible'),dosub), set(state.subpatch(1),'visible',dosub); end
                if strcmp(get(state.patch(2),'visible'),dosub), set(state.subpatch(2),'visible',dosub); end
            case 'colorbar',
                if strcmp(varargin{1},'rescale')
                    if numel(varargin)==2
                        tVrange=Vrange{1};
                        tVrange([1 end])=varargin{2};
                        tinputparams=inputparams;
                        tinputparams{10}=tVrange;
                        conn_mesh_display_multi(tinputparams{:});                        
                    else
                        answ=inputdlg({'Enter new colorbar limits:'},'Rescale colorbar',1,{mat2str(Vrange{1}([1 end]),6)});
                        if ~isempty(answ)&&numel(str2num(answ{1}))==2
                            tVrange=Vrange{1};
                            tVrange([1 end])=str2num(answ{1});
                            tinputparams=inputparams;
                            tinputparams{10}=tVrange;
                            conn_mesh_display_multi(tinputparams{:});
                        end
                    end
                else
                    set(state.colorbar,'visible',varargin{1});
                end
            case 'position'
                p=get(gca,'cameraposition'); 

%                 set(findobj(gcbf,'type','light'),'position',p);
                % Sami flipped the sign of p in order to get the light
                % souce in its good place.
                set(findobj(gcbf,'type','light'),'position',-p);
            case 'print'
                str=varargin{1};
                if numel(varargin) >= 2
                    filenameout=varargin{2};
                else
                    filenameout = [];
                end
                back=state.reducedpatch;
                conn_mesh_display_refresh([],[],'brain',[],1);
                switch(str)
                    case 1, conn_print(fullfile(state.defaultfilepath,'print01.jpg'));
%                         case 2, conn_print(fullfile(state.defaultfilepath,'print01.jpg'),'-mosaic',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'));
                    % Sami - added -no_gui
                    case 2, conn_print(fullfile(state.defaultfilepath,'print01.jpg'),'-nogui','-mosaic',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'));
                    case 3, conn_print(fullfile(state.defaultfilepath,'print01.jpg'),'-column',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'));
%                     case 4, conn_print(fullfile(state.defaultfilepath,'print01.jpg'),'-row',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'));
                    case 4, 
                        global SAMI_conn_print_filename;
                        if ~isempty(SAMI_conn_print_filename)
                            conn_print(fullfile(SAMI_conn_print_filename),'-nogui','-row',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'));
                        else
                            conn_print(fullfile(state.defaultfilepath,'print01.jpg'),'-nogui','-row',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'));
                        end
                    case 5, 
                        global SAMI_conn_print_filename;
                        if ~isempty(SAMI_conn_print_filename)                        
                            conn_print(fullfile(SAMI_conn_print_filename),'-nogui','-mosaic8',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Anterior view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'),get(findobj(state.hfig,'label','Posterior view'),'callback'),get(findobj(state.hfig,'label','Superior view'),'callback'),get(findobj(state.hfig,'label','Inferior view'),'callback'));
                        else
                            if isempty(filenameout)
                                conn_print(fullfile(state.defaultfilepath,'print01.jpg'),'-mosaic8',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Anterior view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'),get(findobj(state.hfig,'label','Posterior view'),'callback'),get(findobj(state.hfig,'label','Superior view'),'callback'),get(findobj(state.hfig,'label','Inferior view'),'callback'));
                            else
                                conn_print(fullfile(filenameout),'-nogui','-mosaic8',get(findobj(state.hfig,'label','Left view'),'callback'),get(findobj(state.hfig,'label','Left medial view'),'callback'),get(findobj(state.hfig,'label','Anterior view'),'callback'),get(findobj(state.hfig,'label','Right view'),'callback'),get(findobj(state.hfig,'label','Right medial view'),'callback'),get(findobj(state.hfig,'label','Posterior view'),'callback'),get(findobj(state.hfig,'label','Superior view'),'callback'),get(findobj(state.hfig,'label','Inferior view'),'callback'));
                            end
                        end
                end
                if back~=1, conn_mesh_display_refresh([],[],'brain',[],back); end
        end
    end
end



