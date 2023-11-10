function result = simpson(x, y, dim)
%     Integrate y(x) using samples along the given axis and the composite
%     Simpson's rule. If x is None, spacing of dx is assumed.
%     If there are an even number of samples, N, then there are an odd
%     number of intervals (N-1), but Simpson's rule requires an even number
%     of intervals. The parameter 'even' controls how this is handled.
%     Parameters
%     ----------
%     y : array_like
%         Array to be integrated.
%     x : array_like, optional
%         If given, the points at which `y` is sampled.
%     dx : float, optional
%         Spacing of integration points along axis of `x`. Only used when
%         `x` is None. Default is 1.
%     axis : int, optional
%         Axis along which to integrate. Default is the last axis.
%     even : str {'avg', 'first', 'last'}, optional
%         'avg' : Average two results:1) use the first N-2 intervals with
%                   a trapezoidal rule on the last interval and 2) use the last
%                   N-2 intervals with a trapezoidal rule on the first interval.
%         'first' : Use Simpson's rule for the first N-2 intervals with
%                 a trapezoidal rule on the last interval.
%         'last' : Use Simpson's rule for the last N-2 intervals with a
%                trapezoidal rule on the first interval.
%     Returns
%     -------
%     float
%         The estimated integral computed with the composite Simpson's rule.
%     See Also
%     --------
%     quad : adaptive quadrature using QUADPACK
%     romberg : adaptive Romberg quadrature
%     quadrature : adaptive Gaussian quadrature
%     fixed_quad : fixed-order Gaussian quadrature
%     dblquad : double integrals
%     tplquad : triple integrals
%     romb : integrators for sampled data
%     cumulative_trapezoid : cumulative integration for sampled data
%     ode : ODE integrators
%     odeint : ODE integrators
%     Notes
%     -----
%     For an odd number of samples that are equally spaced the result is
%     exact if the function is a polynomial of order 3 or less. If
%     the samples are not equally spaced, then the result is exact only
%     if the function is a polynomial of order 2 or less.
%     Examples
%     --------
%     >>> from scipy import integrate
%     >>> import numpy as np
%     >>> x = np.arange(0, 10)
%     >>> y = np.arange(0, 10)
%     >>> integrate.simpson(y, x)
%     40.5
%     >>> y = np.power(x, 3)
%     >>> integrate.simpson(y, x)
%     1642.5
%     >>> integrate.quad(lambda x: x**3, 0, 9)[0]
%     1640.25
%     >>> integrate.simpson(y, x, even='first')
%     1644.5
perm = []; nshifts = 0;dim = 1;
if nargin == 3 % simpson(x,y,dim)
  if ~isscalar(dim) || ~isnumeric(dim) || (dim ~= floor(dim))
      error(message('MATLAB:getdimarg:dimensionMustBePositiveInteger'));
  end
  dim = min(ndims(y)+1, dim);
  perm = [dim:max(ndims(y),dim) 1:dim-1];
  y = permute(y,perm);
  m = size(y,1);
elseif nargin == 2 && isscalar(y) % trapz(y,dim)
  dim = y;
  y = x;
  x = 1;
  if ~isscalar(dim) || ~isnumeric(dim) || (dim ~= floor(dim))
      error(message('MATLAB:getdimarg:dimensionMustBePositiveInteger'));
  end
  dim = min(ndims(y)+1, dim);
  perm = [dim:max(ndims(y),dim) 1:dim-1];
  y = permute(y,perm);
  m = size(y,1);
else % trapz(y) or trapz(x,y)
  if nargin < 2
      y = x;
      x = 1;
  end
  [y,~] = shiftdim(y);
  m = size(y,1);
end
if ~isvector(x)
  error(message('MATLAB:trapz:xNotVector'));
end
x = x(:);
if ~isscalar(x) && length(x) ~= m
    error(message('MATLAB:trapz:LengthXmismatchY'));
end
N = m;
if mod(N,2) == 0
    val = zeros(1,size(y,2));
    result = zeros(1,size(y,2));
% Compute using Simpson's rule on first intervals
    val = val + 0.5*x*(y(end,:)+y(end-1,:));
    result = result + basic_simpson(y, 1, N-2, x, dim);
% Compute using Simpson's rule on last set of intervals
    val = val + 0.5*x*(y(1,:)+y(2,:));
    result = result + basic_simpson(y, 2, N-1, x, dim);
    val = val / 2.0;
    result = result / 2.0;
    result = result + val;
    
else
    result = basic_simpson(y, 1, N-1, x, dim);
end


function result = basic_simpson(y, start, stop, dx, dim)
step = 2;
result = sum(y(start:step:stop-1,:) + 4.0*y(start+1:step:stop,:) + y(start+2:step:stop+1,:), dim);
result = result * dx / 3.0;
