#!/bin/bash

pip install -r requirements.txt -t ./package
cd package
zip -r ../function.zip .
cd ..
zip -g function.zip lambda_function.py