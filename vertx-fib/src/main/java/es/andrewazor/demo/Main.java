package es.andrewazor.demo;

import io.vertx.core.Vertx;

class Main {
    public static void main(String[] args) {
        Vertx.vertx().deployVerticle(App.class.getName());
    }
}
