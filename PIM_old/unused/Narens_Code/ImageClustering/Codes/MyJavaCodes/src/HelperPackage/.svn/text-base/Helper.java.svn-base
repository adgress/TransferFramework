/* Run this package (NSF_Downloader) in the following sequence.
 * ProgramElementCodeExtractor
 * DownloadXMLFiles
 * remodeUnicodeCharacters
 * MergeCollaborativeResearchesInAllClass // the award numbers are changed. However since this is used only for the training purpose, it will be not needed later.
 * CreateNSFClassDirs
 */

package HelperPackage;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.Normalizer;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.Set;
import java.util.StringTokenizer;
import java.util.Vector;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JTable;
import javax.swing.JTree;
import javax.swing.event.TreeSelectionListener;
import javax.swing.table.DefaultTableModel;
import javax.swing.tree.DefaultMutableTreeNode;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreeNode;
import javax.swing.tree.TreePath;

/**
 * This is an abstract class the contains some helping methods.
 * @author M. Shahriar Hossain<br>
 * Dept. of CS,Virginia Tech<br>
 * Blacksburg, VA 24061, USA.<br>
 * Email: <i>msh at the rate of cs dot vt dot edu</i>
 */
public abstract class Helper {


    public static String CONFIG_FILE = "config";

    public static String ALL_DOC_INFO_File = "ALL_DOC_INFO.txt";

    public static String ALL_CLASS_LABELS_STRING = "All class labels";

    public static String CLASS_DIR = "AllClasses";
    public static String TF_DIR = "TFDirs";
    public static String TEMP_DIR = "TempDir";


    public static int DEFAULT_NUMBER_OF_SUGGESTIONS = 5;

    public static String CONVERTER = "converter/minetext.exe";

    private static String[] ALLOWED_EXTENSIONS ={"txt", "pdf", "doc"};


    public static String FILE_NOT_IN_ORIGINAL_LOCATION = "File missing";
    public static String FILE_LASTMODIFIED_MISMATCH = "Modified";
    public static String FILE_SIZE_MISMATCH = "Size changed";
    public static String FILE_OK = "OK";

    public static String tokenDelim = ", -";


    public static HashSet ALLOWED_EXTENSIONS(){
        HashSet h= new HashSet();
        for (int i=0; i<ALLOWED_EXTENSIONS.length;i++){
            h.add(ALLOWED_EXTENSIONS[i]);
        }
        return h;
    }


    public static void replaceImageNamesWithIdsOfTheLocaionFile(
            String inputLocationFile, String outputFile,
            String imageIDVsImageNameFile, String IDvsLocationFile){
        Hashtable idVSImageName = Helper.readHashTableFromFile(imageIDVsImageNameFile);
        Hashtable imageNameVsID = Helper.reverseAHashtable(idVSImageName);
        Hashtable idVSLocation = Helper.readIDVsLattitudeLongitudeFromFile(IDvsLocationFile);
        Hashtable locationVsID = Helper.reverseAHashtable(idVSLocation);

        try{
            BufferedReader br = new BufferedReader(new FileReader(inputLocationFile));
            BufferedWriter bw = new BufferedWriter(new FileWriter(outputFile));
            String line = "";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                // It assumes that the first token is available in imageNameVsID as a key
                String imageName = stkn.nextToken();
                String imageID = imageNameVsID.get(imageName).toString();
                String user = stkn.nextToken();
                String timeTaken = stkn.nextToken();
                String lat=stkn.nextToken();
                String longi=stkn.nextToken();
                String locationID = locationVsID.get(lat+"\t"+longi).toString();
                String accu=stkn.nextToken();

                bw.write(imageID+"\t"+user+"\t"+timeTaken+"\t"+locationID+"\t"+accu);
                bw.newLine();
                bw.flush();
            }
            br.close();
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
    }


