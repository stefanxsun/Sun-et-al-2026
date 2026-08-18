function db1DateVector = NS_NlxTStamp2DateVector(db1RefDateVector, db1RefTStamp, db1TStamp)
%This function estimates the absolute time vector of a Neuralynx TimeStamp
%(expressed in microseconds) using a reference vector and a reference time
%stamps. Though neuralynx time stamps are initialized at the opoening of
%the cheetah software, they only become linearly aligned with absolute time
%at the start of recording. Thus the reference point should be the first
%time that recording is started. The time and time stamp of this event have
%to be extracted from the Nueralynx log file.

%2016-09-13 QP: Created

dbTSTampSec = (db1TStamp - db1RefTStamp)/1000000;

db1DateVector = nan(1, 6);
db1DateVector(6) = mod(dbTSTampSec + db1RefDateVector(6), 60);
db1Rem = floor((dbTSTampSec + db1RefDateVector(6))/60);

db1DateVector(5) = mod(db1Rem + db1RefDateVector(5), 60);
db1Rem = floor((db1Rem + db1RefDateVector(5))/60);
db1DateVector(4) = mod(db1Rem + db1RefDateVector(4), 24);
db1Rem = floor((db1Rem + db1RefDateVector(4))/24);
switch db1RefDateVector(2)
    case {1, 3, 5, 7, 8, 10, 12}
        db1DateVector(3) = 1 + mod(db1Rem + db1RefDateVector(3) - 1, 31);
        db1Rem = floor((db1Rem + db1RefDateVector(3) - 1)/31);
    case {4, 6, 9, 11}
        db1DateVector(3) = 1 + mod(db1Rem + db1RefDateVector(3) - 1, 30);
        db1Rem = floor((db1Rem + db1RefDateVector(3) - 1)/30);
    case {2}
        if mod(db1RefDateVector(1),4) == 0
            db1DateVector(3) = 1 + mod(db1Rem + db1RefDateVector(3) - 1, 29);
            db1Rem = floor((db1Rem + db1RefDateVector(3) - 1)/29);
        else
            db1DateVector(3) = 1 + mod(db1Rem + db1RefDateVector(3) - 1, 28);
            db1Rem = floor((db1Rem + db1RefDateVector(3) - 1)/28);
        end
end
db1DateVector(2) = 1 + mod(db1Rem + db1RefDateVector(2) - 1, 12);
db1Rem = floor((db1Rem + db1RefDateVector(2) - 1)/12);
db1DateVector(1) = db1Rem + db1RefDateVector(1);