function dbXCoherence = NS_Coherence(cp2Coeff1, cpXCoeff2)
%SYNOPSIS:
%   DBXCOHERENCE = NS_Coherence(CP2COEFF1, CPXCOEFF2)
%Calculate the coherence between the complexed valued spectro-temporal
%representations CP2COEFF1 and CP2COEFF2.
%INPUT:
%-CP2COEFF1 : formated as (Freq x Time)
%-CP2COEFF2 : formated as (Freq x Time x Channel)
%OUTPUT:
%-DBXCOHERCE: formated as (Freq x Channel)


dbXCNum         = abs(nansum(cp2Coeff1 .* conj(cpXCoeff2), 2)) .^ 2;
dbXCDenom       = nansum(abs(cp2Coeff1) .^ 2, 2) .* nansum(abs(cpXCoeff2) .^ 2, 2);
dbXCoherence    = dbXCNum ./ dbXCDenom;
dbXCoherence    = dbXCoherence - ((1 - dbXCoherence) ./ sum(~isnan(cp2Coeff1 .* conj(cpXCoeff2)), 2)); %Debiased coherence
dbXCoherence    = abs(squeeze(dbXCoherence)); %Abs avoids negative values due to rounding errors