    public static void replaceImageNamesWithIdsOfTheLocaionFile(String inputLocationFile, String outputFile,
            String imageIDVsImageNameFile){
        Hashtable idVSImageName = Helper.readHashTableFromFile(imageIDVsImageNameFile);
        Hashtable imageNameVsID = Helper.reverseAHashtable(idVSImageName);

        try{
            BufferedReader br = new BufferedReader(new FileReader(inputLocationFile));
            BufferedWriter bw = new BufferedWriter(new FileWriter(outputFile));
            String line = "";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }                
                StringTokenizer stkn = new StringTokenizer(line);
                // It assumes that the first token is available in imageNameVsID as a key
                int whichToken=1;
                String toWrite="";
                while (stkn.hasMoreTokens()){
                    String token=stkn.nextToken();
                    if (whichToken==1){
                        String ID = imageNameVsID.get(token).toString();
                        toWrite=ID;
                    }else{
                        toWrite=toWrite+"\t"+token;
                    }
                    whichToken++;
                }
                bw.write(toWrite);
                bw.newLine();
                bw.flush();
            }
            br.close();
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
    }

    public static void replaceImageNamesAndTagsWithIdsOfTheTagsFile(
            String inputTagsFile, String outputTagsFile,
            String imageIDVsImageNameFile, String tagIDVasTagsFile){
        Hashtable idVSImageName = Helper.readHashTableFromFile(imageIDVsImageNameFile);
        Hashtable imageNameVsID = Helper.reverseAHashtable(idVSImageName);

        Hashtable idVSTag = Helper.readHashTableFromFile(tagIDVasTagsFile);
        Hashtable tagVsID = Helper.reverseAHashtable(idVSTag);

        try{
            BufferedReader br = new BufferedReader(new FileReader(inputTagsFile));
            BufferedWriter bw = new BufferedWriter(new FileWriter(outputTagsFile));
            String line = "";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                //The first token is the image name
                String imageName=stkn.nextToken();
                String imageID = imageNameVsID.get(imageName).toString();
                //The second token is the tag
                String tag=stkn.nextToken();
                //System.out.println(tag);

                if (tagVsID.containsKey(tag)==false){
                    System.out.println("Could not find "+tag+" in keys of tagVsID. Trying its ascii version.");
                    tag=Helper.convertUnicodeToAscii(tag);
                    if (tagVsID.containsKey(tag)==false){
                        System.out.println("Could not even find teh ascii "+tag+" in keys of tagVsID.");
                    }
                }else{
                }
                String tagID = tagVsID.get(tag).toString();
                bw.write(imageID+"\t"+tagID);
                bw.newLine();
                bw.flush();
            }
            br.close();
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
    }


    public static String convertUnicodeToAscii(String s){

        String s1 = Normalizer.normalize(s, Normalizer.Form.NFKD);
        String regex = "[\\p{InCombiningDiacriticalMarks}\\p{IsLm}\\p{IsSk}]+";

        String s2 ="";
        try{
            s2 = new String(s1.replaceAll(regex, "").getBytes("ascii"), "ascii");
        } catch (Exception eee) {
            eee.printStackTrace();
        }
        return s2;
    }


    public static Hashtable reverseAHashtable(Hashtable ht){
        Hashtable reversedHT = new Hashtable();
        for (Iterator it=ht.keySet().iterator(); it.hasNext();){
            String key=it.next().toString();
            String val = ht.get(key).toString();
            reversedHT.put(val, key);
        }

        return reversedHT;
    }


    /**
     * 
     * @param IDvsImageFile
     * @param patricksSimmmat
     * @param outputFileWithIdsInSimmMat
     */
    public static void ConvertPatricksSimMatToMySimmat(
            String IDvsImageFile,
            String patricksSimmmat,
            String outputFileWithIdsInSimmMat){
        Hashtable IDvsImage=Helper.readHashTableFromFile(IDvsImageFile,"");
        Hashtable ImageVsID=Helper.reverseAHashtable(IDvsImage);
        System.out.println("IDvsImage: "+IDvsImage);
        System.out.println("ImageVsID: "+ImageVsID);
        try{
            BufferedReader br = new BufferedReader(new FileReader(patricksSimmmat));
            BufferedWriter bw = new BufferedWriter(new FileWriter(outputFileWithIdsInSimmMat));
            String line="";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                String imageName1=stkn.nextToken();
                String imageName2=stkn.nextToken();
                String similarity=stkn.nextToken();
                System.out.print("imageName1:"+imageName1);
                String id1= ImageVsID.get(imageName1).toString();
                System.out.println(" id:"+id1);
                System.out.print("imageName2:"+imageName2);
                String id2= ImageVsID.get(imageName2).toString();
                System.out.println(" id:"+id2);
                bw.write(id1+"\t"+id2+"\t"+similarity);
                bw.newLine();
                bw.flush();
            }
            br.close();
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
    }


    public static void produceIDFileForTwoMergedColumns(
            String inputFile, String outputFile, int whichCol1, int whichCol2){
        try{
            BufferedReader br = new BufferedReader(new FileReader(inputFile));
            String line="";
            Hashtable StringVSid = new Hashtable();
            int ID=1;
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                int runningColumn = 1;
                String value="";
                while (stkn.hasMoreTokens()){
                    String token = stkn.nextToken();
                    if (runningColumn==whichCol1||runningColumn==whichCol2){
                        if (value.equals("")){
                            value=(value+"\t"+token).trim();
                        }else{
                            value=(value+"\t"+token).trim();
                            if (StringVSid.containsKey(value)==false){
                                StringVSid.put(value, ID);
                                ID++;
                            }
                        }
                    }
                    runningColumn++;
                }
            }
            br.close();
            
            String[] allStrings = new String[StringVSid.size()];
            for (Iterator it=StringVSid.keySet().iterator();it.hasNext(); ){
                String key = it.next().toString();
                int id = (Integer) StringVSid.get(key);
                allStrings[id-1]=new String(key);
            }

            BufferedWriter bw = new BufferedWriter(new FileWriter(outputFile));
            for (int i=0; i<allStrings.length;i++){
                bw.write((i+1)+"\t"+allStrings[i]);
                bw.newLine();
                bw.flush();
            }
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        
    }


    public static void produceIDFileForTwoColumnsOfTwoFiles(
            String file1, int file1WhichCol, String file2, int file2WhichCol,
            String outputMapFile){
        try{
            BufferedReader br = new BufferedReader(new FileReader(file1));
            String line="";
            int ID=1;
            Hashtable StringVSid = new Hashtable(); // key = string, value=int
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                int runningColumn = 1;
                while (stkn.hasMoreTokens()){
                    String token = stkn.nextToken();
                    if (runningColumn==file1WhichCol){
                        if (StringVSid.containsKey(token)==false){
                            StringVSid.put(token, ID);
                            ID++;
                        }
                    }
                    runningColumn++;
                }
            }
            br.close();
            br = new BufferedReader(new FileReader(file2));
            line="";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                int runningColumn = 1;
                while (stkn.hasMoreTokens()){
                    String token = stkn.nextToken();
                    if (runningColumn==file2WhichCol){
                        if (StringVSid.containsKey(token)==false){
                            StringVSid.put(token, ID);
                            ID++;
                        }
                    }
                    runningColumn++;
                }
            }
            br.close();
            
            String[] allStrings = new String[StringVSid.size()];
            for (Iterator it=StringVSid.keySet().iterator();it.hasNext(); ){
                String key = it.next().toString();
                int id = (Integer) StringVSid.get(key);
                allStrings[id-1]=new String(key);
            }

            BufferedWriter bw = new BufferedWriter(new FileWriter(outputMapFile));
            for (int i=0; i<allStrings.length;i++){
                bw.write((i+1)+"\t"+allStrings[i]);
                bw.newLine();
                bw.flush();
            }
            bw.close();
        }catch (Exception eee){
            eee.printStackTrace();
        }
    }

    private static String removeQuestionMarkFromStartEndEnd(String s){
        String writee = new String(s);
        while (writee.lastIndexOf("?")==0){
            if (writee.length()>1){
                writee=writee.substring(1);
            }
        }
        while (writee.lastIndexOf("?")==writee.length()-1){
            writee=writee.substring(0, writee.length()-1);
        }
        if (writee.length()==0){
            writee="";
        }
        return writee;
    }

    public static void produceIDFileForASpecificColumn(String inputFile, int whichCol,
            String outputMapFile){
        try{
            BufferedReader br = new BufferedReader(new FileReader(inputFile));
            String line="";
            int ID=1;
            Hashtable StringVSid = new Hashtable(); // key = string, value=int
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line);
                int runningColumn = 1;
                while (stkn.hasMoreTokens()){
                    String token = stkn.nextToken();
                    if (runningColumn==whichCol){
                        if (StringVSid.containsKey(token)==false){
                            StringVSid.put(token, ID);
                            ID++;
                        }
                    }
                    runningColumn++;
                }
            }
            br.close();
            String[] allStrings = new String[StringVSid.size()];
            for (Iterator it=StringVSid.keySet().iterator();it.hasNext(); ){
                String key = it.next().toString();
                int id = (Integer) StringVSid.get(key);
                allStrings[id-1]=new String(key);
            }

            BufferedWriter bw = new BufferedWriter(new FileWriter(outputMapFile));
            for (int i=0; i<allStrings.length;i++){
                String s =convertUnicodeToAscii(allStrings[i]);
                bw.write((i+1)+"\t"+s);
                bw.newLine();
                bw.flush();
            }
            bw.close();
        }catch (Exception eee){
            eee.printStackTrace();
        }
    }


    /**
     * This function will recursivly delete directories and files.
     * @param path File or Directory to be deleted
     * @return true indicates success.
     */
    public static boolean deleteFile(File path) {
        if( path.exists() ) {
            if (path.isDirectory()) {
                    File[] files = path.listFiles();
                    for(int i=0; i<files.length; i++) {
                       if(files[i].isDirectory()) {
                               deleteFile(files[i]);
                       } else {
                         files[i].delete();
                       }
                    }
            }
        }
        return(path.delete());
    }    

    /**
     * Converts to lower case, and removes any quatation marks at the start or end
     * @param eiID
     * @return
     */
    public static String cleanBOMDescription(String description){
        description=new String(description);
        description=description.replace("\\", "");
        description=description.replace("\"", "");
        
        description=description.toLowerCase();
        if (description.indexOf("\"")==0 && description.length()>1){
            description=description.substring(1);
        }
        if (description.lastIndexOf("\"")==description.length()-1 && description.length()>1){
            description=description.substring(0, description.length()-1);
        }
        return description.trim();
    }



    /**
     * Recursively deletes all files and directories in it and also deletes itself.
     * @param dirName
     */
    public static void delDir(String dirName){
        File dir = new File(dirName);
        if (dir.exists()==false)
            return;

        if (dir.isDirectory()==true){
            String inDirNames[] = dir.list();
            for (int i=0; i<inDirNames.length;i++){
                String inDirName = dirName+"/"+inDirNames[i];
                File inDir = new File(inDirName);
                if (inDir.isDirectory())
                    delDir(inDirName);
                else
                    inDir.delete();
            }

        }
        dir.delete();

    }


    public static void prepareTreeAllClasses(JTree jtree, String allClassedDir){

//        DefaultMutableTreeNode top =
//            new DefaultMutableTreeNode("The Java Series");
//
//        DefaultTreeModel treeModel = (DefaultTreeModel) jtree.getModel();
//
//        DefaultMutableTreeNode rootNode =(DefaultMutableTreeNode) treeModel.getRoot();
//        rootNode.removeAllChildren();
//        rootNode.removeFromParent();
//        treeModel.reload();

        TreePath tp_temp = jtree.getSelectionPath();
        TreeSelectionListener[] listeners = jtree.getTreeSelectionListeners();
        for (int i=0; i<listeners.length;i++){
            jtree.removeTreeSelectionListener(listeners[i]);
        }

        //jtree.getSelectionModel().clearSelection();

        DefaultMutableTreeNode rootNode =new DefaultMutableTreeNode(ALL_CLASS_LABELS_STRING);
        DefaultTreeModel treeModel=new DefaultTreeModel(rootNode);
        jtree.setModel(treeModel);
        
        File dir = new File(allClassedDir);
        String[] files = dir.list();
        for (int i=0; i<files.length;i++){
            File inFile = new File(allClassedDir+"/"+files[i]);
            if (inFile.isDirectory())
                insertDir(jtree, rootNode, allClassedDir+"/"+files[i]);

//            File cDir = new File(allClassedDir+"/"+files[i]);
//            if (cDir.isDirectory()){
//
//            }else{
//
//            }
        }

        for (int i=0; i<listeners.length;i++){
            jtree.addTreeSelectionListener(listeners[i]);
        }
        try{
            jtree.getSelectionModel().setSelectionPath(tp_temp);
        }catch (Exception ex){
            System.out.println("Error in Helper.prepareTreeAllClasses()");
        }
        System.out.println();
    }



    /**
     * Recursively inserts all files and directories in it.
     * @param dirName
     */
    public static void insertDir(JTree jtree,
                                 DefaultMutableTreeNode parent,
                                 //Object child,
                                 String dirName){
        File dir = new File(dirName);
        if (dir.exists()==false)
            return;

        if (dir.isFile())
            return;


        //System.out.print(dirName+" "+dir.isDirectory());
        //parent =  inDirName

        //DefaultMutableTreeNode node=new DefaultMutableTreeNode(lastSlashToken(removeTxtExtension(dirName)));
        DefaultMutableTreeNode node=new DefaultMutableTreeNode(lastSlashToken(dirName));
        //System.out.print(" "+lastSlashToken(dirName));
        DefaultMutableTreeNode currentNode = addObject(jtree, parent, node, dir.isDirectory());
        //System.out.println(" "+currentNode.toString());

        if (dir.isDirectory()==true){
            String inDirNames[] = dir.list();
            for (int i=0; i<inDirNames.length;i++){
                String inDirName = dirName+"/"+inDirNames[i];
                insertDir(jtree, currentNode, inDirName);
            }

        }

    }


    private static String removeTxtExtension(String s){
        if (s.contains(".txt")){
            return s.substring(0, s.lastIndexOf(".txt"));
        }
        return s;
    }

    private static String lastSlashToken(String s){
        StringTokenizer stkn = new StringTokenizer(s, "/");
        String token = "";
        while(stkn.hasMoreTokens()){
            token=stkn.nextToken();
        }
        return token;
    }

    public static DefaultMutableTreeNode addObject(JTree jtree,
                                            DefaultMutableTreeNode parent,
                                            Object child,
                                            boolean shouldBeVisible) {
        DefaultTreeModel treeModel = (DefaultTreeModel) jtree.getModel();
        DefaultMutableTreeNode childNode =
                new DefaultMutableTreeNode(child);

        if (parent == null) {            
            DefaultMutableTreeNode rootNode =(DefaultMutableTreeNode) treeModel.getRoot();
            parent = rootNode;
            System.out.println("Inserted to root sice parent is null");
        }

	//It is key to invoke this on the TreeModel, and NOT DefaultMutableTreeNode
        treeModel.insertNodeInto(childNode, parent,
                                 parent.getChildCount());

        //Make sure the user can see the lovely new node.
        if (shouldBeVisible) {
            jtree.scrollPathToVisible(new TreePath(childNode.getPath()));
        }
        return childNode;
    }

    public static String putQuteInFilePath(String fileName){
        return "\""+fileName+"\"";
    }


    public static void writeHashtableInFile(Hashtable ht, String fileName){
        try{
            BufferedWriter bw = new BufferedWriter(new FileWriter(fileName));
            for (Iterator it = ht.keySet().iterator(); it.hasNext(); ){
                String key = it.next().toString();
                String value = ht.get(key).toString();
                bw.write(key+"\t"+value);
                bw.newLine();
                bw.flush();
            }
            bw.close();
        }catch (Exception eee){
            eee.printStackTrace();
        }
    }

    public static Hashtable readIDVsLattitudeLongitudeFromFile(String fileName){
        Hashtable ht = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String ID = stkn.nextToken();
                String lat = stkn.nextToken();
                String longi = stkn.nextToken();
                
                ht.put(ID, lat+"\t"+longi);
            }
        }catch (Exception eee) {
            eee.printStackTrace();
        }
        return ht;
    }


    public static Hashtable readHashTableFromFile(String fileName){
        Hashtable ht = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String myID = stkn.nextToken();
                String PrtNo = stkn.nextToken();
                ht.put(myID, PrtNo);
            }
        }catch (Exception eee) {
            eee.printStackTrace();
        }
        return ht;
    }


    public static Hashtable readHashTableFromFile(String fileName, String delim){
        Hashtable ht = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn;
                if (delim.equals("")){
                    stkn =new StringTokenizer(line);
                }else{
                    stkn =new StringTokenizer(line, delim);
                }
                String myID = stkn.nextToken();
                String PrtNo = stkn.nextToken();
                ht.put(myID, PrtNo);
            }
        }catch (Exception eee) {
            eee.printStackTrace();
        }
        return ht;
    }


    public static double[][] readDistanceMartrixFromFile(String fileName, int size){
        double[][] distMat = new double[size][size];
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String index1 = stkn.nextToken();
                String index2 = stkn.nextToken();
                String distance = stkn.nextToken();                
                distMat[Integer.parseInt(index1)-1][Integer.parseInt(index2)-1] =
                        Double.parseDouble(distance);
            }
        }catch (Exception eee) {
            eee.printStackTrace();
        }
        return distMat;
    }

    public static boolean convertToTextFile(String inputFile, String outputFile){
        String s = null;
        try {
            File converter = new File(Helper.CONVERTER);
            String converterFile = converter.getAbsolutePath();
            // run the Unix "ps -ef" command
            // using the Runtime exec method:
            Process p = Runtime.getRuntime().exec(converterFile + " "+inputFile+" "+outputFile);
            BufferedReader stdInput = new BufferedReader(new
                 InputStreamReader(p.getInputStream()));

            BufferedReader stdError = new BufferedReader(new
                 InputStreamReader(p.getErrorStream()));

            // read the output from the command
            System.out.println("Here is the standard output of the command:\n");
            String error = "";
            while ((s = stdInput.readLine()) != null) {
                System.out.println(s);
                error=error+s;
            }

            error=error.trim();
            if (error.contains("Text is mined from")==false){
                JOptionPane.showMessageDialog(null, error, "Error during conversion", JOptionPane.ERROR_MESSAGE);
                return false;
            }

            // read any errors from the attempted command

            System.out.println("Here is the standard error of the command (if any):\n");
            error = "";
            while ((s = stdError.readLine()) != null) {
                System.out.println(s);
                error=error+s;                
            }
            error=error.trim();
            if (error.equals("")==false){
                JOptionPane.showMessageDialog(null, error, "Error during conversion", JOptionPane.ERROR_MESSAGE);
                return false;
            }

        } catch (Exception ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            JOptionPane.showMessageDialog(null, ex, "Error:", JOptionPane.ERROR_MESSAGE);
            return false;
        }
        return true;
    }


    /**
     * 
     * @param stemmedTermsV contains the stemmed terms of a particular document
     * @return Hashtable TFHT. key=term, value=frequency of this term in the document (i.e., the stemmedTermsV)
     */
    public static Hashtable createTFHTFromStemmedTermsVector(Vector stemmedTermsV){
        Hashtable ht = new Hashtable();
        for (int i=0; i<stemmedTermsV.size();i++){
            String term = stemmedTermsV.get(i).toString();
            if (ht.containsKey(term)){
                int tf = (Integer) ht.get(term);
                ht.put(term, tf+1);
            }else{
                ht.put(term, 1);
            }
        }
        return ht;
    }


    public static String getFileExtension(String fileName){
        String extension="";
        if (fileName.contains(".")){
            extension=fileName.substring(fileName.lastIndexOf(".")+1);
        }
        return extension;
    }

    /**
     * Example input: TempDir/1101_1.txt
     * @param inputString. 
     * @return Example: 1101_1.txt
     */
    public static String dropFirstSlashPartOfAString(String inputString){
        String returnee="";
        if (inputString.contains("/")){
            returnee=inputString.substring(inputString.indexOf("/")+1);
        }else{
            returnee=inputString;
        }
        return returnee;
    }


    /**
     * Given a JTree and class label, this method returns the TreePath of this class label
     * in the JTree.
     * @param tree where to look for the classLabel
     * @param classLabel
     * @return
     */

    public static TreePath getTreePathFromClassLabel(JTree tree, String classLabel){
        String classLabelString = new String(classLabel);
        classLabelString=classLabelString.replaceAll("/", "\t");
        StringTokenizer stkn = new StringTokenizer(classLabelString,"\t");
        int count=stkn.countTokens();
        String[] names = new String[count+1];
        int i=0;
        names[i]=Helper.ALL_CLASS_LABELS_STRING;
        while (stkn.hasMoreTokens()){
            i++;
            String token = stkn.nextToken();
            names[i]=token;            
        }
        TreePath tp =  findTreePathByName(tree, names);
        return tp;
    }


    public static String getClassLabelFromSelectedTreePath(JTree tree){
        TreePath tp = tree.getSelectionPath();

        Object[] path = tp.getPath();
        if (path.length<=1)
            return "";

        String classLabel = "";
        for (int i=1; i<path.length;i++){
            classLabel=classLabel+path[i].toString();
            if (i!=path.length-1)
                classLabel=classLabel+"/";
        }

        return classLabel;
    }


    /**
     * Finds the path in tree as specified by the array of names. The names array is a
     * sequence of names where names[0] is the root and names[i] is a child of names[i-1].
     * Comparison is done using String.equals(). Returns null if not found.
     * @param tree
     * @param names
     * @return
     */

    public static TreePath findTreePathByName(JTree tree, String[] names) {
        TreeNode root = (TreeNode)tree.getModel().getRoot();
        return find2(tree, new TreePath(root), names, 0, true);
    }
    private static TreePath find2(JTree tree, TreePath parent, Object[] nodes, int depth, boolean byName) {
        TreeNode node = (TreeNode)parent.getLastPathComponent();
        Object o = node;

        // If by name, convert node to a string
        if (byName) {
            o = o.toString();
        }

        // If equal, go down the branch
        if (o.equals(nodes[depth])) {
            // If at end, return match
            if (depth == nodes.length-1) {
                return parent;
            }

            // Traverse children
            if (node.getChildCount() >= 0) {
                for (Enumeration e=node.children(); e.hasMoreElements(); ) {
                    TreeNode n = (TreeNode)e.nextElement();
                    TreePath path = parent.pathByAddingChild(n);
                    TreePath result = find2(tree, path, nodes, depth+1, byName);
                    // Found a match
                    if (result != null) {
                        return result;
                    }
                }
            }
        }

        // No match at this branch
        return null;
    }



    public static String getSlashizedString(String in){
        return in.replaceAll("/", "SLASH");
    }

    public static String putRealSlashInString(String in){
        return in.replaceAll("SLASH", "/");
    }


    /**
     * It returns true if termTFHT is successfully written in the tfFile.
     * @param tfFileName
     * @param docName
     * @param termTFHT
     * @return
     */
    public static boolean appendToTFFile(String tfFileName, String docName, Hashtable termTFHT){
        FileWriter fw = null;
        try {
            fw = new FileWriter (tfFileName, true);
            fw.append(docName+"\t");
            for (Iterator it = termTFHT.keySet().iterator(); it.hasNext();) {
                String term = it.next().toString();
                int freq = (Integer) termTFHT.get(term);
                fw.append(term + "\t" + freq+"\t");
            }
            fw.append("\n");
            fw.flush();
            fw.close();
        } catch (IOException ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println(ex);
            return false;
        }
        return true;
    }


    public static boolean doesStringHaveAtSomethingInLastToken(String str){

        StringTokenizer stkn = new StringTokenizer(str, ",");
        String lastToken = "";
        while (stkn.hasMoreTokens()){
            lastToken = stkn.nextToken();
        }
        if (lastToken.contains("at ")==false)
            return false;
        lastToken=lastToken.trim();
        stkn = new StringTokenizer(lastToken, " ,");
        String firstOfLastToken = "";
        if (stkn.hasMoreTokens()){
            firstOfLastToken=stkn.nextToken();
        }
        if (firstOfLastToken.equals("at")){
            return true;
        }

        return false;

    }


    public static boolean appendLineToFile(String fileName, String line){
        FileWriter fw = null;
        try {
            fw = new FileWriter (fileName, true);
            fw.append(line);
            fw.append("\n");
            fw.flush();
            fw.close();
        } catch (IOException ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println(ex);
            return false;
        }
        return true;
    }






    /**
     * Returns true if the newlabel is already there or succesully created.
     * @param newClasslabel
     * @param jtree
     * @return
     */

    public static boolean makeNewLabel(String newClasslabel){
        StringTokenizer stkn = new StringTokenizer(newClasslabel,"/");
        String path=Helper.CLASS_DIR;
        //String classLabel = "";
        boolean success=false;
        while (stkn.hasMoreTokens()){
            String token = stkn.nextToken();
            if (token.equals(""))
                continue;
            path=path+"/"+token;
//            classLabel=classLabel+token;
//            if (stkn.hasMoreTokens())
//                classLabel=classLabel+"/";
            File dir = new File(path);
            success=true;
            if (dir.exists())
                continue;
            dir.mkdir();
            System.out.println("Made: "+path);
        }        
        return success;
    }


    /**
     *
     * @param fileName The name of the file from which a line would be removed.
     * @param i_thTokenMatch The line's ith token must match with the matchString
     * @param matchString String that must match with the i-th token of the line
     * @return success if successfully work is done
     */
    public static boolean deleteLineFromFile(String fileName, int i_thTokenMatch, String matchString){
        BufferedWriter bw = null;
        try {
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String tempFile = Helper.TEMP_DIR+"/"+"temp.txt";
            bw = new BufferedWriter(new FileWriter(tempFile));
            String line = "";
            while ((line = br.readLine()) != null) {
                line = line.trim();
                if (line.equals("")) {
                    continue;
                }
                //StringTokenizer stkn = new StringTokenizer(line, "\t");
                String i_thToke = geti_thToken(line, i_thTokenMatch);
                System.out.println(i_thToke+" .... "+matchString);
                if (i_thToke.equals(matchString) == false) {
                    try {
                        bw.write(line);
                        bw.newLine();
                        bw.flush();
                    } catch (IOException ex) {
                        Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }else{
                    System.out.println("Skipping this line");
                }
            }
            br.close();
            bw.close();

            File f= new File(fileName);
            boolean deleteSuccess = f.delete();
            System.out.println("deleteSuccess:"+deleteSuccess);

            if (deleteSuccess==false){
                boolean copySuccess = copyFileToDestination(tempFile, fileName);
                System.out.println("copySuccess:"+copySuccess);
                return true;
            }
            f= new File(tempFile);
            boolean renameSuccess = f.renameTo(new File(fileName));
            if (renameSuccess==false){
                copyFileToDestination(tempFile, fileName);
                return true;
            }
            System.out.println("renameSuccess:"+renameSuccess);
            return true;
        } catch (Exception ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println(ex);
        }
        return false;
    }



    public static Vector deleteLineFromFileWithPartialMatch(String fileName, int i_thTokenMatch, String matchString){
        Vector stringsWithFullOrPartialMatch = new Vector();
        BufferedWriter bw = null;
        try {
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String tempFile = Helper.TEMP_DIR+"/"+"temp.txt";
            bw = new BufferedWriter(new FileWriter(tempFile));
            String line = "";
            while ((line = br.readLine()) != null) {
                line = line.trim();
                if (line.equals("")) {
                    continue;
                }
                //StringTokenizer stkn = new StringTokenizer(line, "\t");
                String i_thToke = geti_thToken(line, i_thTokenMatch);
                System.out.println(i_thToke+" .... "+matchString);
                if (i_thToke.equals(matchString) == false) {
                    if (i_thToke.indexOf(matchString+"/")!=0){                        
                        try {
                            bw.write(line);
                            bw.newLine();
                            bw.flush();
                        } catch (IOException ex) {
                            Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
                        }
                    }else{
                        stringsWithFullOrPartialMatch.add(i_thToke);
                        System.out.println("Skipping this line since it is inner class.");
                    }
                }else{
                    stringsWithFullOrPartialMatch.add(i_thToke);
                    System.out.println("Skipping this line");
                }
            }
            br.close();
            bw.close();

            File f= new File(fileName);
            boolean deleteSuccess = f.delete();
            System.out.println("deleteSuccess:"+deleteSuccess);

            if (deleteSuccess==false){
                boolean copySuccess = copyFileToDestination(tempFile, fileName);
                System.out.println("copySuccess:"+copySuccess);
                return stringsWithFullOrPartialMatch;
            }
            f= new File(tempFile);
            boolean renameSuccess = f.renameTo(new File(fileName));
            if (renameSuccess==false){
                copyFileToDestination(tempFile, fileName);
                return stringsWithFullOrPartialMatch;
            }
            System.out.println("renameSuccess:"+renameSuccess);
            return stringsWithFullOrPartialMatch;
        } catch (Exception ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println(ex);
        }
        return stringsWithFullOrPartialMatch;
    }


    public static boolean copyFileToDestination(String inFile, String destinationFile){
        try {
            BufferedReader br = new BufferedReader(new FileReader(inFile));
            BufferedWriter bw = new BufferedWriter(new FileWriter(destinationFile));
            String line = "";
            while ((line = br.readLine()) != null) {
                bw.write(line);
                bw.newLine();
                bw.flush();
            }
            bw.close();
            br.close();
        } catch (Exception ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println(ex);
            return false;
        }
        return true;
    }

    private static String geti_thToken(String inString, int i){
        StringTokenizer stkn = new StringTokenizer(inString, "\t");
        int j=0;
        while (stkn.hasMoreTokens()){
            String token=stkn.nextToken();
            if (i==j)
                return token;
            j++;
        }
        return "";
    }

    public static Hashtable prepareTagVsImages(String fileName){
        Hashtable tagVsImagesHT = new Hashtable();        
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer(line);
                String imageID = stkn.nextToken();
                String tagID = stkn.nextToken();
                if (tagVsImagesHT.containsKey(tagID)){
                    HashSet images = (HashSet) tagVsImagesHT.get(tagID);
                    images.add(imageID);
                    tagVsImagesHT.put(tagID, images);
                }else{
                    HashSet images = new HashSet();
                    images.add(imageID);
                    tagVsImagesHT.put(tagID, images);
                }
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return tagVsImagesHT;
    }

    public static void filterImageTagsBasedOnAThreshold(String inputImageTagsFile,
            String outputImageTagsFile, int threshold){
        Hashtable tagVsImagesHT = prepareTagVsImages(inputImageTagsFile);
        HashSet selectedTags = new HashSet();
        try{
            BufferedReader br = new BufferedReader(new FileReader(inputImageTagsFile));
            BufferedWriter bw = new BufferedWriter(new FileWriter(outputImageTagsFile));
            HashSet linesEncountered= new HashSet();
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals("")){
                    continue;
                }
                if (linesEncountered.contains(line)){
                    continue;
                }
                linesEncountered.add(line);

                StringTokenizer stkn = new StringTokenizer(line);
                String image = stkn.nextToken();
                String tag = stkn.nextToken();
                //System.out.println(image+"\t"+tag);
                HashSet imagesH = (HashSet) tagVsImagesHT.get(tag);
                if (imagesH.size()>threshold){
                    selectedTags.add(tag);
                    bw.write(image+"\t"+tag);
                    bw.newLine();
                    bw.flush();
                }
            }
            br.close();
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        System.out.println(selectedTags.size()+" tags out of "+tagVsImagesHT.size()+" tags are selected.");

    }


    /**
     * Column 0 indicaes the first column, 1 indicates the second column, so and so forth.
     * @param fileName
     * @param column
     * @return
     */
    public static Vector<String> readAColumnofAFile(String fileName, int column){
        Vector<String> v = new Vector<String>();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                if (column>=stkn.countTokens()){ // error
                    return new Vector<String>();
                }
                int tok = 0;
                while (stkn.hasMoreTokens()){
                    String s = stkn.nextToken();
                    if (tok==column){
                        v.add(s);
                        break;
                    }
                    tok++;
                }
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        
        return v;
    }


    public static HashSet getunMappedMyIDS(HashSet allmyIDs, String bomClusterinfoFile){
        Vector mappedmyIDsV = readAColumnofAFile(bomClusterinfoFile, 3); // read the fourth column

        HashSet unmappedMyIDs = (HashSet) allmyIDs.clone();
        
        unmappedMyIDs.removeAll(mappedmyIDsV);
        return unmappedMyIDs;

    }


    /**
     * The input file fileName should have a header row. The file should
     * have four columns. The 2nd and the 3rd columns are the myIDs and the
     * BOM descriptions. This methods returns Ids as key and descriptions
     * as values of a hashtable.
     * @param fileName
     * @return
     */
    public static Hashtable readBOMsFromAllBOMSFile(String fileName){
        Hashtable bomIDVsDescription = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";

            while ((line=br.readLine())!=null){ // skip one header line
                line = line.trim();
                if (line.equals(""))
                    continue;
                break;
            }

            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;

                StringTokenizer stkn = new StringTokenizer(line, "\t");
                stkn.nextToken(); // Avoid the first column
                String id= stkn.nextToken(); // second column is myID
                String description = stkn.nextToken();
                bomIDVsDescription.put(id, description);
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVsDescription;
    }


    /**
     *
     * @param myIDsH is a hashset of string IDs. These strings are convertable to integers
     * @return
     */
    public static int getLargestmyID(HashSet myIDsH){
        int largestID = -1;
        for (Iterator it=myIDsH.iterator(); it.hasNext();){
            String myID_S = it.next().toString();
            int myID = Integer.parseInt(myID_S);
            if (myID>largestID){
                largestID=myID;
            }
        }
        return largestID;
    }


    public static Hashtable readBOMsFromAllBOMSFileMyIDVsPartNo(String fileName){
        Hashtable bomIDVspartNoHT = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";

            while ((line=br.readLine())!=null){ // skip one header line
                line = line.trim();
                if (line.equals(""))
                    continue;
                break;
            }

            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;

                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String partNo = stkn.nextToken(); // Avoid the first column
                String id= stkn.nextToken(); // second column is myID
                String description = stkn.nextToken();
                bomIDVspartNoHT.put(id, partNo);
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVspartNoHT;
    }

    public static Hashtable readBOMsFromAllBOMSFileMyIDVsBONNO(String fileName){
        Hashtable bomIDVspartNoHT = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";

            while ((line=br.readLine())!=null){ // skip one header line
                line = line.trim();
                if (line.equals(""))
                    continue;
                break;
            }

            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;

                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String partNo = stkn.nextToken(); // Avoid the first column
                String id= stkn.nextToken(); // second column is myID
                String description = stkn.nextToken();
                stkn.nextToken();
                String bom = stkn.nextToken();
                bomIDVspartNoHT.put(id, bom);
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVspartNoHT;
    }

    public static Hashtable readBOMFile(String fileName){
        Hashtable bomIDVsDescription = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;

                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String id= stkn.nextToken();
                String description = stkn.nextToken();
                bomIDVsDescription.put(id, description);
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVsDescription;
    }

    public static Hashtable readEiVectorsDataHasHeader(String impactFactorFile){
        Hashtable bomIDVsImpactFactors = new Hashtable();
        try{
            BufferedReader brImpact = new BufferedReader(new FileReader(impactFactorFile));
            String line = "";
            while ((line=brImpact.readLine())!=null){ // skip header
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                break;
            }
            while ((line=brImpact.readLine())!=null){
                line=line.trim();
                if (line.equals("")){
                    continue;
                }
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String id= stkn.nextToken();
                String impactFactors = line.substring(id.length());
                impactFactors=impactFactors.trim();
                bomIDVsImpactFactors.put(id, impactFactors);
            }
            brImpact.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVsImpactFactors;
    }


    public static Hashtable readEiInfoAndVectors(String eiInfoFile, String impactFactorFile){
        Hashtable bomIDVsImpactFactors = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(eiInfoFile));
            BufferedReader brImpact = new BufferedReader(new FileReader(impactFactorFile));
            String line = "";
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String id= stkn.nextToken();
                String description = stkn.nextToken();
                
                String impactLine = "";
                while ((impactLine=brImpact.readLine())!=null){
                    impactLine=impactLine.trim();
                    if (impactLine.equals("")){
                        continue;
                    }else{
                        break;
                    }
                }
                bomIDVsImpactFactors.put(id, impactLine);
               
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVsImpactFactors;
    }


    public static void writeBOMFile(Hashtable partNoVsDesc, String fileName){
        Hashtable bomIDVsDescription = new Hashtable();
        try{
            BufferedWriter bw = new BufferedWriter(new FileWriter(fileName));
            for (Iterator it = partNoVsDesc.keySet().iterator(); it.hasNext(); ){
                String partno = it.next().toString();
                String desc = partNoVsDesc.get(partno).toString();
                bw.write(partno+"\t"+desc);
                bw.newLine();
                bw.flush();
            }
            bw.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
    }

    /**
     * It reads from a file with three columns. The first two columns (token+"_"+token2)
     * become the key and the last column becomes the value. The method returns
     * a hashtable. The method assumes that there is not header when hasHeader
     * is true.
     * @param fileName
     * @return
     */
    public static Hashtable readClustToEnvMapFile(String fileName, boolean hasHeader){
        Hashtable bomIDVsDescription = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            if (hasHeader)
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                break;
            }
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;

                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String level= stkn.nextToken();
                String clustID= stkn.nextToken();
                String description = stkn.nextToken();
                bomIDVsDescription.put(level+"_"+clustID, description);
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVsDescription;
    }



    public static Hashtable readClustToEnvMapFile(String fileName, boolean hasHeader, int prefix){
        Hashtable bomIDVsDescription = new Hashtable();
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            if (hasHeader)
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;
                break;
            }
            while ((line=br.readLine())!=null){
                line = line.trim();
                if (line.equals(""))
                    continue;

                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String level= stkn.nextToken();
                String clustID= stkn.nextToken();
                String eiID = stkn.nextToken();
                bomIDVsDescription.put(prefix+"_"+level+"_"+clustID, eiID);
            }
            br.close();
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return bomIDVsDescription;
    }



    //public static Hashtable


    /**
     *
     * @param fileName contains terms with synonyms
     * @return a hashtable. key = term, value = Hashset of synomous terms
     */
    public static Hashtable readSynonymsPrepareHT(String fileName){
        Hashtable termSynonymHT = new Hashtable(); // key = term, value = Hashset of synomous terms
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer (line, "\t");
                HashSet synonyms = new HashSet();
                while(stkn.hasMoreTokens()){
                    String term = stkn.nextToken().trim();
                    synonyms.add(term);
                    termSynonymHT.put(term, synonyms);
                }
            }
            br.close();
        }catch (Exception eee){
            eee.printStackTrace();
        }
        return termSynonymHT;
    }


    /**
     * returns hashtable. Key=unit, value = unit of what
     * @param fileName
     * @return
     */
    public static Hashtable readUnitPrepareHT(String fileName){
        Hashtable unitVSTypeHT = new Hashtable(); // Key=unit, value = unit of what
        try{
            BufferedReader br = new BufferedReader(new FileReader(fileName));
            String line = "";
            while ((line=br.readLine())!=null){
                line=line.trim();
                if (line.equals(""))
                    continue;
                StringTokenizer stkn = new StringTokenizer (line, "\t");
                HashSet synonyms = new HashSet();
                String unitOfWhat = stkn.nextToken().toLowerCase().trim();
                while(stkn.hasMoreTokens()){
                    String unit = stkn.nextToken().trim().toLowerCase();
                    unitVSTypeHT.put(unit, unitOfWhat);
                }
            }
            br.close();
        }catch (Exception eee){
            eee.printStackTrace();
        }
        return unitVSTypeHT;
    }


    public static Hashtable prepareTypeVsUnitsHT(Hashtable unitVSType){
        Hashtable typeVSUnitsHT = new Hashtable(); // Key=type, value = Hashset of units

        for (Iterator uit = unitVSType.keySet().iterator(); uit.hasNext(); ){
            String unit = uit.next().toString();
            String type = unitVSType.get(unit).toString();
            if (typeVSUnitsHT.contains(type)){
                HashSet units = (HashSet) typeVSUnitsHT.get(type);
                units.add(unit);
                typeVSUnitsHT.put(type, units);
            }else{
                HashSet units = new HashSet();
                units.add(unit);
                typeVSUnitsHT.put(type, units);
            }
        }
        return typeVSUnitsHT;
    }


    public static Hashtable getTFHTFromABOMString(String bomString){
        String temp = new String(bomString);
        temp=temp.replace("+/-", "+/+");
        temp=temp.replace("+/- ", "+/+");
        //System.out.println(temp);

        for (int i=0; i<temp.length();i++){ // replace . with - if the dot is not in between two digits
            if (temp.charAt(i)=='.'){
                if (i>0 && i<temp.length()-1){
                    if (Character.isDigit(temp.charAt(i-1)) && Character.isDigit(temp.charAt(i+1))){
                    }else{
                        temp=temp.substring(0,i)+"-"+temp.substring(i+1);
                    }
                }
            }
        }

        StringTokenizer stkn = new StringTokenizer(temp, ", -");


        Hashtable termHT = new Hashtable();
        while (stkn.hasMoreTokens()){
            String term = stkn.nextToken();
            term = term.trim();
            if (term.length()<2) // any term smaller than length 2 is not considered as a term
                continue;

            if (termHT.containsKey(term)){
                int f = (Integer) termHT.get(term);
                termHT.put(term, f+1);
            }else{
                termHT.put(term, 1);
            }
        }
        Hashtable ht = new Hashtable();
        for (Iterator tit=termHT.keySet().iterator(); tit.hasNext();){
            String term = tit.next().toString();
            int f = (Integer) termHT.get(term);
            if (term.contains("+/+"))
                term =term.replace("+/+", "+/-");
            ht.put(term, f);
        }
        return ht;
    }


    public static Hashtable getTFHTFromABOMString(String bomString, Hashtable synonymsHT){
        String temp = new String(bomString);
        temp=temp.replace("+/-", "+/+");
        temp=temp.replace("+/- ", "+/+");
        //System.out.println(temp);

        for (int i=0; i<temp.length();i++){ // replace . with - if the dot is not in between two digits
            if (temp.charAt(i)=='.'){
                if (i>0 && i<temp.length()-1){
                    if (Character.isDigit(temp.charAt(i-1)) && Character.isDigit(temp.charAt(i+1))){
                    }else{
                        temp=temp.substring(0,i)+"-"+temp.substring(i+1);
                    }
                }
            }
        }

        StringTokenizer stkn = new StringTokenizer(temp, ", -");


        Hashtable termHT = new Hashtable();
        while (stkn.hasMoreTokens()){
            String term = stkn.nextToken();
            term = term.trim();

            if (term.length()<2) // any term smaller than length 2 is not considered as a term
                continue;

            if (synonymsHT.containsKey(term)){
                term = ((HashSet)synonymsHT.get(term)).toString();
            }

            if (termHT.containsKey(term)){
                int f = (Integer) termHT.get(term);
                termHT.put(term, f+1);
            }else{
                termHT.put(term, 1);
            }
        }
        Hashtable ht = new Hashtable();
        for (Iterator tit=termHT.keySet().iterator(); tit.hasNext();){
            String term = tit.next().toString();
            int f = (Integer) termHT.get(term);
            if (term.contains("+/+"))
                term =term.replace("+/+", "+/-");
            ht.put(term, f);
        }
        return ht;
    }



    public static Hashtable getTFHTFromABOMString(String bomString, Hashtable synonymsHT, Hashtable unitsHT){
        String temp = new String(bomString.toLowerCase());
        temp=temp.replace("+/-", "+/+");
        temp=temp.replace("+/- ", "+/+");
        //System.out.println(temp);

        for (int i=0; i<temp.length();i++){ // replace . with - if the dot is not in between two digits
            if (temp.charAt(i)=='.'){
                if (i>0 && i<temp.length()-1){
                    if (Character.isDigit(temp.charAt(i-1)) && Character.isDigit(temp.charAt(i+1))){
                    }else{
                        temp=temp.substring(0,i)+"-"+temp.substring(i+1);
                    }
                }
            }
        }

        StringTokenizer stkn = new StringTokenizer(temp, tokenDelim);

        Hashtable termHT = new Hashtable();
        while (stkn.hasMoreTokens()){
            String term = stkn.nextToken();
            term = term.trim();

            if (term.length()<2) // any term smaller than length 2 is not considered as a term
                continue;

            if (synonymsHT.containsKey(term)){
                term = ((HashSet)synonymsHT.get(term)).toString();
            }else{
                String unitType = unitTest(term, unitsHT);
                if (unitType.equals("")==false){
                    System.out.println("Unit found: "+term+" UnitType: "+unitType);
                    term = unitType;
                }
            }

            if (termHT.containsKey(term)){
                int f = (Integer) termHT.get(term);
                termHT.put(term, f+1);
            }else{
                termHT.put(term, 1);
            }
        }
        Hashtable ht = new Hashtable();
        for (Iterator tit=termHT.keySet().iterator(); tit.hasNext();){
            String term = tit.next().toString();
            int f = (Integer) termHT.get(term);
            if (term.contains("+/+"))
                term =term.replace("+/+", "+/-");
            ht.put(term, f);
        }
        return ht;
    }



    private static Hashtable getTFHTFromABOMString_ReplaceSynWithOne(
            String bomString, Hashtable synonymsHT, Hashtable unitsHT){
        String temp = new String(bomString.toLowerCase());
        temp=temp.replace("+/-", "+/+");
        temp=temp.replace("+/- ", "+/+");
        //System.out.println(temp);

        for (int i=0; i<temp.length();i++){ // replace . with - if the dot is not in between two digits
            if (temp.charAt(i)=='.'){
                if (i>0 && i<temp.length()-1){
                    if (Character.isDigit(temp.charAt(i-1)) && Character.isDigit(temp.charAt(i+1))){
                    }else{
                        temp=temp.substring(0,i)+"-"+temp.substring(i+1);
                    }
                }
            }
        }

        StringTokenizer stkn = new StringTokenizer(temp, ", -");

        Hashtable termHT = new Hashtable();
        while (stkn.hasMoreTokens()){
            String term = stkn.nextToken();
            term = term.trim();

            if (term.length()<2) // any term smaller than length 2 is not considered as a term
                continue;

            if (synonymsHT.containsKey(term)){
                HashSet synonyms = (HashSet)synonymsHT.get(term);
                String firstSyn = synonyms.iterator().next().toString();
                term = firstSyn;
            }else{
                String unitType = unitTest(term, unitsHT);
                if (unitType.equals("")==false){
                    System.out.println("Unit found: "+term+" UnitType: "+unitType);
                    term = unitType;
                }
            }

            if (termHT.containsKey(term)){
                int f = (Integer) termHT.get(term);
                termHT.put(term, f+1);
            }else{
                termHT.put(term, 1);
            }
        }
        Hashtable ht = new Hashtable();
        for (Iterator tit=termHT.keySet().iterator(); tit.hasNext();){
            String term = tit.next().toString();
            int f = (Integer) termHT.get(term);
            if (term.contains("+/+"))
                term =term.replace("+/+", "+/-");
            ht.put(term, f);
        }
        return ht;
    }

    public static String refineBOMDescription(String desc, Hashtable synonymsHT, 
            Hashtable unitsHT, Hashtable typeVsUnitsHT){
        String refinedDesc = "";

        Hashtable tfHT = getTFHTFromABOMString_ReplaceSynWithOne(desc, synonymsHT, unitsHT);
        for (Iterator tit = typeVsUnitsHT.keySet().iterator(); tit.hasNext(); ){
            String unittype = tit.next().toString();
            if (tfHT.containsKey(unittype)){
                int f = (Integer)tfHT.get(unittype);
                tfHT.remove(unittype);
                Vector units = new Vector((HashSet)typeVsUnitsHT.get(unittype));
                String aUnit = units.get(0).toString();
                tfHT.put(aUnit, f);
            }
        }

        for (Iterator it = tfHT.keySet().iterator(); it.hasNext(); ){
            String term = it.next().toString();
            int f = (Integer)tfHT.get(term);
            for (int i=0; i<f; i++){
                refinedDesc=refinedDesc+" "+term;
            }
        }

        return refinedDesc.trim();
    }



    private static String unitTest(String term, Hashtable unitsHT){
        String unit = "";
        term=term.toLowerCase().trim();
        if (term.contains("+/+"))
            term=term.replace("+/+", "");
        if (term.contains("+/-"))
            term=term.replace("+/-", "");
        term=term.trim();
        
        HashSet allUnits = new HashSet(unitsHT.keySet());
        for (Iterator uit=allUnits.iterator(); uit.hasNext(); ){
            String u = uit.next().toString();
            if (term.contains(u))
            if (term.lastIndexOf(u)==(term.length()-u.length())){
                //System.out.println("Term: "+term+" u: "+u);
                String amount = term.substring(0, term.length()-u.length()).toString().trim();
                if (amount.equals(""))
                    return unitsHT.get(u).toString();
                
                if (amount.length()!=0){
                    if (Character.isDigit(amount.charAt(amount.length()-1))){
                        return unitsHT.get(u).toString();
                    }
                }
                /*
                String amount = term.substring(0, term.length()-u.length()).toString().trim();
                try{
                    double am = Double.parseDouble(amount);
                    return unitsHT.get(u).toString();
                }catch (Exception eee){
                }
                 */
            }
        }
        return unit;
    }


    public static Vector getHeader(String fileName){
        try{
            BufferedReader breiData = new BufferedReader(new FileReader(fileName));
            String line="";
            int numberOfFeatures = 0;
            int lineCount=0;
            Vector featuresV = new Vector();
            while ((line=breiData.readLine())!=null){
                lineCount++;
                line=line.trim();
                if (line.equals(""))
                    continue;

                // read header
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                numberOfFeatures = stkn.countTokens()-1;

                stkn.nextToken(); // the dummy corner header in the top left corner
                while (stkn.hasMoreTokens()){
                    featuresV.add(stkn.nextToken().trim());
                }

                break;
            }
            return featuresV;
        }catch (Exception eee){
            eee.printStackTrace();
        }
        return new Vector();
    }

    public static Hashtable<String, Vector<Double>> readEiVectorFile(String fileName){
        Hashtable<String, Vector<Double>> allEiVectorsHT = new Hashtable<String, Vector<Double>>();
        try{
            BufferedReader breiData = new BufferedReader(new FileReader(fileName));
            String line="";
            int numberOfFeatures = 0;
            int lineCount=0;
            Vector featuresV = new Vector();
            while ((line=breiData.readLine())!=null){
                lineCount++;
                line=line.trim();
                if (line.equals(""))
                    continue;

                // read header
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                numberOfFeatures = stkn.countTokens()-1;

                stkn.nextToken(); // the dummy corner header in the top left corner
                while (stkn.hasMoreTokens()){
                    featuresV.add(stkn.nextToken().trim());
                }

                break;
            }
            while ((line=breiData.readLine())!=null){
                lineCount++;
                line=line.trim();
                if (line.equals(""))
                    continue;
                Vector<Double> eV = new Vector<Double>();
                StringTokenizer stkn = new StringTokenizer(line, "\t");
                String eiID = stkn.nextToken();
                while (stkn.hasMoreTokens()){
                    double d = (double) Double.parseDouble(stkn.nextToken().trim());
                    eV.add(d);
                }
                if (eV.size()!=numberOfFeatures){
                    System.out.println("Wrong number of entries .... check data at line "+lineCount);
                    System.exit(-1);
                }
                allEiVectorsHT.put(eiID, eV);
            }
        }catch(Exception eee){
            eee.printStackTrace();
        }
        return allEiVectorsHT;
    }


    private static String getClassifiedNameFromTFFilesFirstToken(String name){
        String classifiedName = new String(name);
        classifiedName=classifiedName.replaceFirst("_", "/");
        return classifiedName;
    }




    public static Hashtable convertTermTFHT_To_TermWeightHT(Hashtable termTFHT){
        Hashtable termWeightHT = new Hashtable();
        try{
            for (Iterator it=termTFHT.keySet().iterator();it.hasNext();){
                String term = (String)it.next();
                int freq = Integer.parseInt(termTFHT.get(term).toString());
                termWeightHT.put(term, ((double)freq));
            }
        }catch (Exception ex){
            System.out.println(ex);
        }
        return termWeightHT;
    }



    public static String getLineOfConfigFile(int lineNo){
        String line="";
        File f=new File(Helper.CONFIG_FILE);
        if (f.exists()==false){
            setDefaultConfigFile();
        }
        try {
            BufferedReader br = new BufferedReader(new FileReader(Helper.CONFIG_FILE));
            String[] lines= new String[3];
            lines[0] = br.readLine();
            lines[1] = br.readLine();
            lines[2] = br.readLine();
            line=lines[lineNo];
            br.close();

        } catch (Exception ex) {
            System.out.println(ex);
        }
        return line;
    }

    public static void setLineOfConfigFile(String setLine, int lineNo){
        File f=new File(Helper.CONFIG_FILE);
        if (f.exists()==false){
            setDefaultConfigFile();
        }
        try {
            BufferedReader br = new BufferedReader(new FileReader(Helper.CONFIG_FILE));
            String[] lines= new String[3];
            lines[0] = br.readLine();
            lines[1] = br.readLine();
            lines[2] = br.readLine();
            lines[lineNo] = setLine;
            br.close();
            
            BufferedWriter bw = new BufferedWriter(new FileWriter(Helper.CONFIG_FILE));
            bw.write(lines[0]);
            bw.newLine();
            bw.write(lines[1]);
            bw.newLine();
            bw.write(lines[2]);
            bw.newLine();
            bw.flush();
            bw.close();
        } catch (Exception ex) {
            System.out.println(ex);
        }
        
    }


    public static void setDefaultConfigFile(){
        try {
            BufferedWriter bw = new BufferedWriter(new FileWriter(Helper.CONFIG_FILE));
            bw.write("false");
            bw.newLine();
            bw.write("5");
            bw.newLine();
            bw.write("./");
            bw.newLine();
            bw.flush();
            bw.close();
        } catch (Exception ex) {
            //Logger.getLogger(Helper.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println(ex);
        }
    }


    public static String formatNewLable(String label){
        String formatted = "";

        StringTokenizer stkn = new StringTokenizer(label, "/");
        while (stkn.hasMoreTokens()){
            String token = stkn.nextToken();
            formatted=formatted+token;
            if (stkn.hasMoreTokens()){
                formatted=formatted+"/";
            }
        }

        return formatted;
    }


    public static double eucledianDistance(Hashtable doc1TermWeightHT, Hashtable doc2TermWeightHT){
        double distance = 0;

        Set doc1Terms = doc1TermWeightHT.keySet();
        Iterator doc1IT = doc1Terms.iterator();

        while (doc1IT.hasNext()){
            String term = doc1IT.next().toString();
            if (doc2TermWeightHT.containsKey(term)){
                double toBeAdded = Double.parseDouble( doc1TermWeightHT.get(term).toString())-
                                   Double.parseDouble( doc2TermWeightHT.get(term).toString());
                toBeAdded = toBeAdded*toBeAdded;
                distance = distance+ toBeAdded;
            }else{
                double toBeAdded = Double.parseDouble( doc1TermWeightHT.get(term).toString());
                toBeAdded = toBeAdded*toBeAdded;
                distance = distance+ toBeAdded;
            }
        }

        Set doc2Terms = doc2TermWeightHT.keySet();
        Iterator doc2IT = doc2Terms.iterator();

        while (doc2IT.hasNext()){
            String term = doc2IT.next().toString();
            if (doc1TermWeightHT.containsKey(term)==false){
                double toBeAdded = Double.parseDouble( doc2TermWeightHT.get(term).toString());
                toBeAdded = toBeAdded*toBeAdded;
                distance = distance+ toBeAdded;
            }
        }

        distance = Math.sqrt(distance);

        return distance;
    }

}
