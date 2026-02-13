function data = format_csv_as_cwa(data_table, t_start, t_stop)

if ~isnumeric(data_table.time)
    data_table.time = datenum(data_table.time);
end

idx_start = find(data_table.time >= t_start, 1, 'first');
idx_stop  = find(data_table.time <= t_stop,  1, 'last');

data = struct();
data.AXES = [data_table.time(idx_start:idx_stop), ...
             data_table.x(idx_start:idx_stop), ...
             data_table.y(idx_start:idx_stop), ...
             data_table.z(idx_start:idx_stop)];
         
t_temp_light = (data_table.time(idx_start):(1/(24*60*60)):data_table.time(idx_stop))';
data.TEMP = [t_temp_light, 30*ones(size(t_temp_light))];
data.LIGHT = [t_temp_light, zeros(size(t_temp_light))];

end