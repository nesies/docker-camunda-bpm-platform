#!/bin/bash

if [ $# -ne 3 ] ; then
	echo "SYNTAX: $0 path/to/bpm-platform.xml /path/to/xsl /path/to/xml"
	exit 1
fi
CAMUNDA_CONF=$1
XSL_FILE=$2
XML_CONF=$3

check() {
	local xml_file=$1
	local xpath_prefix=$2

	local xpath_base="$xpath_prefix/x:plugin[x:class='io.digitalstate.camunda.plugins.AdministrativeUserPlugin']/x:properties"
	local XML_USERNAME="$xpath_base/x:property[@name='administratorUserName']"
	local XML_PASSWORD="$xpath_base/x:property[@name='administratorPassword']"
	local XML_FIRSTNAME="$xpath_base/x:property[@name='administratorFirstName']"
	local XML_LASTNAME="$xpath_base/x:property[@name='administratorLastName']"
	local XML_EMAIL="$xpath_base/x:property[@name='administratorEmail']"
	local tmp
	# Checks
	tmp=$(xmlstarlet \
		sel \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
		-t -v \
		"${XML_USERNAME}" $xml_file)
	if [ "$tmp" != "$ADMIN_USERNAME" ] ; then
		echo "ERROR: $xml_conf administratorUserName does not match env ADMIN_USERNAME"
		exit 1
	fi
	tmp=$(xmlstarlet \
		sel \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
		-t -v \
		"${XML_PASSWORD}" $xml_file)
	if [ "$tmp" != "$ADMIN_PASSWORD" ] ; then
		echo "ERROR: $xml_conf administratorPassword does not match env ADMIN_PASSWORD"
		exit 1
	fi
	tmp=$(xmlstarlet \
		sel \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
		-t -v \
		"${XML_FIRSTNAME}" $xml_file)
	if [ "$tmp" != "$ADMIN_FIRSTNAME" ] ; then
		echo "ERROR: $xml_conf administratorFirstName does not match env ADMIN_FIRSTNAME"
		exit 1
	fi
	tmp=$(xmlstarlet \
		sel \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
		-t -v \
		"${XML_LASTNAME}" $xml_file)
	if [ "$tmp" != "$ADMIN_LASTNAME" ] ; then
		echo "ERROR: $xml_conf administratorLastNAme does not match env ADMIN_LASTNAME"
		exit 1
	fi
	tmp=$(xmlstarlet \
		sel \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
		-t -v \
		"${XML_PASSWORD}" $xml_file)
	if [ "$tmp" != "$ADMIN_PASSWORD" ] ; then
		echo "ERROR: $xml_conf administratorPassword does not match env ADMIN_PASSWORD"
		exit 1
	fi
}

update_xml() {
	local xml_conf=$1
	local xpath_prefix=$2
	local xpath_base="$xpath_prefix/x:plugin/x:properties"
	local XML_USERNAME="$xpath_base/x:property[@name='administratorUserName']"
	local XML_PASSWORD="$xpath_base/x:property[@name='administratorPassword']"
	local XML_FIRSTNAME="$xpath_base/x:property[@name='administratorFirstName']"
	local XML_LASTNAME="$xpath_base/x:property[@name='administratorLastName']"
	local XML_EMAIL="$xpath_base/x:property[@name='administratorEmail']"

	xmlstarlet ed -L \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
	 	-u "${XML_USERNAME}" -v "${ADMIN_USERNAME}" \
		-u "${XML_PASSWORD}" -v "${ADMIN_PASSWORD}" \
		-u "${XML_FIRSTNAME}" -v "${ADMIN_FIRSTNAME}" \
		-u "${XML_LASTNAME}" -v "${ADMIN_LASTNAME}" \
		-u "${XML_EMAIL}" -v "${ADMIN_EMAIL:-}" \
		$xml_conf
}

update_conf() {
	local camunda_conf=$1
	local xsl_file=$2
	local xml_conf=$3

	# check if already exists
	local xpath_prefix="/x:bpm-platform/x:process-engine/x:plugins"
	local xpath_base="$xpath_prefix/x:plugin[x:class='io.digitalstate.camunda.plugins.AdministrativeUserPlugin']/x:properties"
	local xpath="${xpath_base}/x:property[@name='administratorUserName']"
	local tmp

	tmp=$(xmlstarlet \
		sel \
		-N x=http://www.camunda.org/schema/1.0/BpmPlatform \
		-t -v \
		"count(${xpath})" $camunda_conf)
	if [ $tmp -eq 0 ] ; then
		# plugin definition not found
		echo "INFO plugin definition not found, adding"
		file_bck=${camunda_conf}.backup_administrativeuser
		file_tmp=${camunda_conf}.tmp
		cp $camunda_conf $file_bck
		xsltproc \
			-stringparam xml_conf $xml_conf \
			$xsl_file \
			$file_bck > $file_tmp
		if [ $? -ne 0 ] ; then
			echo "ERROR: failed to add administrativeuser on $camunda_conf"
			exit 1
		fi
		check $file_tmp /x:bpm-platform/x:process-engine/x:plugins
		mv $file_tmp $camunda_conf
	else
		# plugin definition found, only update
		echo "INFO plugin definition found, update $camunda_conf"
		update_xml $camunda_conf /x:bpm-platform/x:process-engine/x:plugins
	fi
}	

if [ -n "${ADMIN_USERNAME:-}" ] ; then
	if [ -z "${ADMIN_PASSWORD:-}" ] ; then
		echo "ADMIN_USERNAME set but no ADMIN_PASSWORD"
		exit 1
	fi
	if [ -z "${ADMIN_FIRSTNAME:-}" ] ; then
		echo "no ADMIN_FIRSTNAME"
		exit 1
	fi
	if [ -z "${ADMIN_LASTNAME:-}" ] ; then
		echo "no ADMIN_LASTNAME"
		exit 1
	fi
	if [ -z "${ADMIN_EMAIL:-}" ] ; then
		echo "no ADMIN_EMAIL"
		exit 1
	fi
	echo "Enabling custom user admin ($ADMIN_USERNAME)"
	update_xml $XML_CONF 
	check $XML_CONF 
	update_conf $CAMUNDA_CONF $XSL_FILE $XML_CONF
	echo "INFO remove /camunda/webapps/camunda-invoice"
	rm -rf /camunda/webapps/camunda-invoice
	echo "Enabled custom user admin"
else
	echo "Do not add custom user admin"
fi
