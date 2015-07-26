function [d] = combineGraphs(d)
    assert(d.Wdim == 1);
    W12 = Helpers.combineW(d.W{1},d.W{2},d.Wdim){1};
    W11 = zeros(size(W12,1));
    W22 = zeros(size(W12,2));
    W = [ W11 W12 ; W12' W22];
    [size1,size2] = size(W12);
    
    d.W = W;
    d.WIDs{1} = [d.WIDs{1} ; d.WIDs{1} ; d.WIDs{2}];
    d.WIDs{2} = d.WIDs{1};
    
    appendWrong = @(s) ([s '-wrong']);
    neg = cellfun(appendWrong,d.WNames{1},'UniformOutput',false);    
    d.WNames{1} = [d.WNames{1} ; neg ; d.WNames{2}];
    d.WNames{2} = d.WNames{1};
    
    
    negYNames = cellfun(appendWrong,d.YNames,'UniformOutput',false);
    d.YNames = [d.YNames ; negYNames];
    
    d.objectType = zeros(size(W,1),1);
    d.objectType(1:size1/2) = Constants.STEP_CORRECT;
    d.objectType(size1/2+1:size1) = Constants.STEP_INCORRECT;
    d.objectType(size1+1:end) = Constants.STUDENT;
    
    Y1 = d.Y;
    Y2 = d.Y;
    numClasses = d.numClasses;
    Y2(Y2 > 0) = Y2(Y2 > 0) + numClasses;
    Y = [Y1 ; Y2 ; -1*ones(size2,1)];
    d.type = [d.type ; d.type ; DataSet.TargetTestType(size2)];
    d.trueY = [d.trueY ; d.trueY + numClasses ; -1*ones(size2,1)];
    d.Y = Y;
    d.instanceIDs = [d.instanceIDs ; d.instanceIDs ; -1*ones(size2,1)];           
    d.labelSets = [(1:numClasses)' ; (1:numClasses)'];
end