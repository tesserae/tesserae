#!/bin/bash

SRC="."
DOCUMENT_ROOT="/Users/rao3/Sites/tesserae/www"
SCRIPT_DIR="/Library/WebServer/CGI-Executables"
DATA_DIR="/Users/rao3/data"

# create directories
mkdir -p ${DOCUMENT_ROOT}/css
mkdir -p ${DOCUMENT_ROOT}/xsl
mkdir -p ${DOCUMENT_ROOT}/images
mkdir -p ${SCRIPT_DIR}
mkdir -p ${DATA_DIR}
mkdir -p ${DATA_DIR}/tess_hash
mkdir -p ${DATA_DIR}/tesserae/tmp

echo
echo "HTML-files:"
for filename in `ls ${SRC}/*.php ${SRC}/*.js ${SRC}/*.html favicon.ico icon.jpg 2>/dev/null`; 
do 
	echo "installing $filename to ${DOCUMENT_ROOT}"
	install $filename ${DOCUMENT_ROOT}
done

echo
echo "css stylesheets:"
for filename in `ls ${SRC}/css/*.css  2>/dev/null`; 
do 
	echo "installing $filename to ${DOCUMENT_ROOT}/css"
	install $filename ${DOCUMENT_ROOT}/css
done

echo
echo "xsl stylesheets:"
for filename in `ls ${SRC}/xsl/*.xsl  2>/dev/null`; 
do 
	echo "installing $filename to ${DOCUMENT_ROOT}/xsl"
	install $filename ${DOCUMENT_ROOT}/xsl
done

echo
echo "images:"
for filename in `ls ${SRC}/images/*.{png,gif,jpg,jpeg}  2>/dev/null`; 
do 
	echo "installing $filename to ${DOCUMENT_ROOT}/images"
	install $filename ${DOCUMENT_ROOT}/images
done

echo
echo "CGI-scripts:"
for filename in `ls ${SRC}/cgi-bin/{cwf_session,cwf_get-data}.pl 2>/dev/null`;
do 
	echo "installing $filename to ${SCRIPT_DIR}"
	install $filename ${SCRIPT_DIR}
done
