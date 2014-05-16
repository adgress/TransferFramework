function [] = plot_enrichment( PValues, labels, fileOutput)


threshold=0.0;
thresholdIncrement=0.001;
result=[];
while(threshold<=1.0)
    totalEnrichments=0;
    for i=1:length(labels)
        %theClass=labels(i);
        for j=1:length(labels)
            %theCluster=j;
            if PValues(i, j)<=threshold
                totalEnrichments=totalEnrichments+1;
            end
        end
    end
    result=[result; threshold totalEnrichments];
    threshold=threshold+thresholdIncrement;
end % while rnds here

dlmwrite(fileOutput, result);

end

