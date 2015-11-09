classdef LayeredHypothesisTransfer < LLGCHypothesisTransfer
    %LAYEREDHYPOTHESISTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        finalHyp
    end
    
    methods
        function obj = LayeredHypothesisTransfer(configs)
            obj = obj@LLGCHypothesisTransfer(configs);
            obj.finalHyp = LiblinearMethod(configs);
            obj.set('classification',1);
        end
        %Doing this caused LLGCHypothesisTransfer::train to be called
        %instead.
        %{
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            if ~exist('savedData','var')
                savedData = struct();
            end
            [testResults,savedData] = trainAndTest@LLGCHypothesisTransfer(obj,input,savedData);
            testResults.learnerStats.finalHyp = obj.finalHyp.model;
        end
        %}
        function [] = train(obj,X,Y)      
            isLabeled = ~isnan(Y);
            [Ftarget,fuCombined,labelIDs] = obj.createTransferFeaturesLOO(X,Y);   
            Ftarget = Ftarget(:,1);
            fuCombined = fuCombined(:,labelIDs == 2);
            XT = [Ftarget fuCombined];
            %XT = XT - .5;
            input = struct();
            train = DataSet();
            train.X = XT;
            train.Y = Y(isLabeled);            
            train.trueY = Y(isLabeled);
            train.setTargetTrain();
            input.train = train;
            input.test = [];
            obj.finalHyp.trainAndTest(input);
        end
        
        function [y,fu] = predict(obj,X)
            [Ftarget,fuCombined,labelIDs] = obj.createTransferFeatures(X);   
            Ftarget = Ftarget(:,1);
            fuCombined = fuCombined(:,labelIDs == 2);
            XT = [Ftarget fuCombined];
            %XT = XT - .5;     
            [y,fu] = obj.finalHyp.predict(XT);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LayeredHypTran';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            nameParams{end+1} = 'targetMethod';
            obj.set('targetMethod',obj.targetHyp.getPrefix());
        end 
    end
    
end

