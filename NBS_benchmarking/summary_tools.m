classdef summary_tools
% Summarization tools for benchmarking

% 1. Check save settings
% 2. Log results
% 3. Plot visualizations
%     1. TPR histogram
%     2. Effect size v. tpr
%     3. Residuals (esz v res, res spatial)


methods(Static)

    
%% ------------------------------------------------------------------------- %
% ******** Check saving ********
function ss = check_whether_to_save(ss,step_name,descriptive_string,filename)
    % ss = save_settings
    
    if ~isfield(ss,'asked') || ~isfield(ss.asked,step_name)
        ss.asked.(step_name)=0;
    end
    
    if ~ss.asked.(step_name)
        ss.do_thing_master.(step_name)=ss.do.(step_name);
    end

    if ss.do_thing_master.(step_name)
        if exist(filename, 'file') == 2
            
            if ~ss.asked.(step_name) || ~ss.use_same.(step_name)

                user_response=input(sprintf([descriptive_string,' already exists. Overwrite? [yes/no]\n> ']),'s');
                if strcmp(user_response,'yes')
                    fprintf(['Replacing previous ',descriptive_string,'.\n']);
                    ss.overwrite.(step_name)=1;
                else
                    fprintf(['Keeping existing ',descriptive_string,'.\n']);
                    ss.overwrite.(step_name)=0;
                end

                if ~ss.asked.(step_name)
                    user_response=input(sprintf('Repeat for all? [yes/no]\n> '),'s');
                    if strcmp(user_response,'yes')
                        fprintf('Using this setting for all.\n');
                        ss.use_same.(step_name)=1;
                    else
                        fprintf('Okay, will ask each time.\n');
                        ss.use_same.(step_name)=0;
                    end
                    ss.asked.(step_name)=1;
                end
            end
            
            ss.do.(step_name)=ss.overwrite.(step_name);
           
        else
            ss.do.(step_name)=ss.do_thing_master.(step_name);
        end
    end
    
end

%% -------------------------------------------------------------------------%
% ******** Calculate ground truth dcoefficients **********
function ss=calculate_dcoefficients(tstat_filename,stat_level_map,dcoeff_filename,ss)

    try % try to load ground truth
      lastwarn('');
      if isempty(who('-file', tstat_filename, 'edge_stats_net'))
          use_preaveraged_constrained=1;
          load(tstat_filename,'edge_stats','UI_light','rep_params_copy');
          rep_params=rep_params_copy; % TODO: why isn't saving as rep_params?
      else
          use_preaveraged_constrained=0;
        load(tstat_filename,'edge_stats','edge_stats_net','edge_stats_pool_all','rep_params','UI_light');
      end
      [warnmsg,~] = lastwarn;
      if contains(warnmsg,'Variable ') && contains(warnmsg,'not found.')
          error(['Unable to load all necessary variables from ',tstat_filename,'.\nPlease check these exist and try again.']);
      end
    catch
      error(['Looks like ground truth data needed for calculating TPR does not exist for %s. ' ...
          'Try running calculate_ground_truth.m\n'],tstat_filename);
    end

    % create new variables to match stat_gt_levels 
    tstat.edge=edge_stats;
    if ~use_preaveraged_constrained
        tstat.network=edge_stats_net;
        tstat.whole_brain=edge_stats_pool_all;
    end

    [~,idx] = unique(stat_level_map.stat_gt_levels);
    %       stat_gt_levels_str_new=stat_level_map.stat_gt_levels_str(idx);
    if use_preaveraged_constrained
        idx=1; %edge standing in for network
    end

    % Convert t-stat -> d-coefficient - transpose because need for fitting spline
    warning('Assuming input is t-statistic from paired-sample t-test.')
    n_subs_total=rep_params.n_subs_subset;
    for g=idx'
        gt_level_str=stat_level_map.stat_gt_levels_str{g};
        dcoeff.(gt_level_str)=(tstat.(gt_level_str)/sqrt(n_subs_total))';
    end
    

    n_subs_total=length(UI_light.contrast.ui)-1;
    
    ss = summary_tools.check_whether_to_save(ss,'save_dcoeff','Ground truth d-coefficient',dcoeff_filename);
    if ss.do.save_dcoeff
          save(dcoeff_filename,'dcoeff','n_subs_total','-v7.3');
    end
    
    %{
    % TEMPORARY PLOTTER - TODO: REMOVE
    triu_msk=triu(true(268),1);
    t=+triu_msk;
    t(triu_msk)=dcoeff.edge;
    t=t';
    figure; draw_atlas_boundaries(t)
    caxis([-1,1])
    colormap(bipolar([],0.1))
    %}

end
    
%% -------------------------------------------------------------------------%
% ******** Calculate positives (not *true* positives) **********
function PowerRes = calculate_positives(method_data, alpha, file_type)
%% calculate_positives
% Computes positive detection indicators and summary statistics from repetition data.
% The function thresholds the p-value matrices to create binary indicators of positive
% detections and then computes summary statistics to support subsequent power analysis.
%
% Inputs:
%   - method_data: Struct containing repetition data (e.g., p-value matrices and test statistics).
%
% Outputs:
%   - PowerRes: Struct aggregating positive detection metrics and summary statistics.
%
    switch file_type

        case 'full_file'
            PowerRes = struct();
            
            positives=+(method_data.sig_prob > 1 - alpha);
            positives_neg=+(method_data.sig_prob_neg > 1 - alpha);
            
            PowerRes.positives_total=full(sum(positives, length(size(positives))));
            PowerRes.positives_total_neg=full(sum(positives_neg, length(size(positives_neg))));
        
        case 'compact_file'
            PowerRes = struct();

            % For compact files, positives and negatives are already cumulative sums
            % Just pass them through with the same field names for downstream compatibility
            PowerRes.positives_total = full(method_data.positives);
            PowerRes.positives_total_neg = full(method_data.negatives);

    end


end

%% -------------------------------------------------------------------------%
% ******** Calculate true positives **********
function PowerRes = calculate_tpr(method_data, gt_data, tpr_dthresh, PowerRes, method_name, meta_data)
%% calculate_tpr
% Calculates true positive rates (TPR) from repetition and ground-truth data.
%
% This function compares the ground-truth brain data with the power calculation 
% results to determine the percentage of true positives. It identifies indices with 
% significant positive and negative effects (based on a threshold) and computes the TPR 
% according to the statistic level (edge, network, or whole_brain).
%
% Inputs:
%   - method_data: Struct containing repetition data with meta_data, including the 
%               field statistic_level and rep_parameters.
%   - gt_data: Struct containing ground-truth brain data (field brain_data).
%   - tpr_dthresh: Numeric threshold used to define significant ground-truth effects.
%   - PowerRes: Struct containing computed detection totals (positives_total and 
%               positives_total_neg) and possibly other summary metrics.
%
% Outputs:
%   - PowerRes: The updated PowerRes struct with a new field 'tpr' (true positive rate)
%               computed as a percentage.
%
% Workflow:
%   1. Extracts the statistic level from method_data.meta_data.
%   2. Determines indices where ground-truth values exceed the positive threshold or 
%      fall below the negative threshold.
%   3. For 'edge' and 'network' levels, it assigns the corresponding positive and negative 
%      detection totals.
%   4. For 'whole_brain', it aggregates detections from both positive and negative effects,
%      then adjusts for the doubled repetitions.
%   5. Finally, it computes the TPR as the ratio of true positives to the total number of 
%      repetitions, multiplied by 100.
    
    
    %% Get stat level - edge, network, or brain
    stat_gt_level_str = get_stats_level_from_method_data(method_name, method_data, meta_data);
      
    [ids_pos_vec, ids_neg_vec, ~, pos_effect, neg_effect] = ...
        extract_effect_vector(stat_gt_level_str, gt_data, tpr_dthresh);

    % calculate TPR
    true_positives = nan(size(gt_data));
    if contains(stat_gt_level_str, 'variable')

        true_positives(ids_pos_vec)=PowerRes.positives_total(ids_pos_vec);
        true_positives(ids_neg_vec)=PowerRes.positives_total_neg(ids_neg_vec);

    elseif contains(stat_gt_level_str,'network')

        true_positives(ids_pos_vec)=PowerRes.positives_total(ids_pos_vec);
        true_positives(ids_neg_vec)=PowerRes.positives_total_neg(ids_neg_vec);

    elseif contains(stat_gt_level_str,'whole_brain')

        true_positives = 0;
        if pos_effect
            true_positives = true_positives + PowerRes.positives_total;
        end
        if neg_effect
            true_positives = true_positives + PowerRes.positives_total_neg;
        end
        
        %% Divide by two only if both positive and negative effects are present
        if pos_effect && neg_effect
           true_positives = floor(true_positives/2);
        end

    end
    
    file_type = get_file_type(meta_data);

    switch file_type

        case 'full_file'
            n_reps = size(method_data.sig_prob, 2);

        case 'compact_file'
            n_reps = meta_data.n_repetitions;

    end       
    
    PowerRes.tpr=true_positives*100/n_reps;
    
end

