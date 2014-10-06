classdef ManifoldAlignmentTransfer < Transfer
    %MANIFOLDALIGNMENTTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        parameters = {'sigma','regA','regB','normalizeD','featureAlignment'...
            'includeSourceData'}
    end
    
    methods
        function obj = ManifoldAlignmentTransfer()            
        end
        
        function [transformedTargetTrain,transformedTargetTest,metadata] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData)            
            assert(numel(sourceDataSets) == 1);
            
            for str=obj.parameters
                eval([str{1} '= configs(''' str{1} ''');']);
            end
            sigma=configs('sigma');
            %{
            sigma = configs('sigma');
            regA = configs('regA');
            regB = configs('regB');
            normalizeD = configs('normalizeD');
            featureAlignment = configs('featureAlignment');            
            includeSourceData = configs('includeSourceData');
            %}
            
            numVecs = configs('numVecs');
            sourceTrainData = sourceDataSets{1};
            dimSource = size(sourceTrainData.X,2);
            dimTarget = size(sourceTrainData.X,2);
            numSource = size(sourceTrainData.X,1);
            numTarget = size(targetTrainData.X,1);

            if isempty(fields(savedData.metadata)) || ...
                    ~obj.areConfigsIdentical(configs,savedData.configs)
                W = zeros(numSource+numTarget);
                for i=1:max(sourceTrainData.Y)
                    sourceWithLabel = find(sourceTrainData.Y==i);
                    targetWithLabel = find(targetTrainData.Y==i);
                    W(sourceWithLabel,numSource+targetWithLabel) = 1;
                    W(numSource+targetWithLabel,sourceWithLabel) = 1;                                
                end
                
                wSource = Kernel.RBFKernel(sourceTrainData.X,sigma);
                wTarget = Kernel.RBFKernel(targetTrainData.X,sigma);
                W(1:numSource,1:numSource) = wSource;
                W(numSource+1:end,numSource+1:end) = wTarget;
                D = diag(sum(W));
                L = D-W;

                A = L;
                B = D;
                if featureAlignment                    
                    Z = zeros(numSource+numTarget,dimSource+dimTarget);
                    Z(1:numSource,1:dimSource) = sourceTrainData.X;
                    Z(numSource+1:end,dimSource+1:end) = ...
                        targetTrainData.X;
                    A = Z'*L*Z;
                    B = Z'*D*Z;
                end
                A = A + regA*eye(size(A));
                B = B + regB*eye(size(B));

                [vecs,vals] = eigs(A,B,100,0);
                display('Solve for fewer eigenvectors?');
                vals = diag(vals);
                [vals,indices] = sort(vals,'ascend');
                vecs = vecs(indices,:);
                metadata = struct();
                metadata.metadata = struct();
                metadata.metadata.vals = vals;
                metadata.metadata.vecs = vecs(1:200,:);
                %metadata.metadata.sourceTrainData = sourceTrainData;
                %metadata.metadata.targetTrainData = targetTrainData;
                %metadata.configs = configs;
                clear vals vecs A B Z
            else
                metadata = savedData.metadata;
            end            
            m = metadata.metadata;
            sourceVecs = m.vecs(1:numVecs,1:dimSource);
            targetVecs = m.vecs(1:numVecs,dimSource+1:end);
            for i=1:numVecs
                si = sourceVecs(i,:);                
                ti = targetVecs(i,:);
                if normalizeD
                    sourceD = D(1:numSource,1:numSource);
                    targetD = D(numSource+1:end,numSource+1:end);
                    sourceX = sourceTrainData.X;
                    targetX = targetTrainData.X;
                    sourceVecs(i,:) = si/(si*sourceX'*sourceD*sourceX*si');
                    targetVecs(i,:) = ti/(ti*targetX'*targetD*targetX*ti');
                else
                    sourceVecs(i,:) = si/norm(si);
                    targetVecs(i,:) = ti/norm(ti);
                end
            end
            if featureAlignment
                withLabels = targetTrainData.Y > 0;
                trainX = targetTrainData.X(withLabels,:)*targetVecs';
                trainY = targetTrainData.Y(withLabels);
                if includeSourceData
                    trainX = [trainX ; sourceTrainData.X*sourceVecs'];
                    trainY = [trainY ; sourceTrainData.Y];
                end
                transformedTargetTrain = ...
                    DataSet('','','',trainX,trainY);
                transformedTargetTest = ...
                    DataSet('','','',targetTestData.X*targetVecs',...
                    targetTestData.Y);
            else
                error('Not yet implemented');
            end
            metadata = struct();
            metadata.metadata = m;
            metadata.configs = configs;      
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'sigma','regB','normalizeD','numVecs'};
        end
    end
    methods(Static)
        function [prefix] = getPrefix()
            prefix = 'MA';
        end
    end
    
end

