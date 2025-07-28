package org.acme;

import java.util.Set;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;
import org.jboss.resteasy.annotations.jaxrs.HeaderParam;
import org.jboss.resteasy.annotations.jaxrs.PathParam;
import org.jboss.resteasy.annotations.jaxrs.QueryParam;

import io.vertx.core.json.JsonObject;

@Path("/api/v2.2/discovery")
@RegisterRestClient
public interface CryostatService {

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    JsonObject register(RegistrationInfo registrationInfo, @HeaderParam("Authorization") String auth);

    @DELETE
    @Produces(MediaType.APPLICATION_JSON)
    @Path("{id}")
    void deregister(@PathParam String id, @QueryParam String token);

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Path("{id}")
    void update(@PathParam String id, @QueryParam String token, Set<Node> subtree);

}
