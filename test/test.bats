#!/usr/bin/env bats

setup() {
  if [[ -z "${TEST_CONTAINER}" ]]; then
    echo "ERROR: TEST_CONTAINER environment variable is not set"
    echo "Example:"
    echo "  TEST_CONTAINER=my-container bats tests.bats"
    exit 1
  fi
}

@test "git version" {
  run bash -c "docker exec ${TEST_CONTAINER} git --help"
  [[ "${output}" =~ "usage:" ]]
}