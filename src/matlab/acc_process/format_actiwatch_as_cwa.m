function data = format_actiwatch_as_cwa(data_table, t_start, t_stop)

if ~isnumeric(data_table.time)
    data_table.time = datenum(data_table.time);
end

idx_start = find(data_table.time >= t_start, 1, 'first');
idx_stop  = find(data_table.time < t_stop,  1, 'last');

data = struct();
data.acti_counts = data_table.acti_count(idx_start:idx_stop);
data.t = data_table.time(idx_start:idx_stop);
data.t_acti = data_table.time(idx_start:idx_stop);
data.non_wear = data_table.non_wear(idx_start:idx_stop);

data.temp = 30*ones(size(data.acti_counts));
data.light = zeros(size(data.acti_counts));

end