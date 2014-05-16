clear all;

%Load sparse matrices
load ../data_500(minimini)/SimilarityMatrix_ForLocation.txt;
locationSimMat=convertSparseColumnsToSparseMat(SimilarityMatrix_ForLocation);
fprintf('Loaded locationSimMat\n');
save('../ResultsFromIanDavidson2/locationSimMat.mat', 'locationSimMat');

load ../data_500(minimini)/SimilarityMatrix_ForTags.txt;
tagSimMat=convertSparseColumnsToSparseMat(SimilarityMatrix_ForTags);
fprintf('Loaded tagSimMat\n');
save('../ResultsFromIanDavidson2/tagSimMat.mat', 'tagSimMat');

load ../data_500(minimini)/SimilarityMatrix_ForImages_jaccards.txt;
imageSimMat=convertSparseColumnsToSparseMat(SimilarityMatrix_ForImages_jaccards);
fprintf('Loaded imageSimMat\n');
save('../ResultsFromIanDavidson2/imageSimMat.mat', 'imageSimMat');
