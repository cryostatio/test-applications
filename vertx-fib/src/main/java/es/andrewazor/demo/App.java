package es.andrewazor.demo;

import java.math.BigInteger;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpHeaders;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.StaticHandler;

public class App extends AbstractVerticle {

    @Override
    public void start() {
        int port = getHttpPortEnvVar();

        getVertx().createHttpServer(
                new HttpServerOptions()
                .setPort(port)
                )
            .requestHandler(configureRouter(getVertx()))
            .listen();
    }

    static Router configureRouter(Vertx vertx) {
        Router router = Router.router(vertx);
        router
            .get("/fib/:id")
            .blockingHandler(ctx -> {
                ctx.response().putHeader(HttpHeaders.CONTENT_TYPE, "text/plain");
                String id = ctx.pathParam("id");
                try {
                    ctx.response().end(fib(new BigInteger(id)).toString());
                } catch (IllegalArgumentException e) {
                    e.printStackTrace();
                    ctx.fail(400, e);
                } catch (Exception e) {
                    e.printStackTrace();
                    ctx.fail(500, e);
                }
            });
        router.get("/*")
            .handler(StaticHandler.create(App.class.getPackageName().replaceAll("\\.", "/")));
        return router;
    }

    static BigInteger fib(BigInteger i) {
        if (i.signum() < 0) {
            throw new IllegalArgumentException(String.format("%s is less than zero", i.toString()));
        }
        if (BigInteger.ZERO.equals(i) || BigInteger.ONE.equals(i)) {
            return i;
        }
        BigInteger n1 = fib(i.subtract(BigInteger.ONE));
        BigInteger n2 = fib(i.subtract(BigInteger.TWO));
        return n1.add(n2);
    }

    static int getHttpPortEnvVar() {
        try {
            return Integer.parseInt(System.getenv("HTTP_PORT"));
        } catch(NumberFormatException e) {
            return 8080;
        }
    }

}
