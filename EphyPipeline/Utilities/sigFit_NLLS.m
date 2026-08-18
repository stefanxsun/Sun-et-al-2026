function [W_coef] = sigFit_NLLS(levels, responses, varargin)
% Synopsis : [W_coef] = sigFit(levels, responses, [n_trials]) Function
% fitting a sigmoidal error function of the form:
%   yhats = W_coef(1) + W_coef(2)./(1+exp(-(levels-W_coef(3))/W_coef(4)))
% to the matrix 'responses', with the integer weights 'n_trials' at the
% abscissae defined by 'levels'. The function uses the fit framework
% provided in the Curve Fitting Toolbox. The problem is solved using Non
% Linear Least Square.
% Inputs: -----------------------------------------------------------------
% -levels       : absissae for the fit; must be a row vector
% -responses    : values for the fit; must be a matrix of values with equal
% number of columns as elements in 'levels'
% -n_trials     : OPTIONAL: integers specifying the weights of the values
% in 'responses'. Must be the same size.
% Output: -----------------------------------------------------------------
% -W_Coef       : four value vector of the parameters of the fitted sigmoid
% -------------------------------------------------------------------------
% 
%
% QP: 2017-10-26

% Defines n_trials
if ~isempty(varargin)
    n_trials = varargin{1};
    if any(size(responses) ~= size(n_trials))
        error('responses and n_trials must have the same size');
    end
else
    n_trials = ones(size(responses));
end

% If responses is a matrix, produces a weighted average of the response
if ~isvector(responses)
    error('Responses must be a vector')
    %responses = nansum(responses .* n_trials)./nansum(n_trials);
    %n_trials = nansum(n_trials);
end

% % Checks that the input is properly sized
% if ~isrow(levels), levels = levels'; end
% if ~isrow(responses), responses = responses'; end
% if ~isrow(n_trials), n_trials = n_trials'; end
% if length(levels) ~= size(responses, 2)
%     error('responses must have as many columns as there is elements in levels');
% end

% Checks that the input is properly sized
if ~iscolumn(levels), levels = levels'; end
if ~iscolumn(responses), responses = responses'; end
if ~iscolumn(n_trials), n_trials = n_trials'; end
if length(levels) ~= size(responses, 1)
    error('responses must have as many columns as there is elements in levels');
end

% Removes NaN and zeros weigths
bl1Rem = isnan(responses) | n_trials == 0;
levels(bl1Rem) = [];
responses(bl1Rem) = [];
n_trials(bl1Rem) = [];

% Defines the fit and fits the data
oSIGFIT = fittype('a + b./(1 + exp(-(x - c)./d))', ...
    'coefficients', {'a', 'b',  'c', 'd'});
oFIT    = fit(levels, responses , oSIGFIT, 'Weights', n_trials, 'StartPoint', [0 1 7.5 2]);
% oFIT    = fit(levels, responses, oSIGFIT, 'Weights', n_trials);
[W_coef] = [oFIT.a oFIT.b oFIT.c oFIT.d];