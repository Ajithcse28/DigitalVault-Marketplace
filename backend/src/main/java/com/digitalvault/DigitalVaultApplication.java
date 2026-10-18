package com.digitalvault;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@OpenAPIDefinition(
    info = @Info(
        title = "DigitalVault Marketplace REST API",
        version = "1.0.0",
        description = "Secure REST API for Digital Products Sales, Razorpay Payment Verification, and Authorized Asset Delivery",
        contact = @Contact(name = "DigitalVault Engineering", email = "support@digitalvault.in")
    )
)
public class DigitalVaultApplication {
    public static void main(String[] args) {
        SpringApplication.run(DigitalVaultApplication.class, args);
    }
}
