function [edges] = edge_local(binImage)

[m n] = size(binImage);
dfhor = [NaN(m,1) diff(binImage,[],2)];
dfver = [NaN(1,n);diff(binImage,[],1)];

edges = (dfhor==1 | dfhor==-1 | dfver==1 | dfver==-1);
