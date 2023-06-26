function [K] = load_or_calculate_kernel_for_backprojection_rec(deviceId)
path_K = which('bp_kernel_L11-5v.mat');
if exist(path_K, 'file')
    load(which('bp_kernel_L11-5v.mat'), 'K');
else
    fprintf('Kernel for backprojection reconstruction is being calculated...');
    probe = Probe(deviceId, true, false);
    K = bp_kernel((1:2554) ./ probe.DAC.frequency);
    save('bp_kernel_L11-5v.mat', 'K');
end
end

