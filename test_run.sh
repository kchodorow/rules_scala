#!/bin/bash

set -e

test_disappearing_class() {
  git checkout test/src/main/scala/scala/test/disappearing_class/ClassProvider.scala
  bazel build test/src/main/scala/scala/test/disappearing_class:uses_class
  echo -e "package scala.test\n\nobject BackgroundNoise{}" > test/src/main/scala/scala/test/disappearing_class/ClassProvider.scala
  set +e
  bazel build test/src/main/scala/scala/test/disappearing_class:uses_class
  RET=$?
  git checkout test/src/main/scala/scala/test/disappearing_class/ClassProvider.scala
  if [ $RET -eq 0 ]; then
    echo "Class caching at play. This should fail"
    exit 1
  fi
  set -e
}

test_build_is_identical() {
  bazel build test/... 
  md5sum bazel-bin/test/*.jar > hash1
  bazel clean
  bazel build test/... 
  md5sum bazel-bin/test/*.jar > hash2
  diff hash1 hash2
}

bazel build test/... \
  && bazel run test:ScalaBinary \
  && bazel run test:ScalaLibBinary \
  && bazel run test:JavaBinary \
  && bazel run test:JavaBinary2 \
  && bazel run test/src/main/scala/scala/test/twitter_scrooge:justscrooges \
  && bazel test test/... \
  && find -L ./bazel-testlogs -iname "*.xml" \
  && (find -L ./bazel-testlogs -iname "*.xml" | xargs -n1 xmllint > /dev/null) \
  && test_disappearing_class \
  && test_build_is_identical \
  && echo "import scala.test._; HelloLib.printMessage(\"foo\")" | bazel-bin/test/HelloLibRepl | grep "foo scala" \
  && echo "all good"
