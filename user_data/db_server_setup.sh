#!/bin/bash
yum update -y
amazon-linux-extras install postgresql14 -y
yum install postgresql-server -y
postgresql-setup --initdb
systemctl start postgresql
systemctl enable postgresql 