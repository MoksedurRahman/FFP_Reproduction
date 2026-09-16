function K = cubicKernel(X1, X2)
% cubicKernel
%
% Third-degree polynomial kernel.
%
% K(i,j) = (X1(i,:) * X2(j,:)' + 1)^3
%
% INPUT
%   X1 : N1 x D
%   X2 : N2 x D
%
% OUTPUT
%   K  : N1 x N2 kernel matrix

    X1 = double(X1);
    X2 = double(X2);

    K = (X1 * X2' + 1).^3;

end