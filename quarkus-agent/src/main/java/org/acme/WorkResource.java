package org.acme;

import java.math.BigInteger;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Queue;
import java.util.Random;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.ForkJoinPool;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/work")
public class WorkResource {

    static final long MAX = 1_000_000L;

    Random random;
    ExecutorService executor = ForkJoinPool.commonPool();

    public WorkResource() {
        try {
            this.random = SecureRandom.getInstanceStrong();
        } catch (NoSuchAlgorithmException nsae) {
            this.random = new Random();
        }
    }

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public List<Long> get() {
        long seed = this.random.nextLong(MAX);
        Queue<BigInteger> q = new ConcurrentLinkedQueue<>();
        for (long i = 0; i < seed; i++) {
            final long fi = i;
            executor.submit(() -> p(q, BigInteger.valueOf(fi)));
        }
        List<Long> l = new ArrayList<>(q.size());
        q.stream().map(BigInteger::longValue).forEach(l::add);
        Collections.sort(l);
        return l;
    }

    void p(Queue<BigInteger> q, BigInteger v) {
        if (isPrime(v)) {
            q.add(v);
        }
    }

    boolean isPrime(BigInteger v) {
        if (v.compareTo(BigInteger.TWO) <= 0) {
            return false;
        }
        List<BigInteger> factors = new ArrayList<>();
        BigInteger bound = v.sqrt().add(BigInteger.ONE);
        for (long i = 2; i < bound.longValue(); i++) {
            BigInteger b = BigInteger.valueOf(i);
            if (v.mod(b).equals(BigInteger.ZERO)) {
                factors.add(b);
            }
        }
        return factors.isEmpty();
    }

}
