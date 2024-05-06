package com.example.queuereader.client;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.springframework.stereotype.Component;

import com.oracle.bmc.aivision.AIServiceVisionClient;
import com.oracle.bmc.aivision.model.AnalyzeImageDetails;
import com.oracle.bmc.aivision.model.ImageClassificationFeature;
import com.oracle.bmc.aivision.model.Label;
import com.oracle.bmc.aivision.model.ObjectStorageImageDetails;
import com.oracle.bmc.aivision.requests.AnalyzeImageRequest;
import com.oracle.bmc.aivision.responses.AnalyzeImageResponse;
import com.oracle.bmc.auth.InstancePrincipalsAuthenticationDetailsProvider;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
public class AIVisionClient {

    public String analyzeImage(String imageUrl) {
        // ConfigFileReader.ConfigFile configFile = null;
        // try {
        //     configFile = ConfigFileReader.parseDefault();
        // } catch (IOException ioe) {
        //     return null;
        // }
        // AuthenticationDetailsProvider provider = new ConfigFileAuthenticationDetailsProvider(configFile);
        final InstancePrincipalsAuthenticationDetailsProvider provider;
        try {
            provider = InstancePrincipalsAuthenticationDetailsProvider.builder().build();
        } catch (Exception e) {
            log.error("Could not create Instance Principal Auth Provider", e);
            return null;
        }

        AIServiceVisionClient client = AIServiceVisionClient.builder().build(provider);

        String objectName = "cars-images/" + imageUrl;
        log.info("object name: " + objectName);

        AnalyzeImageDetails analyzeImageDetails = AnalyzeImageDetails.builder()
            .compartmentId("ocid1.compartment.oc1..aaaaaaaaulnuhmwvxfhcj46mtomr64ublwg6unsocdsmj5yvkujach6zewla")
            .features(new ArrayList<>(Arrays.asList(ImageClassificationFeature.builder()
                .modelId("ocid1.aivisionmodel.oc1.iad.amaaaaaaq33dybyan4fwde3syguv3dpp3alpryjs4z7phur4gfhhdr7l3c3q").build())))
            .image(ObjectStorageImageDetails.builder()
                .bucketName("tolldemo")
                .namespaceName("maacloud")
                .objectName(objectName).build())
            .build();

        AnalyzeImageRequest analyzeImageRequest = AnalyzeImageRequest.builder()
            .analyzeImageDetails(analyzeImageDetails)
            .opcRequestId("buggaluggs").build();

        log.info("request: " + analyzeImageRequest);
        AnalyzeImageResponse response = client.analyzeImage(analyzeImageRequest);

        List<Label> labels = response.getAnalyzeImageResult().getLabels();
        if (labels.isEmpty()) {
            return null;
        }
        return labels.get(0).getName() + "," + labels.get(0).getConfidence();

    }

}
