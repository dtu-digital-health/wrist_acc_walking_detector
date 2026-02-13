function acc_c = calibrate_acc(C0, fs)
% ICP - minimize difference between a unit sphere and sqrt(x^2+y^2+z^2)
% with x = gx*x0 + dx, ...

epoch_size = 10*fs;
M = floor(length(C0)/epoch_size)*epoch_size;
avg_acc = arrayfun(@(x) mean(reshape(C0(1:M,x),epoch_size,[])',2), 1:3, 'Un', 0);
avg_acc = [avg_acc{:}];
std_acc = arrayfun(@(x) std(reshape(C0(1:M,x),epoch_size,[])',0,2), 1:3, 'Un', 0);
std_acc = [std_acc{:}];
epoch_retain = all(std_acc < 0.013,2);
avg_acc = avg_acc(epoch_retain,:);
C1 = avg_acc;

d = zeros(1,size(C0,2));
g = ones(1,size(C0,2));
d_inc = zeros(1,size(C0,2));
g_inc = ones(1,size(C0,2));
weights = ones(size(avg_acc,1),1);
res = Inf;
maxiter = 1000;
tol = 1e-10;

for iter = 1:maxiter
    
    % Update EN
    EN = sqrt(sum(C1.^2,2));
    
    % Closest point
    cp = avg_acc ./ repmat(EN,1,size(avg_acc,2));
    
    % Update g, d
    for k = 1:3
        mdl = fitlm(avg_acc(:,k), cp(:,k),'Weights',weights);
        d_inc(k) = mdl.Coefficients.Estimate(1);
        g_inc(k) = mdl.Coefficients.Estimate(2);
        %C1 = mdl.Fitted;
    end
    d = d + d_inc ./ (g .* g_inc);
    g = g .* g_inc;

    % Update C1
    C1 = repmat(g, size(avg_acc, 1), 1) .* avg_acc + repmat(d, size(avg_acc, 1), 1);
    EN = sqrt(sum(C1.^2,2));
    
    
    % Error
    res_old = res;
    res = 3*mean(weights .* (1 - EN).^2)/sum(weights);
    if abs(res - res_old) < tol
        break;
    end
    
    % Weights
    weights = min(1./abs(1 - EN), 100);
end

acc_c = repmat(g, size(C0, 1), 1) .* C0 + repmat(d, size(C0, 1), 1);

end