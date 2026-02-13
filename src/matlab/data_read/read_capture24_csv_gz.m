function content = read_capture24_csv_gz(zip_path)
% DOES NOT WORK
fileStr     = javaObject('java.io.FileInputStream', zip_path);
inflatedStr = javaObject('java.util.zip.GZIPInputStream', fileStr);
charStr     = javaObject('java.io.InputStreamReader', inflatedStr);
lines       = javaObject('java.io.BufferedReader', charStr);

numLines = 0;

allLines = [];
currentLine = 'Something';
linesMax = 10000;
linesCount = 0;
while ~isempty(currentLine) && linesCount <= linesMax
    linesCount = 1 + linesCount;
    currentLine = {split(char(lines.readLine()), ',')'};
    allLines = [allLines; currentLine];
end

content = vertcat(allLines{:});
content = cell2table(content(2:end, :), 'VariableNames', content(1, :));
content.time = datetime(content.time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
content.x = str2double(content.x);
content.y = str2double(content.y);
content.z = str2double(content.z);


end
