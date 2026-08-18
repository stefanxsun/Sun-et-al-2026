function [db2_PVal] = AssociationTest(bl2_Mat)
%Synopsis: DB2_PVAL = FrequencyTest(BL2_MAT) 
%Returns the significance of the association in the occurence of boolean
%variables in the matrix BL2_MAT organized (observation x variables)

inNPar  = size(bl2_Mat, 2); 
db2_Eps = nan(inNPar); 
for iPar = 1:inNPar
%     try
        bl2_A = bl2_Mat(bl2_Mat(:, iPar) == 1, :);
        bl2_B = bl2_Mat(bl2_Mat(:, iPar) == 0, :);
        db1P = mean([bl2_A; bl2_B]);
        db1Q = 1 - db1P;
        inNA = size(bl2_A, 1);
        inNB = size(bl2_B, 1);
        db2_Eps(iPar, :) = abs(mean(bl2_A) - mean(bl2_B)) ./ sqrt(((db1P .* db1Q)/ inNA) + ((db1P .* db1Q)/ inNB));
%     end
end
db2_PVal    = 2 * (1 - normcdf(db2_Eps));