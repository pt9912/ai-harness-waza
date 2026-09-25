# syntax=docker/dockerfile:1

ARG WAZA_VERSION=v0.38.7
ARG REGELWERK_URL=https://github.com/pt9912/ai-harness-course/releases/download/v6.9.0/lab-regelwerk.zip
# SHA256 des ZIP beim ersten Download ermittelt (kein unabhaengig veroeffentlichter Wert geprueft).
ARG REGELWERK_SHA256=8a4e0aaf597a9c67404cb7a350a6fba992f0c98195e011e025c073660ee55cce

# ---- Regelwerk-Bundle laden und verifizieren ---------------------------------
FROM alpine:3.21 AS regelwerk-fetch
ARG REGELWERK_URL
ARG REGELWERK_SHA256
RUN apk add --no-cache curl unzip
WORKDIR /out
RUN curl -fsSL -o /tmp/lab-regelwerk.zip "$REGELWERK_URL" \
 && echo "${REGELWERK_SHA256}  /tmp/lab-regelwerk.zip" | sha256sum -c - \
 && unzip -q /tmp/lab-regelwerk.zip -d /out

# ---- waza aus dem Quellcode bauen (LFS-Artefakte: kein `go install`) --------
FROM golang:1.26-bookworm AS waza-build
ARG WAZA_VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends git git-lfs ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN git lfs install \
 && git clone --depth 1 --branch "${WAZA_VERSION}" https://github.com/microsoft/waza.git /src
WORKDIR /src
RUN git lfs pull \
 && CGO_ENABLED=0 go build -o /out/waza ./cmd/waza

# ---- Laufzeit-Image ----------------------------------------------------------
FROM debian:bookworm-slim AS runtime
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git python3 python-is-python3 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=waza-build /out/waza /usr/local/bin/waza
ENV WAZA_NO_UPDATE_CHECK=1
WORKDIR /workspace
ENTRYPOINT ["waza"]

# ---- Projekt-Image: Skills und Evals eingebacken (kein Bind-Mount) -----------
FROM runtime AS project
COPY .waza.yaml /workspace/.waza.yaml
COPY skills/ /workspace/skills/
COPY evals/ /workspace/evals/
# Regelwerk + Templates kommen aus dem verifizierten ZIP, nicht aus dem Repo.
COPY --from=regelwerk-fetch /out/regelwerk/ /workspace/skills/ai-harness-regelwerk/regelwerk/
COPY --from=regelwerk-fetch /out/templates/ /workspace/skills/ai-harness-regelwerk/templates/
RUN mkdir -p /workspace/results
