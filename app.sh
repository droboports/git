### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf src/openssl-1.0.2-parallel-build.patch "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 < openssl-1.0.2-parallel-build.patch
./Configure --prefix="${DEPS}" \
  --openssldir="${DEST}/etc/ssl" \
  --with-zlib-include="${DEPS}/include" \
  --with-zlib-lib="${DEPS}/lib" \
  shared zlib-dynamic threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -v -a "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -v -aR "${DEPS}/lib"/* "${DEST}/lib/"
rm -v -fr "${DEPS}/lib"
rm -v "${DEST}/lib"/*.a
sed -i -e "s|^exec_prefix=.*|exec_prefix=${DEST}|g" "${DEST}/lib/pkgconfig/openssl.pc"
popd
}

### CURL ###
_build_curl() {
local VERSION="7.41.0"
local FOLDER="curl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://curl.haxx.se/download/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --disable-debug --disable-curldebug --with-zlib="${DEPS}" --with-ssl="${DEPS}" --with-random --with-ca-bundle="${DEST}/etc/ssl/certs/ca-certificates.crt" --enable-ipv6
make
make install
popd
}

### EXPAT ###
_build_expat() {
local VERSION="2.1.0"
local FOLDER="expat-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://switch.dl.sourceforge.net/project/expat/expat/2.1.0/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host=arm-none-linux-gnueabi --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### GIT ###
_build_git() {
local VERSION="2.3.2"
local FOLDER="git-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://www.kernel.org/pub/software/scm/git/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host=arm-none-linux-gnueabi --prefix="${DEST}" --mandir="${DEST}/man" --with-openssl --with-curl --with-expat ac_cv_fread_reads_directories=no ac_cv_snprintf_returns_bogus=no ac_cv_lib_curl_curl_global_init=yes
make
make install
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_openssl
  _build_curl
  _build_expat
  _build_git
  _package
}
