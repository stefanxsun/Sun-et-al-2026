function bl1Output = NS_CloseBoolean(bl1Input, in1Order)
%BL1OUTPUT = NS_CLOSEBOOLEAN(BL1INPUT, IN1ORDER) performs a morphological
%closure of order IN1ORDER (IN1ORDER dilations followed by IN1ORDER
%erosions) on the vector BL1INPUT and returns the result in BL1OUTPUT

if mod(in1Order, 1) ~= 0 && in1Order < 1
    error('The order value must be a postive integer')
end

if min(size(bl1Input)) > 1
    error('The input vector must be a one dimensional')
end

if sum(bl1Input ~= 0 & bl1Input ~= 1) > 0
    error('The input vector must be logical or consist of 0 and 1 only')
end

bl1Output = bl1Input(:);
for idx = 1:in1Order
    bl1Output = NS_DilateBoolean(bl1Output);
end
for idx = 1:in1Order
    bl1Output = NS_ErodeBoolean(bl1Output);
end