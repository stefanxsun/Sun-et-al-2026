function [db1Power] = NS_SineMultiTaperPSD(db1Trace, inSampleRate, inNTaper)
%Synopsis:
%   DB1POWER = NS_SineMultiTaperPSD(DB1TRACE, INNTAPER)
%Performs multitaper estimation of the power spectral density of the trace
%DB1TRACE using INNTAPER sine tapers as described in [1].
%
%[1] Riedel and Sidorenko, RXiv, 2018
%
%IMPORTANT PRACTICAL NOTE:
%The number of taper necessary to obtain a fixed degree a smoothing varies
%according to the trace length and sampling rate. Thus it can be desirable 
%to fix the bandwith of the smoothing and to set the number of tapers using:
%
%	NTapers = round(2 * NW - 1)
%where 	
% 	NW 	= Bandwidth_Hz * 2 * pi * NSample / SampleRate_Hz
%
%A bandwidth of .8Hz gives good results for mouse cortical LFP recordings.

%Handles input
narginchk(2, 3)
if nargin < 3, inNTaper = 7; end

%Checks input
if ~isvector(db1Trace), error('db1Trace must be a vector'); end
if numel(inSampleRate) ~= 1 | any(inSampleRate < 1)
    error('inSampleRate must a positive number'), end
if numel(inNTaper) ~= 1 | any(inNTaper < 1) | any(mod(inNTaper, 1) ~= 0)
    error('inNTaper must a positive integer'), end
if isrow(db1Trace), db1Trace = db1Trace'; end

%Gets the number of samples
inNSmp  = length(db1Trace);

%Computes sine tapers
db1N        = (1:inNSmp)';
db1K        = 1:inNTaper;
db2Taper    = sqrt(2 ./ inNSmp) .* sin(pi .* db1N .* db1K ./ inNSmp);

%Computes the power
db1Weight   = (1 - ((db1K - 1)/inNTaper).^2) ./ sum(1 - ((db1K - 1)/inNTaper).^2);
in1SelIdx   = 1:inNSmp/2+1;
db2FFT      = fft(db2Taper .* db1Trace, [], 1);
db1Power    = 2 * sum(abs(db2FFT(in1SelIdx,:)).^2 .* db1Weight, 2) ./ (inSampleRate .* inNSmp);
