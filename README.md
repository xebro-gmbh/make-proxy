# make-proxy

App-agnostischer TLS-Reverse-Proxy für das xebro-Dev-Setup (`make-core`).
nginx terminiert HTTPS unter `https://${XO_SERVER_NAME}` und leitet HTTP per
301 um. Zertifikat und `/etc/hosts`-Eintrag erzeugt `core/generate_certs.sh`
automatisch in `docker.up` (mkcert bevorzugt, sonst openssl).

## Prinzip: Bundles bringen ihre Route mit

Der Proxy kennt keine Anwendungen. App-Bundles legen bei `<bundle>.install`
ein Route-Snippet in `docker/config/proxy/` ab (`NN-<name>.conf.template`,
Nummernpräfix = Ordnung). Das nginx-Image rendert die Templates per envsubst —
Env-Variablen wie `${XO_SHOP_PATH_PREFIX}` stehen zur Verfügung (`.env` +
`.env.local` werden in den Container gereicht), nginx-Laufzeitvariablen
(`$host`, `$request_uri`, …) bleiben unangetastet.

Beispiel (`90-wordpress.conf.template`):

```nginx
location / {
    proxy_pass http://wordpress:80;
    proxy_set_header Host              $host;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Port  ${XO_PROXY_HTTPS_PORT};
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
}
```

Die `compose.<modul>.yaml`-Overlays (wordpress, shopware) ergänzen
`depends_on` automatisch, wenn das jeweilige Modul im Projekt liegt
(`make core.generate`).

## Targets

```bash
make proxy.routes    # registrierte Route-Snippets anzeigen
make proxy.test      # Redirect + HTTPS-Erreichbarkeit prüfen
make proxy.restart   # neue Snippets laden
make proxy.logs
```

## Environment-Variablen

Seeded in `.env` (bestehende Werte bleiben erhalten):
`XO_SERVER_NAME` (Default `${XO_PROJECT_NAME}.test`), `XO_PROXY_HTTP_PORT`
(80), `XO_PROXY_HTTPS_PORT` (443). Belegte Ports in `.env.local`
überschreiben — dann gehört der Port auch in die App-URLs.

## License

MIT License, Copyright (c) 2026 xebro GmbH. See [LICENSE](./LICENSE).
