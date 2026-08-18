function [XInflection, YInflection] = NS_FindInflectionPoints(trace, inflectionType)
%[XINFLECTION, YINFLECTION] = NS_FindInflectionPoints(TRACE) Finds the
%inflection points of the one dimensional vector TRACE and returns their x
%and y coordinates in the one dimensional vectors XINFLECTION and
%YINFLECTION respectively. The type of inflexion points that the function
%returns is set by the variable INFLECTIONTYPE. if the variable is set to 0,
%the function returns all inflexion points, if set to 1 the function
%returns local maxima and if set to -1 the function returns local minima.

if isempty(find([-1 0 1]==inflectionType, 1))
    error('inflectionType must be set to either -1, 0 or 1')
end

switch inflectionType
    case -1
        XInflection=find(diff(sign(diff(trace)))==2)+1;
    case 0
        XInflection=find(diff(sign(diff(trace)))~=0)+1;
    case 1
        XInflection=find(diff(sign(diff(trace)))==-2)+1;
end
YInflection=trace(XInflection);


