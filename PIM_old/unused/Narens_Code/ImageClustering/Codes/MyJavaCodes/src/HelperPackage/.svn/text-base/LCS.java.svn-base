package HelperPackage;


/**
 * I got a part of this code from this link:
 * "http://code.google.com/p/gumm-project/source/browse/trunk/com.googlecode.gumm/src/com/googlecode/gumm/simfunctions/LCS.java?r=33"
 *
 */

public class LCS {

    /**
     * The distance formula is: s1.length()+s2.length()-2.0*lcs.length();
     * @param s1
     * @param s2
     * @return
     */
    public static double getDistance(String s1, String s2){
        String lcs = getLCS(s1, s2);
        return s1.length()+s2.length()-2.0*lcs.length();
    }


    /**
     * The distance formula is: 1.0-2lcs/(l1+l2)
     * @param s1
     * @param s2
     * @return
     */
    public static double getDistanceRation(String s1, String s2){
        String lcs = getLCS(s1, s2);
        return 1.0-(
                ((double) (2.0*lcs.length()))/
               ((double)(s1.length())+(double)(s2.length()))
               );
    }

    public static double getLongestCommonPrefixDistance(String s1, String s2){
        int pLength = 0;
        for (int i=0;i<s1.length(); i++){
            if (i>s2.length()-1)
                break;
            if (s1.charAt(i)==s2.charAt(i)){
                pLength++;
            }else{
                break;
            }
        }
        return s1.length()+s2.length()-2.0*pLength;
    }


    public static double getLongestCommonPrefixDistanceRation(String s1, String s2){
        int pLength = 0;
        for (int i=0;i<s1.length(); i++){
            if (i>s2.length()-1)
                break;
            if (s1.charAt(i)==s2.charAt(i)){
                pLength++;
            }else{
                break;
            }
        }
        double distance=
                1.0-(
                  2.0*((double)(pLength))/
                  (((double) (s1.length()))+ ((double) s2.length()))
                );

        return distance;
    }

    /**
     * The similarity formula is:
     * (double) lcs.length() / (double) Math.max(s1.length(), s2.length())
     * @param s1
     * @param s2
     * @return
     */
    public static double getSimilarity(String s1, String s2) {
        String lcs = getLCS(s1, s2);
        return (double) lcs.length() / (double) Math.max(s1.length(), s2.length());
    }


    /**
     * The distance formula is:
     * Math.exp(-1.0*lcs.length());
     * @param s1
     * @param s2
     * @return
     */
    public static double getEXPDistance(String s1, String s2) {
        String lcs = getLCS(s1, s2);
        return Math.exp(-1.0*lcs.length());
    }

    public static double getLengthOfCommonPart(String s1, String s2) {
        String lcs = getLCS(s1, s2);
        return (double) lcs.length();
    }

    public static String getLCS(String s1, String s2) {
        int t1 = s1.length();
        int t2 = s2.length();
        int[][] opt = new int[t1+1][t2+1];
        for (int i = t1-1; i >= 0; i--) {
            for (int j = t2-1; j >= 0; j--) {
                if (s1.charAt(i) == s2.charAt(j))
                    opt[i][j] = opt[i+1][j+1] + 1;
                else
                    opt[i][j] = Math.max(opt[i+1][j], opt[i][j+1]);
            }
        }
        StringBuffer buffer = new StringBuffer();
        int i = 0, j = 0;
        while(i < t1 && j < t2) {
            if ( s1.charAt(i) == s2.charAt(j)) {
                buffer.append(s1.charAt(i));
                i++;
                j++;
            }
            else if (opt[i+1][j] >= opt[i][j+1])
                i++;
            else
                j++;
        }
        return buffer.toString();
    }    
}
