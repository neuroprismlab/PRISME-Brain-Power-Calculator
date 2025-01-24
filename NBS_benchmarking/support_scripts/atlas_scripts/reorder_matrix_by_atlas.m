function reordered_mat = reorder_matrix_by_atlas(orig_data, category, varargin)
% orig mat is nxixi; typically a cell mat of connectivity matrix
% e.g., reordered_mat = reorder_matrix_by_atlas(orig_mat,'subnetwork')
% Don't use this natively to summarize ROIs; domatrixsummary_XXX to organize

% Initial process of varagin
p = inputParser;

default_mask = [];

addParameter(p,'mask', default_mask, @islogical);

parse(p, varargin{:});

mask = p.Results.mask;


if iscell(orig_data)
    matdim=size(orig_data{1});
    n_matrices=length(orig_data);
else
    matdim=size(orig_data);
    if length(matdim)==3
        n_matrices=matdim(3);
    else
        n_matrices=1;
    end
end

% Replace this part 
if matdim(1) ~= matdim(2) && ~isempty(mask)
    ismatrix=0;
    matdim = size(mask, 1);
    % warning('Input is not a square matrix. Treating as a single vector. If should be matrix, re-structure first.')
elseif matdim(1) == matdim(2)
    matdim = matdim(1);
    ismatrix=1;
else
    error('The matrix is not square and no mask was given. The reorder by atlas is not possible')
end

map=load_atlas_mapping(matdim, category);
%load(sprintf('map%0.0f_%s.mat',matdim,category));
% if matdim==278
%      load(sprintf('map%0.0f.mat',matdim)); % need: map268.mat or map278.mat
%      map_old=map; clearvars map; map.oldroi=map_old(:,2);


% reorder
if ismatrix
    if iscell(orig_data)
        for n=1:n_matrices
            reordered_mat{n}=orig_data{n}(map.oldroi,map.oldroi);
        end
    else
        reordered_mat=orig_data(map.oldroi,map.oldroi,1:n_matrices);
    end
else
    if iscell(orig_data)
        for n=1:n_matrices
            reordered_mat{n}=orig_data{n}(map.oldroi);
        end
    else
        reordered_mat=orig_data(map.oldroi,1:n_matrices);
    end
end

end

