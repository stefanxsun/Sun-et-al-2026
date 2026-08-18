%% Delete session script (goes to each analysis and deletes the sessions)
clear
cd 'D:\Quentin\Analyses\VisExpHighAll';

%Lists of the sessions to remove
cSESSIONS = {
    '2017-09-11_12-27-03_2', ...
    };

%Lists the analysis folder in the home directory
sDIR_ANALYSIS = dir();
bl1IsAnalysis = ~cellfun(@isempty, strfind({sDIR_ANALYSIS(:).name}, 'VEHA_L')) & [sDIR_ANALYSIS(:).isdir];
sDIR_ANALYSIS = sDIR_ANALYSIS(bl1IsAnalysis);

%Loops through analysis folder and deletes the folder fo the corresponding
%analysis
for iDir = 1:length(sDIR_ANALYSIS)
    fprintf('%s :\r', sDIR_ANALYSIS(iDir).name)
    inNDelSes = 0;
    sDIR_SES = dir(sDIR_ANALYSIS(iDir).name);
    for iSes = 1:length(sDIR_SES)
        if sDIR_SES(iSes).isdir & ismember(sDIR_SES(iSes).name, cSESSIONS)
            blSuccess = rmdir(fullfile(sDIR_ANALYSIS(iDir).name, sDIR_SES(iSes).name), 's');
            if blSuccess fprintf('\t %s: \tremoved\r', sDIR_SES(iSes).name)
            else fprintf('\t %s: \tnon removed\r', sDIR_SES(iSes).name); end    
        end
    end
end