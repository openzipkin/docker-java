# zipkin-docker-jre rationale

## Why do we link /bin/sh to BusyBox?

It is possible to override some Docker commands to use something besides
`/bin/sh`, notably to allow use of `/busybox/sh` included in Alpine and
Distroless debug images:

Ex.
```diff
-ENTRYPOINT ["/busybox/sh", "run.sh"]
+ENTRYPOINT run.sh
```

However, there are some inconsistencies. For example, it is possible to override
docker-compose health-check to use a different shell, but not in Dockerfile
syntax (always invokes with `/bin/sh -c`).

These nuances are very hard to hunt down and require experience to figure out.
Meanwhile, there's little security given by intentionally not making `/bin/sh`
work when `/bin/busybox` exists. To allow the least configuration distration,
and the highest amount of commands to work, we link `/bin/sh` to BusyBox
regardless of whether we are using Alpine (which does this by default) or
Distroless, which doesn't.
