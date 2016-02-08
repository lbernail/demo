#!/bin/bash
set -e

echo "Hello"
pip freeze
aws s3 ls
