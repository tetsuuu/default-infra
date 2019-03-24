#!/bin/bash -e

init() {
  [ -z $ACCOUNT ] && ACCOUNT="$(basename `pwd`)" || ACCOUNT=$ACCOUNT
  [ -z $REGION ] && REGION="" || REGION="${REGION}/"

  cat << EOS
terraform {
  backend "s3" {
    bucket = "${BUCKET}"
    key    = "terraform/${ACCOUNT}/${REGION}${STAGE}/terraform.tfstate"
    region = "us-east-1"
  }
}
EOS

}

while getopts "b:r:s:a:" opt; do
  case "$opt" in
    a)
      ACCOUNT=$OPTARG
      ;;
    b)
      BUCKET=$OPTARG
      ;;
    r)
      REGION=$OPTARG
      ;;
    s)
      STAGE=$OPTARG
      ;;
  esac
done

shift $((OPTIND-1))

init
