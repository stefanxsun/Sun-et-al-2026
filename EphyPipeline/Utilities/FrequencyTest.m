function [db1_PVal] = FrequencyTest(bl2_A, bl2_B)
%Synopsis: DB1_PVAL = FrequencyTest(BL2_A, BL2_B) 
%Returns the statistical difference in the occurence of boolean variables
%in matrices BL2_A and BL2_B. BL2_A and BL2_B must be organized
%(observation x variables)

db1P = mean([bl2_A; bl2_B]);
db1Q = 1 - db1P;
inNA = size(bl2_A, 1);
inNB = size(bl2_B, 1);
db1_Eps     = abs(mean(bl2_A) - mean(bl2_B)) ./ sqrt(((db1P .* db1Q)/ inNA) + ((db1P .* db1Q)/ inNB));
db1_PVal    = 2 * (1 - normcdf(db1_Eps));