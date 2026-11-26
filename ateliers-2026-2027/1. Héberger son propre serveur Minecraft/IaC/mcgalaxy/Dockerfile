
FROM alpine:3.20 AS telechargement
RUN apk add --no-cache curl unzip \
 && mkdir -p /opt/mcgalaxy \
 && curl -fsSL https://cdn.classicube.net/client/mcg/release/MCGalaxy.zip -o /tmp/mcgalaxy.zip \
 && unzip -q /tmp/mcgalaxy.zip -d /tmp/mcg \
 && src="$(dirname "$(find /tmp/mcg -name MCGalaxyCLI.exe | head -n 1)")" \
 && cp -r "$src"/. /opt/mcgalaxy/ \
 && test -f /opt/mcgalaxy/MCGalaxyCLI.exe \
 && chmod -R a+rX /opt/mcgalaxy

FROM mono:6.12
COPY --from=telechargement /opt/mcgalaxy /opt/mcgalaxy
COPY server.properties /opt/mcgalaxy/properties/server.properties
COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh && chmod -R a+rX /opt/mcgalaxy
ENV HOME=/data
WORKDIR /data
EXPOSE 25565
ENTRYPOINT ["/entrypoint.sh"]
