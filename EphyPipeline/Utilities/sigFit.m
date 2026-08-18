function [W_coef] = sigFit(levels, responses, varargin)
% Synopsis : [W_coef] = sigFit(levels, responses, [n_trials]) Function
% fitting a sigmoidal error function of the form:
%   yhats = W_coef(1) + W_coef(2)./(1+exp(-(levels-W_coef(3))/W_coef(4)))
% to the matrix 'responses', with the integer weights 'n_trials' at the
% abscissae defined by 'levels'. The algorithm minimizes the error using
% fminsearch and uses multiple initializations to avoid finding a local
% optimum.
% Inputs: -----------------------------------------------------------------
% -levels       : absissae for the fit; must be a row vector
% -responses    : values for the fit; must be a matrix of values with equal
% number of columns as elements in 'levels'
% -n_trials     : OPTIONAL: integers specifying the weights of the values
% in 'responses'. Must be the same size.
% Output: -----------------------------------------------------------------
% -W_Coef       : four value vector of the parameters of the fitted sigmoid
% -------------------------------------------------------------------------
% This piece of code was initially written by Martin Vinck as a local
% function within the processing of the Peta project. Everything here is
% essentially the same exept for some checks for proper input format. 
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

% sets the space of parameter used for initial guesses
[xx,yy,zz,ww] = ndgrid(0:0.25:1, 0:0.25:1, linspace(0,15,4), 0:1:4); %Grid spanning the space of each parameter for the fit
xx = xx(:); yy = yy(:); zz = zz(:); ww = ww(:); %Linearizes parameter value
n = size(xx,1); %Size of the grid
idx = 1:10:n; % Indices of the initial guess used for fits

% initialize loop variables
W_coeff_all = nan(length(idx), 4); % matrix storing the coefficient for each fit
err = nan(length(idx), 1); % vector storing the error
cnt = 0; % counting variable

% sets parameters structure for fminsearch
op.Display = 'off';
op.MaxIter = 1000;

% loops
for k = idx
    cnt = cnt + 1;
    W_coef = fminsearch(@sigError,[xx(k) yy(k) zz(k) ww(k)], op); %2nd argument is the initialization
    yhats = W_coef(1) + W_coef(2)./(1+exp(-(levels-W_coef(3))/W_coef(4)));
    err(cnt) = var(responses(:) - yhats(:));
    W_coeff_all(cnt,:) = W_coef;
end

% finds the best fit
[~,mn] = nanmin(err);
W_coef = W_coeff_all(mn,:);

function err = sigError(W_coef)
% subfunction computing the error of a sigmoid fit of the observed
% responses for the contrasts set in the global levels.

y = W_coef(1) + W_coef(2)./(1+exp(-(levels-W_coef(3))/W_coef(4)));
err = sum(((y(:)-responses(:)).*n_trials(:)).^2); %errors weighted by the number of trials
end
end