function PowerRes = calculate_fpr(method_data, gt_data, tpr_dthresh, PowerRes)
%   Calculates the true negative rate to conclude the confusion table with
%   the tpr. It's quite similar to the funciton where it first find the
%   gt position and then the repetition data to estimate errors.
%

     %% Get stat level - edge, network, or brain
    stat_gt_level_str = extract_stat_level(method_data.meta_data.level);
    
    [ids_pos_vec, ids_neg_vec, ~, pos_effect, neg_effect] = ...
        extract_effect_vector(stat_gt_level_str, gt_data, tpr_dthresh);


    % calculate TPR
    false_positives = nan(size(gt_data));
    if contains(stat_gt_level_str,'variable')

        false_positives(~ids_pos_vec)=PowerRes.positives_total(~ids_pos_vec);
        false_positives(~ids_neg_vec)=PowerRes.positives_total_neg(~ids_neg_vec);

    elseif contains(stat_gt_level_str,'network')

        false_positives(~ids_pos_vec)=PowerRes.positives_total(~ids_pos_vec);
        false_positives(~ids_neg_vec)=PowerRes.positives_total_neg(~ids_neg_vec);

    elseif contains(stat_gt_level_str,'whole_brain')

        false_positives = 0;
        if ~pos_effect
            false_positives = false_positives + PowerRes.positives_total;
        end
        if ~neg_effect
            false_positives = false_positives + PowerRes.positives_total_neg;
        end
        
        %% Divide by two only if both positive and negative effects are present
        if ~pos_effect && ~neg_effect
           false_positives = floor(false_positives/2);
        end

    end

    n_reps = size(method_data.sig_prob, 2);
    PowerRes.fpr=false_positives*100/n_reps;

end


%% -------------------------------------------------------------------------%
% ******** Visualize ground truth effect sizes ******** 
% IMPORTANT: this is designed to work on the combined summary file which switches the network-level dcoeff from lower to upper tri (see above)
%
% To imitate this manually, you can copy a combined summary file, copy updated dcoeff into there, then:
% n_features_net=10;
% tmp=tril(true(n_features_net));
% triu_msk=triu(true(n_features_net));
% for i=1:7
%   tmp2=structure_data(dcoeff.Constrained(:,i),'mask',tmp);
%   tmp2=tmp2';
%   dcoeff.Constrained(:,i)=tmp2(triu_msk);
% end

function ss=visualize_ground_truth(dcoeff,tpr_dthresh,filename_prefix,pp,stat_level_map,ss)    
    
    if ss.do.save_figs
        ss = summary_tools.check_whether_to_save(ss,'save_figs','Results Figures',[filename_prefix,'_dcoeff_hist.png']); % TODO: update
    end
    
    % setup: identify the first index for each unique gt level
    [~,idx]=unique(stat_level_map.stat_gt_levels);
    filename_prefix_indiv_tasks=[filename_prefix,'_individual_tasks'];
    
    
    % 1. Histogram of ground truth effect size
    
    % combined tasks
    pp.fontsz = pp.fontsz_lg;
    pp.do_combined=1;
    figure();
    for g=1:pp.n_gt_levels
        pp.level=idx(g); % note that this is the stat level (most recently, 1-5), not gt level (most recently, 1-3)
        pp.last_overlay_plot=g==pp.n_gt_levels;
        summary_tools.plot_dcoeff_hist(dcoeff.(stat_level_map.stat_types{idx(g)})(:),tpr_dthresh,pp,stat_level_map,ss.do.save_figs,filename_prefix);
    end
    
    % individual tasks
    pp.fontsz = pp.fontsz_sm;
    pp.do_combined=0;
    figure();
    for t=1:pp.n_tasks
        subplot_tight(1,pp.n_tasks,t,pp.margins_bigx);
        for g=1:pp.n_gt_levels
            pp.level=idx(g);
            pp.last_overlay_plot=g==pp.n_gt_levels && t==pp.n_tasks;
            summary_tools.plot_dcoeff_hist(dcoeff.(stat_level_map.stat_types{idx(g)})(:,t),tpr_dthresh,pp,stat_level_map,ss.do.save_figs,filename_prefix_indiv_tasks)
        end
    end
    
    
    % 2. Spatial map of ground truth effect size for all tasks and combined

    % combined tasks
    pp.fontsz = pp.fontsz_lg;
    pp.do_combined=1;
    figure();
    for g=1:pp.n_gt_levels
        subplot_tight(1,pp.n_gt_levels,g,pp.margins_bigx_dcoeff);
        pp.level=idx(g);
        pp.last_overlay_plot=g==pp.n_gt_levels;
        mean_dcoeff=mean(dcoeff.(stat_level_map.stat_types{idx(g)}),2);
        summary_tools.plot_dcoeff_spatial_map(mean_dcoeff,0,tpr_dthresh,pp,stat_level_map,ss.do.save_figs,filename_prefix);
    end
    
    % individual tasks
    pp.fontsz = pp.fontsz_sm;
    pp.do_combined=0;
    figure();
    for g=1:pp.n_gt_levels
        for t=1:pp.n_tasks
            t_subplot=t+1;
            subplot_tight(ceil(pp.n_tasks/2),pp.n_gt_levels*2,(t_subplot-1)*pp.n_gt_levels+g,pp.margins);
            pp.level=idx(g);
            pp.last_overlay_plot= g==pp.n_gt_levels && t==pp.n_tasks;
            summary_tools.plot_dcoeff_spatial_map(dcoeff.(stat_level_map.stat_types{idx(g)})(:,t),0,tpr_dthresh,pp,stat_level_map,ss.do.save_figs,filename_prefix_indiv_tasks);
        end 
    end

end

