function db2ImSobel = LIP_SobelTransform(db2Im)

hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(db2Im), hy, 'replicate');
Ix = imfilter(double(db2Im), hx, 'replicate');
db2ImSobel = sqrt(Ix.^2 + Iy.^2);
% figure, imshow(db2ImSobel,[]), title('Gradient magnitude (gradmag)')