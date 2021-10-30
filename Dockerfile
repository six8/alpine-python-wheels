FROM quay.io/pypa/musllinux_1_1_x86_64:2021-09-19-a5ef179

# Install required OS dependencies
RUN apk add --no-cache \
    libffi-dev \
    mariadb-connector-c-dev \
    libressl-dev \
    libressl-dev>=2.6.4-r2 \
    libxslt-dev \
    curl-dev

# Use an older version of setuptools because >=58 no longer supports packages that
# have 'use_2to3'. Some of the requirements still do.
# https://setuptools.pypa.io/en/latest/history.html#v58-0-0
RUN for py_bin in /opt/python/cp37-cp37m/bin; do "${py_bin}/pip" install --upgrade 'setuptools<58'; done
COPY build_wheels.sh /build_wheels.sh

CMD ["/build_wheels.sh"]