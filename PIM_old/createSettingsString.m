function [str] = createSettingsString(experiment)
    settings = experiment.settings; 
    str = '';
    if ~isfield(experiment,'sizes')
        str = [str ',percentTrain=' num2str(settings.percentTrain)];
    end
    if ~isfield(experiment,'numTags')
        str = [str ',numTags=' num2str(settings.numTags)];
    end
    if ~isfield(experiment,'numVectors')
        str = [str ',numVectors=' num2str(settings.numVectors)];
    end    
end