function [d,removed] = makeSkillTransferGraph(d)
pc = ProjectConfigs.Create();
sourceLabels = pc.sourceLabels;
targetLabels = pc.targetLabels;

sourceY = d.Y(:,sourceLabels);
targetY = d.Y(:,targetLabels);
I = sum(isnan(sourceY),2) | sum(isnan(targetY),2);

d.Wdim = [];
d.Y = targetY;
d.trueY = targetY;
d.YNames = d.YNames(targetLabels);
if ~isempty(d.X)
    d.X = d.X(:,sourceLabels);
else
    assert(length(sourceLabels) == 1)
    d.W = d.W{sourceLabels};
end

%d.W = Helpers.CreateDistanceMatrix(sourceY);
%d.W = Helpers.CreateDistanceMatrix(targetY);
d.remove(I);
removed = I;
end