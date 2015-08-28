function [d] = makeSingleNodeGraph(d)
assert(d.Wdim == 1);
W12 = d.W{1};
W11 = zeros(size(W12,1));
W22 = zeros(size(W12,2));
W = [ W11 W12 ; W12' W22];
[size1,size2] = size(W12);

d.W = W;

d.WIDs{1} = [d.WIDs{1} ; d.WIDs{2}];
d.WIDs{2} = d.WIDs{1};

d.WNames{1} = [d.WNames{1} ; d.WNames{2}];
d.WNames{2} = d.WNames{1};

d.objectType = zeros(size(W,1),1);
d.objectType(1:size1) = Constants.STEP_CORRECT;
d.objectType(size1+1:end) = Constants.STUDENT;

%Making the min class 1 fixes issues in other parts of the code
I = ~isnan(d.Y);
d.Y(I) = d.Y(I) - min(d.Y(I)) + 1;

d.Y = [d.Y ; nan(size2,1)];
d.type = [d.type ; DataSet.TargetTestType(size2)];
d.trueY = [d.trueY ; nan(size2,1)];
d.instanceIDs = [d.instanceIDs ; nan(size2,1)];           
d.labelSets = (1:d.numClasses)';
d.instancesToInfer = false(size(W,1),1);
d.instancesToInfer(size(W11,1)+1:end) = true;
end