function [triumask, trilmask] = create_masks_from_nodes(n_nodes)
    triumask = triu(true(n_nodes), 1);
    trilmask = tril(true(n_nodes));
end