package org.acme;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/stream")
public class StreamResource {

    @GET
    @Produces(MediaType.APPLICATION_OCTET_STREAM)
    public InputStream hello() {
        return new ByteArrayInputStream("Hello Streams".getBytes());
    }
}
