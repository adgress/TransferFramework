package HelperPackage;

import java.util.HashSet;
import java.util.Hashtable;

/**
 *
 * @author shahriar
 */
public class TagSimilarityFinder {

    public String imageTagsFile = "";
    Hashtable tagVsImages= new Hashtable();

    public TagSimilarityFinder(){        
    }
    public TagSimilarityFinder(String inFile){
        imageTagsFile=inFile;
        prepareTagVsImages();
    }

    public void prepareTagVsImages(){
        tagVsImages=Helper.prepareTagVsImages(imageTagsFile);
    }

    public double findSimilarityBetweenTwoTags(String tag1, String tag2){
        HashSet images1 = (HashSet) tagVsImages.get(tag1);
        HashSet images2 = (HashSet) tagVsImages.get(tag2);

        HashSet intersection = new HashSet(images1);
        intersection.retainAll(images2);
        if (intersection.size()==0){
            return 0.0;
        }
        double similarity = ((double)(intersection.size()))/
                            (
                            ((double)(images1.size()))+((double)(images2.size()))
                            -((double)intersection.size())
                            );
        return similarity;
    }

    public double findSimilarityBetweenTwoTags(int tag1, int tag2){
        return findSimilarityBetweenTwoTags(Integer.toString(tag1), Integer.toString(tag2));
    }

//    public static void main(String[] args){
//        TagSimilarityFinder ts=new TagSimilarityFinder();
//    }

}
