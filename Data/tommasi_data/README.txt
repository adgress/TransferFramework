In this directory there are the features used for the experiments in
CVPR 2010 Paper ID 1963: "Safety in Numbers: Learning 
Categories from Few Examples with Multi Model Knowledge Trasfer".
Cite this paper as reference.

The features were downloaded from 
http://www.vision.ee.ethz.ch/~pgehler/projects/iccv09/
see
http://www.vision.ee.ethz.ch/~pgehler/projects/iccv09/README.features
for details.


1- SIFT
Bag-of-words SIFT descriptors. We considered K=300 codewords
for quantization and grayscale images (128 dimension).

File format is matlab e.g.

>> load 015.bonsai-101.mat
feature  <122x300 double>

>> load 098.harp.mat
feature  <100x300 double>

>> load 257.clutter.mat
background  <827x300 double>


2- PHOG
We used the oriented variant A360 K40 and only the first level of 
the pyramid.

File format is matlab e.g.

>> load 060.duck.mat
feature  <87x40 double>

>> load 257.clutter.mat
background  <827x40 double>


3- RECOV - Region Covariance
We considered only the first level of the spatial pyramid.

File format is matlab e.g.

>> load 030.canoe.mat
feature  <104x28 double>

>> load 257.clutter.mat
background  <827x28 double>


4- LBP - Local Binary Pattern 
Same format as Region Covariance.

e.g.

>> load 068.fern.mat
feature  <110x37 double>

>> load 257.clutter.mat
background  <827x37 double>
