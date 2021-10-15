FROM quay.io/pypa/musllinux_1_1_x86_64:2021-09-19-a5ef179

# Install required OS dependencies
RUN apk add --no-cache \
    libffi-dev \
    mariadb-connector-c-dev \
    libressl-dev

COPY build_wheels.sh /build_wheels.sh

CMD ["/build_wheels.sh"]