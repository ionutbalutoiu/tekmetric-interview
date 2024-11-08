package com.interview.resource;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthCheckResource {

    // To be used for readiness probe
    @RequestMapping("/api/health_check")
    public String health() {
        // NOTE: It should contain logic to check if the application is ready
        // to serve traffic.

        return "OK";
    }

    // To be used for liveness probe
    @RequestMapping("/api/ping")
    public String ping() {
        // NOTE: This is a simple endpoint to check if the application is alive (up and running).

        return "pong";
    }
}