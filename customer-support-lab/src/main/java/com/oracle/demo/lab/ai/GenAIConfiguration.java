package com.oracle.demo.lab.ai;

import com.oracle.bmc.auth.BasicAuthenticationDetailsProvider;
import com.oracle.bmc.auth.ConfigFileAuthenticationDetailsProvider;
import com.oracle.bmc.generativeaiinference.GenerativeAiInference;
import com.oracle.bmc.generativeaiinference.GenerativeAiInferenceClient;
import com.oracle.bmc.generativeaiinference.model.EmbedTextDetails;
import com.oracle.bmc.generativeaiinference.model.OnDemandServingMode;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import java.io.IOException;
import java.nio.file.Paths;

@Configuration
@Profile("ai")
public class GenAIConfiguration {
    @Value("${oci.compartment}")
    private String compartmentId;

    @Value("${oci.embeddingModelID}")
    private String embeddingModelId;

    @Bean
    public BasicAuthenticationDetailsProvider authProvider() throws IOException {
        // Create an OCI authentication provider using the default local
        // config file.
        return new ConfigFileAuthenticationDetailsProvider(
                Paths.get(System.getProperty("user.home"), ".oci", "config")
                        .toString(),
                "DEFAULT"
        );
    }

    @Bean
    public GenerativeAiInference generativeAiInferenceClient(BasicAuthenticationDetailsProvider authProvider) {
        return GenerativeAiInferenceClient.builder()
                .build(authProvider);
    }

    @Bean
    @Qualifier("embedServingMode")
    public OnDemandServingMode embeddingModelServingMode() {
        // Create a chat service for an On-Demand OCI GenAI chat model.
        return OnDemandServingMode.builder()
                .modelId(embeddingModelId)
                .build();
    }

    @Bean
    public EmbedTextDetails.Truncate truncate() {
        return EmbedTextDetails.Truncate.End;
    }
}
