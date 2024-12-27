FROM python:3.10.13-bullseye AS base

ARG BUILD_DATE

ARG APP_VERSION

LABEL org.label-schema.build-date=$BUILD_DATE

LABEL version=$APP_VERSION

ENV DAGSTER_HOME=/opt/dagster/dagster_home

WORKDIR /app

COPY README.md README.md

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev graphviz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/downloaded_packages \
    && mkdir -p $DAGSTER_HOME 

COPY dagster.yaml workspace.yaml repo.py $DAGSTER_HOME

FROM base AS builder

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    PATH="/root/.local/bin:$PATH"

COPY pyproject.toml poetry.lock ./

RUN curl -sSL https://install.python-poetry.org | python3 -\
    && poetry install --no-root \
    && rm -rf $POETRY_CACHE_DIR \
    && curl -sSL https://install.python-poetry.org | python3 - --uninstall 

FROM base AS runtime

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

RUN chmod -R 755 /app \
    && chmod -R 755 $DAGSTER_HOME

WORKDIR $DAGSTER_HOME

EXPOSE 3000

EXPOSE 4000