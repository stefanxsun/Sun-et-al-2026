function db1ElapsedTimeSec = NS_CompareDateVector(db1DateVec_1, db1DateVec_2)
%Compares date vector. Only works if the vectors are from the same day.
%Returns a negative time if db1DateVec_1 after db1DateVec_2

%2016-09-13 QP: Created

if any(size(db1DateVec_1) ~= [1, 6]) 
    error('db1DateVec_1 is not a date vector\r')
elseif any(size(db1DateVec_2) ~= [1, 6])
    error('db1DateVec_2 is not a date vector\r')
end

in1SignDV1V2 = sign(db1DateVec_1 - db1DateVec_2);
if any(in1SignDV1V2(1:3) ~= 0)
    error('This function only works for date vectors of the same day\r')
end
    
db1Dif=db1DateVec_2(4)-db1DateVec_1(4);
db1Dif=db1DateVec_2(5)-(db1DateVec_1(5)-(db1Dif*60));
db1ElapsedTimeSec=(db1DateVec_2(6)-(db1DateVec_1(6)-(db1Dif*60)));