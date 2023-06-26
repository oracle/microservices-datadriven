// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.transfer.servlet.filter;

import org.springframework.boot.autoconfigure.web.servlet.DispatcherServletAutoConfiguration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import javax.servlet.DispatcherType;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;

@Component
@SuppressWarnings("ConfigurationProperties")
@ConfigurationProperties("spring.mvc")
public class SpringMvcPrefixEnforcerFilter implements Filter {
    private static final String SPRING_MVC_SERVLET = DispatcherServletAutoConfiguration.DEFAULT_DISPATCHER_SERVLET_BEAN_NAME;
    private ServletContext servletContext;
    private Set<String> enforcedPrefixes;

    @Override
    public void init(FilterConfig filterConfig) {
        servletContext = filterConfig.getServletContext();
    }

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain) throws IOException,
            ServletException {
        if (request.getDispatcherType() == DispatcherType.FORWARD) {
            chain.doFilter(request, response);
            return;
        }

        if (request instanceof HttpServletRequest && response instanceof HttpServletResponse) {
            doHttpFilter((HttpServletRequest) request,
                    (HttpServletResponse) response,
                    chain);
            return;
        }

        chain.doFilter(request, response);
    }

    private void doHttpFilter(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        if (enforcedPrefixes.stream().anyMatch(request.getRequestURI()::startsWith)) {
            servletContext.getNamedDispatcher(SPRING_MVC_SERVLET)
                    .forward(request, response);
            return;
        }
        chain.doFilter(request, response);
    }

    public void setEnforcedPrefixes(Set<String> enforcedPrefixes) {
        this.enforcedPrefixes = enforcedPrefixes;
    }
}