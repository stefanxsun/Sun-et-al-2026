%%%%%%Stefan 08/07/2023 
%%%%%%Use to fix the jitter in TimeStamps by Neuralynx, but limited to when
%%%%%%it's two consecutive and correlated abnormality, and can only fix one

function [TStamps] = NS_TStampSanityCheck(TStamps)
D = diff(TStamps);
Sanitycheck = abs(D-mean(D))>0.1*mean(D);

if sum(Sanitycheck)>0 
    disp('There are consecutive weird TimeStamps, check if they can be fixed together, if yes press space');    
    AbnormalIndex = find(abs(D-mean(D))>0.1*D);
    for i=1:length(AbnormalIndex)
        D(AbnormalIndex(i)-2:AbnormalIndex(i)+2) %show around the weird TimeStamps Diff
    end
    
    waitforbuttonpress; % it means manually checked that it fits the situation this code can solve
    
    TStamps(AbnormalIndex(1)+1) = TStamps(AbnormalIndex(1)) + (D(AbnormalIndex(1))+D(AbnormalIndex(2)))/2;
    TStamps(AbnormalIndex(2)+1) = TStamps(AbnormalIndex(2)) + (D(AbnormalIndex(1))+D(AbnormalIndex(2)))/2;
    
    D = diff(TStamps);
    for i=1:length(AbnormalIndex)
        D(AbnormalIndex(i)-2:AbnormalIndex(i)+2) %show around the corrected TimeStamps Diff
    end
    waitforbuttonpress; %confirm the corrected TimeStamps
    disp('Resuming...');
end
end