%% -------------------------------------------------------------------------%
% ******** Visualize TPR ******** 
% function ss=visualize_tpr(dcoeff,tpr,tpr_fit,dcoeff_windowed,tpr_windowed,tpr_std,res,filename_prefix,pp,stat_level_map,ss)
function ss=visualize_tpr(dcoeff,tpr,tpr_fit,dcoeff_windowed,tpr_windowed,tpr_std,res,fpr,fwer_strong,fdr,localizing_power,spatial_extent_fp,filename_prefix,pp,stat_level_map,ss) % potential arg: num_fp
    % this does visualization for a single grsize
    % either overlay/combined data (all tasks, all stats) or single data (one task + one stat)
    
    % record master for abs val plots
    pp.ax_xmin_dcoeff_master=pp.ax_xlim_dcoeff_v_tpr(1);
    
    % Plotting
    
    if pp.do_combined % COMPARE STATS, POOLED ACROSS TASKS
        
        % note - don't want to combined the different plots within the same loop ? would have to dynamically set and recall a different figure() for each
        
        if ss.do.save_figs
            ss = summary_tools.check_whether_to_save(ss,'save_figs','Results Figures',[filename_prefix,'_avg_TPR_bar.png']); % TODO: update
        end
        % %{
        % some setup for bar plot, revcumhist, esz v tpr, and residuals plot
        for s=1:pp.n_stat_types

            % tpr
            this_stat_type=stat_level_map.stat_types{s};
            mean_tpr(s)=mean(tpr.(this_stat_type)(:)); % simple vector for bar plot
            tpr_sd(s)=std(mean(tpr.(this_stat_type),1)); % simple vector for bar plot
            if ~strcmp(stat_level_map.stat_gt_levels_str{s},'whole_brain')
                mean_res_across_tasks.(this_stat_type)=mean(res.(this_stat_type),2);
            end
            
            % mean of various error measures -  simple vectors for bar plot
            mean_fpr(s)=mean(fpr.(this_stat_type)(:));
            lp_sd(s)=std(mean(localizing_power.(this_stat_type),1));
            mean_fwer_strong(s)=mean(fwer_strong.(this_stat_type)(:));
            fwer_strong_sd(s)=std(mean(fwer_strong.(this_stat_type),1));
            mean_fdr(s)=mean(fdr.(this_stat_type)(:));
            fdr_sd(s)=std(mean(fdr.(this_stat_type),1));
            mean_lp(s)=mean(localizing_power.(this_stat_type)(:));
            lp_sd(s)=std(mean(localizing_power.(this_stat_type),1));
            mean_spatial_extent_fp(s)=mean(spatial_extent_fp.(this_stat_type)(:));
            spatial_extent_fp_sd(s)=std(mean(spatial_extent_fp.(this_stat_type),1));

        end
        
        % 1. overlay bars (plots using all data at once)
        figure();
        summary_tools.plot_bars(mean_tpr,tpr_sd,pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_avg_TPR'],'ax_ylim_tpr');
        
        % 2. overlay revcumhist (plots using one stat_type's data at a time)
        figure();
        for s=1:pp.n_stat_types
            pp.level=s; % TODO: needed to index into gt level, but there's gotta be a better way
            pp.last_overlay_plot=s==pp.n_stat_types; % TODO: is there a better way? do in the function?
            summary_tools.plot_tpr_revcumhist(tpr.(stat_level_map.stat_types{s})(:),pp,stat_level_map,ss.do.save_figs,filename_prefix)
        end

        % 3.a. overlay signed (+/-) effect size v tpr
        figure();
        for s=1:pp.n_stat_types
            pp.level=s; % TODO: needed to index into gt level, but there's gotta be a better way
            pp.last_overlay_plot=s==pp.n_stat_types; % TODO: is there a better way? do in the function?
            if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                summary_tools.plot_dcoeff_v_tpr(dcoeff.(stat_level_map.stat_types{s})(:),tpr.(stat_level_map.stat_types{s})(:),tpr_fit.(stat_level_map.stat_types{s}),dcoeff_windowed.(stat_level_map.stat_types{s}),tpr_windowed.(stat_level_map.stat_types{s}),tpr_std.(stat_level_map.stat_types{s}),pp,stat_level_map,ss.do.save_figs,filename_prefix);
            else
                summary_tools.plot_dcoeff_v_tpr(dcoeff.(stat_level_map.stat_types{s})(:),tpr.(stat_level_map.stat_types{s})(:),tpr.(stat_level_map.stat_types{s}),[],[],[],pp,stat_level_map,ss.do.save_figs,filename_prefix);
            end
        end
        
        % 3.b. overlay abs value effect size v tpr
        figure();
        filename_prefix__abs=[filename_prefix,'_abs'];
        for s=1:pp.n_stat_types
            
            pp.ax_xlim_dcoeff_v_tpr(1)=0;
            pp.level=s; % TODO: needed to index into gt level, but there's gotta be a better way
            pp.last_overlay_plot=s==pp.n_stat_types; % TODO: is there a better way? do in the function?
            
            if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                % re-fit for abs
                dcoeff_abs=abs(dcoeff.(stat_level_map.stat_types{s})(:));
                [tpr_fit_abs,~,dcoeff_windowed_abs,tpr_windowed_abs,tpr_std_abs,~]=...
                    fit_spline(dcoeff_abs,tpr.(stat_level_map.stat_types{s})(:),pp.spline_smoothing{stat_level_map.stat_gt_levels(s)},pp.window_sz{stat_level_map.stat_gt_levels(s)});
                
                summary_tools.plot_dcoeff_v_tpr(dcoeff_abs,tpr.(stat_level_map.stat_types{s})(:),tpr_fit_abs,dcoeff_windowed_abs,tpr_windowed_abs,tpr_std_abs,pp,stat_level_map,ss.do.save_figs,filename_prefix__abs);
            else
                summary_tools.plot_dcoeff_v_tpr(abs(dcoeff.(stat_level_map.stat_types{s})(:)),tpr.(stat_level_map.stat_types{s}),tpr.(stat_level_map.stat_types{s}),[],[],[],pp,stat_level_map,ss.do.save_figs,filename_prefix__abs);
            end
        end
        

        %{
        % 4. residuals for each stat_type: scatter and spatial distr
        figure();
        pp.last_overlay_plot=0;
        for s=1:pp.n_stat_types
            pp.level=s;
            pp.ax_xlim_dcoeff_v_tpr(1)=pp.ax_xmin_dcoeff_master;
            
            if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                subplot_tight(3,pp.n_stat_types,s);
%                 summary_tools.plot_dcoeff_v_tpr_residuals_scatter(dcoeff_fit.(stat_level_map.stat_types{s})(:),res.(stat_level_map.stat_types{s})(:),pp,stat_level_map,ss.do.save_figs,filename_prefix);
                summary_tools.plot_dcoeff_v_tpr_residuals_scatter(mean(dcoeff.(stat_level_map.stat_types{s}),2),mean_res_across_tasks.(stat_level_map.stat_types{s}),pp,stat_level_map,ss.do.save_figs,filename_prefix);
                subplot_tight(3,pp.n_stat_types,pp.n_stat_types + s);
                summary_tools.plot_dcoeff_v_tpr_residuals_spatial(mean_res_across_tasks.(stat_level_map.stat_types{s}),0,pp,stat_level_map,ss.do.save_figs,filename_prefix);
                subplot_tight(3,pp.n_stat_types,pp.n_stat_types*2 + s);
                pp.last_overlay_plot=(s==pp.n_stat_types-1); % want to exclude whole_brain
                summary_tools.plot_dcoeff_v_tpr_residuals_spatial(mean_res_across_tasks.(stat_level_map.stat_types{s}),1,pp,stat_level_map,ss.do.save_figs,filename_prefix);
            end
        end
        %}

%         % 4. plot localizing_power, fwer_strong, and fdr bars
%         % TODO: rename this function, not just tpr anymore
        figure();
        summary_tools.plot_bars(mean_spatial_extent_fp,spatial_extent_fp_sd,pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_sp_extent'],'ax_ylim_spatial_extent_fp');
        figure();
        summary_tools.plot_bars(mean_fdr,fdr_sd,pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_avg_FDR'],'ax_ylim_FDR')
        figure();
        summary_tools.plot_bars(mean_lp,lp_sd,pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_avg_locpwr'],'ax_ylim_lp');
        figure();
        summary_tools.plot_bars(mean_fwer_strong,fwer_strong_sd,pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_avg_FWERstr'],'ax_ylim_FWERstrong');


        % TODO: TEMP - incorporate this into summarize_fprs.m (or integrate these scripts)
%         % plot fwer_weak bars
%         load('/Volumes/GoogleDrive/My Drive/Lab/Misc/Software/scripts/Matlab/myscripts/fwer_fdr_lp_indvid_files/fwer_weak_gr120.mat')
%         figure();
%         tmp = struct2cell(fwer_weak);
%         fwer_weak = horzcat(tmp{:}) * 100;
%         summary_tools.plot_bars(fwer_weak,zeros(1,7),pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_FWERweak'],'ax_ylim_FWERweak');
        
        
        
    else % INDIVIDUAL TASKS & STATS
        
%         pp.clim_res=pp.clim_res_sm;
        pp.fontsz = pp.fontsz_sm;
        
        % note: pp.stat_level must be defined for individual plots
        for t=1:pp.n_tasks
            
            if ss.do.save_figs
                ss = summary_tools.check_whether_to_save(ss,'save_figs','Results Figures',[filename_prefix,'_dcoeff_v_TPR.png']); % TODO: update
            end
            
            % some setup for bar plot
            for s=1:pp.n_stat_types
                this_stat_type=stat_level_map.stat_types{s};
                mean_tpr(s)=mean(tpr.(this_stat_type)(:,t)); % simple vector for bar plot
                tpr_sd(s)=std(tpr.(this_stat_type)(:,t)); % simple vector for bar plot
            end
            
            % 1. overlay bars (plots using all data at once)
            figure(1);
            subplot(1,pp.n_tasks,t);
            pp.last_overlay_plot=t==pp.n_tasks; % TODO: is there a better way? do in the function?
            summary_tools.plot_bars(mean_tpr,tpr_sd,pp,stat_level_map,ss.do.save_figs,[filename_prefix,'_avg_TPR'],'ax_ylim_tpr');
                
            for s=1:pp.n_stat_types
                pp.level=s;
%                 pp.do_overlay=1;
            
                this_subplot=(t-1)*(pp.n_stat_types)+s;
                pp.last_overlay_plot=(s==pp.n_stat_types && t==pp.n_tasks); % TODO: is there a better way? do in the function?
                

                % 2. revcumhist (plots using one stat_type's data at a time)
                figure(2);
                subplot(1,pp.n_tasks,t);
                summary_tools.plot_tpr_revcumhist(tpr.(stat_level_map.stat_types{s})(:,t),pp,stat_level_map,ss.do.save_figs,filename_prefix)
                
                % 3.a. overlay signed (+/-) effect size v tpr
                figure(3);
                subplot(1,pp.n_tasks,t);
                pp.ax_xlim_dcoeff_v_tpr(1)=pp.ax_xmin_dcoeff_master;
                if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                    summary_tools.plot_dcoeff_v_tpr(dcoeff.(stat_level_map.stat_types{s})(:,t),tpr.(stat_level_map.stat_types{s})(:,t),tpr_fit.(stat_level_map.stat_types{s})(:,t),dcoeff_windowed.(stat_level_map.stat_types{s}).(pp.all_tasks{t}),tpr_windowed.(stat_level_map.stat_types{s}).(pp.all_tasks{t}),tpr_std.(stat_level_map.stat_types{s}).(pp.all_tasks{t}),pp,stat_level_map,ss.do.save_figs,filename_prefix);
                else
                    summary_tools.plot_dcoeff_v_tpr(dcoeff.(stat_level_map.stat_types{s})(:,t),tpr.(stat_level_map.stat_types{s})(:,t),tpr.(stat_level_map.stat_types{s}),[],[],[],pp,stat_level_map,ss.do.save_figs,filename_prefix);
                end
                
                % 3.b. overlay abs value effect size v tpr
                figure(4);
                subplot(1,pp.n_tasks,t);
                pp.ax_xlim_dcoeff_v_tpr(1)=0;
                filename_prefix__abs=[filename_prefix,'_abs'];
                if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                    % re-fit for abs
                    dcoeff_abs=abs(dcoeff.(stat_level_map.stat_types{s})(:,t));
                    [tpr_fit_abs,~,dcoeff_windowed_abs,tpr_windowed_abs,tpr_std_abs,~]=...
                        fit_spline(dcoeff_abs,tpr.(stat_level_map.stat_types{s})(:,t),pp.spline_smoothing{stat_level_map.stat_gt_levels(s)},pp.window_sz{stat_level_map.stat_gt_levels(s)});

                    summary_tools.plot_dcoeff_v_tpr(dcoeff_abs,tpr.(stat_level_map.stat_types{s})(:,t),tpr_fit_abs,dcoeff_windowed_abs,tpr_windowed_abs,tpr_std_abs,pp,stat_level_map,ss.do.save_figs,filename_prefix__abs);
                else
                    summary_tools.plot_dcoeff_v_tpr(abs(dcoeff.(stat_level_map.stat_types{s})(:,t)),tpr.(stat_level_map.stat_types{s})(:,t),tpr.(stat_level_map.stat_types{s})(:,t),[],[],[],pp,stat_level_map,ss.do.save_figs,filename_prefix__abs);
                end
                
                % 4. residuals for each stat_type: scatter and spatial distr
                    
                figure(5);
                subplot(pp.n_tasks,pp.n_stat_types,this_subplot);
                if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
%                    summary_tools.plot_dcoeff_v_tpr_residuals_scatter(dcoeff_fit.(stat_level_map.stat_types{s})(:),res.(stat_level_map.stat_types{s})(:),pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                    summary_tools.plot_dcoeff_v_tpr_residuals_scatter(mean(dcoeff.(stat_level_map.stat_types{s}),2),res.(stat_level_map.stat_types{s})(:,t),pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                else
                    summary_tools.plot_dcoeff_v_tpr_residuals_scatter([],[],pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                end
                
                figure(6);
                subplot(pp.n_tasks,pp.n_stat_types,this_subplot);
                if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                    summary_tools.plot_dcoeff_v_tpr_residuals_spatial(res.(stat_level_map.stat_types{s})(:,t),0,pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                else
                    summary_tools.plot_dcoeff_v_tpr_residuals_spatial([],0,pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                end
                
                figure(7);
                subplot(pp.n_tasks,pp.n_stat_types,this_subplot);
                if ~strcmp(stat_level_map.stat_gt_levels_str(s),'whole_brain')
                    summary_tools.plot_dcoeff_v_tpr_residuals_spatial(res.(stat_level_map.stat_types{s})(:,t),1,pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                else
                    summary_tools.plot_dcoeff_v_tpr_residuals_spatial([],1,pp,stat_level_map,ss.do.save_figs,filename_prefix); % TODO: TESTING
                end
                
                
                
            end
            
        end
        
    end
    
end

%% -------------------------------------------------------------------------%
% ******* Plot ground truth histogram ******* 
function plot_dcoeff_hist(dcoeff,tpr_dthresh,pp,stat_level_map,save_figs,file_prefix)

    stat_level=pp.level;
    gt_level_str=stat_level_map.stat_gt_levels_str{stat_level};
%     if ~strcmp(stat_level_map.stat_gt_levels_str{stat_level},'whole_brain')

    % if not whole_brain, apply any Cohen's d thresholding (Cohen's d thresholding is not applied to whole_brain since it doesn't translate to multivariate effect size)
    if ~strcmp(gt_level_str,'whole_brain')
        dcoeff(dcoeff<tpr_dthresh & dcoeff>(-1*tpr_dthresh))=0;
    end

    face_col = pp.stat_color_order(stat_level,:);
    edge_col = 'none';
    histogram(dcoeff,pp.dcoeff_hist_nbins.(gt_level_str),'Normalization','probability','EdgeColor',edge_col,'FaceColor',face_col,'DisplayName',stat_level_map.stat_levels_str{stat_level});
    
%     legend(stat_level_map.stat_levels_str{stat_level},'Interpreter', 'none','Location','southwest')
    axis([pp.ax_xlim_dcoeff_hist,pp.ax_ylim_dcoeff_hist]);
    set(gca,'fontsize',pp.fontsz)
    
    hold on;
    
    if pp.last_overlay_plot
        
        % flip it and reverse it :)
        h = get(gca,'Children');
        set(gca,'Children',[h(3) h(2) h(1)])
        lgd=legend(h([3 2 1]));
        lgd=legend('Interpreter', 'none','Location','northeast');
        lgd.FontSize = pp.fontsz;
        
        if pp.do_combined
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, pp.fig_width_1plt_norm_big, pp.fig_height_1plt_norm_big])
%             set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_combined_dcoeff, pp.fig_height_combined_dcoeff])
        else
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, pp.fig_width_7plts_norm, pp.fig_height_1plt_norm])
%             set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_sz_7plots, pp.fig_sz_1plot])
        end
        if save_figs 
            print(gcf,[file_prefix,'_dcoeff_hist'],'-dpng','-r300'); 
%             saveas(gcf,[file_prefix,'_dcoeff_hist'],'png');
        end
    end

end

%% -------------------------------------------------------------------------%
% ******* Plot ground truth spatial map ******* 
function plot_dcoeff_spatial_map(dcoeff,summarize_by_net,tpr_dthresh,pp,stat_level_map,save_figs,file_prefix)

    gt_level_str=stat_level_map.stat_gt_levels_str{pp.level};

    if ~strcmp(gt_level_str,'whole_brain')

        % apply any d-thresholding
        dcoeff(dcoeff<tpr_dthresh & dcoeff>(-1*tpr_dthresh))=0;

        d_mat_tmp=+pp.triu_msk.(gt_level_str);
        d_mat_tmp(pp.triu_msk.(gt_level_str))=dcoeff;
        d_mat_tmp2=d_mat_tmp';

        if strcmp(gt_level_str,'edge')
            if summarize_by_net
                summarize_matrix_by_atlas(d_mat_tmp2);
            else
                draw_atlas_boundaries(d_mat_tmp2);
            end
        elseif strcmp(gt_level_str,'network')
            map=load_atlas_mapping(pp.n_nodes.edge,'subnetwork'); % TODO: should be able to use edge_groups rather than loading Shen - for future flexibility
            d_net2edge=summary_to_full_matrix(d_mat_tmp2,map);
            d_net2edge=d_net2edge{1};
            summarize_matrix_by_atlas(d_net2edge);
        end
    else % empty whole-brain plot
        t=+pp.triu_msk.edge;
        t(:,:)=dcoeff;
        summarize_matrix_by_atlas(t);
%         imagesc(dcoeff)
        axis('square')
    end
    
    if ~pp.do_combined
        set(findall(gca, 'Type', 'Line'),'LineWidth',pp.atlas_line_width_single_tasks);
        set(gca,'fontsize',pp.fontsz)
    else
        set(gca,'fontsize',pp.fontsz_lg)
    end

    if summarize_by_net
       caxis(pp.clim_dcoeff.(gt_level_str)/2);
    else
       caxis(pp.clim_dcoeff.(gt_level_str)); 
    end
    
    if pp.last_overlay_plot
        
        colormap(bipolar([],0.1)); % this acts on all subplots at once

        if pp.do_combined
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, pp.fig_width_3plts_norm*4, pp.fig_height_1plt_norm*2.6])
%             set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_combined_dcoeff, pp.fig_height_combined_dcoeff])
        else
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, pp.fig_width_6plts_norm, pp.fig_height_4plts_norm])
%             set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks_dcoeff, pp.fig_height_single_tasks_dcoeff])
        end
        if save_figs 
            print(gcf,[file_prefix,'_dcoeff_spatial'],'-dpng','-r300'); 
