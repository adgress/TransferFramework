javaaddpath('MyJavaCodes.jar');
import HelperPackage.*;

inputDir='../data_vanc-1k';
IDvsImageFile = strcat(inputDir,'/','IDvsImage.map'); %input. 
InputSimilarityFile=strcat(inputDir, '/image-sim-vanc1k.tsv'); % input. Patrick sent it to me
OutputSimilarityFile=strcat(inputDir,'/SimilarityMatrix_ForImages.txt'); %Output

Helper.ConvertPatricksSimMatToMySimmat(IDvsImageFile, InputSimilarityFile, OutputSimilarityFile);