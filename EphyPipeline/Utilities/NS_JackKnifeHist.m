function [db1H, db1HVar] = NS_JackKnifeHist(db1Value, db1Group, db1BinEdge, blCumulative)
%Synopsis:
%	[DB1H, DB1HVAR] = NS_JackKnifeHist(DB1VALUE, DB1GROUP, DB1BINEDGE, [BLCUMULATIVE])
%Computes a histograms DB1H and a variance DB1HVAR for the values in DB1VALUE
%and the bins defined by DB1BINEDGE. Each value is assigned to a group with the
%indexing vector DB1GROUP. The variance is calculated in each bin by removing 
%the contribution with a leave one out Jack knife approach. BLCUMULATIVE (optional)
%will yield to a cumulative histogram if set to true.

%Checks the input
narginchk(3, 4);
if nargin < 4, blCumulative = false; end
if ~isvector(db1Value) | ~isvector(db1Group)
	error('db1Values and db1Group must be vectors of the same length');
elseif length(db1Value) ~= length(db1Group)
	error('db1Values and db1Group must be vectors of the same length');
end
if ~isvector(db1BinEdge), error('db1BindEdge must be a vector'); end
if ~islogical(blCumulative) | ~isscalar(blCumulative); 
	disp('blCumulative must be a single boolean value. Set to false'); 
	blCumulative = false; 
end

%Gets the number of groups
db1U_Group 	= unique(db1Group);
inNGp 		= length(db1U_Group);

%Computes histogram
db1H		 = DoHist(db1Value, db1BinEdge, blCumulative);

%Computes histogram variance
if inNGp == 1
	%If there is only one group returns a zero variance
	db1HVar	 = zeros(size(db1H));
else
	%Else computes the histogram while removing each group
	db2H_Jck = zeros(inNGp, length(db1H));
	for iGp = 1:inNGp
		bl1NoGp = db1Group ~= db1U_Group(iGp);
		db2H_Jck(iGp, :) = DoHist(db1Value(bl1NoGp), db1BinEdge, blCumulative);
	end
	%Then computes the variance with a JackKnife procedure
	db1HVar = ((inNGp - 1) / inNGp) .* sum((db2H_Jck - db1H) .^ 2);
end

function db1H = DoHist(db1Value, db1BinEdge, blCumulative)
%Utility computing the histogram

%Initializes output
inNBin 	= length(db1BinEdge) - 1;
db1H 	= nan(1, inNBin);

%Loops through bins
for iBin = 1:inNBin
	if blCumulative
		db1H(iBin) = sum(db1Value < db1BinEdge(iBin + 1)) ./ length(db1Value);
	else
		db1H(iBin) = sum(db1Value > db1BinEdge(iBin) & db1Value < db1BinEdge(iBin + 1)) ...
			./ length(db1Value);
	end
end
