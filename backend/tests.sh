#!/bin/bash
clear
docker compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from backend && docker compose -f docker-compose.test.yml down -v