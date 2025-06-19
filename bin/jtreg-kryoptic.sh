#!/bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
# This code is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 only, as
# published by the Free Software Foundation.
#
# This code is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details (a copy is included in the LICENSE file that
# accompanied this code).
#
# You should have received a copy of the GNU General Public License version
# 2 along with this work; if not, write to the Free Software Foundation,
# Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
# or visit www.oracle.com if you need additional information or have any
# questions.
#

set -o errexit
set -o xtrace

JDK_BIN="$(realpath "$(dirname "$0")")"
JDK="$(realpath "${JDK_BIN}"/..)"
ROOT="$(realpath "${JDK}"/..)"

# Initialize Kryoptic token.
export KRYOPTIC="${ROOT}"
# Note intentional extra "P" in "TMPPDIR".
export TMPPDIR="${ROOT}"/kryoptic-configuration
export TESTSSRCDIR="${ROOT}"/pkcs11-provider/tests
export TOKDIR="${TMPPDIR}"
export PINVALUE="fo0m4nchU"
mkdir --parents "${TMPPDIR}"
title() { echo "$@"; }
# Needed so that kryoptic.nss-init.sh can be rerun without error.
rm --force "${TMPPDIR}"/cert9.db
# Clean up other files too.
rm --force "${TMPPDIR}"/key4.db "${TMPPDIR}"/kryoptic.conf "${TMPPDIR}"/libkryoptic_pkcs11.so
source "${TESTSSRCDIR}"/kryoptic.nss-init.sh

# PKCS11Test.java does a depth-first search for the first file with
# this name under jdk.test.lib.artifacts.nsslib-linux_x64.  It finds
# kryoptic/target/debug/deps/libkryoptic_pkcs11.so.  This fails with:
#
# | thread '<unnamed>' panicked at ossl/src/fips.rs:706:5:
# | assertion failed: ret == 1
# | note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
# | fatal runtime error: failed to initiate panic, error 5
#
# because hmacify.sh is only run on kryoptic/target/debug/libkryoptic_pkcs11.so.
#
# To protect against this, copy libkryoptic_pkcs11.so to
# kryoptic-configuration and point
# jdk.test.lib.artifacts.nsslib-linux_x64 there.
cp "${P11LIB}" "${TMPPDIR}"

# Use absolute directories for test source files.
tests=("$@")
for index in "${!tests[@]}"
do
    tests[index]="${JDK}"/test/jdk/sun/security/pkcs11/"${tests[index]}"
done
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
"${ROOT}"/jtreg/bin/jtreg -verbose:fail,error \
    -javaoption:-DCUSTOM_P11_CONFIG_NAME=p11-kryoptic.txt \
    -javaoption:-DCUSTOM_P11_LIBRARY_NAME=kryoptic_pkcs11 \
    -javaoption:-Djdk.test.lib.artifacts.nsslib-linux_x64="${TMPPDIR}" \
    -javaoption:-DCUSTOM_DB_DIR="${TMPPDIR}" \
    -testjdk:/usr/lib/jvm/java-21-openjdk \
    -javacoption:-g \
    "${tests[@]}"

# Local Variables:
# compile-command: "shellcheck --external-sources $(pwd)/jtreg-kryoptic.sh"
# End:
