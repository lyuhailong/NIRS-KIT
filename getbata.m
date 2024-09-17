% MATLAB 脚本：提取所有 .mat 文件中的 indexdata.index 数据并保存到 .csv 文件

% 初始化两个空的单元数组
fileDataNames = {};      % 用于存储文件名
indexDataCells = {};     % 用于存储 indexdata.index 数据

% 获取当前目录的完整路径
currentDir = pwd;

% 使用 dir 函数递归查找所有子文件夹中的 .mat 文件
% '**' 表示递归搜索，'*.mat' 表示匹配所有 .mat 文件
matFiles = dir(fullfile(currentDir, '**', '*.mat'));

% 检查是否找到任何 .mat 文件
if isempty(matFiles)
    disp('当前目录及其子目录中未找到任何 .mat 文件。');
    return;
end

% 初始化一个计数器，用于记录成功提取的数据量
successCount = 0;

% 遍历每个找到的 .mat 文件
for k = 1:length(matFiles)
    % 获取当前 .mat 文件的完整路径
    filePath = fullfile(matFiles(k).folder, matFiles(k).name);
    
    % 显示正在处理的文件
    fprintf('正在处理文件: %s\n', filePath);
    
    % 尝试加载 .mat 文件中的 'indexdata' 变量
    try
        data = load(filePath, 'indexdata');
        
        % 检查 'indexdata' 变量是否存在
        if isfield(data, 'indexdata')
            % 检查 'indexdata' 是否具有 'index' 字段
            if isfield(data.indexdata, 'index')
                indexValue = data.indexdata.index;
                
                % 检查 'index' 是否为行向量
                if isrow(indexValue)
                    % 增加成功计数
                    successCount = successCount + 1;
                    
                    % 将提取的数据存储到单元数组中
                    indexDataCells{successCount, 1} = indexValue;
                    
                    % 同时记录对应的文件名
                    fileDataNames{successCount, 1} = matFiles(k).name;
                    
                    % 显示成功提取的信息
                    fprintf('成功提取文件: %s，数据长度: %d\n', matFiles(k).name, length(indexValue));
                else
                    warning('文件 %s 中的 indexdata.index 不是一个行向量。', filePath);
                end
            else
                warning('文件 %s 中不存在 indexdata.index 字段。', filePath);
            end
        else
            warning('文件 %s 中不存在 indexdata 变量。', filePath);
        end
    catch ME
        % 捕获并显示任何加载文件时的错误
        warning('无法加载文件 %s: %s', filePath, ME.message);
    end
end

% 检查是否成功提取了任何数据
if successCount == 0
    disp('未从任何 .mat 文件中提取到 indexdata.index 数据。');
    return;
end

% 找到所有行向量中的最大列数
maxCols = max(cellfun(@length, indexDataCells));

% 打印最大列数
fprintf('最大数据长度: %d\n', maxCols);

% 初始化一个单元数组，用于存储文件名和数据
% 第一行作为表头
combinedCell = cell(successCount + 1, maxCols + 1);
combinedCell{1,1} = 'FileName';
for c = 1:maxCols
    combinedCell{1, c+1} = sprintf('Var%d', c);
end

% 填充数据行，逐个单元格赋值
for i = 1:successCount
    combinedCell{i +1, 1} = fileDataNames{i};
    currentData = indexDataCells{i};
    for j = 1:length(currentData)
        combinedCell{i +1, 1 + j} = currentData(j);
    end
    if length(currentData) < maxCols
        % 填充剩余的单元格为 NaN
        for j = length(currentData) +1 : maxCols
            combinedCell{i +1, 1 + j} = NaN;
        end
    end
end

% 指定保存的 CSV 文件名
outputCSVFile = 'extracted_indexdata.csv';

% 写入 CSV 文件
try
    writecell(combinedCell, outputCSVFile);
    fprintf('成功将提取的数据保存到文件: %s\n', outputCSVFile);
catch ME
    warning('无法将数据写入 CSV 文件: %s', ME.message);
end

% （可选）显示部分提取的数据
disp('已提取的部分 indexdata.index 数据:');
disp(combinedCell(1:min(6, end), :));  % 显示表头和前5行数据