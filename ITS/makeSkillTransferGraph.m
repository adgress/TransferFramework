function [d,removed] = makeSkillTransferGraph(d)
pc = ProjectConfigs.Create();
sourceLabels = pc.sourceLabels;
targetLabels = pc.targetLabels;
assert(length(sourceLabels) == 1)
sourceY = d.Y(:,sourceLabels);
targetY = d.Y(:,targetLabels);
I = isnan(sourceY) | isnan(targetY);

d.Wdim = [];
d.Y = targetY;
d.YNames = d.YNames(targetLabels);
d.W = d.W{sourceLabels};
%d.W = Helpers.CreateDistanceMatrix(sourceY);
%d.W = Helpers.CreateDistanceMatrix(targetY);
d.remove(I);
removed = I;
end