FROM ubuntu:15.10
MAINTAINER MadKatz

# Cache Buster
ENV CREATED_AT 2016-03-31T12:40:00

# explicitly set user/group IDs
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

RUN mkdir /docker-entrypoint-initdb.d

RUN wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
    apt-key add -

ENV PG_MAJOR 9.4
ENV PG_VERSION 9.4.6-1.pgdg15.10+1
ENV POSTGIS_MAJOR 2.2

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ wily-pgdg main' > /etc/apt/sources.list.d/pgdg.list

# Install Postgre, PostGIS and GDAL using APT
RUN apt-get update \
	&& apt-get install -y postgresql-common \
	&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
	&& apt-get install -y \
		postgresql-$PG_MAJOR \
		postgresql-contrib-$PG_MAJOR \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
		gdal-bin \
	&& rm -rf /var/lib/apt/lists/*


# make the sample config easier to munge (and "correct by default")
RUN mv -v /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample /usr/share/postgresql/ \
	&& ln -sv ../postgresql.conf.sample /usr/share/postgresql/$PG_MAJOR/ \
	&& sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
