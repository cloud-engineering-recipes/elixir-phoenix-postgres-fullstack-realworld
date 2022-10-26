#!/bin/bash

docker compose up -d && mix test && docker compose down
