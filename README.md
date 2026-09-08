# make-proxy

App-agnostic TLS reverse proxy for the xebro dev setup (`make-core`).
nginx terminates HTTPS at `https://${XO_SERVER_NAME}` and redirects HTTP with
a 301. Certificate and `/etc/hosts` entry are created automatically by
`core/generate_certs.sh` during `docker.up` (mkcert preferred, openssl as
fallback).

## Principle: bundles bring their own route

The proxy knows nothing about applications. App bundles drop a route snippet
into `docker/config/proxy/` during `<bundle>.install`
(`NN-<name>.conf.template`, numeric prefix = ordering). The nginx image
renders the templates via envsubst — environment variables like
`${XO_SHOP_PATH_PREFIX}` are available (`.env` + `.env.local` are passed into
the container), nginx runtime variables (`$host`, `$request_uri`, …) are left
untouched.

Example (`90-wordpress.conf.template`):

```nginx
location / {
    proxy_pass http://wordpress:80;
    proxy_set_header Host              $host;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Port  ${XO_PROXY_HTTPS_PORT};
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
}
```

The `compose.<module>.yaml` overlays (wordpress, shopware) add `depends_on`
automatically when the respective module is present in the project
(`make core.generate`).

## Targets

```bash
make proxy.routes    # list registered route snippets
make proxy.test      # check redirect + HTTPS reachability
make proxy.restart   # load new snippets
make proxy.logs
```

## Environment variables

Seeded into `.env` (existing values are kept):
`XO_SERVER_NAME` (default `${XO_PROJECT_NAME}.test`), `XO_PROXY_HTTP_PORT`
(80), `XO_PROXY_HTTPS_PORT` (443). Override occupied ports in `.env.local` —
the port then also belongs into the app URLs.

## License

MIT License, Copyright (c) 2026 xebro GmbH. See [LICENSE](./LICENSE).
