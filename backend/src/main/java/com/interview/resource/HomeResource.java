package com.interview.resource;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeResource {

    // Simple home page handler. It returns the hostname and host address of the server.
    @RequestMapping("/")
    public String index() {
        String hostName = "", hostAddress = "";

        try {
            hostName = java.net.InetAddress.getLocalHost().getHostName();
            hostAddress = java.net.InetAddress.getLocalHost().getHostAddress();
        } catch (java.net.UnknownHostException e) {
            e.printStackTrace();
        }

        return String.format("Welcome to '%s' (%s) home!\n", hostName, hostAddress);
    }
}