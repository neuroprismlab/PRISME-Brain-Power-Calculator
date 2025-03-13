function nbs = set_up_nbs_parameters(varargin)
        
    %Declare the nbs structure global to avoid passing between NBS and NBSrun
    % TODO: I'm not sure this is a good idea - look into alternatives - SMN
    % global nbs
    
    %Don't precompute randomizations if the number of test statistics populates 
    %a matrix with more elements than Limit. Slows down computation but saves 
    %memory.   
    % Redefine limit for now - to skip
    % Limit=10^8/3;
    Limit = 1;
    
    %Waitbar position in figure
    WaitbarPos=[0.69 0.021 0.05 0.21];
    
    %User inputs
    UI=varargin{1}; 
    
    % Handles to GUI objects to enable progress updates to be written to GUI
    if nargin==2
        S=varargin{2};
        try 
            set(S.OUT.ls,'string',[]); 
        catch 
        end
    else 
        S=0; % added to keep running in command line even if didn't pass S object - smn
    end
    
    %Assume UI is valid to begin with
    %Can be set to zero after reading UI or performing error checking
    UI.method.ok=1;
    UI.design.ok=1;
    UI.contrast.ok=1;
    UI.thresh.ok=1;
    UI.test.ok=1;
    UI.matrices.ok=1;
    UI.node_coor.ok=1;
    UI.node_label.ok=1;
    UI.size.ok=1;
    UI.use_preaveraged_constrained.ok=1;
    UI.edge_groups.ok=1;
    % UI.do_Constrained_FWER_second_level.ok=1;
    UI.perms.ok=1;
    UI.alpha.ok=1;
    UI.exchange.ok=1;
    
    %% Asing mask to stats NBS
    nbs.STATS.mask = UI.mask.ui;
    
    % Read UI and assign to appropriate structure
    % Connectivity matrices
    
    % Matrices and dimensions and contrast
    nbs.GLM.y = UI.matrices.ui';
    nbs.GLM.X = UI.design.ui;
    DIMS = UI.DIMS;
    nbs.GLM.contrast = UI.contrast.ui;
    
    
    % Exchange blocks for permutation [optional]
    [tmp, UI.exchange.ok] = read_exchange(UI.exchange.ui, DIMS);
    
    if UI.exchange.ok
        nbs.GLM.exchange=tmp; 
    elseif isfield(nbs,'GLM')
        if isfield(nbs.GLM,'exchange')
            nbs.GLM=rmfield(nbs.GLM,'exchange');
        end
    end
    
    % Test statistic
    try 
        nbs.GLM.test=UI.test.ui; 
        nbs.STATS.test_stat = UI.test_stat.ui;
    catch
        UI.test.ok = 0;
    end
    
    % Number of permutations
    try 
        if ischar(UI.perms.ui)
            nbs.GLM.perms = str2num(UI.perms.ui);
        else
            nbs.GLM.perms = UI.perms.ui;
        end
    catch
        UI.perms.ok = 0;
    end
    
    try 
        if ~isnumeric(nbs.GLM.perms) || ~(nbs.GLM.perms>0)
            UI.perms.ok=0;
        end
    catch
        UI.perms.ok=0;
    end
    
    % Test statistic threshold
    try 
        if ischar(UI.thresh.ui)
            nbs.STATS.thresh=str2num(UI.thresh.ui); 
        else
            nbs.STATS.thresh=UI.thresh.ui;
        end
    catch 
        UI.thresh.ok=0;
    end
    
    
    try 
        if ~isnumeric(nbs.STATS.thresh) || ~(nbs.STATS.thresh>0)
            UI.thresh.ok=0; 
        end
    catch
        UI.thresh.ok=0; 
    end
    
    % Corrected p-value threshold
    try 
        if ischar(UI.alpha.ui)
            nbs.STATS.alpha = str2num(UI.alpha.ui); 
        else 
            nbs.STATS.alpha = UI.alpha.ui; 
        end
    catch
        UI.alpha.ok=0;
    end
    
    try 
        if ~isnumeric(nbs.STATS.alpha) || ~(nbs.STATS.alpha>0)
            UI.alpha.ok=0;
        end
    catch
        UI.alpha.ok=0;
    end
    
    
    try 
        nbs.STATS.size = UI.size.ui;
    catch 
        UI.size.ok = 0;
    end
    
    try 
        nbs.STATS.use_preaveraged_constrained = UI.use_preaveraged_constrained.ui; 
    catch 
        UI.use_preaveraged_constrained.ok = 0; 
    end 
    
    %Edge groups [required if using Constrained or Multidimensional_cNBS
    % if preaveraging, n_groups will be taken from data and no grouping file is required]
    if isfield(UI, 'edge_groups') && isfield(UI.edge_groups, 'ui') && ~isempty(UI.edge_groups.ui)
        % If explicit edge group data is provided, read it
        try 
            [nbs.STATS.edge_groups, UI.edge_groups.ok] = read_edge_groups(UI.edge_groups.ui, DIMS);
        catch
            UI.edge_groups.ok = 0;
        end
    else
        % If no edge groups are provided and it's not preaveraged, disable use_edge_groups
        nbs.STATS.use_edge_groups = 0;
    end
    
    % Number of nodes
    nbs.STATS.N = DIMS.nodes; 
    
    try
       nbs.STATS.ground_truth = logical(UI.ground_truth);
    catch
       error('Error setting up gt value')
    end
    
    % Do error checking on user inputs
    [msg,stop] = errorcheck(UI,DIMS,S);
    
    % Attempt to print result of error checking to listbox. If this fails, print
    % to screen
    try 
        tmp = get(S.OUT.ls,'string'); 
        set(S.OUT.ls,'string', [msg;tmp]); 
        drawnow;
    catch
        for i=1:length(msg)
            fprintf('%s\n',msg{i}); 
        end
    end
    %Do not proceed with computation if mandatory user inputs are missing or
    %cannot be read
    if stop 
        return
    end
        
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read permutation exchange blocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [exchange, ok] = read_exchange(data, DIMS)
    ok = 1; % Initialize ok flag as true      
    
    % Check if data is not empty and has appropriate dimensions
    if ~isempty(data)
        [nr, nc] = size(data); % Get the dimensions of the data
        
        % Check if data is a column vector and matches the number of observations
        if nc == 1 && nr == DIMS.observations
            exchange = data; % Use data as exchange
        else
            ok = 0; % Set ok to false if dimensions do not match
            exchange = [];
        end
    else
        ok = 0; % Set ok to false if data is empty
        exchange = [];
    end

    % Additional checks or transformations can be performed here if necessary
    if ok
        % Verify that exchange blocks are properly defined if more checks are needed
        unique_blocks = unique(exchange);
        fprintf('Number of unique exchange blocks: %d\n', length(unique_blocks));
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read edge groups for Constrained or SEA NBS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [edge_groups,ok]=read_edge_groups(Name,DIMS)
    ok=1;
    if ischar(Name)
        data=readUI(Name);
    else
        data=Name;
    end
    if ~isempty(data)
        [nr,nc,ns]=size(data);
        if nr==DIMS.nodes && nc==DIMS.nodes && ns==1
            edge_groups.groups=data; 
            u=unique(edge_groups.groups)'; % unique returns a column vec but more natural in scripts to use row vec
            edge_groups.unique=u(u>0); % unique entries greater than 0
        else
            ok=0; edge_groups.groups=[];
        end
    else
        ok=0; edge_groups.groups=[]; 
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check if there are any errors in the input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [msg,stop]=errorcheck(UI,DIMS,S)
    stop=1;
    %Mandatroy UI
    %UI.method.ok %no need to check
    if ~UI.matrices.ok
        msg={'Stop: Connectivity Matrices not found or inconsistent'};
        try set(S.DATA.matrices.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.design.ok
        msg={'Stop: Design Matrix not found or inconsistent'};
        try set(S.STATS.design.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.contrast.ok 
        msg={'Stop: Contrast not found or inconsistent'};
        try set(S.STATS.contrast.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.thresh.ok
        msg={'Stop: Threshold not found or inconsistent'};
        try set(S.STATS.thresh.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.test.ok 
        msg={'Stop: Statistical Test not found or inconsistent'};
        try set(S.STATS.test.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.perms.ok
        msg={'Stop: Permutations not found or inconsistent'};
        try set(S.ADV.perms.text,'ForegroundColor','red');
        catch; end
        return;
    end        
    if ~UI.alpha.ok
        msg={'Stop: Significance not found or inconsistent'};
        try set(S.ADV.alpha.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.size.ok
        msg={'Stop: Component Size not found or inconsistent'};
        try set(S.ADV.size.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.use_preaveraged_constrained.ok
        msg={'Stop: Preaveraging flag not found or inconsistent'};
        try set(S.ADV.size.text,'ForegroundColor','red');
        catch; end
        return;
    end
    if ~UI.edge_groups.ok
        msg={'Stop: Edge groups not found or inconsistent'};
        try set(S.ADV.edge_groups.text,'ForegroundColor','red');
        catch; end
        return;
    end
    stop=0;

    msg = [];
    
    % SMN: todo: add report of statistic type and size type
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read connectivity matrices and vectorize the upper triangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,ok,DIMS]=read_matrices(Name)
    ok=1;
    if ischar(Name) % char input so load in by filename
        data=readUI(Name);
    else
        data=Name;
    end
    if ~isempty(data)
        [nr,nc,ns]=size(data);
        if ns>0 && ~iscell(data) && isnumeric(data)
            if nr~=nc && ns==1
                % accept stuff that's been triangularized - smn
                y=data';
                nr_old=nr;
                nr=ceil(sqrt(2*nr_old));
                if nr_old==nr*(nr-1)/2
                    ns=nc;
                    nc=nr;
                else
                    ok=0; y=[];
                    return
                end
            elseif nr==nc
                ind_upper=find(triu(ones(nr,nr),1));
                y=zeros(ns,length(ind_upper));
                %Collapse matrices
                for i=1:ns
                    tmp=data(:,:,i);
                    y(i,:)=tmp(ind_upper);
                end
            else
                ok=0; y=[];
                return
            end
        elseif iscell(data)
            [nr,nc]=size(data{1});
            ns=length(data);
            if nr==nc && ns>0
                ind_upper=find(triu(ones(nr,nr),1));
                y=zeros(ns,length(ind_upper));
                %Collapse matrices
                for i=1:ns
                    [nrr,ncc]=size(data{i});
                    if nrr==nr && ncc==nc && isnumeric(data{i})
                        y(i,:)=data{i}(ind_upper);
                    else
                        ok=0; y=[]; 
                        break
                    end
                end
            else
                ok=0; y=[];
            end
        end
    else
        ok=0; y=[];
    end
    if ok==1
        %Number of nodes
        DIMS.nodes=nr;
        %Number of matrices
        DIMS.observations=ns;
    else
        %Number of nodes
        DIMS.nodes=0;
        %Number of matrices
        DIMS.observations=0;
    end
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read design matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X,ok,DIMS]=read_design(Name,DIMS)
ok=1;
if ischar(Name)
    data=readUI(Name);
else
    data=Name;
end
if ~isempty(data)
    [nr,nc,ns]=size(data);
    if nr==DIMS.observations && nc>0 && ns==1 && isnumeric(data) 
        X=data; 
    else
        ok=0; X=[];
    end
else
    ok=0; X=[];
end
clear data
if ok==1
    %Number of predictors
    DIMS.predictors=nc;
else
    DIMS.predictors=0;
end
end