%             saveas(gcf,[file_prefix,'_dcoeff_spatial'],'png');
        end
    end
    

end

%% -------------------------------------------------------------------------%
% ******* Plot TPR: Bar plot of average TPR ******* 
function plot_bars(mean_tpr,tpr_sd,pp,stat_level_map,save_figs,file_prefix,ylim_str)

    b=bar(mean_tpr,'FaceColor','flat','EdgeColor','none');
    
    for i = 1:length(mean_tpr) % colors
        b.CData(i,:) = pp.stat_color_order(i,:);  
    end

    hold on;
    er=errorbar(mean_tpr,tpr_sd);    

    set(gca,'xticklabel',stat_level_map.stat_levels_str,'TickLabelInterpreter','none','fontsize',pp.fontsz);
    er.Color = [0,0,0]; 
    er.LineStyle = 'none';
    ylim(pp.(ylim_str));
    xtickangle(15)
    hold off;
    
    if save_figs
        if ~pp.do_combined
            if pp.last_overlay_plot
                set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks, pp.fig_height_single_tasks])
            end
        end
        print(gcf,[file_prefix,'_bar'],'-dpng','-r300');
        %         saveas(gcf,[file_prefix,'_avg_TPR_bar'],'png')
    end


end

%% -------------------------------------------------------------------------%
% ******* Plot TPR: reverse cumulative TPR probability density ******* 
function plot_tpr_revcumhist(tpr,pp,stat_level_map,save_figs,file_prefix)
    
    % Interpretation: how many elements (edges/network pairs) have x power or greater?
    hold on;
    
    gt_level_str=stat_level_map.stat_gt_levels_str{pp.level};
    % dotted line for FDR-based approaches
    if contains(stat_level_map.stat_levels_str(pp.level),'(fdr)'); line_type_str=pp.line_type_fdr;
    else; line_type_str='-';
    end
    
    nbins=ceil((pp.ax_ylim_tpr(2)-pp.ax_ylim_tpr(1))/pp.tpr_bin_width.(gt_level_str)); % TODO: this needs to be gt level
    bin_edges=linspace(pp.ax_ylim_tpr(1),pp.ax_ylim_tpr(2),nbins+1);

    tpr_histcounts=histcounts(tpr,bin_edges,'Normalization','probability');
    bin_centers=bin_edges(1:end-1)+pp.tpr_bin_width.(gt_level_str)/2;
    ndist = tpr_histcounts / sum(tpr_histcounts);
    cdist = cumsum(ndist,'reverse'); % percent of effects showing X power or greater
    plot(bin_centers,cdist,line_type_str,'LineWidth',3,'Color',pp.stat_color_order(pp.level,:));
    
    ylim(pp.ax_ylim_revcumhist);
    set(gca,'fontsize',pp.fontsz);
    
