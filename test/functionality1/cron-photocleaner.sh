#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$script_dir"

source ../util/setup.sh

set -ex

do_test () {
  q "delete from person"
  q "delete from duo_session"
  q "delete from undeleted_photo"

  ../util/create-user.sh user1 0 3
  ../util/create-user.sh user2 0 2

  user1id=$(get_id 'user1@example.com')
  user2id=$(get_id 'user2@example.com')

  # We'll delete photos with these uuids
  local uuid1=$(q "select uuid from photo where person_id = ${user1id} and position = 2")
  local uuid2=$(q "select uuid from photo where person_id = ${user2id} and position = 1")

  # Delete user1's photo
  wait_for_creation_by_uuid "${uuid1}"

  assume_role user1; jc DELETE /profile-info -d '{ "files": [2] }'

  wait_for_deletion_by_uuid "${uuid1}"

  # Delete user2's photo
  wait_for_creation_by_uuid "${uuid2}"

  assume_role user2; jc DELETE /profile-info -d '{ "files": [1] }'

  wait_for_deletion_by_uuid "${uuid2}"

  # Check that all the other images still exist
  local uuids=( $(q "select uuid from photo") )

  [[ "${#uuids[@]}" -eq 3 ]]

  for uuid in "${uuids[@]}"
  do
    wait_for_creation_by_uuid "${uuid}"
  done
}

do_test
