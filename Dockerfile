FROM reactivefinance/idris:latest as builder
ARG VERSION
ARG CHEZ_SCHEME_VERSION

RUN apk add --no-cache \
  git \
  make \
  gcc \
  util-linux-dev \
  ncurses-dev

RUN mkdir -p /usr/src
WORKDIR /usr/src
RUN git clone https://github.com/cisco/ChezScheme.git --branch $CHEZ_SCHEME_VERSION
RUN git clone https://github.com/edwinb/Idris2.git
ENV PREFIX /usr/local
WORKDIR /usr/src/ChezScheme
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h
RUN ./configure --installprefix=$PREFIX --threads --disable-x11 && make install
WORKDIR /usr/src/Idris2
# Hack: the network library has ${HOME}/.idris2 hard-coded instead of using PREFIX
RUN mkdir -p ${HOME}/.idris2/idris2/network/lib
#RUN make install
# Chez Scheme tests fail - we therefore replace make install by the following
RUN make idris2 libs install-exec install-libs

FROM alpine:latest
ARG BUILD_DATE
ARG VCS_REF
ARG GIT_COMMIT=unspecified
LABEL org.label-schema.version=$VERSION
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vcs-url=https://github.com/reactivefinance/idris2-docker
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL git_commit=$GIT_COMMIT
LABEL maintainer="Patrick Haener <contact@haenerconsulting.com>"

RUN apk add --no-cache \
  libffi \
  ncurses \
  musl \
  zlib \
  musl-dev \
  gmp-dev \
  gcc \
  libuuid

COPY --from=builder /usr/local /usr/local
VOLUME /home/idris
WORKDIR /home/idris
CMD ["/usr/local/bin/idris2"]