%     if pp.do_overlay
%         hold on;
        if pp.last_overlay_plot % last plot
%             legend(stat_level_map.stat_levels_str,'Interpreter','none','Location','southwest'); % ultimately had to turn off legend for combined plots for a custom solution
            hold off;
            if ~pp.do_combined
                set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks, pp.fig_height_single_tasks])
            end
            if save_figs
                print(gcf,[file_prefix,'_TPR_revcumhist'],'-dpng','-r300'); 
%                 saveas(gcf,[file_prefix,'_TPR_revcumhist'],'png')
            end
        end
%     else % assuming saving single, non-overlay plot
%         if save_figs
%             saveas(gcf,[file_prefix,'_TPR_revcumhist'],'png')
%         end
%     end
    
end

%% -------------------------------------------------------------------------%
% ******* Plot TPR: Effect size versus TPR ******* 
function plot_dcoeff_v_tpr(dcoeff,tpr,tpr_fit,dcoeff_windowed,tpr_windowed,tpr_std,pp,stat_level_map,save_figs__results,file_prefix)
    
    % doing (:) because some are n_edges x n_tasks, but want to pool
    if size(dcoeff,2)>1
        dcoeff=dcoeff(:);
        tpr=tpr(:);
        tpr_fit=tpr_fit(:);
    end
    
    % dotted line for FDR-based approaches
    if contains(stat_level_map.stat_levels_str(pp.level),'(fdr)'); line_type_str=pp.line_type_fdr;
    else; line_type_str='-';
    end
    
    hold on
%     yyaxis left
%     this_stat_type=stat_level_map.stat_types{pp.level};
    [~,ind]=sort(dcoeff);
    plot(dcoeff(ind),tpr_fit(ind),line_type_str,'LineWidth',3,'Color',pp.stat_color_order(pp.level,:))
    if stat_level_map.stat_gt_levels(pp.level)==1
        if exist('shadedErrorBar','file')
            shadedErrorBar(dcoeff_windowed,tpr_windowed,tpr_std,'noLine',1,'lineProps',{'-','color',pp.stat_color_order(pp.level,:)})
        else
            warning('Can''t find shadedError function, so won''t draw shaded error bars.')
        end
    else
        markertype='.';
        if pp.level==4
            markertype='.';
        end
        scatter(dcoeff,tpr,6,markertype,'MarkerEdgeColor',pp.stat_color_order(pp.level,:)) % 'MarkerEdgeColor', % TODO: undo blue
%         scatter(dcoeff,tpr,1,'.','MarkerEdgeColor',pp.stat_color_order(pp.level,:)) % TODO: undo blue
    end
%     hold off

    % add stuff to TPR by esz
    axis([pp.ax_xlim_dcoeff_v_tpr,pp.ax_ylim_tpr])
    set(gca,'fontsize',pp.fontsz)
    
%     if pp.do_overlay
%         hold on;
        if pp.last_overlay_plot % last plot
            
            h=get(gca,'Children'); % grab all the axes handles at once
            lines_to_get=flip([1:length(h)]);
            lines_to_get=lines_to_get(1:2:end);

            hold off;
            
            
            if ~pp.do_combined
                set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks, pp.fig_height_single_tasks])
                legend(h(lines_to_get),stat_level_map.stat_levels_str,'Interpreter','none','Location','southeast')  % ultimately had to turn off legend for combined plots for a custom solution            
            end
            
            if save_figs__results
                print(gcf,[file_prefix,'_dcoeff_v_TPR'],'-dpng','-r300'); 
%                 saveas(gcf,[file_prefix,'_dcoeff_v_TPR'],'png')
            end
        end

end

%% -------------------------------------------------------------------------%
% ******* Plot residuals (from effect size v. TPR): scatterplot ******* 
function plot_dcoeff_v_tpr_residuals_scatter(dcoeff,res,pp,stat_level_map,save_figs,file_prefix)

    gt_level_str=stat_level_map.stat_gt_levels_str{pp.level};
    
    if ~strcmp(gt_level_str,'whole_brain')

        scatter(dcoeff,res,1,'b.')
        hold on;
        std_thresh=pp.n_std_residual_outlier*std(res);
        idx=abs(res)>std_thresh;
        scatter(dcoeff(idx),res(idx),1,'.')
        plot(dcoeff,zeros(size(dcoeff)),'k-','LineWidth',2) % plot zero residual line
    %     hold off;
    
    
    axis([pp.ax_xlim_dcoeff_hist,pp.ax_ylim_res.(gt_level_str)])
    end
    
    if pp.last_overlay_plot
        if ~pp.do_combined
            set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks_stats, pp.fig_height_single_tasks_stats])
        end
        if save_figs
            print(gcf,[file_prefix,'_dcoeff_v_tpr_residuals_scatter'],'-dpng','-r300'); 
%             saveas(gcf,[file_prefix,'_dcoeff_v_tpr_residuals_scatter'],'png')
        end
    end

end

%% -------------------------------------------------------------------------%
% ******* Plot residuals (from effect size v. TPR): spatial map ******* 
function plot_dcoeff_v_tpr_residuals_spatial(res,summarize_by_net,pp,stat_level_map,save_figs,file_prefix)

%     gt_level=stat_level_map.stat_gt_levels(pp.level);
    gt_level_str=stat_level_map.stat_gt_levels_str{pp.level};
    
    if ~strcmp(gt_level_str,'whole_brain')
        % put edge-level residuals back into upper triangle
        triu_msk=pp.triu_msk.(gt_level_str);
        if numel(res)==pp.n_features.(gt_level_str)
            res_mat=+triu_msk;
            res_mat(triu_msk)=res;
        else
            res_mat=+triu_msk;
            res_mat(triu_msk)=mean(reshape(res,pp.n_features.(gt_level_str),pp.n_tasks),2);
        end 

        if strcmp(gt_level_str,'edge')
            if summarize_by_net
                summarize_matrix_by_atlas(res_mat','atlascategory','subnetwork');
            else
                draw_atlas_boundaries(res_mat');
            end
        elseif strcmp(gt_level_str,'network')
            map=load_atlas_mapping(pp.n_nodes.edge,'subnetwork');  % TODO: should be able to use edge_groups rather than loading Shen - for future flexibility
            res_tmp=summary_to_full_matrix(res_mat,map);
            res_tmp=res_tmp{1};
            summarize_matrix_by_atlas(res_tmp','atlascategory','subnetwork');
        end
        if ~pp.do_combined
            set(findall(gca, 'Type', 'Line'),'LineWidth',pp.atlas_line_width_single_tasks);
            set(gca,'fontsize',pp.fontsz)
        end
    
        if strcmp(gt_level_str,'edge') && summarize_by_net
            caxis(pp.clim_res.edge_bynet);
        else
            caxis(pp.clim_res.(gt_level_str));
        end
        
        colormap(bipolar([],0.1));
    else % plot 0 for whole-brain case since no line gets fit
        imagesc(0)
        axis('square')
    end
    
    if pp.last_overlay_plot
        if pp.do_combined
            set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_combined, pp.fig_height_combined])
        else
            set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks_stats, pp.fig_height_single_tasks_stats])
        end
        if save_figs 
            print(gcf,[file_prefix,'_dcoeff_v_tpr_residuals_spatial'],'-dpng','-r300'); 
