classdef ActiveLearningMeasure < Measure
    %ACTIVELEARNINGMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();
            iterationResults = split.iterationResults;
            valTrain = [];
            valTest = [];
            preTransferValTrain = [];
            preTransferValTest = [];
            transferMeasures = [];
            preTransferMeasures = [];
            regs = [];
            bestRegs = [];
            cvAcc = [];
            divergence = zeros(length(iterationResults),1);
            for resultIdx=1:length(iterationResults)
                if resultIdx > 1 && ~isempty(split.activeMetadata)
                    m = split.activeMetadata{resultIdx-1};
                    divergence(resultIdx) = m.divergence;
                end
                r = iterationResults{resultIdx};
                if ~isempty(r)
                    [valTrain(resultIdx),valTest(resultIdx)] = ...
                        obj.computeTrainTestResults(r);
                end
                r2 = split.preTransferResults{resultIdx};
                if ~isempty(r2)
                    [preTransferValTrain(resultIdx), ...
                        preTransferValTest(resultIdx)] = ...
                        obj.computeTrainTestResults(r2);
                    regs(resultIdx) = r2.learnerMetadata.reg;
                    cvAcc(resultIdx) = r2.learnerMetadata.cvAcc;
                    bestRegs(resultIdx) = r2.modelResults(argmax([r2.modelResults.testAcc])).reg;
                end
                if ~isempty(split.transferMeasureResults)
                    transferMeasures(resultIdx) = ...
                        split.transferMeasureResults{resultIdx}.percCorrect;
                end
                if ~isempty(split.preTransferMeasureResults)
                    preTransferMeasures(resultIdx) = ...
                        split.preTransferMeasureResults{resultIdx}.percCorrect;
                end
            end
            hasTransfer = ~isempty(r);
            hasPreTransfer = ~isempty(r2);
            hasBoth = hasPreTransfer && hasTransfer;
            if hasBoth
                transferDifference = ...
                    valTest - preTransferValTest;
                measureResults.learnerStats.transferDifference = transferDifference;
            end
            measureResults.learnerStats.divergence = divergence;
            if hasPreTransfer
                measureResults.learnerStats.preTransferValTrain = preTransferValTrain;
                measureResults.learnerStats.preTransferValTest = preTransferValTest;
                measureResults.learnerStats.regs = log10(regs);
                measureResults.learnerStats.bestRegs = log10(bestRegs);
                measureResults.learnerStats.regDiffs = abs(log10(bestRegs)-log10(regs));
                measureResults.learnerStats.cvPerfDiff = abs(preTransferValTest-cvAcc);
                measureResults.learnerStats.cvPerfDelta = cvAcc-preTransferValTest;
                measureResults.learnerStats.cvAcc = cvAcc;
                
                desiredPerf = ProjectConfigs.desiredPerf;
                measureResults.learnerStats.terminatedPerf = zeros(size(desiredPerf));
                measureResults.learnerStats.numIterations = zeros(size(desiredPerf));
                measureResults.learnerStats.terminatedPerfError = zeros(size(desiredPerf));
                %{
                    for idx=1:length(desiredPerf)
                        hasDesiredPerf = cvAcc >= desiredPerf(idx);
                        minIdx = find(hasDesiredPerf,1,'first');
                        if isempty(minIdx)
                            minIdx = length(cvAcc);
                        end
                        measureResults.learnerStats.terminatedPerf(idx) = preTransferValTest(minIdx);
                        measureResults.learnerStats.numIterations(idx) = minIdx -1;
                        measureResults.learnerStats.terminatedPerfError(idx) ...
                            = abs(preTransferValTest(minIdx) - cvAcc(minIdx));
                    end
                %}
                iterationDelta = ProjectConfigs.iterationDelta;
                for idx=1:length(iterationDelta)
                    %delta = cvAcc(2:end) - cvAcc(1:end-1);
                    %meetsDelta = delta <= cvDelta(idx);
                    %minIdx = find(meetsDelta,1,'first');
                    %minIdx = findsubmat(meetsDelta, true(1,3));
                    isDec = Helpers.isDecreasing(cvAcc,iterationDelta(idx));
                    minIdx = find(isDec,1,'first');
                    if isempty(minIdx)
                        minIdx = length(cvAcc)-iterationDelta(idx);
                    else
                        minIdx = minIdx(1);
                    end
                    minIdx = minIdx + iterationDelta(idx);
                    measureResults.learnerStats.terminatedPerf(idx) = preTransferValTest(minIdx);
                    measureResults.learnerStats.numIterations(idx) = minIdx -1;
                    measureResults.learnerStats.terminatedPerfCVDelta(idx) ...
                        = preTransferValTest(minIdx);
                    measureResults.learnerStats.terminatedPerfError(idx) ...
                        = abs(preTransferValTest(minIdx) - cvAcc(minIdx));
                end
            end
            if ~isempty(preTransferMeasures)
                measureResults.learnerStats.preTransferMeasures = preTransferMeasures;
                measureResults.learnerStats.preTransferMeasurePerfDiff = ...
                    abs(preTransferMeasures - preTransferValTest);
            end
            if ~isempty(transferMeasures)
                measureResults.learnerStats.transferMeasures = transferMeasures;
                measureResults.learnerStats.transferMeasurePerfDiff = ...
                    abs(transferMeasures - valTest);
            end
            if ~isempty(transferMeasures) && ~isempty(preTransferMeasures)
                transferMeasureDifference = transferMeasures - preTransferMeasures;
                measureResults.learnerStats.transferMeasureDifference = transferMeasureDifference;
                measureResults.learnerStats.accuracyMeasureDifference =  ...
                    abs(measureResults.learnerStats.transferMeasureDifference - ...
                    transferDifference);
                measureResults.learnerStats.negativeTransferPrediction = ...
                    (transferDifference >= 0) == ...
                    (transferMeasureDifference >= 0);
                %{
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        (1 - measureResults.learnerStats.negativeTransferPrediction) .* ...
                        abs(transferDifference);
                    %}
                    a = measureResults.learnerStats.negativeTransferPrediction;
                    b = preTransferValTest;
                    c = valTest;
                    d = transferMeasureDifference > 0;
                    %{
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        (1-a) .* abs(transferDifference);
                    %}
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        d.*c + (1-d).*b;
            end
        end
    end
    
end

