
%% GROUND TRUTH ONLY: Pre-load and reorder data unless already specified to be loaded
% note that for benchmarking (not ground truth), we load/reorder data during each repetition
if RepParams.do_ground_truth
    
    load_data ='y';
    if exist('m','var')
        load_data=input('Some data is already loaded in the workspace. Replace? (y/n)','s');
    end

    if strcmp(load_data,'y')
    
        %fprintf('Loading %d subjects. Progress:\n', RepParams.n_subs);

        % load data differently for paired or one-sample test
        if RepParams.use_both_tasks % for paired
            
            if RepParams.paired_design
                if RepParams.use_preaveraged_constrained % no need to reorder/pool

                    m = zeros(RepParams.n_var, RepParams.n_subs*2);

                    for i = 1:RepParams.n_subs                   

                        m(:, i) = util_extract_subject_data(RepParams.brain_data, task1, i);                
                                            
                        m(:,n_subs + i) = util_extract_subject_data(RepParams.brain_data, task2, i);
                        
                        % print every 50 subs x 2 tasks
                        %if mod(i,50)==0 
                        %    fprintf('%d/%d  (x2 tasks)\n',i,n_subs)
                        %end
                    end
                    
                else % go ahead and reorder by atlas and pool by nets/all for ground truth

                    m = zeros(RepParams.n_nodes*(RepParams.n_nodes-1)/2, RepParams.n_subs*2);
                    m_net = zeros(RepParams.n_node_nets*(RepParams.n_node_nets-1)/2+RepParams.n_node_nets, ...
                                  RepParams.n_subs * 2);
                    m_pool_all = zeros(1, RepParams.n_subs * 2);

                    for i = 1:RepParams.n_subs
                
                        sub_data_t1 = util_extract_subject_data(RepParams.brain_data, task1, i);
                        m(:,i) = sub_data_t1;
                        
                        d = util_unflatten_diagonal(sub_data_t1);      

                        d_net = summarize_matrix_by_atlas(d, 'suppressimg', 1);
                        m_net(:,i) = d_net(RepParams.trilmask_net);  
                      
                        m_pool_all(i) = mean(d(RepParams.triumask));
                        
                        sub_data_t2 = util_extract_subject_data(RepParams.brain_data, task2, i);
                        m(:,RepParams.n_subs + i) = sub_data_t2;

                        d = util_unflatten_diagonal(sub_data_t2);  
                        
                        d_net = summarize_matrix_by_atlas(d,'suppressimg',1);
                        m_net(:,RepParams.n_subs + i) = d_net(RepParams.trilmask_net);
                        
                        m_pool_all(RepParams.n_subs + i) = mean(d(RepParams.triumask)); 

                        % print every 50 subs x 2 tasks
                        %if mod(i,50)==0 
                        %    fprintf('%d/%d  (x2 tasks)\n', i, RepParams.n_subs) 
                        %end
                    end
                end
            else
                error('This script hasn''t been fully updated/tested for two-sample yet.');
            end
        
        else % for single task v 0

            if RP.use_preaveraged_constrained % no need to reorder/pool
                m = zeros(RepParams.n_var, RepParams.n_subs);

                for i = 1:n_subs
                    
                    m(:,i) = util_extract_subject_data(RepParams.brain_data, task1, i);
                    
                end
            else % go ahead and reorder by atlas and pool by nets/all for ground truth
                m = zeros(RepParams.n_nodes*(RepParams.n_nodes-1)/2, RepParams.n_subs);
                m_net = zeros(RepParams.n_node_nets*(RepParams.n_node_nets-1)/2 + RepParams.n_node_nets, ...
                              RepParams.n_subs);
                m_pool_all=zeros(1, RepParams.n_subs);

                for i = 1:n_subs  
                    
                    sub_data_t1 = util_extract_subject_data(RepParams.brain_data, task1, i);                            
                    
                    d = util_unflatten_diagonal(sub_data_t1);    
                    
                    % reorder bc proximity matters for SEA and cNBS
                    d=reorder_matrix_by_atlas(d, mapping_category); 
                    m(:, i) = d(triumask);

                    d_net=summarize_matrix_by_atlas(d,'suppressimg',1);

                    m_net(:, i) = d_net(trilmask_net);
                    m_pool_all(i) = mean(d(triumask));
                    % print every 100
                    % if mod(i,100)==0; fprintf('%d/%d\n',i,n_subs); end
                end
            end 
        end

    else
        fprintf('Okay, keeping previous data and assuming already reordered.\n');
    end

end

%% Check expected inclusion of resting tasks - Remove it? - It's not necessary anymore
% We now infere the test type from the data, so we check the dataset for
% the tasks
if RepParams.use_both_tasks && false
    if RepParams.do_TPR
        if ~contains(RepParams.task2, 'REST') 
        %if ~(strcmp(task2,'REST') || strcmp(task2,'REST2'))
            warning(['Not using REST or REST2 for contrasting with task; ' ...
                'this differs from the intended use of these benchmarking scripts.']);
        else
            if RepParams.use_trimmed_rest
                disp('Fix this too')
                RepParams.task2=[RepParams.task2,'_',num2str(RepParams.n_frames.(task1)),'frames'];
                if RepParams.do_TPR
                    warning('Using trimmed rest for power calculation.');
                end
            end
        end
    else
        if ~(contains(RepParams.task1,'REST') && contains(RepParams.task2,'REST'))
        %if ~((strcmp(task1,'REST') && strcmp(task2,'REST2')) || (strcmp(task1,'REST2') && strcmp(task2,'REST')))
            error('Not using REST vs. REST2 or REST2 vs. REST for estimating false positives; this differs from the intended use of these benchmarking scripts.');
        else
            if RepParams.use_trimmed_rest
                RepParams.task1=[RepParams.task1,'_',num2str(RepParams.n_frames.(task1)),'frames'];
                RepParams.task2=[RepParams.task2,'_',num2str(RepParams.n_frames.(task2)),'frames'];
            end
        end
    end
end

% GT CODE
% set ground truth parameters
% REMOVE THIS ? - not for now
if do_gt
    RepParams.do_ground_truth = 1;
    RepParams.task1 = RepParams.task_gt;
    RepParams.do_TPR = 1;
    %use_both_tasks=1;
    RepParams.cluster_stat_type = RepParams.stat_type_gt;
    %cluster_stat_type='Size';
    RepParams.omnibus_type = RepParams.omnibus_type_gt;
    RepParams.n_perms = RepParams.n_perms_gt;
    %n_perms='1';
  
    if ~RepParams.use_both_tasks % temporary check that both tasks are being used
        warning(['Not performing a contrast between two tasks. ' ...
            'Specify ''use_both_tasks=1'' to match results from Levels of Inference study.'])
    end
else
    RepParams.do_ground_truth = 0;
end
