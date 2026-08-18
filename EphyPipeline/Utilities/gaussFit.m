function [W_coef] = gaussFit(levels, responses, varargin)
% Synopsis : [W_coef] = sigFit(levels, responses, [n_trials]) Function
% fitting a gaussian function of the form:
%   yhats = (W_coef(1)/(W_coef(2)*sqrt(2*pi))) * exp(-(1/2) * (((levels - W_coef(3))/W_coef(2)).^2))
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
% This piece of code is adapted from a some fitting code written by Martin
% Vinck as a local function within the processing of the Peta project.
% Everything here is essentially the same exept for some checks for proper
% input format and the nature of the function being fitted.
%
% QP: 2017-11-08

% Defines n_trials
if ~isempty(varargin)
    n_trials = varargin{1};
else
    n_trials = ones(size(responses));
end

% Checks that the input is properly sized
if ~isrow(levels), levels = levels'; end
if length(levels) ~= size(responses, 2);
    error('responses must have as many columns as there is elements in levels');
elseif any(size(responses) ~= size(n_trials))
    error('responses and n_trials must have the same size');
end

% If responses is a matrix, produces a weighted average of the response
if ~isvector(responses)
    responses = nansum(responses .* n_trials)./nansum(n_trials);
    n_trials = nansum(n_trials);
end

% sets the space of parameter used for initial guesses
[xx,yy,zz] = ndgrid((0.9:0.05:1.1) * nanmax(nanmean(responses, 1)), ...
    (0.9:0.05:1.1) * nanmean(responses(:)), ...
    (0.9:0.05:1.1) * nanstd(responses(:))); %Grid spanning the space of each parameter for the fit
xx = xx(:); yy = yy(:); zz = zz(:); %Linearizes parameter value
n = size(xx,1); %Size of the grid
idx = 1:5:n; % Indices of the initial guess used for fits

% initialize loop variables
W_coeff_all = nan(length(idx), 3); % matrix storing the coefficient for each fit
err = nan(length(idx), 1); % vector storing the error
cnt = 0; % counting variable

% sets parameters structure for fminsearch
op.Display = 'off';
op.MaxIter = 1000;

% loops
for k = idx
    cnt = cnt + 1;
    W_coef = fminsearch(@sigError,[xx(k) yy(k) zz(k)], op); %2nd argument is the initialization
    yhats = (W_coef(1)/(W_coef(2)*sqrt(2*pi))) * exp(-(1/2) * (((levels - W_coef(3))/W_coef(2)).^2));
    err(cnt) = var(responses(:) - yhats(:));
    W_coeff_all(cnt,:) = W_coef;
end

% finds the best fit
[~,mn] = nanmin(err);
W_coef = W_coeff_all(mn,:);

function err = sigError(W_coef)
% subfunction computing the error of a sigmoid fit of the observed
% responses for the contrasts set in the global levels.

y = (W_coef(1)/(W_coef(2)*sqrt(2*pi))) * exp(-(1/2) * (((levels - W_coef(3))/W_coef(2)).^2));
err = sum(((y(:)-responses(:)).*n_trials(:)).^2); %errors weighted by the number of trials
end
end