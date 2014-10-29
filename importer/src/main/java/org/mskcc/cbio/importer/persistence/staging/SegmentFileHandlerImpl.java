package org.mskcc.cbio.importer.persistence.staging;

import com.google.common.base.Function;
import com.google.common.collect.Lists;
import com.google.inject.internal.Preconditions;
import org.apache.log4j.Logger;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import static java.nio.file.StandardOpenOption.APPEND;
import static java.nio.file.StandardOpenOption.CREATE;
import static java.nio.file.StandardOpenOption.DSYNC;

/**
 * Created by criscuof on 10/28/14.
 */
public class SegmentFileHandlerImpl extends TsvStagingFileHandler implements SegmentFileHandler{
    private final static Logger logger = Logger.getLogger(SegmentFileHandlerImpl.class);
    private static final List<String> columnHeadings = Lists.newArrayList("ID", "chrom","loc.start", "loc.end", "num.mark", "seg.means");


    public SegmentFileHandlerImpl() {}

    /*
   Implementation of interface method to associate a staging file with segment data
   and to initialize the file if it is new
     */

    @Override
    public void registerSegmentStagingFile(Path segmentFilePath) {
        Preconditions.checkArgument(null != segmentFilePath,
                "A Path object is required to write out the segment data staging file");
        super.registerStagingFile(segmentFilePath, columnHeadings);
    }



    @Override
    public void removeDeprecatedSamplesFromSegmentStagingFiles(String sampleIdColumnName, Set<String> deprecatedSampleSet) {
        super.removeDeprecatedSamplesFomMAFStagingFiles(sampleIdColumnName, deprecatedSampleSet);
    }

    @Override
    public void transformImportDataToStagingFile(List aList, Function transformationFunction) {
        super.transformImportDataToStagingFile(aList, transformationFunction);

    }
}