%             saveas(gcf,[file_prefix,'_dcoeff_v_tpr_residuals_spatial'],'png');
        end
    end
    
    %{
    % Summary plot only for edge-level
    if gt_level==1
        summarize_matrix_by_atlas(res_mat');
        caxis(pp.clim_res{gt_level}); colormap(bipolar([],0.1));
        if save_figs__results; saveas(gcf,[filename_prefix,'_residuals',pp.level_str{gt_level},'_in_networks'],'png'); end
    end
    %}

end

%% -------------------------------------------------------------------------%
% ******** Log summary info (TPR at/within effect size thresholds) **********
function ss=write_summary_log(dcoeff_windowed,tpr_windowed,fdr,fwer_strong,localizing_power,spatial_extent_fp,log_data,stat_level_map,pp,ss,file_prefix,do_combined)

    gt_level=stat_level_map.stat_gt_levels(pp.level);
    
    % unpack plot params for log
    thresholds=[pp.thresh_small, pp.thresh_med, pp.thresh_large];

    n_tasks=length(fwer_strong);

    for i=1:length(thresholds)

        % Get IDs of edges below/between d-thresh (e.g., edges < thresh_high; edges < thresh_high & > thresh_low)
        ids_lt_thr=abs(dcoeff_windowed) <= thresholds(i);
        if i~=1
            ids_btw_thr_and_thr_below=abs(dcoeff_windowed) <= thresholds(i) & abs(dcoeff_windowed) >= thresholds(i-1);
        end

        % -> Get TPR of edges below/between d-threshold
        tpr_lt_thr(i) = nanmean(tpr_windowed(ids_lt_thr));
        if i~=1
            tpr_btw_thr_and_thr_below(i-1) = nanmean(tpr_windowed(ids_btw_thr_and_thr_below));
        end

        % Get IDs of edges at (around) dcoeff (divide by 2 to get both halves of the bin)
        ids_at_pos_thr = abs(dcoeff_windowed-thresholds(i)) <= pp.bin_width_at_summary_thresh{gt_level} / 2;
        ids_at_neg_thr = abs(dcoeff_windowed+thresholds(i)) <= pp.bin_width_at_summary_thresh{gt_level} / 2;

        % -> Get TPR of edges at (around) +thresh, -thresh, and mean
        tpr_at_thr(3*(i-1) + 1) = nanmean(tpr_windowed(ids_at_pos_thr));
        tpr_at_thr(3*(i-1) + 2) = nanmean(tpr_windowed(ids_at_neg_thr));
        tpr_at_thr(3*(i-1) + 3) = mean(tpr_at_thr((3*i-2):(3*i-1)));

    end

    if do_combined
        spatial_extent_fp=mean(spatial_extent_fp);
        fdr=mean(fdr);
        localizing_power=mean(localizing_power);
        fwer_strong=mean(fwer_strong);
        
        log_data_all_tasks=log_data;
        log_data=[];
        a=fieldnames(log_data_all_tasks);

        log_data.n_repetitions=log_data_all_tasks.(a{1}).n_repetitions;
        log_data.n_perms=str2num(log_data_all_tasks.(a{1}).n_perms);
        log_data.n_subs_subset=log_data_all_tasks.(a{1}).n_subs_subset;
        for i=1:length(a)
            log_data.n_subs_total(i)=log_data_all_tasks.(a{i}).n_subs_total;
            log_data.run_time_h(i)=log_data_all_tasks.(a{i}).run_time_h; % toc is in sec
        end
        log_data.n_subs_total_std=mean(log_data.n_subs_total);
        log_data.n_subs_total=mean(log_data.n_subs_total);
        log_data.run_time_h_std=std(log_data.run_time_h);
        log_data.run_time_h=mean(log_data.run_time_h);
    end


    % Log percent esz and TP at thresholds

    logfile=[file_prefix,'_log','.txt'];
    ss = summary_tools.check_whether_to_save(ss,'save_logs','Log file',logfile);

    if ss.do.save_logs
        fprintf('Saving log in %s.\n',logfile);

        fid=fopen(logfile,'w');
        fprintf(fid,'SENSITIVITY\n');
        fprintf(fid,'Mean TPR between d=+/-%1.1f: %1.3f\n',[thresholds; tpr_lt_thr]);
        fprintf(fid,'Mean TPR between d=%1.1f and %1.1f: %1.3f\n',[thresholds(2:end); thresholds(1:end-1); tpr_btw_thr_and_thr_below]);
        fprintf(fid,'Mean TPR at d=+/-%1.1f: %f (+), %f (-), %f (mean)\n',[thresholds; reshape(tpr_at_thr,3,length(thresholds))]);
        fprintf(fid,'SPECIFICITY\n');
        fprintf(fid,'Mean spatial extent FP: %1.3f\n',mean(spatial_extent_fp));
        fprintf(fid,'Mean FDR: %1.3f\n',mean(fdr));
        fprintf(fid,'Mean spatial precision: %1.3f\n',localizing_power);
        fprintf(fid,'Strong FWER: %1.3f\n',fwer_strong);
        fprintf(fid,'BENCHMARKING INFO\n');
        fprintf(fid,'%d total repetitions\n',log_data.n_repetitions);
        fprintf(fid,'%d total permutations\n',log_data.n_perms);
        fprintf(fid,'%d subjects sampled out of %d total subjects\n',log_data.n_subs_subset,round(log_data.n_subs_total));
        fprintf(fid,'Run time: %1.2f hours\n',log_data.run_time_h); % toc is in sec
        if do_combined
            fprintf(fid,'Total subjects std: %1.3f\n',log_data.n_subs_total_std);
            fprintf(fid,'Run time std: %1.3f hours\n',log_data.run_time_h_std); % toc is in sec
        end
        fclose(fid);
    end
end


%% -------------------------------------------------------------------------%
% ******** Calculate FPR metrics for the case when the null is not true everywhere **********
function [fpr,fwer_strong,fdr,localizing_power,num_fp,spatial_extent_fp]=calculate_fpr_metrics(stat_level_str,benchmarking_summary_filename,n_repetitions,ids_esz_pos_vec,ids_esz_neg_vec,ids_esz_zero_vec,ids_esz_pos,ids_esz_neg,ids_esz_zero,edge_groups,dcoeff_edge,triu_msk,ids_triu,tpr_dthresh)

    % TODO: all of this could be more efficient
    load(benchmarking_summary_filename,'positives','positives_neg');

    % reshape if needed -  TFCE and Size_Extent are *sometimes* n_nodes x n_nodes due to older code, but need to be n_edges x n_reps
    if ndims(positives)==3 
        positives=reshape(positives, [], n_repetitions);
        positives_neg=reshape(positives_neg, [], n_repetitions);
    end
    


    % 1. Calculate FPR maps and strong FWER
    % TODO: here and elsewhere pass and use stats_levelstr_map so can just call out cluster, network, etc.
    
    if contains(stat_level_str,'edge') % ids from matrix vector (max=n*(n-1)/2)

        ids_esz_pos_vec = ids_esz_pos_vec | ids_esz_zero_vec;
        ids_esz_neg_vec = ids_esz_neg_vec | ids_esz_zero_vec;
        ids_esz_neg_vec__tri=find(ids_esz_neg_vec);
        ids_esz_pos_vec__tri=find(ids_esz_pos_vec);
        ids_esz_zero_vec__tri=find(ids_esz_zero_vec);
        
        % count n_nodes
        n_nodes__edge_level=size(triu_msk,1);
        
        fp_pos=zeros(size(positives));
        fp_neg=zeros(size(positives_neg));
        fp_pos(ids_esz_neg_vec__tri,:)=positives(ids_esz_neg_vec__tri,:);
        fp_neg(ids_esz_pos_vec__tri,:)=positives_neg(ids_esz_pos_vec__tri,:);
        fp_zero__avg_tails(ids_esz_zero_vec__tri,:)=(positives(ids_esz_zero_vec__tri,:)+positives_neg(ids_esz_zero_vec__tri,:))/2; % for null, take average false positives in both dir

        % summarize false positives across both tails
        fdr_pos=100*sum(fp_pos)./sum(positives);
        fdr_neg=100*sum(fp_neg)./sum(positives_neg);
        fdr = (fdr_pos+fdr_neg)/2; % percent per repetition - avg of test in both dirs

        fpr(ids_esz_neg_vec__tri)=100 * sum(fp_pos(ids_esz_neg_vec__tri,:),2)/n_repetitions;
        fpr(ids_esz_pos_vec__tri)=100 * sum(fp_neg(ids_esz_pos_vec__tri,:),2)/n_repetitions;  % will overwrite fpr_pos at true zero edges, thus the next step
        fpr(ids_esz_zero_vec__tri)=100 * sum(fp_zero__avg_tails(ids_esz_zero_vec__tri,:),2)/n_repetitions; % per edge - average fp for true zero edges
        num_fp=(sum(fp_pos)+sum(fp_neg))/2; % per repetition, in edges - avg of test in both dirs
        spatial_extent_fp = 100 * num_fp / size(positives,1); % per repetition, in % total edges - avg of test in both dirs
        fwer_strong = 100 * (sum(fdr_pos>0)+sum(fdr_neg>0)) / 2 / n_repetitions;


    elseif contains(stat_level_str,'cluster')  % special procedure for cluster — a FP cluster occurs when no true effect exists in the whole cluster

         n_nodes__edge_level=size(triu_msk,1);

        % reshape positives to square symmetric adjacency, as required for get_components
        ids_esz_pos_vec(ids_esz_zero_vec)=0;  % using the opposite strategy here as for the other procedures, since now we're using this indexing var to get true positives (then false positives), not false positives directly
        ids_esz_neg_vec(ids_esz_zero_vec)=0;
        ids_esz_zero_vec__tri=find(ids_esz_zero_vec);

        fp_pos=zeros(length(ids_esz_pos_vec),n_repetitions);
        fp_neg=zeros(length(ids_esz_pos_vec),n_repetitions);
        fp_zero__avg_tails=zeros(length(ids_esz_pos_vec),n_repetitions);

        positives_sq_thisrep__pos=zeros(n_nodes__edge_level);
        positives_sq_thisrep__neg=zeros(n_nodes__edge_level);

        for this_rep=1:n_repetitions
            positives_sq_thisrep__pos=structure_data(positives(:,this_rep),'mask',ones(size(triu_msk)));
            positives_sq_thisrep__neg=structure_data(positives_neg(:,this_rep),'mask',ones(size(triu_msk)));
            
            % get individual positive clusters
            % IMPORTANT: get_edge_components labels components by size, so it is possible (though unlikely in practice) to have multiple components with the same label that are actually unique but unable to be distinguished % NOTE: size is full and double counts component sizes, whereas tfce is upper triangle only
            [positives_labelled_by_comp__pos,comp_sizes__pos] = get_edge_components(positives_sq_thisrep__pos,0,positives_sq_thisrep__pos,0,268,find(triu_msk),0);
            [positives_labelled_by_comp__neg,comp_sizes__neg] = get_edge_components(positives_sq_thisrep__neg,0,positives_sq_thisrep__neg,0,268,find(triu_msk),0);
            positives_labelled_by_comp_vec__pos=positives_labelled_by_comp__pos(triu_msk); % could be more efficient - convert to triu but then use original for fp_map
            positives_labelled_by_comp_vec__neg=positives_labelled_by_comp__neg(triu_msk);
            num_pos_clusters__pos(this_rep)=length(comp_sizes__pos);
            num_pos_clusters__neg(this_rep)=length(comp_sizes__neg);

            % find all clusters that contain true positive edges
            components_with_tp__pos=unique(positives_labelled_by_comp_vec__pos(ids_esz_pos_vec));
            components_with_tp__neg=unique(positives_labelled_by_comp_vec__neg(ids_esz_neg_vec));
            components_with_tp__pos(components_with_tp__pos==0)=[];
            components_with_tp__neg(components_with_tp__neg==0)=[];
            num_tp_clusters__pos(this_rep)=length(components_with_tp__pos);
            num_tp_clusters__neg(this_rep)=length(components_with_tp__neg);

            num_fp_clusters__pos(this_rep)=num_pos_clusters__pos(this_rep)-num_tp_clusters__pos(this_rep);
            num_fp_clusters__neg(this_rep)=num_pos_clusters__neg(this_rep)-num_tp_clusters__neg(this_rep);

            % create FP map by duplicating P map and zeroing out any components that contain a true positive edge
            fp_map__pos=positives_sq_thisrep__pos;
            fp_map__neg=positives_sq_thisrep__neg;
            for j=1:length(components_with_tp__pos)
                fp_map__pos(positives_labelled_by_comp__pos==components_with_tp__pos(j))=0;
            end
            for j=1:length(components_with_tp__neg)
                fp_map__neg(positives_labelled_by_comp__neg==components_with_tp__neg(j))=0;
            end

            fp_pos(:,this_rep)=fp_map__pos(triu_msk);
            fp_neg(:,this_rep)=fp_map__neg(triu_msk);
            fp_zero__avg_tails(ids_esz_zero_vec__tri,this_rep)=(fp_pos(ids_esz_zero_vec__tri,this_rep)+fp_neg(ids_esz_zero_vec__tri,this_rep))/2; % for null, take average false positives in both dir

        end

        % convert positives from full mat *vector* (nxn) to triu *vector* (nx(n-1)/2) so fp and positives are all in the same space for spatial extent and spatial precision calculation
        positives=positives(ids_triu,:); 
        positives_neg=positives_neg(ids_triu,:);
        
        % summarize false positive rates
        fdr_pos=100 * num_fp_clusters__pos./num_pos_clusters__pos;
        fdr_neg=100 * num_fp_clusters__neg./num_pos_clusters__neg;
        fdr = (fdr_pos+fdr_neg)/2; % per repetition - avg of test in both dirs
        fpr=100 * sum(fp_pos,2)/n_repetitions;
        fpr=100 * sum(fp_neg,2)/n_repetitions;  % will overwrite fpr_pos at true zero edges, thus the next step
        fpr(ids_esz_zero_vec__tri)=100 * sum(fp_zero__avg_tails(ids_esz_zero_vec__tri,:),2)/n_repetitions; % per edge - average fp for true zero edges

        num_fp=(num_fp_clusters__pos + num_fp_clusters__neg)/2; % per repetition, in clusters - avg of test in both dirs
        num_fp__in_edges=(sum(fp_pos) + sum(fp_neg)) /2; % per repetition, in edges - avg of test in both dirs
        spatial_extent_fp = 100 * num_fp__in_edges / size(positives,1); % per repetition, in % total edges - avg of test in both dirs
        fwer_strong = 100 * (sum(fdr_pos>0)+sum(fdr_neg>0)) / 2 / n_repetitions;
    
    elseif contains(stat_level_str,'network') % ids from vectorized matrix (max=n*n ?)
        
        n_nodes__edge_level=size(edge_groups,1);
        ids_esz_pos = ids_esz_pos | ids_esz_zero;
        ids_esz_neg = ids_esz_neg | ids_esz_zero;

        fp_pos=zeros(size(positives));
        fp_neg=zeros(size(positives_neg));
        fp_pos(ids_esz_neg,:)=positives(ids_esz_neg,:);
        fp_neg(ids_esz_pos,:)=positives_neg(ids_esz_pos,:);
        fp_zero__avg_tails(ids_esz_zero,:)=(positives(ids_esz_zero,:)+positives_neg(ids_esz_zero,:))/2; % for null, take average false positives in both dir

        fp_in_edges_pos=fp_pos;
        fp_in_edges_neg=fp_neg;
        for i=1:size(positives,1)
            fp_in_edges_pos(i,:)=fp_pos(i,:)*nnz(edge_groups==i);
            fp_in_edges_neg(i,:)=fp_neg(i,:)*nnz(edge_groups==i);
        end

        % summarize false positives across both tails
        fdr_pos=100 * sum(fp_pos)./sum(positives);
        fdr_neg=100 * sum(fp_neg)./sum(positives_neg);
        fdr = (fdr_pos+fdr_neg)/2; % per repetition - avg of test in both dirs
        fpr(ids_esz_neg)=100 * sum(fp_pos(ids_esz_neg,:),2)/n_repetitions;
        fpr(ids_esz_pos)=100 * sum(fp_neg(ids_esz_pos,:),2)/n_repetitions;  % will overwrite fpr_pos at true zero network, thus the next step
        fpr(ids_esz_zero)=100 * sum(fp_zero__avg_tails(ids_esz_zero,:),2)/n_repetitions; % per network - average fp for true zero networks
        num_fp=(sum(fp_pos)+sum(fp_neg))/2; % per repetition, in networks - avg of test in both dirs
        num_fp__in_edges=(sum(fp_in_edges_pos)+sum(fp_in_edges_neg))/2; % per repetition, in edges - avg of test in both dirs
        spatial_extent_fp = 100 * num_fp__in_edges / nnz(edge_groups); % per repetition, in % total edges - avg of test in both dirs
        fwer_strong = 100 * (sum(fdr_pos>0)+sum(fdr_neg>0)) / 2 / n_repetitions;
        
        
    elseif contains(stat_level_str,'whole brain')
        
        ids_esz_pos_vec = ids_esz_pos_vec | ids_esz_zero_vec;
        ids_esz_neg_vec = ids_esz_neg_vec | ids_esz_zero_vec;
        n_nodes__edge_level=int16(roots([1 -1 -2*length(dcoeff_edge)]));
        n_nodes__edge_level=n_nodes__edge_level(1);
        fp=zeros(1,n_repetitions); % in the task contrast experiment, there is always at least one real ground truth effect - thus, a positive MV test is always a true positive
        
        % summarize false positive rates
        fdr = 100 * sum(fp)./sum(positives); % per repetition
        fpr = 100 * sum(fp')/n_repetitions; % per variable
        num_fp = fp; % per repetition
        spatial_extent_fp = 100 * fp; % per repetition, in % edges
        fwer_strong = 100 * sum(+(sum(fp)>0)) / n_repetitions / 2;

    end



    % 2. Calculate localizing power as univariate "true discovery rate" (PPV)
    % final measure is average localizing power per repetition
    % TDR = TP/P = (P - FP)/P = 1 - FP/P = 1 - FDR
    % For this, need univariate pseudo-false positives for everything beyond the edge-level
    % (note: these are not strictly false positives according to the definition of broader scales of inference)
    if contains(stat_level_str,'edge')
        fdr_perrep = fdr;
        lp_perrep= 100 - fdr_perrep;
        localizing_power = mean(lp_perrep);
        

    elseif contains(stat_level_str,'cluster')
        pseudo_fp_pos=zeros(size(positives));
        pseudo_fp_neg=zeros(size(positives));
        pseudo_fp_pos(find(ids_esz_neg_vec | ids_esz_zero_vec),:)=positives(find(ids_esz_neg_vec | ids_esz_zero_vec),:);
        pseudo_fp_neg(find(ids_esz_pos_vec | ids_esz_zero_vec),:)=positives_neg(find(ids_esz_pos_vec | ids_esz_zero_vec),:);
        
        pseudo_fdr_pos = 100 * sum(pseudo_fp_pos)./sum(positives);
        pseudo_fdr_neg = 100 * sum(pseudo_fp_neg)./sum(positives_neg);
        pseudo_fdr = (pseudo_fdr_pos+pseudo_fdr_neg)/2; % per repetition - avg of test in both dirs

        lp_perrep = 100 - pseudo_fdr;
        localizing_power = mean(lp_perrep);

    elseif contains(stat_level_str,'network')
        
        % First convert positives map to univariate map
        % Note: input positives are upper triangle (only network-level dcoeffs are lower triangular, but these are not used here - this uses edge-level dcoeffs, which are upper triangular)
        % TODO: possibly adjust - this is the only one that needs dcoeff_edge and triu_msk passed to the function (although whole_brain uses for dimensions)

        ids_esz_pos_vec=dcoeff_edge>tpr_dthresh;
        ids_esz_neg_vec=dcoeff_edge<(-1*tpr_dthresh);
        ids_esz_zero_vec=(dcoeff_edge<tpr_dthresh) & (dcoeff_edge>(-1*tpr_dthresh));
        ids_esz_pos_vec=ids_esz_pos_vec | ids_esz_zero_vec;
        ids_esz_neg_vec=ids_esz_neg_vec | ids_esz_zero_vec;
        
        map=load_atlas_mapping(n_nodes__edge_level,'subnetwork');  % TODO: should be able to use edge_groups rather than loading Shen - for future flexibility

        triu_msk_edge=logical(triu(ones([n_nodes__edge_level,n_nodes__edge_level]),1));
        pseudo_positives_pos_vec=zeros(size(dcoeff_edge,1),n_repetitions);
        pseudo_positives_neg_vec=zeros(size(dcoeff_edge,1),n_repetitions);
        pseudo_fp_pos=zeros(size(dcoeff_edge,1),n_repetitions);
        pseudo_fp_neg=zeros(size(dcoeff_edge,1),n_repetitions);
        
        for this_rep=1:n_repetitions
            positives_mat_pos=structure_data(positives(:,this_rep),'mask',triu_msk); % sum of num positive reps per network
            positives_mat_neg=structure_data(positives_neg(:,this_rep),'mask',triu_msk);
    
            pseudo_positives_fullmat_pos=summary_to_full_matrix(positives_mat_pos,map); % convert num positive reps/net to num per edge
            pseudo_positives_fullmat_neg=summary_to_full_matrix(positives_mat_neg,map);
    

            pseudo_positives_pos_vec(:,this_rep)=pseudo_positives_fullmat_pos{1}(triu_msk_edge);
            pseudo_positives_neg_vec(:,this_rep)=pseudo_positives_fullmat_neg{1}(triu_msk_edge);
    
            pseudo_fp_pos(ids_esz_neg_vec,this_rep)=pseudo_positives_pos_vec(ids_esz_neg_vec,this_rep);
            pseudo_fp_neg(ids_esz_pos_vec,this_rep)=pseudo_positives_neg_vec(ids_esz_pos_vec,this_rep);
    
        end

        %  the following is equal to mean(fdr_perrep) and mean(lp_perrep)
        pseudo_fdr_pos = 100 * sum(pseudo_fp_pos)./sum(pseudo_positives_pos_vec);
        pseudo_fdr_neg = 100 * sum(pseudo_fp_neg)./sum(pseudo_positives_neg_vec);        
        pseudo_fdr = (pseudo_fdr_pos+pseudo_fdr_neg)/2;
        
        lp_perrep = 100 - pseudo_fdr;
        localizing_power = mean(lp_perrep);

        % get per group - added for supp analysis
        %{
        edge_groups_triu=edge_groups';        
        edge_groups_triu=edge_groups_triu(triu_msk_edge);
        for i=1:n_repetitions
            for j=1:length(unique(edge_groups_triu))
                pseudo_fp_pos_by_group(j,i)=mean(pseudo_fp_pos((edge_groups_triu==j),i));
                pseudo_fp_neg_by_group(j,i)=mean(pseudo_fp_neg((edge_groups_triu==j),i));
                pseudo_positives_pos_by_group(j,i)=mean(pseudo_positives_pos_vec((edge_groups_triu==j),i));
                pseudo_positives_neg_by_group(j,i)=mean(pseudo_positives_neg_vec((edge_groups_triu==j),i));
            end
        end
        localizing_power_pos_by_group=100*(1-pseudo_fp_pos_by_group./pseudo_positives_pos_by_group);
        localizing_power_neg_by_group=100*(1-pseudo_fp_neg_by_group./pseudo_positives_neg_by_group);
        fprintf('SP:           %1.1f\n',localizing_power);
        fprintf('SP, by group: %1.1f\n',mean([nanmean(localizing_power_pos_by_group(:)),nanmean(localizing_power_neg_by_group(:))]));
        %}

    elseif contains(stat_level_str,'whole brain')
        % Here we leave localizing power undefined. Since there is no edge-level bidirectional null, this is biased towards showing 100% "localizing power" each time
        localizing_power=0;
        pseudo_fp = 0;

    end



    % 3. Save an example map of positives at repetition 1
    save_example_map=0; % TODO: temp
    
    if save_example_map
        example_rep=1;

        tp_fp_map=positives(:,example_rep)-2*fp(:,example_rep); % 1 is TP, -1 is FP

        if contains(stat_level_str,'edge')
            example_pos_map=structure_data(tp_fp_map,'mask',triu_msk);
        elseif contains(stat_level_str,'cluster')
            example_pos_map=structure_data(tp_fp_map,'mask',triu_msk);
        elseif contains(stat_level_str,'network')
            tp_fp_map_mat=structure_data(tp_fp_map','mask',triu_msk);
            map=load_atlas_mapping(n_nodes__edge_level,'subnetwork'); % TODO: should be able to use edge_groups rather than loading Shen - for future flexibility
            example_pos_map=summary_to_full_matrix(tp_fp_map_mat,map);
            example_pos_map=example_pos_map{1};
        elseif contains(stat_level_str,'whole brain')
           example_pos_map=ones(n_nodes__edge_level)*tp_fp_map;
        end

        this_grsize=80; % TODO: TEMP - don't want to use here, so don't bother passing...
        this_clim_tpmap=[0,1];
        this_fontsz_lg=18;
        this_folder='/Volumes/GoogleDrive/My Drive/Lab/Misc/Software/scripts/Matlab/myscripts/fwer_fdr_lp_indvid_files/pics/';
        example_tpmap=(example_pos_map+example_pos_map')>0;
        example_fpmap=(example_pos_map+example_pos_map')<0;

        figure;
        draw_atlas_boundaries(example_tpmap);
        set(gca,'fontsize',this_fontsz_lg)
        caxis(this_clim_tpmap); 
        colormap([1,1,1;1,0,0])
        print(gcf,sprintf([this_folder,'example_posmap_%s_gr%d__tp'],stat_level_str,this_grsize),'-dpng','-r300'); 

        figure;
        draw_atlas_boundaries(example_fpmap);
        set(gca,'fontsize',this_fontsz_lg)
        caxis(this_clim_tpmap); 
        colormap([1,1,1;0,0,1])
        print(gcf,sprintf([this_folder,'example_posmap_%s_gr%d__fp'],stat_level_str,this_grsize),'-dpng','-r300'); 

        writematrix(example_tpmap,sprintf([this_folder,'example_posmap_%s_gr%d__tp.txt'],stat_level_str,this_grsize))
        writematrix(example_fpmap,sprintf([this_folder,'example_posmap_%s_gr%d__fp.txt'],stat_level_str,this_grsize))
    end


end

%% -------------------------------------------------------------------------%
% ******* Plot ground truth spatial map ******* 
function plot_positive_map(posmap,summarize_by_net,pp,stat_level_map,save_figs,file_prefix)

    gt_level_str=stat_level_map.stat_gt_levels_str{pp.level};
    
    if ~strcmp(gt_level_str,'whole_brain')
        d_mat_tmp=+pp.triu_msk.(gt_level_str);
        d_mat_tmp(pp.triu_msk.(gt_level_str))=dcoeff;
        d_mat_tmp2=d_mat_tmp';

        if strcmp(gt_level_str,'edge')
            if summarize_by_net
                summarize_matrix_by_atlas(d_mat_tmp2);
            else
                draw_atlas_boundaries(d_mat_tmp2);
            end
        elseif strcmp(gt_level_str,'network')
            map=load_atlas_mapping(pp.n_nodes.edge,'subnetwork'); % TODO: should be able to use edge_groups rather than loading Shen - for future flexibility
            d_net2edge=summary_to_full_matrix(d_mat_tmp2,map);
            d_net2edge=d_net2edge{1};
            summarize_matrix_by_atlas(d_net2edge);
        end
    else % empty whole-brain plot
        t=+pp.triu_msk.edge;
        t(:,:)=dcoeff;
        summarize_matrix_by_atlas(t);
%         imagesc(dcoeff)
        axis('square')
    end
    
    if ~pp.do_combined
        set(findall(gca, 'Type', 'Line'),'LineWidth',pp.atlas_line_width_single_tasks);
        set(gca,'fontsize',pp.fontsz)
    else
        set(gca,'fontsize',pp.fontsz_lg)
    end

    if summarize_by_net
       caxis(pp.clim_dcoeff.(gt_level_str)/2);
    else
       caxis(pp.clim_dcoeff.(gt_level_str)); 
    end
    
    if pp.last_overlay_plot
        
        colormap(bipolar([],0.1)); % this acts on all subplots at once

        if pp.do_combined
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, pp.fig_width_3plts_norm*4, pp.fig_height_1plt_norm*2.6])
%             set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_combined_dcoeff, pp.fig_height_combined_dcoeff])
        else
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0, pp.fig_width_6plts_norm, pp.fig_height_4plts_norm])
%             set(gcf, 'Units', 'Inches', 'Position', [0, 0, pp.fig_width_single_tasks_dcoeff, pp.fig_height_single_tasks_dcoeff])
        end
        if save_figs 
            print(gcf,[file_prefix,'_dcoeff_spatial'],'-dpng','-r300'); 
%             saveas(gcf,[file_prefix,'_dcoeff_spatial'],'png');
        end
    end
    

end

end % close methods
end % close class def
