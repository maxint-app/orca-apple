filter-openapi:
	pnpx openapi-format http://192.168.1.101:8081/openapi.yaml -o dist/openapi-formatted.yaml --filterFile ./openapi-filters.yaml


generate:
	swift build

.PHONY: filter-openapi generate
