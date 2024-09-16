function nirsdata=NR_filter(nirsdata,FilterMethod,FilterModel,FilterOrder,hpf,lpf)

% Filter on the input images
%
%
% Input:
% filter_mathod:  1 = IIR; 2 = FIR; 3 = FFT.
% filter_type: 1 = high pass; 2 = low pass; 3 = bandpass.
% 


% 检查并处理非有限值
fields = {'oxyData', 'dxyData', 'totalData'};
for i = 1:length(fields)
    field = fields{i};
    data = nirsdata.(field);
    
    % 详细检查数据
    non_finite = ~isfinite(data);
    nan_values = isnan(data);
    inf_values = isinf(data);
    
    if any(non_finite(:)) || any(nan_values(:)) || any(inf_values(:))
        warning('在 %s 中发现问题值：\n非有限值: %d\nNaN值: %d\n无穷大值: %d', ...
            field, sum(non_finite(:)), sum(nan_values(:)), sum(inf_values(:)));
        
        % 尝试多种方法处理问题值
        % 1. 线性插值
        data = fillmissing(data, 'linear', 'EndValues', 'nearest');
        
        % 2. 如果还有问题，使用移动中位数填充
        if any(isnan(data(:)) | isinf(data(:)))
            data = fillmissing(data, 'movmedian', 5, 'EndValues', 'nearest');
        end
        
        % 3. 如果仍然存在问题，用列的中位数替换
        problem_indices = isnan(data) | isinf(data);
        for col = 1:size(data, 2)
            col_median = median(data(:,col), 'omitnan');
            data(problem_indices(:,col), col) = col_median;
        end
        
        % 最后检查
        if any(isnan(data(:)) | isinf(data(:)))
            warning('在 %s 中仍存在问题值，将使用全局中位数替换。', field);
            global_median = median(data(:), 'omitnan');
            data(isnan(data) | isinf(data)) = global_median;
        end
        
        nirsdata.(field) = data;
        disp(['已处理 ' field ' 中的问题值。']);
    end
end

% 最终检查
for i = 1:length(fields)
    field = fields{i};
    data = nirsdata.(field);
    if any(isnan(data(:)) | isinf(data(:)))
        error('无法完全处理 %s 中的问题值，请检查原始数据。', field);
    end
end

 % 原有的滤波代码

if FilterMethod == 1 % IIR
    T=nirsdata.T;
    fs=1/T;
    
    switch FilterModel
        case {1,2}
        [hb,ha]=KIT_IIR(FilterModel,fs,FilterOrder,hpf,lpf);

        nirsdata.oxyData = filtfilt(hb,ha,nirsdata.oxyData); 
        nirsdata.dxyData = filtfilt(hb,ha,nirsdata.dxyData);
        nirsdata.totalData = filtfilt(hb,ha,nirsdata.totalData); 
        
        otherwise
        % first LP filtering
        [hb,ha]=KIT_IIR(2,fs,FilterOrder,'',lpf);

        nirsdata.oxyData = filtfilt(hb,ha,nirsdata.oxyData); 
        nirsdata.dxyData = filtfilt(hb,ha,nirsdata.dxyData);
        nirsdata.totalData = filtfilt(hb,ha,nirsdata.totalData); 
        
        % then HP filtering
        [hb,ha]=KIT_IIR(1,fs,FilterOrder,hpf,'');

        nirsdata.oxyData = filtfilt(hb,ha,nirsdata.oxyData); 
        nirsdata.dxyData = filtfilt(hb,ha,nirsdata.dxyData);
        nirsdata.totalData = filtfilt(hb,ha,nirsdata.totalData);
        
    end 
    
elseif FilterMethod == 2 % FIR
    window = 4; %  hamming window
    T=nirsdata.T;
    fs=1/T;
    
    switch FilterModel
        case {1,2}
        [hb]=KIT_FIR(FilterModel,fs,FilterOrder,hpf,lpf,window);

        nirsdata.oxyData = filtfilt(hb,1,nirsdata.oxyData);
        nirsdata.dxyData = filtfilt(hb,1,nirsdata.dxyData);
        nirsdata.totalData = filtfilt(hb,1,nirsdata.totalData);
    
        otherwise
        % first LP filtering
        [hb]=KIT_FIR(2,fs,FilterOrder,'',lpf,window);
        nirsdata.oxyData = filtfilt(hb,1,nirsdata.oxyData);
        nirsdata.dxyData = filtfilt(hb,1,nirsdata.dxyData);
        nirsdata.totalData = filtfilt(hb,1,nirsdata.totalData);
        
        % then HP filtering
        [hb]=KIT_FIR(1,fs,FilterOrder,hpf,'',window);
        nirsdata.oxyData = filtfilt(hb,1,nirsdata.oxyData);
        nirsdata.dxyData = filtfilt(hb,1,nirsdata.dxyData);
        nirsdata.totalData = filtfilt(hb,1,nirsdata.totalData);
       
    end
    
elseif FilterMethod == 3 % FFT
    
    [nirsdata, ActualBandFrequency] = KIT_FFT(nirsdata,FilterModel,hpf,lpf)
end

end
