package com.example.queuereader.client;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import org.springframework.stereotype.Component;

import com.oracle.bmc.ConfigFileReader;
import com.oracle.bmc.aivision.AIServiceVisionClient;
import com.oracle.bmc.aivision.model.AnalyzeImageDetails;
import com.oracle.bmc.aivision.model.ImageClassificationFeature;
import com.oracle.bmc.aivision.model.ObjectStorageImageDetails;
import com.oracle.bmc.aivision.requests.AnalyzeImageRequest;
import com.oracle.bmc.aivision.responses.AnalyzeImageResponse;
import com.oracle.bmc.auth.AuthenticationDetailsProvider;
import com.oracle.bmc.auth.ConfigFileAuthenticationDetailsProvider;

@Component
public class AIVisionClient {

    public AnalyzeImageResponse analyzeImage(String imageUrl) {
        ConfigFileReader.ConfigFile configFile = null;
        try {
            configFile = ConfigFileReader.parseDefault();
        } catch (IOException ioe) {
            return null;
        }
        AuthenticationDetailsProvider provider = new ConfigFileAuthenticationDetailsProvider(configFile);
        AIServiceVisionClient client = AIServiceVisionClient.builder().build(provider);

        AnalyzeImageDetails analyzeImageDetails = AnalyzeImageDetails.builder()
            .compartmentId("ocid1.compartment.oc1..aaaaaaaaulnuhmwvxfhcj46mtomr64ublwg6unsocdsmj5yvkujach6zewla")
            .features(new ArrayList<>(Arrays.asList(ImageClassificationFeature.builder().build())))
            .image(ObjectStorageImageDetails.builder()
                .bucketName("tolldemo")
                .namespaceName("maacloud")
                .objectName("cars-images/htsngg9tpc-2/" + imageUrl).build())
            .build();

        AnalyzeImageRequest analyzeImageRequest = AnalyzeImageRequest.builder()
            .analyzeImageDetails(analyzeImageDetails)
            .opcRequestId("buggaluggs").build();

        AnalyzeImageResponse response = client.analyzeImage(analyzeImageRequest);

        return response;

    }

}
