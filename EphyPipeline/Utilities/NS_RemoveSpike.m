function db1InterpTrace=NS_RemoveSpike(db1Trace, in1SpikeIndex, in1Interval, chMethod)
%DB1INTERPTRACE=RemoveSpike(DB1TRACE, IN1SPIKEINDEX, IN1INTERVAL, [CHMETHOD]) removes
%the points situated in the interval specifid by IN1INTERVAL around the
%indices specified by IN1SPIKEINDEX and replaces the removed points by a
%cubic spline interpolation. IN1INTERVAL must be specified as a two point
%vector whose first element must be negative and represent the number of
%point before the indices specified in IN1SPIKEINDEX that have to be
%removed. The second element must be positive and represent the number of
%points after the indices that have to removed. CHMETHOD (optional), is the 
%methods used for interpolation (see interp1 for details). Default is 'pchip'.
%
%2016-10-11 QP: Edited from RemoveSpike, used in Amsterdam. The script is
%               almost identical
%2022-01-03 QP: Edited so that the interpolation method can be set with the
% 				optional argument CHMETHOD; The code has also been made 
% 				a bit slicker.
%Checks arguments
narginchk(3, 4);
if ~exist(chMethod, 'var'); chMethod = 'pchip'; end

%Does some checking
if nansum(mod(in1SpikeIndex,1))~=0
    error('The values in in1SpikeIndex must be integers')
end

if numel(in1SpikeIndex)~=0
    if min(in1SpikeIndex)<1 || max(in1SpikeIndex)>length(db1Trace)
        error('The values in in1SpikeIndex exceed the traces dimension or are not appropriate for that interval')
    end
end

if numel(in1Interval)~=2
    error('in1Interval must be a two elements vector')
end

if in1Interval(1)>0 || in1Interval(2)<0
    error('The first element of in1Interval must be negative and the second must be positive');
end

%Removes spikes if they are to close from the edges of the trace
in1SpikeIndex=in1SpikeIndex(in1SpikeIndex>-in1Interval(1)+1 & in1SpikeIndex<length(db1Trace)-in1Interval(2)-1);

%Computes the values of the indices to be removed around the values of spikePeakIndexes
in1Win 		= in1Interval(1):in1Interval(2);
in1RemIndex = in1Win + in1SpikeIndex(:);

%Computes the interpolated trace
[in1TraceIndex, in1NoSpikeIndex]= deal(1:length(db1Trace));
db1Trace(in1RemIndex)=[]; in1NoSpikeIndex(in1RemIndex)=[];
db1InterpTrace=interp1(in1NoSpikeIndex,db1Trace,in1TraceIndex, chMethod); 
