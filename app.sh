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
rm -vf "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2g"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -vfa "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### CURL ###
_build_curl() {
local VERSION="7.47.1"
local FOLDER="curl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://curl.haxx.se/download/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-zlib="${DEPS}" \
  --with-ssl="${DEPS}" \
  --with-ca-bundle="${DEST}/etc/ssl/certs/ca-certificates.crt" \
  --disable-debug --disable-curldebug --with-random --enable-ipv6
make
make install
popd
}

### EXPAT ###
_build_expat() {
local VERSION="2.1.0"
local FOLDER="expat-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/expat/files/expat/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### SVN::CORE ###
_build_svn_core() {
if [ ! -d "${DROBOAPPS}/perl5" ]; then
  echo "Please cross-compile perl5 before git. See https://github.com/droboports/perl5"
  exit 1
fi

local VERSION="1.8.11.0"
local FOLDER="Alien-SVN-v${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://search.cpan.org/CPAN/authors/id/M/MS/MSCHWERN/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"
"${DROBOAPPS}/perl5/bin/perl" Build.PL
# --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" PERL=/mnt/DroboFS/Shares/DroboApps/perl5/bin/perl
popd
}

### GIT ###
_build_git() {
local VERSION="2.7.2"
local FOLDER="git-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://www.kernel.org/pub/software/scm/git/${FILE}"
#export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEST}" \
  --mandir="${DEST}/man" \
  --with-openssl --with-curl --with-expat \
  ac_cv_fread_reads_directories=no ac_cv_snprintf_returns_bogus=no ac_cv_lib_curl_curl_global_init=yes
# --with-perl="${DROBOAPPS}/perl5/bin/perl" --with-python="${DROBOAPPS}/python2/bin/python"
make
make install
#mv -v "${DEST}/share/man" "${DEST}/man"
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_openssl
  _build_curl
  _build_expat
#  _build_svn_core
  _build_git
  _package
}
