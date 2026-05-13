#!/usr/bin/env bash
set -euo pipefail

COLLECTION="${1:-postman/collections/FIT4110_lab03_iot_ingestion.postman_collection.json}"
ENVIRONMENT="${2:-postman/environments/FIT4110_lab03_mock.postman_environment.json}"
REPORT="${3:-reports/newman-report.xml}"

mkdir -p reports

npx newman run "${COLLECTION}" \
  -e "${ENVIRONMENT}" \
  --reporters cli,junit \
  --reporter-junit-export "${REPORT}"
